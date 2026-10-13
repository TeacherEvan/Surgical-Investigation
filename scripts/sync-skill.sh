#!/usr/bin/env bash
# sync-skill.sh — mirror this repo's skill assets into every local agent install.
#
# Canonical source of truth is THIS git checkout. Installs are copies and will
# drift (that is exactly what happened between v1.1.0 and v1.2.0), so after any
# change here, run:
#
#   ./scripts/sync-skill.sh check    # show what differs, change nothing
#   ./scripts/sync-skill.sh sync     # bring every install up to date
#   ./scripts/sync-skill.sh verify   # byte-compare each install against the repo
#
# Mirrored:  SKILL.md, README.md, templates/, references/, docs/
# Skipped:   .git/, .github/, tests/, scripts/  (repo-only)
# Preserved: anything matching _archive* (local-only investigation artifacts),
#            __pycache__/, *.pyc — never uploaded, never deleted.
#
# Override targets with SKILL_TARGETS, colon-separated, relative to $HOME:
#   SKILL_TARGETS=".hermes/skills/surgical-investigation" ./scripts/sync-skill.sh sync

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-check}"
SKILL_NAME="$(basename "$REPO_DIR")"

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
EXCLUDES=(--exclude '_archive*' --exclude '__pycache__' --exclude '*.pyc')
BASE_FLAGS=(-a --delete "${EXCLUDES[@]}")

case "$MODE" in
  check)  FLAGS=("${BASE_FLAGS[@]}" --dry-run --itemize-changes) ;;
  sync)   FLAGS=("${BASE_FLAGS[@]}" --itemize-changes) ;;
  verify) FLAGS=("${BASE_FLAGS[@]}" --dry-run --itemize-changes) ;;
  *) echo "usage: $0 [check|sync|verify]" >&2; exit 2 ;;
esac

echo "repo   : $REPO_DIR"
echo "commit : $(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"
echo "mode   : $MODE"
echo

changed_total=0
dirty=0

for rel in "${TARGETS[@]}"; do
  dest="$HOME/$rel"
  if [ -d "$dest" ]; then
    label="OK  "
  elif [ "$MODE" = sync ]; then
    mkdir -p "$dest"
    label="NEW "
  else
    echo "[SKIP] $rel (not installed)"
    continue
  fi

  out=""
  for p in "${INCLUDE[@]}"; do
    [ -e "$REPO_DIR/$p" ] || continue
    out+="$(rsync "${FLAGS[@]}" "$REPO_DIR/$p" "$dest/" || true)"
  done

  n=$(printf '%s' "$out" | grep -c '^[<>ch]' || true)
  if [ "$n" -eq 0 ]; then
    echo "[$label] $rel — in sync ($(find "$dest" -type f -not -path '*__pycache__*' | wc -l) files)"
  else
    echo "[$label] $rel — $n change(s)"
    [ "$MODE" != sync ] && printf '%s\n' "$out" | sed 's/^/        /'
    [ "$MODE" = sync ] && printf '%s\n' "$out" | sed 's/^/        /'
    dirty=$((dirty + 1))
  fi
  changed_total=$((changed_total + n))
done

echo
if [ "$MODE" = sync ]; then
  echo "Done. $changed_total file operation(s) across ${#TARGETS[@]} target(s)."
  echo "Re-run '$0 verify' to confirm every install matches $SKILL_NAME."
else
  if [ "$dirty" -eq 0 ]; then
    echo "All installs match the repo. Nothing to do."
  else
    echo "$dirty install(s) out of date — run '$0 sync' to fix."
    exit 1
  fi
fi
