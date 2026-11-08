#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/session-track.sh
# PostToolUse (Edit|MultiEdit|Write|NotebookEdit|Bash): records, per session,
# what kind of work happened, for journal-reminder.sh (Stop hook).
#
#   ~/.claude/saltay-state/<session_id>.log
#     E<TAB><path>   a file was edited / written
#     B              a shell command ran
#     R              journal-reminder.sh reset point (written by the Stop hook)
#
# Deliberately tiny: it runs after EVERY Bash call, so no hook-meta.sh
# subprocess, one read of stdin, jq when available. Never blocks: exit 0.
# =============================================================================

here="$(cd "$(dirname "$0")" && pwd)"
state="$(dirname "$here")/saltay-state"
[ -t 0 ] && exit 0
IN=$(cat)

if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$IN" | jq -r '.session_id // empty' 2>/dev/null)
  tool=$(printf '%s' "$IN" | jq -r '.tool_name // empty' 2>/dev/null)
  path=$(printf '%s' "$IN" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
else
  first() {
    printf '%s' "$IN" | tr -d '\r\n' | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
      | sed "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
  }
  sid=$(first session_id); tool=$(first tool_name)
  path=$(first file_path); [ -n "$path" ] || path=$(first notebook_path)
  path=$(printf '%s' "$path" | sed 's/\\\\/\\/g')
fi
# session ids are uuids; anything else is not used as a file name
case "$sid" in ''|*[!A-Za-z0-9_-]*) exit 0 ;; esac

mkdir -p "$state" 2>/dev/null || exit 0
if [ "$tool" = "Bash" ]; then
  echo "B" >> "$state/$sid.log"
elif [ -n "$path" ]; then
  printf 'E\t%s\n' "$(printf '%s' "$path" | sed 's/\\/\//g')" >> "$state/$sid.log"
fi
exit 0
