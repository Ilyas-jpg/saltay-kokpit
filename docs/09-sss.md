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
K2. Kontrol: `session-reminder.json` her prompt'ta geliyor mu (`settings.json` → `UserPromptSubmit`)?
Claude Code izin modu ne? Yüklü bir output style ya da eklenti "karar noktasında dur, kullanıcıya
sor" diyor olabilir: anayasayla çelişen yük kuralı sessizce ezer ([10-dersler](10-dersler.md) #23).
Sonra vault'a `feedback_` notu: hangi soruyu sordu, sen ne dedin. İki tekrar = kural.

### "v1.0 kurdum, nasıl yükseltirim?"
```bash
git pull
bash scripts/install.sh --lang tr
```
Kurulum `settings.json`'daki iki eski hatırlatıcıyı çıkarır, yenisini ekler, eski iki dosyayı
`.<tarih>.bak` yapar. `CLAUDE.md`'ne ve vault notlarına dokunmaz: yeni anayasa `CLAUDE.saltay.md`'ye
yazılır, yeni üç vault şablonu eklenir. Vault'unda hâlâ v1.0 metni duran şablonlar (5 kanonik kural,
skill routing, `MEMORY.md`) kurulumun sonunda listelenir; onları `templates/vault/` ile elle
karşılaştır. Farklar: [CHANGELOG](../CHANGELOG.md).

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
(zorunlu), sonra K0-K5 + trafik ışığı, gerisi isteğe bağlı. Birleştirirken boyuta dikkat: anayasa her
oturumda yüklenir; ≤ 12 KB hedef, `vault-health.sh` 15 KB'ı geçince uyarır.

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

### "Claude skill'lerimi kullanmıyor."
v1.1'de bilinçli: skill varsayılan değil. Claude yalnız kendisinde olmayan, işe ya da sürüme özgü bilgi
veren bir skill'i (dosya üretimi, sürüme özgü API, senin yazdığın bir hat) çağırır ve bunu tek cümleyle
söyler; atladığını anlatmaz. Belirli bir iş için bir skill'in kullanılmasını istiyorsan bunu
`reference_skill_routing` notuna yaz ya da görevde söyle. Bir skill çıktıyı kötüleştirdiyse adını aynı
nota "çağırma" tarafına yaz. Arka plan: [06-skill-agent-mcp](06-skill-agent-mcp.md).

### "Subagent kullanmak istiyorum."
Serbest, ama takılmak yasak. Büyük ve bağımsız işte (birbirinden bağımsız modüller, salt-okuma paralel
kontroller) Claude ajan açabilir: süre sınırı koyar, tahmini süreyi baştan söyler, dönen sonucu
doğrular. Araştırma ve soru-cevapta ajan açmaz; paralel aramayla kısa turlar yürütür. Sessizlik
toleransın yüksekse `CLAUDE.md`'deki 🤖 satırını gevşet: bu senin kalibrasyonun.

### "Claude dondu mu? Sayaç dönüyor, ekranda tek satır yok."
Büyük ihtimalle bir `Agent` çağrısı sürüyor. `Agent` mesajı bloklar: aynı mesajdaki her işin sonucu en
yavaş ajan bitince gelir, o sürede model sana tek satır yazamaz. Durdurup "ajansız, paralel aramayla
devam et" de; olayı vault'a `feedback_` notu olarak yazdır. Anayasadaki 🤖 satırı bunun için var
([10-dersler](10-dersler.md) #26).

### "Hook'lar macOS'ta çalışır mı?"
Evet; bash + awk + sed yeter. `LC_ALL=C.UTF-8` yoksa script `en_US.UTF-8`'e düşer. BSD awk eski
sürümlerde `substr`'ı byte sayabilir — açıklama sonunda nadiren kırık karakter görürsen `BUDGET`'i
değiştirmen gerekmez, sadece kozmetik.
