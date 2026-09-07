#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/archive-project.sh <name> [--reason "why"]
# Closes a project the Saltay way — reversibly:
#   projects/Aktif/<name>/  →  projects/Arsiv/<name>/   (mv, nothing deleted)
#   vault/proje_<name>.md   status: archived + dated line
#   vault/MEMORY.md         📦 marker on the project's line
#   vault/not_kararlar.md   one dated decision entry
# Undo: mv it back and remove the status line — no data is lost at any step.
# =============================================================================
set -euo pipefail
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CONF="${SALTAY_CONF:-$CLAUDE_HOME/vault.conf}"
[ -f "$CONF" ] || { echo "vault.conf missing — run scripts/install.sh first"; exit 1; }
# shellcheck disable=SC1090
. "$CONF"

NAME="${1:-}"; REASON=""
[ -n "$NAME" ] || { echo "usage: archive-project.sh <name> [--reason \"why\"]"; exit 1; }
shift
while [ $# -gt 0 ]; do case "$1" in --reason) REASON="$2"; shift 2 ;; *) shift ;; esac; done
SLUG=$(printf '%s' "$NAME" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9._-]/-/g; s/--*/-/g; s/^-//; s/-$//')
KEY=$(printf '%s' "$SLUG" | tr '-' '_')
TODAY=$(date +%Y-%m-%d)

if [ "${VAULT_LANG:-tr}" = "en" ]; then
  ACTIVE="Active"; ARCHIVE="Archive"; PFX="project_"; DEC="$VAULT_DIR/note_decisions.md"
  T_ARCH="Archived"; T_REASON="reason"; T_ENTRY="archived"
else
  ACTIVE="Aktif"; ARCHIVE="Arsiv"; PFX="proje_"; DEC="$VAULT_DIR/not_kararlar.md"
  T_ARCH="Arşivlendi"; T_REASON="sebep"; T_ENTRY="arşivlendi"
fi

SRC="$PROJECTS_DIR/$ACTIVE/$SLUG"; DST="$PROJECTS_DIR/$ARCHIVE/$SLUG"
if [ -d "$SRC" ]; then
  [ -e "$DST" ] && DST="$DST-$TODAY"
  mkdir -p "$PROJECTS_DIR/$ARCHIVE" && mv "$SRC" "$DST"
  echo "moved   : $SRC → $DST"
else
  echo "folder  : $SRC not found (vault only)"
fi

NOTE="$VAULT_DIR/$PFX$KEY.md"
if [ -f "$NOTE" ]; then
  if grep -q '^status:' "$NOTE"; then
    awk '/^status:/ && !d {print "status: archived"; d=1; next} {print}' "$NOTE" > "$NOTE.tmp" && mv "$NOTE.tmp" "$NOTE"
  else
    awk 'NR==2 {print "status: archived"} {print}' "$NOTE" > "$NOTE.tmp" && mv "$NOTE.tmp" "$NOTE"
  fi
  printf '\n## %s %s\n\n%s: %s · %s: `%s`\n' "$T_ARCH" "$TODAY" "$T_REASON" "${REASON:-—}" "$ARCHIVE" "$DST" >> "$NOTE"
  echo "note    : $NOTE → status: archived"
else
  echo "note    : $NOTE not found"
fi

MEM="$VAULT_DIR/MEMORY.md"
if [ -f "$MEM" ] && grep -q "\[\[$PFX$KEY\]\]" "$MEM"; then
  sed -i.tmp "s/^- \[\[$PFX$KEY\]\]/- 📦 [[$PFX$KEY]]/" "$MEM" && rm -f "$MEM.tmp"
  echo "MEMORY  : 📦 marker set"
fi

if [ -f "$DEC" ]; then
  # insert the entry right after the first '---' separator (newest on top)
  awk -v e="## $TODAY — $NAME $T_ENTRY" -v r="${REASON:-—}" 'BEGIN{done=0} {print} /^---$/ && !done {print ""; print e; print ""; print r; print ""; done=1}' "$DEC" > "$DEC.tmp" && mv "$DEC.tmp" "$DEC"
  echo "decision: logged in $(basename "$DEC")"
fi
