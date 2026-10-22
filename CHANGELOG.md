# Changelog

Biçim [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/), sürümleme [SemVer](https://semver.org/).
Format follows Keep a Changelog; versions follow SemVer.

## [Unreleased]

### Değişti · Changed
- `SECURITY.md`, `CODE_OF_CONDUCT.md`: güvenlik ve davranış bildirimleri yalnız GitHub'ın özel zafiyet
  bildirimiyle alınır; e-posta adresi kaldırıldı · security and conduct reports go only through GitHub
  private vulnerability reporting; the email address was removed.

## [1.1.0] — 2026-10-22

Sistemin yedi haftalık gerçek kullanımından gelen güncelleme: anayasa sadeleşti, iki kural (skill,
subagent) olaylarla yeniden yazıldı, 17 yeni ders. · Seven more weeks of real use: a leaner
constitution, two rules (skills, subagents) rewritten after incidents, 17 new lessons.

### Değişti · Changed
- **Anayasa / Constitution:** `templates/CLAUDE.md` + `CLAUDE.en.md` "belge değil, yükleme politikası"
  ilkesiyle yeniden yazıldı (TR 13,7 → 11,2 KB): K0-K5 kural başına tek satır; envanter, tarihçe ve
  uzun kural metinleri vault'a; güvenlik bölümü üç satır; self-test bloğu kaldırıldı. · Rewritten as a
  loading policy: one line per rule, inventory/history/long texts moved to the vault, three-line
  security section, no self-test block.
- **K0:** "son 5 mesajı tara" → "brief'in son paragrafı + oturum içi yasaklar" · "scan the last 5 messages" → "the brief's last paragraph + in-session bans".
- **K2:** yetki verilmiş işte güvenlik töreni yok; yapılabilen operasyonel iş kullanıcıya atılmaz · no security ceremony in authorised work; operational work you can do is never handed to the user.
- **K3:** tarayıcı otomasyonunda `onThisComputer` (`isLocal` yalnız işletim sistemi eşleşmesi) · browser automation uses `onThisComputer` (`isLocal` only matches the OS).
- **K4:** "skill görünür / tier" → "skill varsayılan değil": yalnız sende olmayan, işe ya da sürüme özgü
  bilgi için; genel öğüt skill'i çağrılmaz; çelişkide vault kazanır · "skills visible / tiers" → "a skill
  is not a default"; general-advice skills are not called; the vault wins on conflict.
- **Subagent:** "varsayılan kapalı" → "serbest, takılmak yasak": `Agent` çağrısı mesajı bloklar;
  araştırmada ajan yok (5-8 paralel arama); büyük işte ≤ 15 dk süre sınırı · "off by default" →
  "allowed, hanging forbidden": no agents for research, time limits for large jobs.
- **Otonom sınırlar / Autonomy:** kendi varlıklarında doğrulanmış deploy 🟢; müşterinin canlı sitesi ve
  iş durumunu değiştiren anahtarlar 🔴 · verified deploys on your own assets are green; a client's live
  site and business-state switches are red.
- **Hatırlatma / Reminder:** iki uzun `UserPromptSubmit` hatırlatması (1,7 KB / prompt) yerine tek
  `session-reminder.json` (~500 B) · two long reminders replaced by one short one.
- `templates/vault/feedback_5_kanonik_davranis_kurali.md` + EN: kural + tek cümle Why + How; kanıtlar
  sondaki Tarihçe'de · rule + one-sentence Why + How, evidence in a History section.
- `templates/vault/reference_skill_routing.md` + EN: tier tablosu yerine çağır / çağırma tablosu · call / don't-call table instead of tiers.
- `scripts/install.sh`: yeni hatırlatıcı; v1.0'dan otomatik geçiş; vault'ta hâlâ v1.0 metni duran
  şablonları sonda listeler · new reminder, automatic v1.0 migration, lists vault templates still on v1.0 text.
- `scripts/merge-settings.js` / `.py`: isteğe bağlı üçüncü argümanla eski sürümün komutlarını birebir
  eşleşmeyle kaldırır · optional third argument removes an older release's commands by exact match.
- `scripts/vault-health.sh`: hatırlatıcı kontrolü (v1.0 kaldıysa ya da ikisi birden kayıtlıysa uyarı),
  `MEMORY.md` > 100 KB ve `CLAUDE.md` > 15 KB uyarıları, K0-K5 kontrolü ·
  reminder checks, size warnings, K0-K5 check.
- Dokümanlar / Docs: 01-09 güncellendi (yükleme politikası, teslim klasörü, skill/subagent evrimi,
  oturum başı yük, Windows tuzakları, SSS); `docs/10-dersler.md` 21 → 38 ders.
- README TR + EN: v1.1 notu, sayılar, kurallar tablosu, yükseltme bölümü · v1.1 note, numbers, rules table, upgrade section.

### Eklendi · Added
- `templates/reminders/session-reminder.json` + `.en.json`.
- `hooks/settings.remove.json`: v1.0'ın kaydettiği iki hatırlatıcı komutu · the two reminder commands v1.0 registered.
- Vault şablonları / vault templates: `reference_dogrulama_yuzeyi` (doğrulama karar tablosu · verification
  decision table), `reference_kurulum_envanteri` (sayma komutları, oturum başı yük · counting commands,
  session-start load), `not_claude_md_revizyon_gecmisi` (anayasa tarihçesi · constitution history) +
  EN: `reference_verification_surface`, `reference_setup_inventory`, `note_claude_md_revision_history`.

### Düzeltildi · Fixed
- `scripts/install.ps1`: WSL kurulu makinelerde PATH'teki ilk `bash.exe` WSL'in Linux kabuğuydu; kurulum
  Linux içinde başlayıp `/c/...` yollarını bulamıyor, çıkış 127 ile duruyordu. Artık yalnız Git Bash
  seçilir (`CLAUDE_CODE_GIT_BASH_PATH`, `Program Files\Git`, `git.exe`'nin yanı), WSL başlatıcısı atlanır.
  Türkçe karakterli yol ve `-Name` argümanı test edildi. · On machines with WSL the first `bash.exe` on
  PATH was the WSL launcher and the installer died with exit 127; only Git Bash is used now.
- `scripts/vault-health.sh`: `grep '\|'` kalıpları `grep -E`'ye çevrildi (BSD grep / macOS uyumu) · BRE
  alternations replaced with `grep -E` for BSD grep.

### Kaldırıldı · Removed
- `templates/reminders/behavior-check-reminder*.json`, `skill-check-reminder*.json` (yerine · replaced by `session-reminder`).

### Yükseltme · Upgrade
`git pull && bash scripts/install.sh --lang tr` (ya da `en`). Eski iki hatırlatıcı `settings.json`'dan
çıkarılır, dosyaları `.<tarih>.bak` olur; `CLAUDE.md` ve vault notların ezilmez (yeni anayasa
`CLAUDE.saltay.md`'ye yazılır). · The two old reminders are unregistered and renamed to `.bak`; your
`CLAUDE.md` and vault notes are never overwritten.

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

[Unreleased]: https://github.com/Ilyas-jpg/saltay-kokpit/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Ilyas-jpg/saltay-kokpit/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Ilyas-jpg/saltay-kokpit/releases/tag/v1.0.0
