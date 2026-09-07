# 09 · SSS ve sorun giderme

### "Claude hafızası yokmuş gibi davranıyor."
Tahmin etme, ölç:
```bash
bash scripts/vault-health.sh
```
Sırayla: `vault.conf` var mı → index boyutu (< 9.500) → oturum başında `<persisted-output> Output
too large` gördün mü (= index kesildi, arşivle) → `settings.json`'da `SessionStart` kayıtlı mı →
`CLAUDE.md`'de koşullu bir ifade ("ilgiliyse vault'a bak") kaldı mı (kaldır; koşulsuz olacak).
Yazarın vakasında üç ay boyunca sebep koşullu talimattı; ikinci vakada 10K sınırıydı. İkisinde de
veri kaybı yoktu.

### "Yedek alınmıyor / `.backups/` oluşmuyor."
`~/.claude/changes.log`'un son satırına bak. `[tarih]` sonrası boşsa hook sözleşmesi kırılmış:
`settings.json`'daki hook'lar `$CLAUDE_TOOL_FILE_PATH` yerine `hook-meta.sh` kullanmalı (bu depodaki
blok öyle). Ayrıca `.backups/` **cwd'ye göre** açılır — vault dosyasını düzenlediysen yedek o anki
proje klasöründedir.

### "Index'in sonunda 'sıkışma seviyesi 4' yazıyor."
Arşiv zamanı: kapanmış `not_` + 3 aydır dokunulmamış `proje_` → `arsiv/` (protokol `arsiv/README.md`).
Taşıma öncesi her adayın `description`'ını oku. Sonra `bash ~/.claude/hooks/vault-index.sh | wc -c`.

### "Claude sürekli izin soruyor."
K2. Kontrol: `behavior-check-reminder.json` her prompt'ta geliyor mu (`settings.json`
`UserPromptSubmit`)? Claude Code izin modu bypass mı? Sonra vault'a `feedback_` notu: hangi soruyu
sordu, sen ne dedin. İki tekrar = kural.

### "Claude işi genişletiyor / istemediğim refactor yapıyor."
K5. Görevin fiil + nesnesini kendin de net yaz: "sadece hero bölümünü, başka bir şeye dokunma".
Tekrarlarsa `feedback_scope_dar_<proje>.md`.

### "Claude 'sıfırdan' dediğimde eski dosyaları koruyor."
K1. Bir kez daha tekrarlarsa `feedback_` notu; anayasa tablosunda "sıfırdan = tüm dosyalar atılır" zaten var.

### "Vault'u git'e koyayım mı?"
Public'e asla. Private repo veya bulut senkronu olur; credential dosyası onun da dışında kalsın.

### "Birden fazla bilgisayarım var."
Vault'u senkronla (Obsidian Sync / iCloud / Syncthing / private git). Her makinede `install.sh`
çalıştır — `vault.conf` makineye özgü yolu tutar, hook'lar aynıdır. Anayasadaki yollar makine
başına farklıysa `{{VAULT_DIR}}` satırını elle düzelt.

### "Zaten bir CLAUDE.md'm var."
`install.sh` dokunmaz; `~/.claude/CLAUDE.saltay.md` yazar. Önce **Hafıza Protokolü** bölümünü al
(zorunlu), sonra 5 kural + trafik ışığı, gerisi isteğe bağlı.

### "Türkçe mi İngilizce mi?"
Kurulumda `--lang tr|en`. Prefix seti ve index etiketleri dile göre gelir (`proje_`/`not_` ↔
`project_`/`note_`). Karıştırma; hook tek seti tanır. Sonradan değiştirmek = dosyaları yeniden adlandır
+ `vault.conf`'ta `VAULT_LANG`.

### "Obsidian şart mı?"
Hayır. Düz `.md`; Claude için Obsidian'ın varlığı fark etmez. Ama grafik görünümü, wiki-link
tamamlama ve insan-okur arayüzü için tavsiye. `.obsidian/` klasörünü senkron dışında tutabilirsin.

### "Hangi Claude Code sürümü?"
10K hook sınırı ≥ 2.1.88'de görüldü; script daha eski sürümlerde de zararsız çalışır. Hook'ların
stdin JSON sözleşmesi güncel sürümlerde geçerli; ortam değişkenleri geri gelirse `hook-meta.sh` onları
otomatik önceler.

### "Claude Code'un kendi hafıza dizini dolmaya devam ediyor."
Anayasa "kullanma" der; yine de oluşursa `templates/auto-memory-redirect.md` içeriğini oradaki
`MEMORY.md`'ye koy. Tek kaynak vault.

### "Skill'ler çalışıyor mu, nasıl anlarım?"
Claude her görev başında tier kararını **söylemek** zorunda ("frontend-design çağırıyorum çünkü…" /
"senior-backend atlıyorum çünkü generic"). Söylemiyorsa `skill-check-reminder.json` yüklü mü bak;
yüklüyse `feedback_` notu.

### "Subagent kullanmak istiyorum."
Anayasada varsayılan kapalı; açıkça iste. Claude süreyi önden söylemeli ve kapsamı bölmeli.
Sessizlik toleransın yüksekse `CLAUDE.md`'deki anti-pattern satırını yumuşat — bu senin kalibrasyonun.

### "Hook'lar macOS'ta çalışır mı?"
Evet; bash + awk + sed yeter. `LC_ALL=C.UTF-8` yoksa script `en_US.UTF-8`'e düşer. BSD awk eski
sürümlerde `substr`'ı byte sayabilir — açıklama sonunda nadiren kırık karakter görürsen `BUDGET`'i
değiştirmen gerekmez, sadece kozmetik.
