#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · tests/run.sh
# End-to-end tests in a throw-away HOME. Never touches your real ~/.claude:
# every install/uninstall gets an explicit --claude-home, --vault and
# --projects/--no-projects inside the sandbox.
#
#   bash tests/run.sh            # needs bash + node (CI: ubuntu, macos, windows)
# =============================================================================
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SB="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/saltay-test.$$")"; mkdir -p "$SB"
trap 'rm -rf "$SB"' EXIT
export HOME="$SB/home"; mkdir -p "$HOME"
PASS=0; FAILN=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
fail() { FAILN=$((FAILN+1)); printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/       /'; }
check() { if eval "$2"; then ok "$1"; else fail "$1" "${3:-}"; fi; }
# count commands containing $2 in settings file $1
# (needle passed without MSYS path conversion: commands keep the bash spelling of the path)
ncmd() { MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' node -e 'const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));let n=0;for(const e of Object.values(s.hooks||{}))for(const g of e)for(const h of g.hooks||[])if(h.command.includes(process.argv[2]))n++;console.log(n)' "$(native_path "$1")" "$2"; }
native_path() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
valid_json() { node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$1" 2>/dev/null; }
meta() { printf '%s' "$1" | bash "$REPO/hooks/hook-meta.sh"; }
scan() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" | bash "$REPO/hooks/secret-scan.sh" 2>/dev/null; echo $?; }

echo "[hook-meta]"
J1='{"tool_name":"Edit","tool_input":{"file_path":"C:\\Users\\x\\a.md"}}'
J2='{"tool_name":"Write","tool_input":{"file_path":"/a.md","content":"x"},"tool_response":{"file_path":"/b.md"}}'
J3='{"tool_name":"NotebookEdit","tool_input":{"notebook_path":"/n.ipynb"}}'
check "windows path un-escaped" '[ "$(meta "$J1")" = "Edit|C:/Users/x/a.md" ]' "$(meta "$J1")"
check "first file_path wins" '[ "$(meta "$J2")" = "Write|/a.md" ]' "$(meta "$J2")"
check "notebook_path fallback" '[ "$(meta "$J3")" = "NotebookEdit|/n.ipynb" ]' "$(meta "$J3")"

echo "[secret-scan]"
W="$SB/scan"; mkdir -p "$W"
# Fake keys below are fixtures; the trailing marker keeps the scanner quiet on THIS file.
printf "api_key = 'abcdefghijklmnop'\n" > "$W/a.py"                                 # saltay:allow
printf 'password = "abc27xyz12345"\n' > "$W/b.py"                                    # saltay:allow
printf '{"api_key": "abcdefghijklmnop"}\n' > "$W/c.json"                             # saltay:allow
printf 'const k = "sk-ant-api03-%s";\n' "abcdefghijklmnopqrstuvwxyz0123" > "$W/d.js" # saltay:allow
printf 'AWS=AKIAABCDEFGHIJKLMNOP\n' > "$W/e.sh"                                      # saltay:allow
printf 'password = "your_password_here"\napi_key = process.env.API_KEY\n' > "$W/f.py"
printf 'API_KEY=abcdefghijklmnop\n' > "$W/.env"
printf 'nothing to see here\n' > "$W/g.txt"
printf 'password = "abcdefghijklm"  # saltay:allow\n' > "$W/h.py"
for f in a.py b.py c.json d.js e.sh; do check "detects $f (exit 2)" '[ "$(scan "$W/'$f'")" = 2 ]'; done
for f in f.py .env g.txt h.py; do check "ignores $f (exit 0)" '[ "$(scan "$W/'$f'")" = 0 ]'; done
OUTMSG=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$W/a.py" | bash "$REPO/hooks/secret-scan.sh" 2>&1 >/dev/null)
check "never prints the secret value" '! printf "%s" "$OUTMSG" | grep -q abcdefghijklmnop'

echo "[backup]"
BH="$SB/bh/.claude"; mkdir -p "$BH/hooks"; cp "$REPO/hooks/backup.sh" "$REPO/hooks/hook-meta.sh" "$BH/hooks/"
bk() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" | SALTAY_CONF="$SB/none.conf" bash "$BH/hooks/backup.sh"; }
P="$SB/proj"; mkdir -p "$P/x" "$P/y"; printf 'one\n' > "$P/x/same.txt"; printf 'two\n' > "$P/y/same.txt"
git init -q "$P"
( cd "$SB" && bk "$P/x/same.txt" && bk "$P/y/same.txt" )
check "Write over an existing file is backed up" '[ "$(ls "$P/.backups" | grep -c "^same.txt")" = 2 ]'
check "git file -> repo root .backups/, not the cwd" '[ ! -d "$SB/.backups" ]'
check ".backups/ ignores itself in git" '[ "$(cat "$P/.backups/.gitignore")" = "*" ]'
L="$SB/loose"; mkdir -p "$L"; printf 'x\n' > "$L/note.md"
( cd "$SB" && bk "$L/note.md" )
check "non-git file -> ~/.claude/saltay-backups/" '[ "$(ls "$BH/saltay-backups" | grep -c "^note.md")" = 1 ]'
( cd "$P" && bk "$P/new.txt" ); check "new file: no backup, no error" '[ $? -eq 0 ]'

echo "[slugify]"
. "$REPO/scripts/lib.sh"
check "Şirket Sitesi -> sirket-sitesi" '[ "$(slugify "Şirket Sitesi")" = "sirket-sitesi" ]'
check "Çiçek Ünal Güzellik -> cicek-unal-guzellik" '[ "$(slugify "Çiçek Ünal Güzellik")" = "cicek-unal-guzellik" ]'
check "İstanbul Ağaç Işık -> istanbul-agac-isik" '[ "$(slugify "İstanbul Ağaç Işık")" = "istanbul-agac-isik" ]'

echo "[install: flat, tr, fresh]"
CH="$HOME/.claude"
OUT=$(bash "$REPO/scripts/install.sh" --lang tr --vault "$HOME/vault" --projects "$HOME/projeler" --claude-home "$CH" --name "Test" 2>&1); RC=$?
check "installer exit 0" '[ $RC -eq 0 ]' "$OUT"
check "settings.json valid" 'valid_json "$CH/settings.json"'
check "7 saltay hook commands" '[ "$(ncmd "$CH/settings.json" "$CH/")" = 7 ]'
check "no env added by default" '! grep -q CLAUDE_CODE_DISABLE_BACKGROUND_TASKS "$CH/settings.json"'
check "vault templates copied" '[ -f "$HOME/vault/kullanici_profil.md" ]'
check "projects skeleton" '[ -d "$HOME/projeler/Aktif" ]'
SZ=$(SALTAY_CONF="$CH/vault.conf" bash "$CH/hooks/vault-index.sh" | wc -c | tr -d ' ')
check "index 0 < $SZ <= 9500" '[ "$SZ" -gt 0 ] && [ "$SZ" -le 9500 ]'
bash "$REPO/scripts/install.sh" --lang tr --vault "$HOME/vault" --projects "$HOME/projeler" --claude-home "$CH" >/dev/null 2>&1
check "re-run is idempotent (still 7)" '[ "$(ncmd "$CH/settings.json" "$CH/")" = 7 ]'
HOUT=$(cd "$SB" && CLAUDE_HOME="$CH" SALTAY_CONF="$CH/vault.conf" bash "$REPO/scripts/vault-health.sh" 2>&1); HRC=$?
check "vault-health: healthy" '[ $HRC -eq 0 ]' "$HOUT"

echo "[new/archive project, Turkish name]"
NP=$(CLAUDE_HOME="$CH" bash "$REPO/scripts/new-project.sh" "Şirket Sitesi" --desc "Kurumsal site & teklif | form" 2>&1)
check "folder Aktif/sirket-sitesi" '[ -d "$HOME/projeler/Aktif/sirket-sitesi" ]' "$NP"
check "vault note proje_sirket_sitesi.md" '[ -f "$HOME/vault/proje_sirket_sitesi.md" ]'
check "& and | survive in the note" 'grep -qF "Kurumsal site & teklif | form" "$HOME/vault/proje_sirket_sitesi.md"'
CLAUDE_HOME="$CH" bash "$REPO/scripts/archive-project.sh" "Şirket Sitesi" --reason "teslim" >/dev/null 2>&1
check "archived to Arsiv/sirket-sitesi" '[ -d "$HOME/projeler/Arsiv/sirket-sitesi" ]'
check "MEMORY.md 📦 marker" 'grep -qF "📦 [[proje_sirket_sitesi]]" "$HOME/vault/MEMORY.md"'

echo "[upgrade from v1.1 + user hooks kept]"
CH2="$HOME/up/.claude"; mkdir -p "$CH2"
# fill the placeholder with sed in bash, exactly like the v1.1 installer did: on Windows this
# keeps the Git Bash /c/... spelling that node would otherwise see as C:/...
sed "s|__CLAUDE_HOME__|$CH2|g" "$REPO/hooks/settings.remove.json" > "$SB/remove.filled.json"
node -e '
const fs=require("fs"),[rm,out]=process.argv.slice(1);
const r=JSON.parse(fs.readFileSync(rm,"utf8")),f=s=>s;
const st={hooks:{}};
st.hooks.SessionStart=[{hooks:[{type:"command",command:f(r.SessionStart[0])}]}];
st.hooks.UserPromptSubmit=[{hooks:[{type:"command",command:f(r.UserPromptSubmit[2])}]}];
st.hooks.PreToolUse=[{matcher:"Edit|MultiEdit",hooks:[{type:"command",command:f(r.PreToolUse[0])}]},{matcher:"Bash",hooks:[{type:"command",command:"echo mine"}]}];
st.hooks.PostToolUse=[{matcher:"Edit|Write",hooks:[{type:"command",command:f(r.PostToolUse[0])}]},{matcher:"Edit|MultiEdit|Write",hooks:[{type:"command",command:f(r.PostToolUse[1])}]}];
st.permissions={allow:["Bash(ls:*)"]};
fs.writeFileSync(out,JSON.stringify(st,null,2));' "$SB/remove.filled.json" "$CH2/settings.json"
bash "$REPO/scripts/install.sh" --vault "$HOME/vault" --no-projects --claude-home "$CH2" >/dev/null 2>&1
check "old inline commands removed" '[ "$(ncmd "$CH2/settings.json" "hook-meta.sh); ")" = 0 ]'
check "7 new commands" '[ "$(ncmd "$CH2/settings.json" "$CH2/hooks/")" -eq 6 ] && [ "$(ncmd "$CH2/settings.json" "session-reminder")" -eq 1 ]'
check "user hook kept" '[ "$(ncmd "$CH2/settings.json" "echo mine")" = 1 ]'
check "permissions kept" 'grep -q "Bash(ls:\*)" "$CH2/settings.json"'

echo "[home folder with spaces]"
CH3="$HOME/My Home/.claude"
bash "$REPO/scripts/install.sh" --vault "$HOME/vault" --no-projects --claude-home "$CH3" >/dev/null 2>&1
CMD=$(node -e 'const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log(s.hooks.SessionStart[0].hooks[0].command)' "$CH3/settings.json")
IDX=$(SALTAY_CONF="$CH3/vault.conf" bash -c "$CMD" 2>&1)
check "registered SessionStart command runs" 'printf "%s" "$IDX" | grep -q "KANONIK KAYNAK"' "$CMD"
check "opt-in env flag" 'bash "$REPO/scripts/install.sh" --vault "$HOME/vault" --no-projects --claude-home "$CH3" --disable-background-tasks >/dev/null 2>&1 && grep -q CLAUDE_CODE_DISABLE_BACKGROUND_TASKS "$CH3/settings.json"'

echo "[folders layout]"
FV="$HOME/Folder Vault"; mkdir -p "$FV/Hafıza/Geri Bildirim" "$FV/Hafıza/Projeler" "$FV/Hafıza/Günlük" "$FV/Şablonlar" "$FV/Hafıza/Arşiv" "$FV/.obsidian"
note() { printf -- '---\ntype: x\nsummary: %s\n---\n# t\n' "$2" > "$1"; }
note "$FV/Ana Sayfa.md" "giris noktasi"
note "$FV/Hafıza/Geri Bildirim/Kapsami genisletme.md" "istenmeyen kismi degistirme"
note "$FV/Hafıza/Projeler/Ornek Musteri Sitesi.md" "kurumsal site"
note "$FV/Şablonlar/Not Şablonu.md" "sablon"
note "$FV/Hafıza/Arşiv/Eski.md" "eski"
CH4="$HOME/fold/.claude"
FOUT=$(bash "$REPO/scripts/install.sh" --vault "$FV" --no-projects --claude-home "$CH4" 2>&1)
check "layout auto-detected as folders" 'grep -q "VAULT_LAYOUT=\"folders\"" "$CH4/vault.conf"' "$FOUT"
check "no templates poured into the vault" '[ ! -e "$FV/MEMORY.md" ] && [ ! -e "$FV/kullanici_profil.md" ]'
check "folders reminder installed" 'grep -q "MOC" "$CH4/session-reminder.json"'
FI=$(SALTAY_CONF="$CH4/vault.conf" bash "$CH4/hooks/vault-index.sh")
check "binding folder detected" 'printf "%s" "$FI" | grep -q "Geri Bildirim/ (1) — BAGLAYICI"' "$FI"
check "root note is core" 'printf "%s" "$FI" | grep -q "^- Ana Sayfa — giris noktasi"'
check "templates excluded" '! printf "%s" "$FI" | grep -q "Not Şablonu"'
check "archive counted, not listed" 'printf "%s" "$FI" | grep -q "Hafıza/Arşiv (1)" && ! printf "%s" "$FI" | grep -q "^- Eski"'
i=1; while [ $i -le 700 ]; do note "$FV/Hafıza/Günlük/2026-01-01 cok uzun bir gunluk notu basligi numara $i.md" "bu bir test ozetidir ve oldukca uzun yazilmistir ki index sikissin $i"; i=$((i+1)); done
i=1; while [ $i -le 60 ]; do note "$FV/Hafıza/Geri Bildirim/kural $i.md" "kural ozeti $i"; i=$((i+1)); done
FI=$(SALTAY_CONF="$CH4/vault.conf" bash "$CH4/hooks/vault-index.sh"); FSZ=$(printf '%s\n' "$FI" | wc -c | tr -d ' ')
check "big folders vault fits the budget ($FSZ B)" '[ "$FSZ" -le 9500 ]'
check "compression warning shown" 'printf "%s" "$FI" | grep -q "sikisma seviyesi"'
check "binding names never trimmed (60/60)" '[ "$(printf "%s" "$FI" | grep -o "kural [0-9]*" | sort -u | wc -l | tr -d " ")" = 60 ]'
FH=$(cd "$SB" && CLAUDE_HOME="$CH4" SALTAY_CONF="$CH4/vault.conf" bash "$REPO/scripts/vault-health.sh" 2>&1)
check "health reports orphan notes" 'printf "%s" "$FH" | grep -q "orphan notes"' "$FH"

echo "[journal reminder]"
trk()  { printf '{"session_id":"%s","tool_name":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2" "${3:-}" | bash "$CH4/hooks/session-track.sh"; }
stopr(){ printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s}' "$1" "${2:-false}" | SALTAY_CONF="${3:-$CH4/vault.conf}" bash "$CH4/hooks/journal-reminder.sh" 2>"$SB/jr.err"; echo $?; }
W2="$SB/work"; mkdir -p "$W2"
trk s1 Edit "$W2/a.js"; trk s1 Write "$W2/b.js"
check "2 edits: quiet" '[ "$(stopr s1)" = 0 ]'
trk s1 Edit "$W2/c.js"
check "3 edits: reminds (exit 2)" '[ "$(stopr s1)" = 2 ]'
check "names the journal folder" 'grep -q "Hafıza/Günlük" "$SB/jr.err"' "$(cat "$SB/jr.err")"
check "stop_hook_active: never loops" '[ "$(stopr s1 true)" = 0 ]'
check "reminds once per stretch" '[ "$(stopr s1)" = 0 ]'
trk s2 Edit "$W2/a.js"; trk s2 Edit "$W2/b.js"; trk s2 Edit "$W2/c.js"; trk s2 Write "$FV/Hafıza/Günlük/2026-01-02 is.md"
check "journal written: quiet" '[ "$(stopr s2)" = 0 ]'
i=0; while [ $i -lt 5 ]; do trk s3 Edit "$FV/Hafıza/Projeler/Ornek Musteri Sitesi.md"; i=$((i+1)); done
check "vault upkeep is not 'work'" '[ "$(stopr s3)" = 0 ]'
i=0; while [ $i -lt 15 ]; do trk s4 Bash; i=$((i+1)); done
check "15 shell commands: reminds" '[ "$(stopr s4)" = 2 ]'
cp "$CH4/vault.conf" "$SB/off.conf"; echo "JOURNAL_REMIND=0" >> "$SB/off.conf"
trk s5 Edit "$W2/a.js"; trk s5 Edit "$W2/b.js"; trk s5 Edit "$W2/c.js"
check "JOURNAL_REMIND=0 turns it off" '[ "$(stopr s5 false "$SB/off.conf")" = 0 ]'
check "bad session id ignored" '[ "$(stopr "../x")" = 0 ]'
echo "JOURNAL_MIN_EDITS=7" >> "$CH4/vault.conf"
bash "$REPO/scripts/install.sh" --vault "$FV" --no-projects --claude-home "$CH4" >/dev/null 2>&1
check "reinstall keeps hand-added vault.conf settings" 'grep -q "^JOURNAL_MIN_EDITS=7" "$CH4/vault.conf"'

echo "[flat layout under pressure]"
i=1; while [ $i -le 400 ]; do printf -- '---\ndescription: x\n---\n' > "$HOME/vault/proje_cok_uzun_bir_proje_adi_numara_$i.md"; i=$((i+1)); done
FL=$(SALTAY_CONF="$CH/vault.conf" bash "$CH/hooks/vault-index.sh"); FLS=$(printf '%s\n' "$FL" | wc -c | tr -d ' ')
check "big flat vault fits the budget ($FLS B)" '[ "$FLS" -le 9500 ]'

echo "[uninstall]"
UOUT=$(bash "$REPO/scripts/uninstall.sh" --claude-home "$CH2" 2>&1); URC=$?
check "uninstall exit 0" '[ $URC -eq 0 ]' "$UOUT"
check "no saltay commands left" '[ "$(ncmd "$CH2/settings.json" "$CH2/")" = 0 ]'
check "user hook still there" '[ "$(ncmd "$CH2/settings.json" "echo mine")" = 1 ]'
check "hook files retired, not deleted" '[ ! -e "$CH2/hooks/vault-index.sh" ] && ls "$CH2/hooks/" | grep -q "vault-index.sh.*\.bak"'
check "vault untouched" '[ -f "$HOME/vault/MEMORY.md" ]'

echo
echo "passed: $PASS  failed: $FAILN"
[ "$FAILN" -eq 0 ]
