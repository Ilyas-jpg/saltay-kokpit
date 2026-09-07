#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/new-project.sh <name> [--desc "one line"]
# Opens a project the Saltay way, in one go:
#   projects/Aktif/<name>/   + .gitignore (AI files excluded) + git init + README
#   vault/proje_<name>.md    from the template, dated
#   vault/MEMORY.md          one new line under "Aktif projeler"
# Claude usually does exactly this by itself when a new client/project shows
# up (CLAUDE.md → memory protocol); the script is the manual shortcut.
# =============================================================================
set -euo pipefail
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CONF="${SALTAY_CONF:-$CLAUDE_HOME/vault.conf}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$CONF" ] || { echo "vault.conf missing — run scripts/install.sh first"; exit 1; }
# shellcheck disable=SC1090
. "$CONF"

NAME="${1:-}"; DESC=""
[ -n "$NAME" ] || { echo "usage: new-project.sh <name> [--desc \"one line\"]"; exit 1; }
shift
while [ $# -gt 0 ]; do case "$1" in --desc) DESC="$2"; shift 2 ;; *) shift ;; esac; done
SLUG=$(printf '%s' "$NAME" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//')
KEY=$(printf '%s' "$SLUG" | tr '-' '_')
TODAY=$(date +%Y-%m-%d)

if [ "${VAULT_LANG:-tr}" = "en" ]; then
  ACTIVE="Active"; PFX="project_"; TPL="$REPO_DIR/templates/vault-en/project_EXAMPLE.md"; HDR="## 🚧 Active projects"; FILL="(fill in)"
else
  ACTIVE="Aktif"; PFX="proje_"; TPL="$REPO_DIR/templates/vault/proje_ORNEK.md"; HDR="## 🚧 Aktif projeler"; FILL="(doldur)"
fi

DIR="$PROJECTS_DIR/$ACTIVE/$SLUG"
[ -e "$DIR" ] && { echo "exists: $DIR"; exit 1; }
mkdir -p "$DIR"
cp "$REPO_DIR/templates/project/.gitignore" "$DIR/.gitignore"
printf '# %s\n\n%s\n' "$NAME" "${DESC:-}" > "$DIR/README.md"
if command -v git >/dev/null 2>&1; then (cd "$DIR" && git init -q && git add . && git commit -qm "chore: bootstrap $SLUG (saltay-kokpit)" >/dev/null 2>&1 || true); fi
echo "project : $DIR"

NOTE="$VAULT_DIR/$PFX$KEY.md"
if [ -e "$NOTE" ]; then
  echo "note    : $NOTE exists — not touched"
else
  sed -e "s|<Proje adı>|$NAME|g; s|<Project name>|$NAME|g" \
      -e "s|<tek cümle ne>|${DESC:-…}|g; s|<one sentence what>|${DESC:-…}|g" \
      -e "s|YYYY-MM-DD|$TODAY|g" \
      -e "s|<klasör>|$SLUG|g; s|<folder>|$SLUG|g" \
      -e "s|{{PROJECTS_DIR}}|$PROJECTS_DIR|g" "$TPL" > "$NOTE"
  if [ -n "$DESC" ]; then
    awk -v d="$DESC" 'BEGIN{done=0} /^description:/ && !done {print "description: " d; done=1; next} {print}' "$NOTE" > "$NOTE.tmp" && mv "$NOTE.tmp" "$NOTE"
  fi
  echo "note    : $NOTE"
fi

MEM="$VAULT_DIR/MEMORY.md"
LINE="- [[$PFX$KEY]] — ${DESC:-$FILL} ($TODAY)"
if grep -q "\[\[$PFX$KEY\]\]" "$MEM" 2>/dev/null; then
  echo "MEMORY  : line exists"
elif grep -q "^$HDR" "$MEM" 2>/dev/null; then
  awk -v h="$HDR" -v l="$LINE" '{print} $0==h {print l}' "$MEM" > "$MEM.tmp" && mv "$MEM.tmp" "$MEM"
  echo "MEMORY  : line added under \"$HDR\""
else
  printf '\n%s\n%s\n' "$HDR" "$LINE" >> "$MEM"
  echo "MEMORY  : section + line appended"
fi
