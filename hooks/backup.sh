#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/backup.sh
# PreToolUse (Edit|MultiEdit|Write): copies the file into .backups/ in the
# current working directory BEFORE Claude changes it.
#
# v1.2 changes
#   - Write is covered too: a Write over an existing file replaces it entirely,
#     the most destructive edit of all — v1.1 did not back it up.
#   - The name carries a short checksum of the full path, so two files with the
#     same basename in different folders never share a backup name.
#   - .backups/ gets its own .gitignore ("*") the first time it is created: a
#     copied .env can never be committed by accident, whatever the project's
#     .gitignore says.
#   - Nothing is ever deleted here; vault-health.sh reports the folder size.
# Never blocks the tool call: every failure path exits 0.
# =============================================================================

m=$(bash "$(dirname "$0")/hook-meta.sh"); f=${m#*|}
[ -n "$f" ] && [ -f "$f" ] || exit 0

dir=".backups"
if [ ! -d "$dir" ]; then
  mkdir -p "$dir" 2>/dev/null || exit 0
  printf '*\n' > "$dir/.gitignore" 2>/dev/null
fi

sum=$(printf '%s' "$f" | cksum | cut -d' ' -f1)
cp "$f" "$dir/$(basename "$f").$sum.$(date +%Y%m%d_%H%M%S).bak" 2>/dev/null
exit 0
