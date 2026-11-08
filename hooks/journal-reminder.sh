#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · hooks/journal-reminder.sh
# Stop hook: when a stretch of real work ends without anything written to the
# journal (or, in a flat vault, to the vault at all), Claude is asked ONCE to
# write a short session summary — or to say in one line that none is needed.
#
# WHY A STOP HOOK
#   "Write a session summary at the end of important work" is a conditional
#   instruction — the same failure as "read the vault if the task relates to the
#   past" (docs/10-dersler.md): left to the model's momentary judgement, it is
#   skipped exactly when the session was long and busy. SessionEnd cannot make
#   Claude act (the session is already over), so this runs on Stop — the end of
#   each answer — and stays quiet unless the thresholds below were crossed.
#
# HOW IT DECIDES (state written by session-track.sh)
#   Since the last reset point it counts: file edits OUTSIDE the vault, and shell
#   commands. If a journal note was written in that stretch -> reset, quiet.
#   If edits >= JOURNAL_MIN_EDITS or commands >= JOURNAL_MIN_COMMANDS -> remind
#   once (exit 2: Claude reads the reason and continues) and reset.
#   stop_hook_active=true (Claude is already answering a Stop hook) -> quiet.
#
# CONFIG  ~/.claude/vault.conf
#   JOURNAL_REMIND=1          # 0 turns it off
#   JOURNAL_MIN_EDITS=3
#   JOURNAL_MIN_COMMANDS=15
#   JOURNAL_DIR="Memory/Journal"   # folders layout; default: first folder named
#                                  #   günlük / gunluk / journal / daily
# =============================================================================

here="$(cd "$(dirname "$0")" && pwd)"
CH="$(dirname "$here")"
state="$CH/saltay-state"
export LC_ALL=C.UTF-8

VAULT_DIR=""; VAULT_LANG="tr"; VAULT_LAYOUT="flat"
JOURNAL_REMIND=1; JOURNAL_MIN_EDITS=3; JOURNAL_MIN_COMMANDS=15; JOURNAL_DIR=""
# shellcheck disable=SC1090
[ -f "${SALTAY_CONF:-$CH/vault.conf}" ] && . "${SALTAY_CONF:-$CH/vault.conf}"
[ "$JOURNAL_REMIND" = "0" ] && exit 0
[ -t 0 ] && exit 0
IN=$(cat)

# already continuing because of a Stop hook -> never loop
printf '%s' "$IN" | tr -d '\r\n' | grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
sid=$(printf '%s' "$IN" | tr -d '\r\n' | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
case "$sid" in ''|*[!A-Za-z0-9_-]*) exit 0 ;; esac
log="$state/$sid.log"
[ -f "$log" ] || exit 0

# housekeeping: state of sessions idle for a week (our own files, nothing else)
find "$state" -name '*.log' -mtime +7 -exec rm -f {} + 2>/dev/null

# comparable paths: /c/x and C:/x -> c:/x, lower-case ASCII
norm() { printf '%s' "$1" | sed 's|\\|/|g; s|^/\([A-Za-z]\)/|\1:/|; s|/*$||' | tr 'A-Z' 'a-z'; }
[ -n "$VAULT_DIR" ] || exit 0
V=$(norm "$VAULT_DIR")

if [ "$VAULT_LAYOUT" = "folders" ]; then
  if [ -z "$JOURNAL_DIR" ]; then
    jd=$(cd "$VAULT_DIR" 2>/dev/null && find . -type d \( -name .obsidian -o -name .trash -o -name .git \) -prune -o -type d -print 2>/dev/null \
         | grep -iE '/(günlük|gunluk|journal|daily|günce)$' | head -1 | sed 's|^\./||')
    JOURNAL_DIR="$jd"
  fi
  [ -n "$JOURNAL_DIR" ] && J="$V/$(norm "$JOURNAL_DIR")" || J="$V"
else
  J="$V"
fi

# lines since the last reset point
tail_part=$(awk '/^R$/ {buf=""; next} {buf = buf $0 "\n"} END {printf "%s", buf}' "$log")
[ -n "$tail_part" ] || exit 0

edits=0; cmds=0; wrote=0
while IFS= read -r line; do
  case "$line" in
    B) cmds=$((cmds+1)) ;;
    E*) p=$(norm "$(printf '%s' "$line" | cut -f2-)")
        case "$p" in
          "$J"/*) wrote=1 ;;
          "$V"/*) : ;;                       # other vault notes: memory upkeep, not work
          *) edits=$((edits+1)) ;;
        esac ;;
  esac
done <<EOF
$tail_part
EOF

if [ "$wrote" -eq 1 ]; then echo "R" >> "$log"; exit 0; fi
[ "$edits" -ge "$JOURNAL_MIN_EDITS" ] || [ "$cmds" -ge "$JOURNAL_MIN_COMMANDS" ] || exit 0
echo "R" >> "$log"

today=$(date +%Y-%m-%d)
SHOW="$VAULT_DIR"; SHOWJ="$VAULT_DIR/$JOURNAL_DIR"
# one path style per path: C:\...\Günlük on Windows (not C:\...\CLAUDE/Hafıza/Günlük)
if command -v cygpath >/dev/null 2>&1; then SHOW=$(cygpath -w "$VAULT_DIR"); SHOWJ=$(cygpath -w "$VAULT_DIR/$JOURNAL_DIR"); fi
if [ "$VAULT_LANG" = "en" ]; then
  if [ "$VAULT_LAYOUT" = "folders" ] && [ -n "$JOURNAL_DIR" ]; then
    where="an atomic note in $SHOWJ (\"$today <topic>.md\", same format as the existing ones) and link it from that folder's MOC"
  else
    where="the vault ($SHOW): project / HANDOFF note or a dated line in the decisions note"
  fi
  msg="saltay journal-reminder: this stretch of work ($edits file edit(s), $cmds command(s)) ended without a journal entry. If it produced something worth finding in 3 months (a delivery, a decision, a fix, a new tool, a file location), write a short summary to $where. If it did not, write nothing and just say \"no journal entry needed\". Never write secrets. Then finish your answer as you normally would."
else
  if [ "$VAULT_LAYOUT" = "folders" ] && [ -n "$JOURNAL_DIR" ]; then
    where="$SHOWJ altına atomik not (\"$today <konu>.md\", mevcut günlük notlarının biçiminde) yaz ve o klasörün MOC'una [[link]] ekle"
  else
    where="vault'a ($SHOW) yaz: proje / HANDOFF notu ya da kararlar notuna tarihli satır"
  fi
  msg="saltay günlük-hatırlatıcı: bu iş parçası ($edits dosya düzenlemesi, $cmds komut) günlüğe bir şey yazılmadan bitti. 3 ay sonra aranacak bir değer ürettiyse (teslim, karar, düzeltme, yeni araç, dosya konumu) kısa bir oturum özetini $where. Üretmediyse hiçbir şey yazma, yalnız \"günlük gerekmez\" de. Sır/parola asla yazılmaz. Sonra cevabını normal şekilde bitir."
fi
printf '%s\n' "$msg" >&2
exit 2
