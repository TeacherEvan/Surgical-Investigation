#!/usr/bin/env bash
# sync-skill.sh — mirror this repo's skill assets into every local agent install.
#
# Canonical source of truth is THIS git checkout. Installs are copies and they
# drift silently (that is exactly what happened between v1.1.0 and v1.2.0), so
# after any change here:
#
#   ./scripts/sync-skill.sh check    # rsync dry-run: what differs (exit 1 if stale)
#   ./scripts/sync-skill.sh sync     # bring every install up to date
#   ./scripts/sync-skill.sh verify   # independent byte compare (diff -r / cmp)
#   ./scripts/sync-skill.sh list     # show targets and whether they exist
#
# check and verify are both read-only, and deliberately use DIFFERENT mechanisms
# (rsync dry-run vs diff/cmp), so a passing verify is real evidence instead of
# rsync agreeing with itself.
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
  -h|--help|help) sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

echo "repo   : $REPO_DIR"
echo "commit : $(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"
echo "mode   : $MODE"
echo

changed=0
dirty=0
missing=0

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

  if [ "$MODE" = verify ]; then
    # Independent mechanism: byte comparison, not rsync's own dry-run report.
    diffs=""
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
    if [ -z "$diffs" ]; then
      echo "[OK  ] $rel — byte-identical to repo"
    else
      echo "[FAIL] $rel — $(printf '%s' "$diffs" | grep -c . ) difference(s)"
      printf '%s' "$diffs" | sed 's/^/        /'
      dirty=$((dirty + 1))
    fi
    continue
  fi

  # --- check / sync: rsync with itemized output -------------------------------
  flags=(-a --delete "${RSYNC_EXCLUDES[@]}" --itemize-changes)
  if [ "$MODE" = check ]; then
    flags+=(--dry-run)
  fi

  out=""
  for p in "${INCLUDE[@]}"; do
    [ -e "$REPO_DIR/$p" ] || continue
    out+="$(rsync "${flags[@]}" "$REPO_DIR/$p" "$dest/" 2>&1 || true)"
  done

  # '<'/'>' = transfer, 'c' = local change, 'h' = hardlink, '*' = "*deleting"
  # (rsync flags pruned files with a leading '*', so it must be counted too —
  # otherwise a deletion-only drift reports "in sync").
  n=$(printf '%s' "$out" | grep -c '^[<>ch*]' || true)
  changed=$((changed + n))
  if [ "$n" -eq 0 ]; then
    echo "[OK  ] $rel — in sync"
    continue
  fi

  if [ "$MODE" = sync ]; then
    echo "[SYNC] $rel — $n change(s) applied"
  else
    echo "[STALE] $rel — $n change(s) needed"
  fi
  printf '%s' "$out" | sed 's/^/        /'
  dirty=$((dirty + 1))
done

echo
case "$MODE" in
  sync)
    echo "Done. $changed file operation(s); $dirty install(s) updated."
    echo "Next: $0 verify"
    ;;
  list)
    echo "${#TARGETS[@]} target(s) configured."
    ;;
  check|verify)
    if [ "$dirty" -eq 0 ]; then
      echo "All $(( ${#TARGETS[@]} - missing )) install(s) match the repo."
      if [ "$missing" -gt 0 ]; then
        echo "($missing target(s) not installed on this machine — skipped)"
      fi
      exit 0
    fi
    echo "$dirty install(s) out of date — run: $0 sync"
    exit 1
    ;;
esac
