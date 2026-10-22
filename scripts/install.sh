#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/install.sh
#
# Installs the four layers: vault (memory) · CLAUDE.md (constitution) ·
# hooks + reminder (reflexes) · projects folder skeleton (order).
# Idempotent: existing files are never overwritten without a timestamped
# backup, existing vault notes are never touched. Upgrading from v1.0: the two
# old prompt reminders are unregistered and renamed to .bak (settings.remove.json).
#
# Usage:
#   bash scripts/install.sh [--lang tr|en] [--vault DIR] [--projects DIR]
#                           [--claude-home DIR] [--name "Your Name"] [--dry-run]
#
# Windows: run from Git Bash (Claude Code already requires it), or
#          powershell -File scripts/install.ps1 (thin wrapper).
# =============================================================================
set -euo pipefail

LANG_MODE="tr"
VAULT_DIR=""
PROJECTS_DIR=""
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
USER_NAME="${USER:-${USERNAME:-you}}"
DRY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --lang)        LANG_MODE="$2"; shift 2 ;;
    --vault)       VAULT_DIR="$2"; shift 2 ;;
    --projects)    PROJECTS_DIR="$2"; shift 2 ;;
    --claude-home) CLAUDE_HOME="$2"; shift 2 ;;
    --name)        USER_NAME="$2"; shift 2 ;;
    --dry-run)     DRY=1; shift ;;
    -h|--help)     sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
done

case "$LANG_MODE" in tr|en) ;; *) echo "--lang must be tr or en"; exit 1 ;; esac

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
TODAY="$(date +%Y-%m-%d)"

if [ "$LANG_MODE" = "tr" ]; then
  [ -n "$VAULT_DIR" ]    || VAULT_DIR="$HOME/Documents/ClaudeVault"
  [ -n "$PROJECTS_DIR" ] || PROJECTS_DIR="$HOME/Desktop/00-Projeler"
  TPL_VAULT="$REPO_DIR/templates/vault"
  TPL_CLAUDE="$REPO_DIR/templates/CLAUDE.md"
  REMINDER="$REPO_DIR/templates/reminders/session-reminder.json"
  SUBDIRS="Aktif Arsiv _araclar _yedekler"
else
  [ -n "$VAULT_DIR" ]    || VAULT_DIR="$HOME/Documents/ClaudeVault"
  [ -n "$PROJECTS_DIR" ] || PROJECTS_DIR="$HOME/Desktop/00-Projects"
  TPL_VAULT="$REPO_DIR/templates/vault-en"
  TPL_CLAUDE="$REPO_DIR/templates/CLAUDE.en.md"
  REMINDER="$REPO_DIR/templates/reminders/session-reminder.en.json"
  SUBDIRS="Active Archive _tools _backups"
fi

# Display paths: on Windows show C:\... in CLAUDE.md, keep /c/... for bash config.
disp() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }

say()  { printf '%s\n' "$*"; }
run()  { if [ "$DRY" -eq 1 ]; then say "  [dry-run] $*"; else eval "$@"; fi; }
backup_if_exists() {
  if [ -e "$1" ]; then run "cp '$1' '$1.$TS.bak'"; say "  backup: $1.$TS.bak"; fi
}
# Replace placeholders in a file (portable sed -i).
fill() {
  local f="$1"
  [ "$DRY" -eq 1 ] && return 0
  local vd pd ch
  vd=$(disp "$VAULT_DIR"); pd=$(disp "$PROJECTS_DIR"); ch=$(disp "$CLAUDE_HOME")
  # escape sed specials in replacements (\, &, |)
  esc() { printf '%s' "$1" | sed 's/[\\&|]/\\&/g'; }
  sed -i.tmp \
    -e "s|{{VAULT_DIR}}|$(esc "$vd")|g" \
    -e "s|{{PROJECTS_DIR}}|$(esc "$pd")|g" \
    -e "s|{{CLAUDE_HOME}}|$(esc "$ch")|g" \
    -e "s|{{USER_NAME}}|$(esc "$USER_NAME")|g" \
    -e "s|{{INSTALL_DATE}}|$TODAY|g" "$f" && rm -f "$f.tmp"
}

say "saltay-kokpit install  (lang=$LANG_MODE)"
say "  vault      : $VAULT_DIR"
say "  projects   : $PROJECTS_DIR"
say "  claude home: $CLAUDE_HOME"
say ""

# ------------------------------------------------------------------ 1. vault
say "[1/6] vault"
run "mkdir -p '$VAULT_DIR'"
# Templates whose text changed in v1.1: an existing copy is still kept; if it still carries
# the v1.0 text (marker below) it is listed at the end so the user can compare by hand.
v10_marker() {
  case "$1" in
    MEMORY.md) echo 'K4 skill görünür|K4 skills visible' ;;
    feedback_5_kanonik_davranis_kurali.md|feedback_5_canonical_rules.md) echo 'Self-test' ;;
    reference_skill_routing.md) echo 'TIER 1' ;;
  esac
}
KEPT_CHANGED=""
NEW_NOTES=""
for src in "$TPL_VAULT"/*.md "$TPL_VAULT"/*/README.md; do
  [ -e "$src" ] || continue
  rel="${src#$TPL_VAULT/}"
  dst="$VAULT_DIR/$rel"
  if [ -e "$dst" ]; then
    say "  keep   : $rel (exists)"
    m="$(v10_marker "$rel")"
    [ -n "$m" ] && grep -qE "$m" "$dst" && KEPT_CHANGED="$KEPT_CHANGED $rel"
    continue
  fi
  run "mkdir -p '$(dirname "$dst")' && cp '$src' '$dst'"
  fill "$dst"
  say "  create : $rel"
  NEW_NOTES="$NEW_NOTES $rel"
done

# --------------------------------------------------------- 2. projects folder
say "[2/6] projects folder"
for d in $SUBDIRS; do run "mkdir -p '$PROJECTS_DIR/$d'"; done
run "mkdir -p '$PROJECTS_DIR/.claude'"
if [ ! -e "$PROJECTS_DIR/.claude/launch.json" ]; then
  run "cp '$REPO_DIR/templates/project/launch.json.example' '$PROJECTS_DIR/.claude/launch.json.example'"
fi
say "  $PROJECTS_DIR/{$(echo $SUBDIRS | tr ' ' ',')}"

# ------------------------------------------------------------------ 3. hooks
say "[3/6] hooks"
run "mkdir -p '$CLAUDE_HOME/hooks'"
for h in vault-index.sh hook-meta.sh; do
  backup_if_exists "$CLAUDE_HOME/hooks/$h"
  run "cp '$REPO_DIR/hooks/$h' '$CLAUDE_HOME/hooks/$h' && chmod +x '$CLAUDE_HOME/hooks/$h'"
  say "  install: hooks/$h"
done

backup_if_exists "$CLAUDE_HOME/vault.conf"
if [ "$DRY" -eq 0 ]; then
  cat > "$CLAUDE_HOME/vault.conf" <<CONF
# saltay-kokpit — read by hooks/vault-index.sh and scripts/*.sh (shell syntax)
VAULT_DIR="$VAULT_DIR"
PROJECTS_DIR="$PROJECTS_DIR"
VAULT_LANG="$LANG_MODE"
BUDGET=9500
# CORE="..."   # optional: override the notes that get a description in the index
CONF
fi
say "  write  : vault.conf"

backup_if_exists "$CLAUDE_HOME/session-reminder.json"
run "cp '$REMINDER' '$CLAUDE_HOME/session-reminder.json'"
say "  install: session-reminder.json"

# --------------------------------------------------------------- 4. CLAUDE.md
say "[4/6] CLAUDE.md"
if [ -e "$CLAUDE_HOME/CLAUDE.md" ]; then
  run "cp '$TPL_CLAUDE' '$CLAUDE_HOME/CLAUDE.saltay.md'"
  fill "$CLAUDE_HOME/CLAUDE.saltay.md"
  say "  exists : $CLAUDE_HOME/CLAUDE.md — NOT touched."
  say "  written: $CLAUDE_HOME/CLAUDE.saltay.md → merge the sections you want by hand"
  say "           (upgrading from v1.0? CHANGELOG.md lists what changed in the core)."
else
  run "cp '$TPL_CLAUDE' '$CLAUDE_HOME/CLAUDE.md'"
  fill "$CLAUDE_HOME/CLAUDE.md"
  say "  create : $CLAUDE_HOME/CLAUDE.md"
fi

# ----------------------------------------------------------- 5. settings.json
say "[5/6] settings.json hooks"
HOOKS_TMP="$(mktemp)"
REMOVE_TMP="$(mktemp)"
sed "s|__CLAUDE_HOME__|$CLAUDE_HOME|g" "$REPO_DIR/hooks/settings.hooks.json" > "$HOOKS_TMP"
sed "s|__CLAUDE_HOME__|$CLAUDE_HOME|g" "$REPO_DIR/hooks/settings.remove.json" > "$REMOVE_TMP"
SETTINGS="$CLAUDE_HOME/settings.json"
if [ "$DRY" -eq 1 ]; then
  say "  [dry-run] would merge hooks into $SETTINGS"
elif [ ! -e "$SETTINGS" ]; then
  # fresh file: the hook block minus the _comment key
  if command -v node >/dev/null 2>&1; then
    node -e 'const fs=require("fs");const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));delete j._comment;fs.writeFileSync(process.argv[2],JSON.stringify(j,null,2)+"\n")' "$HOOKS_TMP" "$SETTINGS"
  else
    grep -v '"_comment"' "$HOOKS_TMP" > "$SETTINGS"
  fi
  say "  create : $SETTINGS"
else
  backup_if_exists "$SETTINGS"
  if command -v node >/dev/null 2>&1; then
    node "$REPO_DIR/scripts/merge-settings.js" "$SETTINGS" "$HOOKS_TMP" "$REMOVE_TMP"
    say "  merged : $SETTINGS (node)"
  elif python3 -c 'import sys' >/dev/null 2>&1; then   # (Windows Store stub fails this test)
    python3 "$REPO_DIR/scripts/merge-settings.py" "$SETTINGS" "$HOOKS_TMP" "$REMOVE_TMP"
    say "  merged : $SETTINGS (python3)"
  else
    cp "$HOOKS_TMP" "$CLAUDE_HOME/settings.saltay.json"
    say "  !! neither node nor python3 found — hook block written to"
    say "     $CLAUDE_HOME/settings.saltay.json — merge it into settings.json by hand,"
    say "     and remove these old commands if they are there:"
    grep -o '"cat [^"]*"' "$REMOVE_TMP" | sed 's/^/       /'
  fi
fi
rm -f "$HOOKS_TMP" "$REMOVE_TMP"

# v1.0 → v1.1: the two old prompt reminders are retired once nothing references them.
for old in behavior-check-reminder.json skill-check-reminder.json; do
  [ -e "$CLAUDE_HOME/$old" ] || continue
  if [ "$DRY" -eq 1 ]; then
    say "  [dry-run] would retire $old → $old.$TS.bak once settings.json no longer references it"
  elif [ -e "$SETTINGS" ] && grep -q "$old" "$SETTINGS"; then
    say "  keep   : $old (still referenced in settings.json)"
  else
    mv "$CLAUDE_HOME/$old" "$CLAUDE_HOME/$old.$TS.bak"
    say "  retire : $old → $old.$TS.bak (replaced by session-reminder.json)"
  fi
done

# ----------------------------------------------------------------- 6. verify
say "[6/6] verify"
if [ "$DRY" -eq 0 ]; then
  SZ=$(SALTAY_CONF="$CLAUDE_HOME/vault.conf" bash "$CLAUDE_HOME/hooks/vault-index.sh" | wc -c | tr -d ' ')
  say "  index size: $SZ bytes (budget 9500 — must stay below 10000)"
  META=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.md"}}' | bash "$CLAUDE_HOME/hooks/hook-meta.sh")
  say "  hook-meta : $META"
fi

say ""
say "done. next steps:"
if [ "$LANG_MODE" = "tr" ]; then
  say "  1. Claude Code'u yeniden başlat — oturum başında vault index'i gelmeli."
  say "  2. Obsidian → Open folder as vault → $VAULT_DIR"
  say "  3. $VAULT_DIR/kullanici_profil.md dosyasını doldur (ya da ilk oturumda Claude'a anlat, o yazar)."
  say "  4. Sağlık kontrolü: bash scripts/vault-health.sh"
else
  say "  1. Restart Claude Code — the vault index should arrive at session start."
  say "  2. Obsidian → Open folder as vault → $VAULT_DIR"
  say "  3. Fill $VAULT_DIR/user_profile.md (or tell Claude in the first session, it writes it)."
  say "  4. Health check: bash scripts/vault-health.sh"
fi

if [ -n "$KEPT_CHANGED" ]; then
  say ""
  say "upgrade note: these vault files still carry the v1.0 text; yours were kept (never overwritten):"
  for f in $KEPT_CHANGED; do say "  - $f   new version: $TPL_VAULT/$f"; done
  say "  compare them by hand; add a MEMORY.md line for each note created this run:${NEW_NOTES:- none}"
fi
