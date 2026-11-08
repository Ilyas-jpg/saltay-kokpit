#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/uninstall.sh
# Removes what install.sh registered — reversibly. Nothing is deleted:
#   settings.json   every saltay hook command (current + older releases) removed
#                   by exact match; a timestamped backup is taken first
#   hooks/*.sh, vault.conf, session-reminder.json, saltay-kokpit.version
#                   renamed to <name>.<date>.bak
# Never touched: your vault, CLAUDE.md / CLAUDE.saltay.md, the projects folder,
# changes.log, .backups/ folders, env keys in settings.json (you may have set
# CLAUDE_CODE_DISABLE_BACKGROUND_TASKS yourself — remove it by hand if not).
#
# Usage: bash scripts/uninstall.sh [--claude-home DIR] [--dry-run]
# =============================================================================
set -euo pipefail
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --claude-home) CLAUDE_HOME="${2:?--claude-home needs a value}"; shift 2 ;;
    --dry-run)     DRY=1; shift ;;
    -h|--help)     sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
done
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
. "$REPO_DIR/scripts/lib.sh"
TS="$(date +%Y%m%d_%H%M%S)"
say() { printf '%s\n' "$*"; }
retire() {
  [ -e "$1" ] || return 0
  if [ "$DRY" -eq 1 ]; then say "  [dry-run] $1 → $1.$TS.bak"; else mv "$1" "$1.$TS.bak"; say "  retire : $1 → .$TS.bak"; fi
}

say "saltay-kokpit uninstall  (claude home: $CLAUDE_HOME)"
S="$CLAUDE_HOME/settings.json"
say "[1/2] settings.json"
if [ ! -f "$S" ]; then
  say "  not found — nothing to remove"
elif [ "$DRY" -eq 1 ]; then
  say "  [dry-run] would back up $S and remove every saltay hook command"
else
  cp "$S" "$S.$TS.bak"; say "  backup : $S.$TS.bak"
  # home path passed exactly as bash spells it (see install.sh), file paths made native
  N_S=$(native "$S"); N_H=$(native "$REPO_DIR/hooks/settings.hooks.json"); N_R=$(native "$REPO_DIR/hooks/settings.remove.json")
  if command -v node >/dev/null 2>&1; then
    MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' node "$(native "$REPO_DIR/scripts/merge-settings.js")" "$N_S" "$N_H" "$N_R" --home "$CLAUDE_HOME" --uninstall
  elif python3 -c 'import sys' >/dev/null 2>&1; then
    MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' python3 "$(native "$REPO_DIR/scripts/merge-settings.py")" "$N_S" "$N_H" "$N_R" --home "$CLAUDE_HOME" --uninstall
  else
    say "  !! neither node nor python3 found — remove the saltay hook commands from $S by hand"
  fi
fi

say "[2/2] files"
for f in hooks/vault-index.sh hooks/hook-meta.sh hooks/backup.sh hooks/secret-scan.sh hooks/change-log.sh \
         vault.conf session-reminder.json saltay-kokpit.version; do
  retire "$CLAUDE_HOME/$f"
done

say ""
say "done. Kept: your vault, CLAUDE.md$( [ -e "$CLAUDE_HOME/CLAUDE.saltay.md" ] && echo ' (+ CLAUDE.saltay.md — delete it if you do not need it)'), changes.log, .backups/."
say "If install.sh created CLAUDE.md for you, review it — it still describes the saltay hooks."
say "Restart Claude Code. Reinstall any time: bash scripts/install.sh"
