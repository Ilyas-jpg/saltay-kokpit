#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/hook-meta.sh
# Extracts "<tool_name>|<file_path>" from the JSON Claude Code pipes to a hook
# on STDIN. The other hook scripts (backup.sh, secret-scan.sh, change-log.sh)
# start with:
#
#   m=$(bash "$(dirname "$0")/hook-meta.sh"); n=${m%%|*}; f=${m#*|}
#
# WHY THIS FILE EXISTS (docs/10-dersler.md — "hook fires ≠ hook works")
#   Hooks used to read $CLAUDE_TOOL_FILE_PATH / $CLAUDE_TOOL_NAME. A Claude Code
#   release changed that contract and the variables came back EMPTY — so the
#   backup hook kept "running" (log lines still appeared!) while producing no
#   backups for two weeks. The reliable source is the JSON on stdin
#   (hook_event_name, tool_name, tool_input.file_path).
#   If the env variables ever come back they are preferred (forward compatible).
#
# PARSING
#   jq when it is installed; otherwise the FIRST "key": "value" match. (v1.1 used
#   a greedy sed that picked the LAST match on the line.) Keys that appear inside
#   other string values are JSON-escaped (\"file_path\") and never match.
# =============================================================================

if [ -n "${CLAUDE_TOOL_FILE_PATH:-}" ] || [ -n "${CLAUDE_TOOL_NAME:-}" ]; then
  printf '%s|%s\n' "${CLAUDE_TOOL_NAME:-}" "${CLAUDE_TOOL_FILE_PATH:-}"
  exit 0
fi

# No stdin (manual run) -> do not block.
if [ -t 0 ]; then
  printf '|\n'
  exit 0
fi
IN=$(cat)

if command -v jq >/dev/null 2>&1; then
  name=$(printf '%s' "$IN" | jq -r '.tool_name // empty' 2>/dev/null)
  path=$(printf '%s' "$IN" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
else
  # grep -o lists every match in order; head -1 keeps the first one.
  first() {
    printf '%s' "$IN" | tr -d '\r\n' \
      | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
      | sed "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
  }
  name=$(first tool_name)
  path=$(first file_path)
  [ -n "$path" ] || path=$(first notebook_path)
  # Windows paths arrive JSON-escaped (C:\\Users\\...): un-double the backslashes.
  path=$(printf '%s' "$path" | sed 's/\\\\/\\/g')
fi

# Forward slashes for Git Bash (C:\Users\x -> C:/Users/x); harmless elsewhere.
path=$(printf '%s' "$path" | sed 's/\\/\//g')

printf '%s|%s\n' "$name" "$path"
