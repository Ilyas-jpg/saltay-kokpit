#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/secret-scan.sh
# PostToolUse (Edit|MultiEdit|Write): looks for hardcoded secrets in the file
# Claude just changed and TELLS CLAUDE about them.
#
# v1.1 problems this fixes
#   - The warning went to stderr with exit 0. Claude Code shows that only in
#     the transcript; the MODEL never saw it. Exit 2 feeds stderr back to Claude
#     (the edit has already happened; Claude is asked to fix it).
#   - The regex used \x27 inside a grep -E bracket, which grep reads as the
#     characters \ x 2 7, not as a single quote: 'single-quoted' values,
#     "key": "value" (JSON/YAML) and any value containing x, 2 or 7 were missed.
#
# What it reports: line number + pattern name. Never the value itself.
# Skipped: .env files (that IS where secrets belong — keep them out of git),
# *.example / *.sample, binaries, files over 1 MB, placeholder values.
# =============================================================================

m=$(bash "$(dirname "$0")/hook-meta.sh"); f=${m#*|}
[ -n "$f" ] && [ -f "$f" ] || exit 0

case "$(basename "$f")" in
  .env|.env.*|*.example|*.sample|*.template) exit 0 ;;
esac
case "$f" in
  */.backups/*|*/node_modules/*|*/.git/*) exit 0 ;;
esac
# size and binary guard
[ "$(wc -c < "$f" 2>/dev/null || echo 0)" -le 1048576 ] || exit 0
grep -qI . "$f" 2>/dev/null || exit 0

Q="[\"']"
NQ="[^\"'[:space:]]"
# name|regex  (POSIX ERE, case-insensitive for the assignment rule only)
RULES="assignment|(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token|private[_-]?key|client[_-]?secret)${Q}?[[:space:]]*[:=][[:space:]]*${Q}${NQ}{8,}${Q}
anthropic-key|sk-ant-[A-Za-z0-9_-]{20,}
openai-key|(^|[^A-Za-z0-9_-])sk-(proj-)?[A-Za-z0-9_-]{20,}
github-token|(ghp|gho|ghs|ghu)_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}
aws-access-key|AKIA[0-9A-Z]{16}
google-api-key|AIza[0-9A-Za-z_-]{35}
slack-token|xox[abprs]-[A-Za-z0-9-]{10,}
private-key-block|-----BEGIN [A-Z ]*PRIVATE KEY-----"

# lines that are obviously not real secrets
PLACEHOLDER='example|placeholder|your[_-]|<[a-z_]+>|changeme|xxxxxx|\*\*\*\*|\$\{|process\.env|os\.environ|getenv|import\.meta\.env'

hits=""
while IFS='|' read -r name rx; do
  [ -n "$name" ] || continue
  if [ "$name" = "assignment" ]; then flags="-niE"; else flags="-nE"; fi
  lines=$(grep $flags -- "$rx" "$f" 2>/dev/null | grep -viE "$PLACEHOLDER" | cut -d: -f1 | head -5 | tr '\n' ',' | sed 's/,$//')
  [ -n "$lines" ] && hits="$hits
  - $name (line $lines)"
done <<EOF
$RULES
EOF

[ -n "$hits" ] || exit 0
{
  echo "⚠️  saltay secret-scan: possible hardcoded secret in $f$hits"
  echo "Move the value to an environment variable / .env (gitignored) or a password manager, and reference it from the code."
} >&2
exit 2
