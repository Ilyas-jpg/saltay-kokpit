#!/usr/bin/env bash
# =============================================================================
# saltay-kokpit · scripts/vault-health.sh
# One-command health check for the whole setup. Run it whenever Claude "seems
# to forget" — the two silent failures this system has met (index truncated at
# the 10K limit, hook contract change) both show up here.
# =============================================================================
set -u
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CONF="${SALTAY_CONF:-$CLAUDE_HOME/vault.conf}"
ok()   { printf '  ✅ %s\n' "$*"; }
bad()  { printf '  ❌ %s\n' "$*"; FAIL=1; }
warn() { printf '  ⚠️  %s\n' "$*"; }
FAIL=0

echo "saltay-kokpit health"
echo "[config]"
if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"; ok "vault.conf: $CONF (lang=${VAULT_LANG:-tr})"
else
  bad "vault.conf missing: $CONF — run scripts/install.sh"; VAULT_DIR="${VAULT_DIR:-}"; VAULT_LANG="${VAULT_LANG:-tr}"
fi

echo "[vault]"
if [ -n "${VAULT_DIR:-}" ] && [ -d "$VAULT_DIR" ]; then
  ok "folder: $VAULT_DIR"
  cd "$VAULT_DIR"
  total=$(ls *.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "${VAULT_LANG:-tr}" = "en" ]; then P="user_ personal_ feedback_ reference_ project_ HANDOFF_ note_"; else P="kullanici_ kisisel_ feedback_ reference_ proje_ HANDOFF_ not_"; fi
  line=""; for p in $P; do c=$(ls "$p"*.md 2>/dev/null | wc -l | tr -d ' '); line="$line$p$c  "; done
  ok "notes: $total  ($line)"
  nofm=0; for f in *.md; do [ "$f" = "MEMORY.md" ] && continue; [ "$f" = "README.md" ] && continue; head -1 "$f" | grep -q '^---' || nofm=$((nofm+1)); done
  [ "$nofm" -eq 0 ] && ok "frontmatter: every note has it" || warn "frontmatter missing in $nofm note(s) — description will not show in the index"
  if [ -f MEMORY.md ]; then
    mkb=$(( $(wc -c < MEMORY.md) / 1024 ))
    if [ "$mkb" -gt 100 ]; then warn "MEMORY.md is ${mkb} KB — it has become a document: don't open it in sessions (Grep), shorten each line to one sentence"
    else ok "MEMORY.md present ($(wc -l < MEMORY.md | tr -d ' ') lines, ${mkb} KB)"; fi
  else
    bad "MEMORY.md missing"
  fi
else
  bad "vault folder not found: ${VAULT_DIR:-<unset>}"
fi

echo "[index hook]"
IDX="$CLAUDE_HOME/hooks/vault-index.sh"
if [ -x "$IDX" ] || [ -f "$IDX" ]; then
  OUT=$(SALTAY_CONF="$CONF" bash "$IDX")
  SZ=$(printf '%s' "$OUT" | wc -c | tr -d ' ')
  if [ "$SZ" -ge 10000 ]; then bad "index $SZ bytes ≥ 10000 — Claude sees only a 2 KB preview! archive notes now"
  elif [ "$SZ" -gt 9500 ]; then warn "index $SZ bytes > budget 9500 — failsafe active, archive soon"
  else ok "index $SZ bytes (< 9500 budget)"; fi
  if printf '%s' "$OUT" | grep -qE 'seviyesi [45]|level [45]'; then warn "compression level ≥4 — project/note names shortened; time to archive stale notes"; fi
  if printf '%s' "$OUT" | grep -qE 'ZORLA KESILDI|FORCE-CUT'; then bad "index force-cut marker present — archive immediately"; fi
else
  bad "hook missing: $IDX"
fi

echo "[hook-meta]"
META="$CLAUDE_HOME/hooks/hook-meta.sh"
if [ -f "$META" ]; then
  R=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"C:\\\\Users\\\\x\\\\a.md"}}' | bash "$META")
  [ "$R" = "Edit|C:/Users/x/a.md" ] && ok "stdin JSON parsed: $R" || bad "unexpected output: $R"
else
  bad "hook-meta.sh missing"
fi

echo "[settings.json]"
S="$CLAUDE_HOME/settings.json"
if [ -f "$S" ]; then
  grep -q 'vault-index.sh' "$S" && ok "SessionStart → vault-index.sh" || bad "SessionStart hook not registered"
  grep -q 'hook-meta.sh' "$S" && ok "PreToolUse/PostToolUse use hook-meta.sh" || warn "backup/log hooks not registered"
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
  grep -qiE 'Hafıza Protokolü|Memory Protocol' "$C" && ok "memory protocol section present" || warn "no memory protocol section — merge CLAUDE.saltay.md"
  grep -q 'K0' "$C" && grep -q 'K5' "$C" && ok "5 canonical rules present (K0-K5)" || warn "5 canonical rules (K0-K5) missing"
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
if ls -d .backups 2>/dev/null >/dev/null; then ok "cwd has .backups/ ($(ls .backups | wc -l | tr -d ' ') files)"; else warn "no .backups/ in cwd yet — edit a file with Claude and check again"; fi

echo
[ "$FAIL" -eq 0 ] && echo "result: healthy" || { echo "result: PROBLEMS FOUND (see ❌)"; exit 1; }
