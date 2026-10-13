#!/usr/bin/env bash
# sync-skill.sh — mirror this repo's skill assets into every local agent install.
#
# Canonical source of truth is THIS git checkout. Installs are copies and they
# drift silently (that is exactly what happened between v1.1.0 and v1.2.0), so
# after any change here:
#
#   ./scripts/sync-skill.sh check    # rsync dry-run + byte cross-check (exit 1 if stale)
#   ./scripts/sync-skill.sh sync     # update installs, then self-verify them
#   ./scripts/sync-skill.sh verify   # byte compare only (diff -r / cmp)
#   ./scripts/sync-skill.sh list     # show targets and file counts
#
# Every mode ends with the same authoritative byte comparison, so a pass is
# evidence rather than rsync agreeing with itself: `check` cross-checks rsync's
# dry-run against a real diff (and reports an inconsistency if the two disagree),
# and `sync` verifies its own work before calling itself done.
#
# Mirrored:  SKILL.md, README.md, templates/, references/, docs/
# Skipped:   .git/, .github/, tests/, scripts/   (repo-only)
# Preserved: anything matching _archive* (local-only investigation artifacts),
#            __pycache__/, *.pyc — never uploaded, never deleted.
#
# Override targets with SKILL_TARGETS, colon-separated, relative to $HOME:
#   SKILL_TARGETS=".hermes/skills/surgical-investigation" ./scripts/sync-skill.sh check
#
# Exit codes: 0 = in sync / success, 1 = drift detected (check, verify), 2 = usage.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-check}"

case "$MODE" in
  check|sync|verify|list) ;;
  -h|--help|help) sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "usage: $(basename "$0") [check|sync|verify|list]" >&2; exit 2 ;;
esac

# --- install targets (relative to $HOME) --------------------------------------
if [ -n "${SKILL_TARGETS:-}" ]; then
  IFS=':' read -r -a TARGETS <<< "$SKILL_TARGETS"
else
  TARGETS=(
    ".hermes/skills/surgical-investigation"                        # Hermes (primary)
    ".config/opencode/skills/surgical-investigation"               # OpenCode
    ".gemini/skills/surgical-investigation"                        # Gemini CLI
    ".gemini/surgical/surgical-investigation"                      # Gemini CLI (bundle)
    ".gemini/antigravity-cli/skills/surgical-investigation"        # Antigravity CLI
  )
fi

# --- what gets mirrored -------------------------------------------------------
INCLUDE=(SKILL.md README.md templates references docs)
RSYNC_EXCLUDES=(--exclude '_archive*' --exclude '__pycache__' --exclude '*.pyc')
DIFF_EXCLUDES=(--exclude='_archive*' --exclude='__pycache__' --exclude='*.pyc')

# byte_compare <install-dir>
# Independent of rsync: prints every difference and returns 1 if any exist.
byte_compare() {
  local dest="$1" p d diffs=""
  for p in "${INCLUDE[@]}"; do
    [ -e "$REPO_DIR/$p" ] || continue
    if [ ! -e "$dest/$p" ]; then
      diffs+="missing in install: $p"$'\n'
    elif [ -d "$REPO_DIR/$p" ]; then
      d=$(diff -r -q "${DIFF_EXCLUDES[@]}" "$REPO_DIR/$p" "$dest/$p" 2>&1 || true)
      [ -z "$d" ] || diffs+="$d"$'\n'
    else
      cmp -s "$REPO_DIR/$p" "$dest/$p" || diffs+="differs: $p"$'\n'
    fi
  done
  [ -n "$diffs" ] || return 0
  printf '%s' "$diffs"
  return 1
}

echo "repo   : $REPO_DIR"
echo "commit : $(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"
echo "mode   : $MODE"
echo

changed=0
dirty=0
missing=0
failed=0

for rel in "${TARGETS[@]}"; do
  dest="$HOME/$rel"

  if [ ! -d "$dest" ]; then
    if [ "$MODE" = sync ]; then
      mkdir -p "$dest"
      echo "[NEW ] $rel"
    else
      echo "[SKIP] $rel — not installed"
      missing=$((missing + 1))
      continue
    fi
  fi

  if [ "$MODE" = list ]; then
    printf '[OK  ] %-56s %s file(s)\n' "$rel" \
      "$(find "$dest" -type f -not -path '*__pycache__*' -not -path '*_archive*' | wc -l)"
    continue
  fi

  # --- verify: byte comparison only -------------------------------------------
  if [ "$MODE" = verify ]; then
    if diffs=$(byte_compare "$dest"); then
      echo "[OK  ] $rel — byte-identical to repo"
    else
      echo "[FAIL] $rel — differs:"
      printf '%s' "$diffs" | sed 's/^/        /'
      dirty=$((dirty + 1))
    fi
    continue
  fi

  # --- check / sync: rsync, then never trust it alone --------------------------
  flags=(-a --delete "${RSYNC_EXCLUDES[@]}" --itemize-changes)
  if [ "$MODE" = check ]; then
    flags+=(--dry-run)
  fi

  out=""
  for p in "${INCLUDE[@]}"; do
    [ -e "$REPO_DIR/$p" ] || continue
    # Trailing newline keeps itemized lines from gluing together (rsync's last
    # line has none, and command substitution strips it).
    out+="$(rsync "${flags[@]}" "$REPO_DIR/$p" "$dest/" 2>&1 || true)"$'\n'
  done

  # '<'/'>' transfer, 'c' local change, 'h' hardlink, '*' = "*deleting".
  # A deletion-only drift prints only '*' lines, so it must be counted or the
  # target would report "in sync" while a file is missing.
  n=$(printf '%s' "$out" | grep -c '^[<>ch*]' || true)

  if diffs=$(byte_compare "$dest"); then
    if [ "$n" -gt 0 ] && [ "$MODE" = check ]; then
      # rsync wanted changes but the bytes already match — harmless metadata
      # difference (mtimes). Report it rather than hiding it.
      echo "[OK  ] $rel — in sync ($n metadata-only change(s) pending)"
    elif [ "$MODE" = sync ] && [ "$n" -gt 0 ]; then
      echo "[SYNC] $rel — $n change(s) applied"
    else
      echo "[OK  ] $rel — in sync"
    fi
    changed=$((changed + n))
  else
    if [ "$MODE" = sync ]; then
      echo "[FAIL] $rel — sync incomplete, still differs:"
      failed=$((failed + 1))
    else
      echo "[STALE] $rel — out of date:"
      dirty=$((dirty + 1))
    fi
    printf '%s' "$diffs" | sed 's/^/        /'
    [ -n "$out" ] && printf '%s' "$out" | sed 's/^/        rsync: /'
  fi
done

echo
case "$MODE" in
  sync)
    if [ "$failed" -gt 0 ]; then
      echo "FAILED: $failed install(s) still differ after syncing."
      exit 1
    fi
    echo "Done. $changed file operation(s); every install verified byte-identical."
    ;;
  list)
    echo "${#TARGETS[@]} target(s) configured."
    ;;
  check|verify)
    if [ "$dirty" -eq 0 ]; then
      echo "Verified: $(( ${#TARGETS[@]} - missing )) install(s) match the repo."
      if [ "$missing" -gt 0 ]; then
        echo "($missing target(s) not installed on this machine — skipped)"
      fi
      exit 0
    fi
    echo "$dirty install(s) out of date — run: $0 sync"
    exit 1
    ;;
esac
