#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/install.sh
#
# Installs the four layers: vault (memory) · CLAUDE.md (constitution) ·
# hooks + reminder (reflexes) · projects folder skeleton (order).
# Idempotent: existing files are never overwritten without a timestamped
# backup, existing vault notes are never touched. Upgrades from v1.0/v1.1
# replace the old hook commands by exact match (hooks/settings.remove.json).
#
# Usage:
#   bash scripts/install.sh [--lang tr|en] [--vault DIR] [--layout auto|flat|folders]
#                           [--core-notes "Home;Memory/Rules"] [--projects DIR | --no-projects]
#                           [--claude-home DIR] [--name "Your Name"]
#                           [--disable-background-tasks] [--dry-run]
#
#   --layout folders  use an EXISTING Obsidian vault organised in sub-folders; no
#                     templates are copied into it (auto: detected from the vault)
#   --no-projects     skip the projects folder skeleton (new/archive-project.sh need it)
#   --disable-background-tasks  also set CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1
#                     (merged silently in v1.0-v1.1; opt-in since v1.2)
#
# Windows: run from Git Bash (Claude Code already requires it), or
#          powershell -File scripts/install.ps1 (thin wrapper). Uninstall: scripts/uninstall.sh
# =============================================================================
set -euo pipefail

LANG_MODE="tr"
VAULT_DIR=""
LAYOUT="auto"
CORE_NOTES=""
PROJECTS_DIR=""
NO_PROJECTS=0
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
USER_NAME="${USER:-${USERNAME:-you}}"
BG_ENV=0
DRY=0

need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "option $1 needs a value"; exit 1; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --lang)        need "$@"; LANG_MODE="$2"; shift 2 ;;
    --vault)       need "$@"; VAULT_DIR="$2"; shift 2 ;;
    --layout)      need "$@"; LAYOUT="$2"; shift 2 ;;
    --core-notes)  need "$@"; CORE_NOTES="$2"; shift 2 ;;
    --projects)    need "$@"; PROJECTS_DIR="$2"; shift 2 ;;
    --no-projects) NO_PROJECTS=1; shift ;;
    --claude-home) need "$@"; CLAUDE_HOME="$2"; shift 2 ;;
    --name)        need "$@"; USER_NAME="$2"; shift 2 ;;
    --disable-background-tasks) BG_ENV=1; shift ;;
    --dry-run)     DRY=1; shift ;;
    -h|--help)     sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (see --help)"; exit 1 ;;
  esac
done

case "$LANG_MODE" in tr|en) ;; *) echo "--lang must be tr or en"; exit 1 ;; esac
case "$LAYOUT" in auto|flat|folders) ;; *) echo "--layout must be auto, flat or folders"; exit 1 ;; esac

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo dev)"
TS="$(date +%Y%m%d_%H%M%S)"
TODAY="$(date +%Y-%m-%d)"
# shellcheck source=lib.sh
. "$REPO_DIR/scripts/lib.sh"

# The real Desktop: on Windows it is often redirected into OneDrive, and
# $HOME/Desktop then does not exist (v1.1 created an invisible folder there).
desktop_dir() {
  local d=""
  if command -v cygpath >/dev/null 2>&1; then d=$(cygpath -D 2>/dev/null || true); fi
  if [ -z "$d" ] && command -v xdg-user-dir >/dev/null 2>&1; then d=$(xdg-user-dir DESKTOP 2>/dev/null || true); fi
  if [ -z "$d" ] || [ ! -d "$d" ]; then
    for c in "$HOME/Desktop" "${OneDrive:-}/Desktop" "$HOME/OneDrive/Desktop"; do
      [ -d "$c" ] && { d="$c"; break; }
    done
  fi
  [ -n "$d" ] && [ -d "$d" ] || d="$HOME"
  printf '%s' "$d"
}
# Same for Documents (default vault location).
documents_dir() {
  local d=""
  if command -v cygpath >/dev/null 2>&1; then d=$(cygpath -O 2>/dev/null || true); fi
  if [ -z "$d" ] && command -v xdg-user-dir >/dev/null 2>&1; then d=$(xdg-user-dir DOCUMENTS 2>/dev/null || true); fi
  [ -n "$d" ] && [ -d "$d" ] || d="$HOME/Documents"
  printf '%s' "$d"
}

[ -n "$VAULT_DIR" ] || VAULT_DIR="$(documents_dir)/ClaudeVault"
if [ "$LANG_MODE" = "tr" ]; then
  [ -n "$PROJECTS_DIR" ] || PROJECTS_DIR="$(desktop_dir)/00-Projeler"
  TPL_VAULT="$REPO_DIR/templates/vault"
  TPL_CLAUDE="$REPO_DIR/templates/CLAUDE.md"
  SUBDIRS="Aktif Arsiv _araclar _yedekler"
  SFX=""
else
  [ -n "$PROJECTS_DIR" ] || PROJECTS_DIR="$(desktop_dir)/00-Projects"
  TPL_VAULT="$REPO_DIR/templates/vault-en"
  TPL_CLAUDE="$REPO_DIR/templates/CLAUDE.en.md"
  SUBDIRS="Active Archive _tools _backups"
  SFX=".en"
fi
[ "$NO_PROJECTS" -eq 1 ] && PROJECTS_DIR=""

# Layout detection: an existing vault with notes in sub-folders and no prefixed
# notes at its root is a folders vault — never pour flat templates into it.
if [ "$LAYOUT" = "auto" ]; then
  LAYOUT="flat"
  if [ -d "$VAULT_DIR" ]; then
    root_pref=$(ls "$VAULT_DIR" 2>/dev/null | grep -cE '^(feedback|reference|proje|project|not|note|kullanici|user|kisisel|personal|HANDOFF)_.*\.md$' || true)
    sub_md=$(find "$VAULT_DIR" -mindepth 2 -name '*.md' -not -path '*/.obsidian/*' 2>/dev/null | head -5 | wc -l | tr -d ' ')
    [ "$root_pref" -eq 0 ] && [ "$sub_md" -gt 0 ] && LAYOUT="folders"
  fi
fi
if [ "$LAYOUT" = "folders" ]; then
  REMINDER="$REPO_DIR/templates/reminders/session-reminder.folders$SFX.json"
else
  REMINDER="$REPO_DIR/templates/reminders/session-reminder$SFX.json"
fi

# Display paths: on Windows show C:\... in CLAUDE.md, keep /c/... for bash config.
disp() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }

say()  { printf '%s\n' "$*"; }
# run CMD ARGS... — argv, never eval: a path with ' or spaces stays intact.
run()  { if [ "$DRY" -eq 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }
backup_if_exists() {
  if [ -e "$1" ]; then run cp "$1" "$1.$TS.bak"; say "  backup: $1.$TS.bak"; fi
}
# Replace placeholders in a file (portable sed -i).
fill() {
  local f="$1"
  [ "$DRY" -eq 1 ] && return 0
  local vd pd ch
  vd=$(disp "$VAULT_DIR"); pd=$(disp "${PROJECTS_DIR:-—}"); ch=$(disp "$CLAUDE_HOME")
  sed -i.tmp \
    -e "s|{{VAULT_DIR}}|$(sed_escape "$vd")|g" \
    -e "s|{{PROJECTS_DIR}}|$(sed_escape "$pd")|g" \
    -e "s|{{CLAUDE_HOME}}|$(sed_escape "$ch")|g" \
    -e "s|{{USER_NAME}}|$(sed_escape "$USER_NAME")|g" \
    -e "s|{{INSTALL_DATE}}|$TODAY|g" "$f" && rm -f "$f.tmp"
}

say "saltay-kokpit $VERSION install  (lang=$LANG_MODE, layout=$LAYOUT)"
say "  vault      : $VAULT_DIR"
say "  projects   : ${PROJECTS_DIR:-(skipped)}"
say "  claude home: $CLAUDE_HOME"
say ""

# ------------------------------------------------------------------ 1. vault
say "[1/6] vault"
KEPT_CHANGED=""
NEW_NOTES=""
if [ "$LAYOUT" = "folders" ]; then
  if [ -d "$VAULT_DIR" ]; then
    say "  folders layout: your vault is used as it is — no templates copied, nothing changed."
  else
    say "  !! --layout folders needs an existing vault: $VAULT_DIR not found"; exit 1
  fi
else
  run mkdir -p "$VAULT_DIR"
  # Templates whose text changed in v1.1: an existing copy is still kept; if it still carries
  # the v1.0 text (marker below) it is listed at the end so the user can compare by hand.
  v10_marker() {
    case "$1" in
      MEMORY.md) echo 'K4 skill görünür|K4 skills visible' ;;
      feedback_5_kanonik_davranis_kurali.md|feedback_5_canonical_rules.md) echo 'Self-test' ;;
      reference_skill_routing.md) echo 'TIER 1' ;;
    esac
  }
  for src in "$TPL_VAULT"/*.md "$TPL_VAULT"/*/README.md; do
    [ -e "$src" ] || continue
    rel="${src#"$TPL_VAULT"/}"
    dst="$VAULT_DIR/$rel"
    if [ -e "$dst" ]; then
      say "  keep   : $rel (exists)"
      m="$(v10_marker "$rel")"
      [ -n "$m" ] && grep -qE "$m" "$dst" && KEPT_CHANGED="$KEPT_CHANGED $rel"
      continue
    fi
    run mkdir -p "$(dirname "$dst")"
    run cp "$src" "$dst"
    fill "$dst"
    say "  create : $rel"
    NEW_NOTES="$NEW_NOTES $rel"
  done
fi

# --------------------------------------------------------- 2. projects folder
say "[2/6] projects folder"
if [ -z "$PROJECTS_DIR" ]; then
  say "  skipped (--no-projects)"
else
  for d in $SUBDIRS; do run mkdir -p "$PROJECTS_DIR/$d"; done
  run mkdir -p "$PROJECTS_DIR/.claude"
  if [ ! -e "$PROJECTS_DIR/.claude/launch.json" ]; then
    run cp "$REPO_DIR/templates/project/launch.json.example" "$PROJECTS_DIR/.claude/launch.json.example"
  fi
  say "  $PROJECTS_DIR/{$(echo $SUBDIRS | tr ' ' ',')}"
fi

# ------------------------------------------------------------------ 3. hooks
say "[3/6] hooks"
run mkdir -p "$CLAUDE_HOME/hooks"
for h in vault-index.sh hook-meta.sh backup.sh secret-scan.sh change-log.sh; do
  backup_if_exists "$CLAUDE_HOME/hooks/$h"
  run cp "$REPO_DIR/hooks/$h" "$CLAUDE_HOME/hooks/$h"
  run chmod +x "$CLAUDE_HOME/hooks/$h"
  say "  install: hooks/$h"
done

backup_if_exists "$CLAUDE_HOME/vault.conf"
if [ "$DRY" -eq 0 ]; then
  {
    echo "# saltay-kokpit $VERSION — read by hooks/vault-index.sh and scripts/*.sh (shell syntax)"
    echo "VAULT_DIR=$(dq "$VAULT_DIR")"
    echo "PROJECTS_DIR=$(dq "$PROJECTS_DIR")"
    echo "VAULT_LANG=\"$LANG_MODE\""
    echo "VAULT_LAYOUT=\"$LAYOUT\""
    echo "BUDGET=9500"
    if [ "$LAYOUT" = "folders" ]; then
      echo "# folders layout options (';'-separated, relative to VAULT_DIR) — see hooks/vault-index.sh"
      if [ -n "$CORE_NOTES" ]; then echo "CORE_NOTES=$(dq "$CORE_NOTES")"; else echo '# CORE_NOTES="Home;Memory/Memory Rules"'; fi
      echo '# BINDING_DIRS="Memory/Feedback"'
      echo '# EXCLUDE_DIRS="Drafts"'
      echo '# PROJECT_NOTES_DIR="Memory/Projects"   # new-project.sh / archive-project.sh'
      echo '# PROJECT_MOC="Memory/Projects/Projects MOC"'
    else
      echo '# CORE="..."   # optional: override the notes that get a description in the index'
    fi
  } > "$CLAUDE_HOME/vault.conf"
fi
say "  write  : vault.conf"

backup_if_exists "$CLAUDE_HOME/session-reminder.json"
run cp "$REMINDER" "$CLAUDE_HOME/session-reminder.json"
say "  install: session-reminder.json ($(basename "$REMINDER"))"

# --------------------------------------------------------------- 4. CLAUDE.md
say "[4/6] CLAUDE.md"
if [ -e "$CLAUDE_HOME/CLAUDE.md" ]; then
  run cp "$TPL_CLAUDE" "$CLAUDE_HOME/CLAUDE.saltay.md"
  fill "$CLAUDE_HOME/CLAUDE.saltay.md"
  say "  exists : $CLAUDE_HOME/CLAUDE.md — NOT touched."
  say "  written: $CLAUDE_HOME/CLAUDE.saltay.md → merge the sections you want by hand"
  say "           (upgrading? CHANGELOG.md lists what changed in the core)."
else
  run cp "$TPL_CLAUDE" "$CLAUDE_HOME/CLAUDE.md"
  fill "$CLAUDE_HOME/CLAUDE.md"
  say "  create : $CLAUDE_HOME/CLAUDE.md"
fi

# ----------------------------------------------------------- 5. settings.json
say "[5/6] settings.json hooks"
SETTINGS="$CLAUDE_HOME/settings.json"
MERGER=""
if command -v node >/dev/null 2>&1; then MERGER="node $REPO_DIR/scripts/merge-settings.js"
elif python3 -c 'import sys' >/dev/null 2>&1; then MERGER="python3 $REPO_DIR/scripts/merge-settings.py"   # (Windows Store stub fails this test)
fi
merge() {  # merge <block.json> [remove.json]
  if [[ "$MERGER" == node* ]]; then node "$REPO_DIR/scripts/merge-settings.js" "$SETTINGS" "$@" --home "$CLAUDE_HOME"
  else python3 "$REPO_DIR/scripts/merge-settings.py" "$SETTINGS" "$@" --home "$CLAUDE_HOME"; fi
}
if [ "$DRY" -eq 1 ]; then
  say "  [dry-run] would merge hooks into $SETTINGS"
  [ "$BG_ENV" -eq 1 ] && say "  [dry-run] would add env CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1"
elif [ -n "$MERGER" ]; then
  backup_if_exists "$SETTINGS"
  merge "$REPO_DIR/hooks/settings.hooks.json" "$REPO_DIR/hooks/settings.remove.json"
  if [ "$BG_ENV" -eq 1 ]; then merge "$REPO_DIR/hooks/settings.env.json" >/dev/null; say "  env    : CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1"; fi
  say "  merged : $SETTINGS (${MERGER%% *})"
else
  sed "s|__CLAUDE_HOME__|$(sed_escape "$CLAUDE_HOME")|g" "$REPO_DIR/hooks/settings.hooks.json" > "$CLAUDE_HOME/settings.saltay.json"
  say "  !! neither node nor python3 found — hook block written to"
  say "     $CLAUDE_HOME/settings.saltay.json — merge it into settings.json by hand,"
  say "     and remove the old commands listed in hooks/settings.remove.json if they are there."
fi

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
[ "$DRY" -eq 1 ] || printf '%s\n' "$VERSION" > "$CLAUDE_HOME/saltay-kokpit.version"

# ----------------------------------------------------------------- 6. verify
say "[6/6] verify"
if [ "$DRY" -eq 0 ]; then
  SZ=$(SALTAY_CONF="$CLAUDE_HOME/vault.conf" bash "$CLAUDE_HOME/hooks/vault-index.sh" | wc -c | tr -d ' ')
  say "  index size: $SZ bytes (budget 9500 — must stay below 10000)"
  [ "$SZ" -gt 0 ] || say "  !! the index is EMPTY — check VAULT_DIR in $CLAUDE_HOME/vault.conf"
  META=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.md"}}' | bash "$CLAUDE_HOME/hooks/hook-meta.sh")
  say "  hook-meta : $META"
  if [ -e "$SETTINGS" ] && command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$SETTINGS" && say "  settings  : valid JSON"
  fi
fi

say ""
say "done. next steps:"
if [ "$LANG_MODE" = "tr" ]; then
  say "  1. Claude Code'u yeniden başlat — oturum başında vault index'i gelmeli."
  if [ "$LAYOUT" = "flat" ]; then
    say "  2. Obsidian → Open folder as vault → $VAULT_DIR"
    say "  3. $VAULT_DIR/kullanici_profil.md dosyasını doldur (ya da ilk oturumda Claude'a anlat, o yazar)."
  else
    say "  2. İsteğe bağlı: $CLAUDE_HOME/vault.conf içinde CORE_NOTES / BINDING_DIRS ayarla."
    say "  3. CLAUDE.saltay.md'den istediğin bölümleri kendi CLAUDE.md'ne al."
  fi
  say "  4. Sağlık kontrolü: bash scripts/vault-health.sh   ·   Kaldırma: bash scripts/uninstall.sh"
else
  say "  1. Restart Claude Code — the vault index should arrive at session start."
  if [ "$LAYOUT" = "flat" ]; then
    say "  2. Obsidian → Open folder as vault → $VAULT_DIR"
    say "  3. Fill $VAULT_DIR/user_profile.md (or tell Claude in the first session, it writes it)."
  else
    say "  2. Optional: set CORE_NOTES / BINDING_DIRS in $CLAUDE_HOME/vault.conf."
    say "  3. Merge the sections you want from CLAUDE.saltay.md into your CLAUDE.md."
  fi
  say "  4. Health check: bash scripts/vault-health.sh   ·   Uninstall: bash scripts/uninstall.sh"
fi

if [ -n "$KEPT_CHANGED" ]; then
  say ""
  say "upgrade note: these vault files still carry the v1.0 text; yours were kept (never overwritten):"
  for f in $KEPT_CHANGED; do say "  - $f   new version: $TPL_VAULT/$f"; done
  say "  compare them by hand; add a MEMORY.md line for each note created this run:${NEW_NOTES:- none}"
fi
