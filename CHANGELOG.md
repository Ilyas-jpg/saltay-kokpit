# Changelog

Biçim [Keep a Changelog](https://keepachangelog.com/tr/1.1.0/), sürümleme [SemVer](https://semver.org/).
Format follows Keep a Changelog; versions follow SemVer.

## [Unreleased]

## [1.2.0] — 2026-11-09

Hata düzeltmeleri, klasörlü Obsidian kasası desteği, kaldırma betiği ve CI. · Bug fixes, support for
existing folder-based Obsidian vaults, an uninstaller and CI.

### Düzeltildi · Fixed
- **Sır tarayıcı / Secret scan** (`hooks/secret-scan.sh`): uyarı stderr + exit 0 ile basılıyordu, Claude
  Code bunu modele göstermez; artık exit 2 ile Claude'a gider. Regex'teki `\x27` grep'te tek tırnak değil
  `\ x 2 7` karakterleriydi: tek tırnaklı değerler, `"key": "value"` (JSON/YAML) ve içinde x/2/7 geçen
  değerler kaçıyordu. Bilinen anahtar biçimleri eklendi (`sk-ant-`, `sk-`, `ghp_`, `AKIA`, `AIza`, `xox?-`,
  `PRIVATE KEY`); değer asla yazdırılmaz, yalnız satır no. Kasıtlı sahte anahtar içeren satır (test, belge)
  `saltay:allow` işaretiyle susturulur. · The warning never reached the model (stderr + exit 0); now
  exit 2. `\x27` inside a grep bracket matched `\ x 2 7`, not a quote. Known token formats added; the
  value is never printed; a line marked `saltay:allow` is skipped.
- **Windows yol yazımı / path spelling:** Git Bash `/c/...` argümanlarını node'a `C:/...` diye geçirir;
  v1.1'den yükseltmede eski komutların birebir eşleşmesi bu yüzden tutmazdı. Birleştirici artık yolu
  bash'in yazdığı gibi alır ve iki yazımı da tanır; yeniden kurulumda kopya bırakmaz. · Git Bash rewrites
  /c/ paths for node; the merger now gets the bash spelling and matches both.
- **Yedek / Backup** (`hooks/backup.sh`): `Write` ile bir dosyanın tamamen ezilmesi yedeklenmiyordu
  (matcher yalnız `Edit|MultiEdit`). Yedek artık oturumun çalışma klasörüne değil, dosyanın **git
  reposunun köküne** (`<repo>/.backups/`), repo dışındaki dosyalar için `~/.claude/saltay-backups/`'a
  gider: Masaüstü'nde açılmış bir oturum `D:\dev` dosyalarının yedeğini (OneDrive ile senkronlanan)
  Masaüstü'ne saçıyordu. Sabit klasör için `SALTAY_BACKUP_DIR`. Aynı adlı dosyalar çakışmaz (yol
  checksum'ı); her yedek klasörü kendi `.gitignore`'unu (`*`) yazar. · Backups go to the file's repo root
  or `~/.claude/saltay-backups/`, not the session's cwd; `Write` is covered; backup folders ignore themselves.
- **Boşluklu yol / Paths with spaces:** `settings.json`'a yazılan hook komutlarında yol tırnaksızdı;
  `C:\Users\John Doe` gibi bir ev klasöründe bütün hook'lar bozuluyordu. · Hook commands quote the path.
- **Türkçe proje adları / Turkish names** (`scripts/lib.sh`): "Şirket Sitesi" → `irket-sitesi` oluyordu;
  artık `sirket-sitesi`. `&` ve `|` içeren açıklamalar not şablonunu bozmuyor. · Transliteration before slugging.
- **OneDrive Masaüstü / Desktop:** varsayılan proje klasörü `$HOME/Desktop` yerine gerçek Masaüstü
  (`cygpath -D`, `xdg-user-dir`, OneDrive); Masaüstü OneDrive'a taşınmış makinede görünmeyen bir klasör
  açılıyordu. Vault varsayılanı da gerçek Belgeler klasörü. · The real Desktop/Documents folder is used.
- `vault-health.sh`: `.backups/` kontrolü vault klasöründe yapılıyordu (önce `cd`); artık çalıştırıldığı
  klasörde. · checked inside the vault by mistake.
- `hook-meta.sh`: açgözlü sed satırdaki SON `file_path`'i alıyordu; artık ilkini (varsa `jq`).
  · now takes the first match (jq when available).
- `install.sh`: `eval` + tek tırnak yerine argv (`'` içeren yollar), eksik seçenek değeri net hata,
  `vault.conf` güvenli tırnaklama. · no eval; missing option values fail clearly.
- Index metni "credential yaz" diyordu, anayasa "sır parola yöneticisinde" diyor; metin "hesap
  işaretçisi, sır ASLA" oldu. · The index no longer tells the model to write credentials.

### Eklendi · Added
- **Klasörlü kasa / Folders layout** (`VAULT_LAYOUT=folders`): alt klasörlerle düzenlenmiş mevcut bir
  Obsidian kasası olduğu gibi kullanılır; şablon kopyalanmaz. Index klasör klasör, en yeni üstte,
  frontmatter `summary:` açıklama olur; `Geri Bildirim / feedback / kural` klasörleri bağlayıcıdır ve
  hiç kısaltılmaz; şablon klasörleri dışarıda, `arsiv/` sayılır. 0-5 sıkışma seviyeleri ve 10K garantisi
  aynı. `install.sh` düzeni kendisi tanır (`--layout auto`). · Use an existing sub-folder vault as is.
- `scripts/uninstall.sh` (+ `install.ps1 -Uninstall`): bütün saltay hook komutları (eski sürümler dahil)
  birebir eşleşmeyle çıkar, dosyalar `.bak` olur; vault, CLAUDE.md, env dokunulmaz. · reversible uninstall.
- **Günlük hatırlatıcı / Journal reminder** (`hooks/journal-reminder.sh` + `hooks/session-track.sh`):
  "önemli işin sonunda oturum özeti yaz" koşullu bir talimattır ve tam da oturum uzun ve yoğunken
  atlanır. `Stop` hook'u, bir iş parçası (vault dışında ≥3 dosya düzenlemesi ya da ≥15 komut) günlüğe
  bir şey yazılmadan bittiğinde Claude'dan BİR KEZ kısa özet ister ya da "günlük gerekmez" demesini
  ister. `stop_hook_active` ile döngüye girmez; günlük yazıldıysa ya da yalnız vault bakımı yapıldıysa
  susar. Klasörlü kasada günlük klasörünü (`Günlük / Journal / Daily`) kendisi bulur; düz kasada her
  vault yazımı sayılır. Ayarlar: `JOURNAL_REMIND`, `JOURNAL_MIN_EDITS`, `JOURNAL_MIN_COMMANDS`,
  `JOURNAL_DIR`. · A Stop hook asks once per stretch of real work for a session summary (or "none needed").
- `install.sh` yeniden kurulumda `vault.conf`'a elle eklenmiş ayarları korur (v1.1 dosyayı baştan yazıp
  siliyordu). · hand-added vault.conf settings survive a reinstall.
- `tests/run.sh` (69 test, sahte HOME) + `.github/workflows/ci.yml`: shellcheck, JSON, LF; Ubuntu,
  macOS, Windows'ta uçtan uca. · end-to-end tests and CI on three OSes.
- `install.sh`: `--layout`, `--core-notes`, `--no-projects`, `--disable-background-tasks`; `VERSION`
  dosyası, `~/.claude/saltay-kokpit.version`, kurulum sonunda `settings.json` JSON doğrulaması.
- `vault-health.sh`: klasörlü kasada klasör başı sayım, `summary` eksikleri, **yetim notlar** (hiçbir
  `[[link]]`in göstermediği), `settings.json` geçerliliği, hook dosyaları, sır tarayıcı öz-testi,
  `.backups/` boyutu. · orphan notes, JSON validity, secret-scan self-test.
- `changes.log` 1 MB'ta döner (`changes.<tarih>.log`), silinmez. · rotated at 1 MB, never deleted.

### Değişti · Changed
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` artık sessizce eklenmiyor; `--disable-background-tasks` ile
  isteğe bağlı (`hooks/settings.env.json`). Yükseltmede var olan değer korunur. · env is opt-in.
- Satır içi hook komutları `hooks/backup.sh`, `secret-scan.sh`, `change-log.sh` dosyalarına taşındı
  (okunur, test edilir); her hook'a `timeout`. v1.1 komutları yükseltmede otomatik kaldırılır.
- `merge-settings.js/.py`: `--home` (yer tutucu JSON ayrıştırıldıktan sonra değişir), `--uninstall`,
  dosya yoksa oluşturur, atomik yazar, BOM'u tolere eder.
- Index'teki konum Windows'ta `C:\...` biçiminde gösterilir (Read aracının beklediği yol).
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
