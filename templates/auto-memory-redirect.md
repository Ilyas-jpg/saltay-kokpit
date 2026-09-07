# Memory Index

> ⚠️ **KANONİK HAFIZA BURASI DEĞİL / THIS IS NOT THE CANONICAL MEMORY.**

**Gerçek hafıza / real memory:** `{{VAULT_DIR}}` (Obsidian vault).

**Neden / why:** Claude Code'un otomatik hafıza dizini (`~/.claude/projects/<çalışma-dizini>/memory/`)
*çalışma dizinine bağlıdır* — başka bir klasörde açılan oturumda görünmez ve vault ile aynı bilgiyi
tutup drift üretir. Tek kaynağa indirildi. / This auto-memory folder is *bound to the working
directory*: it is invisible in a session opened elsewhere and it drifts against the vault. Reduced to
a single source.

**Nasıl çalışıyor / how it works:** the vault index is injected into every session by the
`SessionStart` hook (`~/.claude/hooks/vault-index.sh`), whatever the folder. If a note name matches
the topic, `Read` it; if you don't know the name, `Grep` the vault.

**Yeni kalıcı bilgi / new permanent knowledge:** not here — into the **vault** (`kullanici_` / `feedback_` /
`reference_` / `proje_` / `not_` prefixes; EN: `user_` / `feedback_` / `reference_` / `project_` / `note_`)
plus one line in the vault's `MEMORY.md`. Rule: `~/.claude/CLAUDE.md` → Memory Protocol.
