#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/change-log.sh
# PostToolUse (Edit|MultiEdit|Write): appends "[time] tool path" to
# ~/.claude/changes.log (the folder this script lives in, one level up).
#
# v1.2: the log is rotated at 1 MB — renamed to changes.<date>.log, NEVER
# deleted (docs/10-dersler.md: logs are never deleted).
# =============================================================================

here="$(cd "$(dirname "$0")" && pwd)"
log="$(dirname "$here")/changes.log"
m=$(bash "$here/hook-meta.sh")

if [ -f "$log" ] && [ "$(wc -c < "$log")" -gt 1048576 ]; then
  mv "$log" "$(dirname "$here")/changes.$(date +%Y%m%d_%H%M%S).log" 2>/dev/null
fi
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${m%%|*} ${m#*|}" >> "$log"
exit 0
