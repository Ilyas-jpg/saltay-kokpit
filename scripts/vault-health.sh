#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/vault-health.sh
# One-command health check for the whole setup. Run it whenever Claude "seems
# to forget" — the two silent failures this system has met (index truncated at
# the 10K limit, hook contract change) both show up here.
#
# v1.2: folders layout (per-folder counts, orphan notes), settings.json JSON
# validity, hook script presence, secret-scan self-test, .backups/ checked in
# the folder you ran it from (v1.1 looked inside the vault by mistake).
# =============================================================================
set -u
START_DIR="$(pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CONF="${SALTAY_CONF:-$CLAUDE_HOME/vault.conf}"
ok()   { printf '  ✅ %s\n' "$*"; }
bad()  { printf '  ❌ %s\n' "$*"; FAIL=1; }
warn() { printf '  ⚠️  %s\n' "$*"; }
FAIL=0
VAULT_LAYOUT="flat"

echo "saltay-kokpit health"
echo "[config]"
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"; ok "vault.conf: $CONF (lang=${VAULT_LANG:-tr}, layout=${VAULT_LAYOUT:-flat})"
else
  bad "vault.conf missing: $CONF — run scripts/install.sh"; VAULT_DIR="${VAULT_DIR:-}"; VAULT_LANG="${VAULT_LANG:-tr}"
fi

echo "[vault]"
if [ -n "${VAULT_DIR:-}" ] && [ -d "$VAULT_DIR" ]; then
  ok "folder: $VAULT_DIR"
  cd "$VAULT_DIR" || exit 1
  if [ "${VAULT_LAYOUT:-flat}" = "folders" ]; then
    LIST=$(find . \( -name .obsidian -o -name .trash -o -name .git -o -name node_modules \) -prune -o -type f -name '*.md' -print 2>/dev/null)
    total=$(printf '%s\n' "$LIST" | grep -c '\.md$')
    per=$(printf '%s\n' "$LIST" | grep '\.md$' | sed 's|^\./||; s|/[^/]*$||; s|^[^/]*\.md$|.|' | sort | uniq -c | awk '{c=$1; $1=""; sub(/^ /,""); printf "%s %s · ", $0, c}' | sed 's/ · $//')
    ok "notes: $total  ($per)"
    nofm=0; nosum=0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      head -1 "$f" | grep -q '^---' || { nofm=$((nofm+1)); continue; }
      head -40 "$f" | grep -qE '^(summary|description):' || nosum=$((nosum+1))
    done <<EOF
$LIST
EOF
    [ "$nofm" -eq 0 ] && ok "frontmatter: every note has it" || warn "frontmatter missing in $nofm note(s)"
    [ "$nosum" -eq 0 ] && ok "summary: every note has one" || warn "$nosum note(s) without summary:/description: — they show without a description in the index"
    # orphan notes: no [[link]] to them anywhere (MOCs and root notes excluded)
    LINKS=$(printf '%s\n' "$LIST" | grep '\.md$' | tr '\n' '\0' | xargs -0 grep -oh '\[\[[^]|#]*' 2>/dev/null | sed 's/^\[\[//; s|.*/||' | sort -u)
    orph=""
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in ./*/*) ;; *) continue ;; esac
      n=$(basename "$f" .md)
      case "$n" in *MOC*|*README*) continue ;; esac
      printf '%s\n' "$LINKS" | grep -qxF "$n" || orph="$orph${orph:+, }$n"
    done <<EOF
$LIST
EOF
    [ -z "$orph" ] && ok "orphan notes: none" || warn "orphan notes (no [[link]] points to them — add them to their MOC): $orph"
  else
    total=$(ls *.md 2>/dev/null | wc -l | tr -d ' ')
    if [ "${VAULT_LANG:-tr}" = "en" ]; then P="user_ personal_ feedback_ reference_ project_ HANDOFF_ note_"; else P="kullanici_ kisisel_ feedback_ reference_ proje_ HANDOFF_ not_"; fi
    line=""; for p in $P; do c=$(ls "$p"*.md 2>/dev/null | wc -l | tr -d ' '); line="$line$p$c  "; done
    ok "notes: $total  ($line)"
    nofm=0; for f in *.md; do [ -e "$f" ] || continue; [ "$f" = "MEMORY.md" ] && continue; [ "$f" = "README.md" ] && continue; head -1 "$f" | grep -q '^---' || nofm=$((nofm+1)); done
    [ "$nofm" -eq 0 ] && ok "frontmatter: every note has it" || warn "frontmatter missing in $nofm note(s) — description will not show in the index"
    if [ -f MEMORY.md ]; then
      mkb=$(( $(wc -c < MEMORY.md) / 1024 ))
      if [ "$mkb" -gt 100 ]; then warn "MEMORY.md is ${mkb} KB — it has become a document: don't open it in sessions (Grep), shorten each line to one sentence"
      else ok "MEMORY.md present ($(wc -l < MEMORY.md | tr -d ' ') lines, ${mkb} KB)"; fi
    else
      bad "MEMORY.md missing"
    fi
  fi
  cd "$START_DIR" || exit 1
else
  bad "vault folder not found: ${VAULT_DIR:-<unset>}"
fi

echo "[index hook]"
IDX="$CLAUDE_HOME/hooks/vault-index.sh"
if [ -f "$IDX" ]; then
  OUT=$(SALTAY_CONF="$CONF" bash "$IDX")
  SZ=$(printf '%s' "$OUT" | wc -c | tr -d ' ')
  if [ "$SZ" -eq 0 ]; then bad "index is EMPTY — vault path wrong or no notes found"
  elif [ "$SZ" -ge 10000 ]; then bad "index $SZ bytes ≥ 10000 — Claude sees only a 2 KB preview! archive notes now"
  elif [ "$SZ" -gt "${BUDGET:-9500}" ]; then warn "index $SZ bytes > budget ${BUDGET:-9500} — failsafe active, archive soon"
  else ok "index $SZ bytes (< ${BUDGET:-9500} budget)"; fi
  if printf '%s' "$OUT" | grep -qE 'seviyesi [45]|level [45]'; then warn "compression level ≥4 — names shortened; time to archive stale notes"; fi
  if printf '%s' "$OUT" | grep -qE 'ZORLA KESILDI|FORCE-CUT'; then bad "index force-cut marker present — archive immediately"; fi
else
  bad "hook missing: $IDX"
fi

echo "[hook scripts]"
for h in hook-meta.sh backup.sh secret-scan.sh change-log.sh; do
  [ -f "$CLAUDE_HOME/hooks/$h" ] && ok "hooks/$h" || bad "hooks/$h missing — run scripts/install.sh"
done
META="$CLAUDE_HOME/hooks/hook-meta.sh"
if [ -f "$META" ]; then
  R=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"C:\\\\Users\\\\x\\\\a.md"}}' | bash "$META")
  [ "$R" = "Edit|C:/Users/x/a.md" ] && ok "stdin JSON parsed: $R" || bad "hook-meta unexpected output: $R"
fi
SCAN="$CLAUDE_HOME/hooks/secret-scan.sh"
if [ -f "$SCAN" ]; then
  T=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/saltay-scan.$$"); mv "$T" "$T.py" 2>/dev/null; T="$T.py"
  printf "api_key = 'abcdefgh27x0123456'\n" > "$T"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$T" | bash "$SCAN" 2>/dev/null; rc=$?
  rm -f "$T"
  [ "$rc" -eq 2 ] && ok "secret-scan self-test: caught and reported to Claude (exit 2)" || bad "secret-scan self-test failed (exit $rc, expected 2)"
fi

echo "[settings.json]"
S="$CLAUDE_HOME/settings.json"
if [ -f "$S" ]; then
  if command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8").replace(/^\uFEFF/,""))' "$S" 2>/dev/null && ok "valid JSON" || bad "settings.json is NOT valid JSON — Claude Code ignores it; restore the newest settings.json.*.bak"
  fi
  grep -q 'vault-index.sh' "$S" && ok "SessionStart → vault-index.sh" || bad "SessionStart hook not registered"
  grep -q 'backup.sh' "$S" && ok "PreToolUse → backup.sh" || warn "backup hook not registered"
  grep -q 'secret-scan.sh' "$S" && ok "PostToolUse → secret-scan.sh + change-log.sh" || warn "secret-scan hook not registered"
  grep -q 'hooks/hook-meta.sh); f=' "$S" && warn "v1.1 inline hook commands still registered — run scripts/install.sh again (it replaces them)"
  OLDREM=0; grep -qE 'behavior-check-reminder\.json|skill-check-reminder\.json' "$S" && OLDREM=1
  if grep -q 'session-reminder.json' "$S"; then
    if [ -f "$CLAUDE_HOME/session-reminder.json" ]; then ok "UserPromptSubmit → session-reminder.json ($(wc -c < "$CLAUDE_HOME/session-reminder.json" | tr -d ' ') bytes per prompt)"
    else bad "session-reminder.json is registered but missing in $CLAUDE_HOME — run scripts/install.sh"; fi
    [ "$OLDREM" -eq 1 ] && warn "the two v1.0 reminders are still registered next to it — the same rules arrive twice on every prompt; run scripts/install.sh again"
  elif [ "$OLDREM" -eq 1 ]; then
    warn "v1.0 reminders registered (behavior/skill-check, 1.7 KB per prompt) — run scripts/install.sh to migrate to session-reminder.json"
  else
    warn "reminder hook not registered"
  fi
  grep -q 'CLAUDE_TOOL_FILE_PATH' "$S" && warn "a hook still reads \$CLAUDE_TOOL_FILE_PATH — that variable can arrive empty; switch it to hook-meta.sh"
else
  bad "settings.json missing"
fi

echo "[CLAUDE.md]"
C="$CLAUDE_HOME/CLAUDE.md"
if [ -f "$C" ]; then
  if [ "${VAULT_LAYOUT:-flat}" = "folders" ]; then
    grep -qiE 'vault|kasa|hafıza|memory' "$C" && ok "CLAUDE.md mentions the vault" || warn "CLAUDE.md never mentions the vault — add a memory protocol (see CLAUDE.saltay.md)"
  else
    grep -qiE 'Hafıza Protokolü|Memory Protocol' "$C" && ok "memory protocol section present" || warn "no memory protocol section — merge CLAUDE.saltay.md"
    grep -q 'K0' "$C" && grep -q 'K5' "$C" && ok "5 canonical rules present (K0-K5)" || warn "5 canonical rules (K0-K5) missing"
  fi
  ckb=$(( $(wc -c < "$C") / 1024 ))
  if [ "$ckb" -gt 15 ]; then warn "CLAUDE.md is ${ckb} KB and loads in every session — move inventory/history/long rule texts to the vault (target ≤ 12 KB)"
  else ok "CLAUDE.md ${ckb} KB"; fi
else
  bad "CLAUDE.md missing at $C"
fi

echo "[backups / log]"
if [ -f "$CLAUDE_HOME/changes.log" ]; then
  last=$(tail -1 "$CLAUDE_HOME/changes.log")
  if printf '%s' "$last" | grep -qE '\] *$'; then bad "last changes.log line has no tool/path → hook contract broken: $last"; else ok "changes.log last: $last"; fi
else
  warn "changes.log not created yet (appears after the first Edit/Write)"
fi
if [ -d "$START_DIR/.backups" ]; then
  nb=$(ls "$START_DIR/.backups" | wc -l | tr -d ' ')
  kb=$(du -sk "$START_DIR/.backups" 2>/dev/null | cut -f1)
  if [ "${kb:-0}" -gt 51200 ]; then warn ".backups/ here: $nb files, $((kb/1024)) MB — move old ones to .curation-trash-<date>/ (never auto-deleted)"
  else ok ".backups/ here: $nb files, ${kb:-?} KB"; fi
  [ -f "$START_DIR/.backups/.gitignore" ] || warn ".backups/ has no .gitignore (created by v1.1) — add one containing * so backups are never committed"
else
  warn "no .backups/ in $START_DIR yet — edit a file with Claude in this folder and check again"
fi

echo
[ "$FAIL" -eq 0 ] && echo "result: healthy" || { echo "result: PROBLEMS FOUND (see ❌)"; exit 1; }
