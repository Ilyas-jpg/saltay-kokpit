#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/hook-meta.sh
# Extracts "<tool_name>|<file_path>" from the JSON Claude Code pipes to a hook
# on STDIN. Every other hook in settings.json starts with this line:
#
#   m=$(bash ~/.claude/hooks/hook-meta.sh); n=${m%%|*}; f=${m#*|}
#
# WHY THIS FILE EXISTS (docs/10-dersler.md — "hook fires ≠ hook works")
#   Hooks used to read $CLAUDE_TOOL_FILE_PATH / $CLAUDE_TOOL_NAME. A Claude Code
#   release changed that contract and the variables came back EMPTY — so the
#   backup hook kept "running" (log lines still appeared!) while producing no
#   backups for two weeks. The reliable source is the JSON on stdin
#   (hook_event_name, tool_name, tool_input.file_path).
#   If the env variables ever come back they are preferred (forward compatible).
# =============================================================================

if [ -n "$CLAUDE_TOOL_FILE_PATH" ] || [ -n "$CLAUDE_TOOL_NAME" ]; then
  printf '%s|%s\n' "$CLAUDE_TOOL_NAME" "$CLAUDE_TOOL_FILE_PATH"
  exit 0
fi

# No stdin (manual run) -> do not block.
if [ -t 0 ]; then
  printf '|\n'
  exit 0
fi
IN=$(cat)

name=$(printf '%s' "$IN" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
# file_path lives inside tool_input; the JSON arrives on one line so the first match is right.
path=$(printf '%s' "$IN" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
# Windows paths arrive JSON-escaped (C:\\Users\\...). Convert to forward slashes for Git Bash.
path=$(printf '%s' "$path" | sed 's/\\\\/\//g; s/\\/\//g')

printf '%s|%s\n' "$name" "$path"
