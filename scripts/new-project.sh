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
# shellcheck source=lib.sh
. "$REPO_DIR/scripts/lib.sh"
[ -n "${PROJECTS_DIR:-}" ] || { echo "projects folder is not configured (installed with --no-projects). Re-run install.sh with --projects DIR."; exit 1; }
SLUG=$(slugify "$NAME")
[ -n "$SLUG" ] || { echo "cannot build a folder name from \"$NAME\" — use letters or digits"; exit 1; }
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

# ---- folders layout (v1.2): human-readable note in PROJECT_NOTES_DIR + link in PROJECT_MOC
if [ "${VAULT_LAYOUT:-flat}" = "folders" ]; then
  NDIR="$VAULT_DIR/${PROJECT_NOTES_DIR:-.}"
  NOTE="$NDIR/$NAME.md"
  if [ -e "$NOTE" ]; then
    echo "note    : $NOTE exists — not touched"
  else
    mkdir -p "$NDIR"
    printf -- '---\ntype: %s\ntags: [%s]\ncreated: %s\nupdated: %s\nsummary: %s\nstatus: active\n---\n# %s\n\n%s\n\n- %s: `%s`\n' \
      "${PFX%_}" "${PFX%_}" "$TODAY" "$TODAY" "${DESC:-$FILL}" "$NAME" "${DESC:-$FILL}" "${ACTIVE}" "$DIR" > "$NOTE"
    echo "note    : $NOTE"
  fi
  if [ -n "${PROJECT_MOC:-}" ]; then
    MOC="$VAULT_DIR/$PROJECT_MOC.md"
    if grep -qF "[[$NAME]]" "$MOC" 2>/dev/null; then echo "MOC     : link exists"
    else printf -- '- [[%s]] — %s (%s)\n' "$NAME" "${DESC:-$FILL}" "$TODAY" >> "$MOC"; echo "MOC     : link added to $PROJECT_MOC"; fi
  fi
  exit 0
fi

NOTE="$VAULT_DIR/$PFX$KEY.md"
if [ -e "$NOTE" ]; then
  echo "note    : $NOTE exists — not touched"
else
  eN=$(sed_escape "$NAME"); eD=$(sed_escape "${DESC:-…}"); eP=$(sed_escape "$PROJECTS_DIR")
  sed -e "s|<Proje adı>|$eN|g; s|<Project name>|$eN|g" \
      -e "s|<tek cümle ne>|$eD|g; s|<one sentence what>|$eD|g" \
      -e "s|YYYY-MM-DD|$TODAY|g" \
      -e "s|<klasör>|$SLUG|g; s|<folder>|$SLUG|g" \
      -e "s|{{PROJECTS_DIR}}|$eP|g" "$TPL" > "$NOTE"
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
