# 04 · Dosya sistemi — düzen, arşiv, yedek, devir

## Masaüstü mantığı

```
Desktop/
├── 00-Projeler/                 ← tüm kod/iş burada (00- = listede hep en üstte)
│   ├── Aktif/                   ← süren projeler (her biri kendi klasörü, kendi git'i)
│   ├── Arsiv/                   ← biten / donmuş projeler (taşınır, silinmez)
│   ├── _araclar/                ← ortak script'ler (pdf denetleyici, tarama, ffmpeg sarmalayıcı…)
│   ├── _yedekler/               ← elle alınan yedekler (tarihli klasörler)
│   ├── .backups/                ← hook'un otomatik yedekleri (cwd'ye göre)
│   ├── .curation-trash-<tarih>/ ← geri-dönülebilir silme (manifest + RESTORE.md)
│   └── .claude/launch.json      ← Browser pane dev sunucu kaydı (proje-local meşru istisna)
└── 00-Belgeler/                 ← kod olmayan iş belgeleri (teklif, sözleşme, sunum)
```

Neden masaüstü: hızlı erişim ve **Claude'un "diskte ara" refleksi** için tek kök. "Yaptığımız kodu
şablona koy" dendiğinde model kodu uydurmak yerine `Desktop/**` altında gerçek dosyayı arar
([10-dersler](10-dersler.md) #16). Kök ne kadar tek ve tahmin edilebilirse arama o kadar isabetli.

`_` ile başlayanlar proje değil altyapıdır; `.` ile başlayanlar makine üretimidir. İkisi de sıralamada
projelerin dışında kalır.

## Proje yaşam döngüsü

| Aşama | Dosya sistemi | Vault |
|---|---|---|
| **Aç** | `Aktif/<isim>/` + `.gitignore` (AI dosyaları hariç) + `git init` — `scripts/new-project.sh` | `proje_<isim>.md` (şablondan, tarihli) + `MEMORY.md` satırı |
| **Çalış** | kod, `.backups/` dolar | `proje_` notu kararlarla büyür; aktif/uzunsa `HANDOFF_<isim>.md` |
| **Teslim** | canlıda doğrula, kanıt | `status: live`, canlı adres, deploy komutu HANDOFF'ta |
| **Kapat** | `Arsiv/<isim>/`'e taşı — `scripts/archive-project.sh` | `status: archived` + tarihli satır; `MEMORY.md`'de 📦; `not_kararlar`'a karar |

Claude bu döngüyü anayasadaki hafıza protokolü gereği **kendisi yürütür**: yeni müşteri geldiğinde
notu açar, iş bitince arşivler. Script'ler elle kısayoldur, zorunluluk değil.

## Teslim klasörü (v1.1)

Kod proje klasöründe yaşar; **teslim** (ses, video, görsel, PDF, belge) kullanıcının gördüğü tek bir
klasöre konur. Yazarın vakasında beş kez aynı şikâyet geldi: dosya proje klasörünün içinde bırakılmış,
"sohbete gönderdim" denmişti; bir seferinde de hızlıca istenen kısa bir metin, uzun bir turun ortasında
ara metin olarak kalıp hiç görülmemişti ([10-dersler](10-dersler.md) #30).

```
<teslim klasörü>/
└── <Proje Adı>/
    ├── 01 - <İçeriği söyleyen ad>.pdf
    ├── 01 - <İçeriği söyleyen ad>.html     ← belge HTML'se PDF'i yanında
    └── 02 - <İçeriği söyleyen ad>.mp4
```

- Klasör ve dosya adları okunur: boşluklu, numaralı, içeriği söyleyen (`01 - Ana Sayfa Metni.pdf`);
  hepsine aynı adı (`01 - Reels.mp4`) vermek de kural ihlalidir, telefona tek tek gidince hangisi ne
  belli olmaz.
- Mesajda tam yol yazılır. Sohbete göndermek, galeride açmak ya da turun ortasında yazmak bunun yerine geçmez.
- Okunacak ya da birine gönderilecek belge HTML üretildiyse yanına aynı adla PDF konur: HTML telefonda
  ve mesajlaşmada açılmaz. Baskı CSS'inde gölge ve saydamlık kullanılmaz (#31).
- Teslim klasörü proje kökünden ayrı bir yerde durur (yazarda masaüstü ya da ikinci bir disk); proje
  klasörü kodun, teslim klasörü kullanıcının.

## Geri-dönülebilir taşıma (silme yerine)

Temizlik, curate, "şunu kaldır" işlerinde varsayılan **silmek değil taşımaktır**:

```
.curation-trash-2026-06-11/
├── RESTORE.md        ← neyi neden taşıdım + tek satırlık geri alma komutu
└── <taşınan dosya/klasörler>
```

Kural tek cümle: *silme yerine `.curation-trash-<tarih>/`'e taşı + manifest + geri alma komutu.*
Bunun neden kural olduğu: bir "staging klasörü" temizliği production'ı düşürdü; bir `journalctl
--vacuum` on günlük web trafiği/saldırı logunu kalıcı sildi ([10-dersler](10-dersler.md) #8, #13).
İkisi de taşıma olsaydı bir `mv` ile geri gelirdi. **Log dosyası hiç silinmez** — yer gerekiyorsa
`tar.gz` + indir.

Aynı protokol vault için `arsiv/` ve global config için `~/.claude/.curation-trash-<tarih>/` olarak
uygulanır (agent/skill/plugin ayıklamalarında).

## Yedekler — üç katman

| Katman | Kim | Nerede | Not |
|---|---|---|---|
| Otomatik | PreToolUse hook | `./.backups/<dosya>.<tarih>.bak` | **cwd'ye göre** açılır: vault veya `~/.claude` dosyasını düzenlersen yedek o anki proje klasörüne düşer. Tuzak ama davranış bilinçli — cwd her zaman var, hedef klasör her zaman yazılabilir değil. |
| Elle | sen / Claude | `_yedekler/<tarih>-<sebep>/` | Sunucu göçü, kapatılan proje, DB dump. md5/sha256 manifestle. |
| Config | Claude | `<dosya>.<tarih>_<sebep>.bak` yanına | `CLAUDE.md`, `settings.json`, hook düzenlemeden önce. |

Yedek hook'unun gerçekten çalıştığını ara sıra kontrol et: bir dosyayı düzenle → `.backups/` oluştu mu?
`changes.log`'daki satırda araç adı + yol var mı? Boş satır = sözleşme kırılmış ([05-hooklar](05-hooklar.md)).

## HANDOFF belgesi

`proje_` notu *"bu proje ne"* der; `HANDOFF_` *"yarın sabah devralan kişi ilk ne yapar"* der. Ayrı
dosya olmasının sebebi: proje notu zamanla anlatıya dönüşür, operasyon bilgisi içinde kaybolur.
HANDOFF kısa, buyurgan ve günceldir:

- **Durum satırı** (🟢/🟡/⚫ + son doğrulanmış sürüm)
- **Runbook** (sağlık kontrolü komutu, log yeri, kriz düğmeleri)
- **Deploy** (komut, yedek, **rollback** — tek komut olmalı)
- **Bir daha yapılmayacaklar** (bu projede yaşananlar → ilgili `feedback_` linki)
- **Açık işler** (öncelik sırasıyla)

Proje kapanınca HANDOFF *tarihsel* işaretlenir ("runbook geçersiz, güncel durum proje notunda") ama
silinmez — arşivdeki bir projeyi geri açan ilk oturum onu okur.

## Dürüst not: kök zamanla dağılır

Yazarın `00-Projeler/` kökünde altı ay sonra 399 öğe vardı: ekran görüntüleri, tek seferlik `.py`
script'leri, geçici çıktılar. Hiçbir sistem bunu tamamen önlemez; **arşiv protokolü ve
geri-dönülebilir taşıma tam bu yüzden var.** Ara sıra bir "temizlik oturumu" aç: kökteki gevşek
dosyaları `.curation-trash-<tarih>/`'e taşı, bir hafta bekle, hiçbir şey aranmadıysa boşalt.
`file-organizer` tipi bir skill bunu sistemli yapar.

## `launch.json` — proje-local meşru istisna

Claude Code'un Browser pane'i dev sunucularını `<proje-kökü>/.claude/launch.json`'dan okur. Bu dosya
gerçekten o klasöre özgüdür; global'e taşınmaz. `templates/project/launch.json.example` örnektir:
statik siteler için `npx serve -l <port> <klasör>`, framework'ler için kendi dev komutu.
