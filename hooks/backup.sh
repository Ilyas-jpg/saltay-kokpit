#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/backup.sh
# PreToolUse (Edit|MultiEdit|Write): copies the file BEFORE Claude changes it.
#
# Where the copy goes (v1.2)
#   file inside a git repo  ->  <repo root>/.backups/
#   anything else           ->  ~/.claude/saltay-backups/   (vault notes, loose files)
#   v1.1 wrote to .backups/ in the session's working directory: a session opened
#   on the Desktop scattered backups of D:\dev files onto the (OneDrive-synced)
#   Desktop. Override with SALTAY_BACKUP_DIR in vault.conf (one fixed folder).
#
# Also v1.2
#   - Write is covered: a Write over an existing file replaces it entirely.
#   - The name carries a short checksum of the full path: same-name files from
#     different folders never share a backup name.
#   - Every backup folder gets its own .gitignore ("*") when it is created, so a
#     copied .env can never be committed, whatever the project's .gitignore says.
#   - Nothing is ever deleted here; vault-health.sh reports the size.
# Never blocks the tool call: every failure path exits 0.
# =============================================================================

here="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME_DIR="$(dirname "$here")"
SALTAY_BACKUP_DIR=""
# shellcheck disable=SC1090
[ -f "${SALTAY_CONF:-$CLAUDE_HOME_DIR/vault.conf}" ] && . "${SALTAY_CONF:-$CLAUDE_HOME_DIR/vault.conf}" 2>/dev/null

m=$(bash "$here/hook-meta.sh"); f=${m#*|}
[ -n "$f" ] && [ -f "$f" ] || exit 0

if [ -n "$SALTAY_BACKUP_DIR" ]; then
  dir="$SALTAY_BACKUP_DIR"
elif root=$(cd "$(dirname "$f")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) && [ -n "$root" ]; then
  dir="$root/.backups"
else
  dir="$CLAUDE_HOME_DIR/saltay-backups"
fi

if [ ! -d "$dir" ]; then
  mkdir -p "$dir" 2>/dev/null || exit 0
  printf '*\n' > "$dir/.gitignore" 2>/dev/null
fi

sum=$(printf '%s' "$f" | cksum | cut -d' ' -f1)
cp "$f" "$dir/$(basename "$f").$sum.$(date +%Y%m%d_%H%M%S).bak" 2>/dev/null
exit 0
