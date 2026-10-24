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
# Must run FROM a git checkout. The script refuses to mirror from a directory that
# is not the toplevel of its own clone: `git -C` otherwise walks up to a parent
# repository and reports a commit that has nothing to do with this skill
# (observed: a stray directory inside ~/.hermes reported ~/.hermes's HEAD).
#
# The skill name comes from SKILL.md frontmatter, NOT from the directory name, so
# a checkout like .../cache/surgical-inv-src still targets .../surgical-investigation.
#
# The Hermes target is DISCOVERED, because the install may be flat or nested one
# level under a category directory:
#   .hermes/skills/surgical-investigation
#   .hermes/skills/<category>/surgical-investigation     <- e.g. skills/DOCTOR/
# If neither exists, the flat path is kept so `sync` can create it.
#
# Override targets with SKILL_TARGETS, colon-separated, relative to $HOME:
#   SKILL_TARGETS=".hermes/skills/DOCTOR/surgical-investigation" ./scripts/sync-skill.sh check
#
# Exit codes: 0 = in sync / success, 1 = drift detected (check, verify),
#             2 = usage error, or not run from a git checkout.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-check}"

case "$MODE" in
  check|sync|verify|list) ;;
  # print the whole leading comment block, however long it grows
  -h|--help|help) awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
  *) echo "usage: $(basename "$0") [check|sync|verify|list]" >&2; exit 2 ;;
esac

# --- refuse to run outside a real checkout -------------------------------------
TOPLEVEL="$(git -C "$REPO_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [ "$TOPLEVEL" != "$REPO_DIR" ]; then
  echo "ERROR: not a git checkout of this skill repo." >&2
  echo "       dir      : $REPO_DIR" >&2
  echo "       toplevel : ${TOPLEVEL:-<none>}" >&2
  echo "       Clone the repo and run scripts/sync-skill.sh from inside the clone." >&2
  exit 2
fi

# --- skill name: frontmatter wins over directory name --------------------------
# A checkout may be named anything (e.g. .../cache/surgical-inv-src); the installs
# are always named after the skill, which is what SKILL.md frontmatter declares.
SKILL_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$REPO_DIR/SKILL.md" 2>/dev/null | head -1 | tr -d '"[:space:]')"
[ -n "$SKILL_NAME" ] || SKILL_NAME="$(basename "$REPO_DIR")"

# --- install targets (relative to $HOME) --------------------------------------
if [ -n "${SKILL_TARGETS:-}" ]; then
  IFS=':' read -r -a TARGETS <<< "$SKILL_TARGETS"
else
  # Hermes: discover the install — flat, or nested one level under a category dir.
  TARGETS=()
  shopt -s nullglob
  for cand in "$HOME/.hermes/skills/$SKILL_NAME" "$HOME"/.hermes/skills/*/"$SKILL_NAME"; do
    [ -d "$cand" ] && TARGETS+=("${cand#"$HOME"/}")
  done
  shopt -u nullglob
  # Nothing installed yet — keep the documented flat path so `sync` can create it.
  [ "${#TARGETS[@]}" -gt 0 ] || TARGETS=(".hermes/skills/$SKILL_NAME")

  TARGETS+=(
    ".config/opencode/skills/$SKILL_NAME"               # OpenCode
    ".gemini/skills/$SKILL_NAME"                        # Gemini CLI
    ".gemini/surgical/$SKILL_NAME"                      # Gemini CLI (bundle)
    ".gemini/antigravity-cli/skills/$SKILL_NAME"        # Antigravity CLI
    ".cursor/skills/$SKILL_NAME"                        # Cursor
  )
fi

# --- de-duplicate by real path -------------------------------------------------
# `~/.config/opencode/skills` is commonly a symlink to `~/.hermes/skills`. Without
# this, the same directory is synced twice (and a second --delete pass runs against
# a tree the first pass just wrote). Cursor has the same shape on some installs.
resolve_target() {
  local rel="$1" parent base
  parent="$(dirname "$HOME/$rel")"
  base="$(basename "$rel")"
  if [ -d "$parent" ]; then
    printf '%s/%s\n' "$(cd -P "$parent" && pwd)" "$base"
  else
    printf '%s/%s\n' "$parent" "$base"
  fi
}

UNIQUE=()
for rel in "${TARGETS[@]}"; do
  real="$(resolve_target "$rel")"
  skip=0
  for seen in "${UNIQUE[@]}"; do
    [ "$(resolve_target "$seen")" = "$real" ] && skip=1 && break
  done
  if [ "$skip" -eq 0 ]; then
    UNIQUE+=("$rel")
  else
    echo "[DEDUPE] $rel -> same directory as an earlier target" >&2
  fi
done
TARGETS=("${UNIQUE[@]}")

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
echo "skill  : $SKILL_NAME"
echo "commit : $(git -C "$REPO_DIR" rev-parse --short HEAD) ($(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD))"
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
