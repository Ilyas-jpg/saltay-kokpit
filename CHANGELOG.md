# Changelog

Biçim [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/), sürümleme [SemVer](https://semver.org/).
Format follows Keep a Changelog; versions follow SemVer.

## [1.0.0] — 2026-09-07

İlk sürüm · Initial release.

### Eklendi · Added
- **Hafıza / Memory:** `hooks/vault-index.sh`: kendini ölçen SessionStart index'i (seviye 0-5 +
  failsafe, 10K sınırına asla ulaşmaz), `~/.claude/vault.conf` ile yapılandırma, TR ve EN prefix
  setleri. `hooks/hook-meta.sh`: stdin JSON'dan `tool_name|file_path`.
- **Anayasa / Constitution:** `templates/CLAUDE.md` ve `CLAUDE.en.md`: hafıza protokolü, 5 kanonik
  kural, otonomi trafik ışığı, skill tier refleksi, güvenlik asgarisi, ortam notları, anti-pattern listesi.
- **Vault iskeleti / Vault skeleton:** `templates/vault/` ve `vault-en/`: README, MEMORY, profil,
  5 kanonik kural, feedback / proje / HANDOFF / reference şablonları, skill routing, karar günlüğü, arşiv protokolü.
- **Refleksler / Reflexes:** `hooks/settings.hooks.json`: SessionStart index, UserPromptSubmit
  hatırlatıcıları, PreToolUse yedek, PostToolUse sır tarama ve değişiklik logu. İsteğe bağlı git
  auto-add ve test-runner hook'ları `hooks/README.md`'de.
- **Düzen / Order:** `scripts/new-project.sh` (Aktif/<ad> + .gitignore + git + vault notu + MEMORY
  satırı), `scripts/archive-project.sh` (geri alınabilir arşivleme + vault status + karar kaydı),
  `templates/project/.gitignore` (AI çalışma dosyalarını dışlar), `launch.json.example`.
- **Kurulum / Install:** `scripts/install.sh` (idempotent; var olan dosyaya dokunmaz, yedekli
  birleştirme) ve `scripts/install.ps1` (Git Bash sarmalayıcı); `merge-settings.js` / `.py`.
- **Sağlık / Health:** `scripts/vault-health.sh`: index boyutu, sıkışma uyarısı, stdin testi, hook
  kaydı, `changes.log` sözleşme kontrolü.
- **Dokümanlar / Docs (TR):** neden · vault · anayasa · dosya sistemi · hook'lar · skill/agent/MCP ·
  güvenlik ve yayın · Windows · SSS · 21 anonim ders.
- README (TR + EN), MIT lisansı, katkı rehberi, davranış kuralları, güvenlik politikası, issue/PR şablonları.

[1.0.0]: https://github.com/Ilyas-jpg/saltay-kokpit/releases/tag/v1.0.0
