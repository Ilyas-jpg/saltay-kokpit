# 05 · Hook'lar — modelin iradesine bırakılmayan davranışlar

Hook, Claude Code'un belirli olaylarda çalıştırdığı kabuk komutudur. Model bir şeyi yapmayı
unutabilir; hook unutmaz. Bu sistemde beş hook var, hepsi **bash** (Windows'ta Git Bash).

## Hook tablosu

| Olay | Eşleşme | Ne yapar | Neden |
|---|---|---|---|
| `SessionStart` | — | `vault-index.sh`: vault index'ini basar | Hafızanın **koşulsuz** yüklenmesi. Tek en önemli hook. |
| `UserPromptSubmit` | — | `behavior-check-reminder.json` + `skill-check-reminder.json` içeriğini prompt'a ekler | 5 kural + skill tier her prompt'ta gelir. Uzun oturumda context sıkıştırılınca anayasa bile silikleşir; bu hatırlatma sıkıştırmayı atlatır. |
| `PreToolUse` | `Edit\|MultiEdit` | `./.backups/<ad>.<tarih>.bak` kopyası | Yeşil ışığın ("düzenle, sorma") dayanağı. |
| `PostToolUse` | `Edit\|Write` | `password = "…"` kalıbında sabit sır arar, uyarır | Sır sızıntısı en ucuz burada yakalanır. |
| `PostToolUse` | `Edit\|MultiEdit\|Write` | `~/.claude/changes.log`'a `[zaman] Araç yol` | Denetim izi; hook sağlığının da göstergesi. |

`settings.json` biçimi `hooks/settings.hooks.json` içinde; `install.sh` `__CLAUDE_HOME__` yer
tutucusunu gerçek yolla değiştirip mevcut ayarlara **birleştirir** (mevcut hook'ları silmez, aynı
komutu ikinci kez eklemez).

İsteğe bağlı iki hook (git auto-add, ilgili testleri koştur) `hooks/README.md`'de; herkes istemez
diye varsayılan blokta yok.

## `vault-index.sh` — kendini ölçen index

Akış: vault'a gir → prefix'lere göre adları topla → seviye 0'dan başlayarak çıktıyı üret → byte say →
bütçeyi (9.500) aşıyorsa bir seviye sıkıştır → seviye 5 bile sığmazsa bütçede kontrollü kes + işaret.
Seviyeler [02-hafiza-vault](02-hafiza-vault.md)'ta.

Yapılandırma `~/.claude/vault.conf` (kabuk sözdizimi): `VAULT_DIR`, `VAULT_LANG` (tr|en prefix seti
+ etiketler), `BUDGET`, isteğe bağlı `CORE` (index'te açıklamasıyla görünecek notlar).

**Locale tuzağı:** Git Bash'te `LANG` boş gelir; `cut -c`, `sed`, bash `${s:0:n}` ve `awk` **byte**
sayar, Türkçe (ve her ASCII-dışı) karakteri ortadan böler. Script `export LC_ALL=C.UTF-8` ile açılır
ve kısaltmayı `awk substr` ile yapar. `iconv` bazı Git Bash kurulumlarında **yok** — ona güvenme.

Test:
```bash
bash ~/.claude/hooks/vault-index.sh | wc -c     # ≤ 9500 olmalı
bash ~/.claude/hooks/vault-index.sh | tail -3   # sıkışma uyarısı var mı?
```

## `hook-meta.sh` — "tetikleniyor ≠ çalışıyor"

Diğer hook'lar dosya yolunu buradan alır. Hikâye: hook'lar `$CLAUDE_TOOL_FILE_PATH` /
`$CLAUDE_TOOL_NAME` ortam değişkenlerini okuyordu. Bir Claude Code sürümü bu sözleşmeyi değiştirdi,
değişkenler **boş** gelmeye başladı. Hook'lar "çalışıyordu" — `changes.log`'a satır düşüyordu — ama
satırlar boştu ve `.backups/` iki hafta boyunca hiç oluşmadı. Yeşil ışık ("düzenle, hook yedek alıyor")
yanlış varsayıma dayanıyordu.

Doğru kaynak: hook'a **stdin'den gelen JSON** (`hook_event_name`, `tool_name`, `tool_input.file_path`).
`hook-meta.sh` onu `sed` ile ayrıştırır, Windows yolundaki kaçışlı `\\`'leri `/`'ye çevirir, ortam
değişkenleri geri gelirse onları önceler.

**Ders:** hook'u denetlerken **çıktının içeriğine** bak. Boş alanlı log satırı = sözleşme kırılmış.
Ara sıra fiilen test et: dosya düzenle → `.backups/` oluştu mu? `scripts/vault-health.sh` bunu
otomatik yapar (`changes.log`'un son satırında araç adı var mı diye bakar).

## 10.000 karakter sınırı

Claude Code ≥ 2.1.88, hook çıktısı ~10K karakteri aşınca `<persisted-output> Output too large` ile
dosyaya kaydeder ve modele 2 KB önizleme verir. Oturum başında bu ifadeyi görürsen **index
kesilmiştir**; `wc -c` ile ölç, arşivle. Script bu sınıra ulaşamayacak şekilde yazıldı; yine de
`vault-health.sh` her çalıştığında ölçer.

## Windows notu

Claude Code Windows'ta hook komutlarını Git Bash'te çalıştırır. Hook'ları PowerShell'e çevirme —
bozulur. `bash` ile başlayan komut, `/c/Users/...` yolu, `[[ ]]`, `$(date)` hepsi bash. Ayrıntı:
[08-windows](08-windows.md).

## Hook'a dokunmadan önce

1. `settings.json`'u yedekle (`settings.json.<tarih>_<sebep>.bak`).
2. Davranışı iyileştirmek meşru (örn. test-runner'ı tüm suite yerine değişen dosyaya bağlamak).
3. Değişiklikten sonra **fiilen test et**: oturum yeniden başlat, dosya düzenle, `.backups/` ve
   `changes.log`'a bak. Ayarlar aynı oturumda etkin olur; yeniden başlatma çoğu zaman gerekmez.
