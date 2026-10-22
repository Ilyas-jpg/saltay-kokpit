<p align="center">
  <img src="assets/banner.svg" alt="Saltay Kokpit — Claude Code için kokpit" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="Lisans: MIT" src="https://img.shields.io/badge/lisans-MIT-F5C518?style=flat-square"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-0B0F14?style=flat-square">
  <img alt="Claude Code" src="https://img.shields.io/badge/Claude%20Code-hooks%20%2B%20CLAUDE.md-0B0F14?style=flat-square">
  <img alt="Dil" src="https://img.shields.io/badge/dil-TR%20%2B%20EN-0B0F14?style=flat-square">
  <a href="README.en.md"><img alt="English" src="https://img.shields.io/badge/README-English-2EA043?style=flat-square"></a>
</p>

**Saltay Kokpit**, Claude Code'u *unutmayan*, kendi düzenini kuran ve denetlenebilir bir çalışma
arkadaşına çeviren açık kaynak kurulumdur. Kalıcı hafıza (Obsidian vault), davranış anayasası
(`CLAUDE.md`), refleksler (hook'lar) ve dosya disiplini (aktif/arşiv) tek pakette. Tek komutla
kurulur, mevcut ayarlarına dokunmaz.

Adını yazarın soyadından ve pilot kabininden alır. Kokpit, göstergelerin, otomatik pilotun ve
kırmızı düğmelerin olduğu yerdir: uçuşu Claude yapar, rotayı ve sınırları sen belirlersin.

> **v1.1 (2026-10-22):** yedi haftalık gerçek kullanımın ardından. Anayasa "belge değil yükleme
> politikası" ilkesiyle ~11 KB'a indi; her prompt'taki iki uzun hatırlatma (1,7 KB) tek kısa
> hatırlatmaya (~500 B); skill kuralı "varsayılan değil", subagent kuralı "serbest, takılmak yasak"
> oldu; üç yeni vault şablonu ve 17 yeni ders geldi. v1.0'dan yükseltme tek komut
> ([aşağıda](#v10dan-yükseltme)); tüm farklar [CHANGELOG](CHANGELOG.md)'da.

---

## İçindekiler

- [Bu ne, kimin için](#bu-ne-kimin-için)
- [Sorun](#sorun)
- [Çözüm: dört katman](#çözüm-dört-katman)
- [Bir oturum nasıl akar](#bir-oturum-nasıl-akar)
- [5 dakikada kurulum](#5-dakikada-kurulum)
- [Depo yapısı](#depo-yapısı)
- [Omurga: kurallar ve refleksler](#omurga-kurallar-ve-refleksler)
- [Gerçek hatalardan çıkan dersler](#gerçek-hatalardan-çıkan-dersler)
- [Sözlük](#sözlük)
- [Dürüst sınırlar](#dürüst-sınırlar)
- [Yol haritası](#yol-haritası)
- [Katkı, güvenlik, lisans](#katkı-güvenlik-lisans)

## Bu ne, kimin için

Claude Code varsayılan olarak **her oturumu sıfırdan** başlatır. Sen kimsin, hangi projeler var,
hangi sunucuya nasıl girilir, dün ne kararlaştırıldı, geçen hafta "bunu bir daha yapma" dediğin
şey: hepsi gider. Bu depo, yedi ay boyunca tek bir bilgisayarda, yüzden fazla gerçek projede
(kurumsal siteler, yönetim panelleri, botlar, video hattı, afet araçları) o sıfırlamayı kırmak için
kurulan sistemin **kişisel ve müşteri verisi ayıklanmış** halidir.

| Sayılarla | v1.0 (eylül) | v1.1 (ekim) |
|---|---|---|
| Vault notu | 375 | 534 (+43 arşivde) |
| Davranış kuralı (`feedback_`) | 128 | 188 |
| Proje notu | 89 | 124 |
| Belgelenmiş "gerçek hata → kural" dersi | 21 | 38 |
| Anayasa (`CLAUDE.md`, her oturumda yüklenir) | 24 KB | 11-14 KB |

Teori değil: her kuralın arkasında tarihli bir olay var ([docs/10-dersler.md](docs/10-dersler.md)).

**Kimin için:** Claude Code ile günlük iş üreten herkes: freelancer, ajans, yan proje yapan öğrenci.
Özellikle "her oturumda aynı şeyi anlatıyorum", "sürekli izin soruyor", "istemediğim yeri de
değiştirdi", "düşük risk dedi, site düştü" diyenler için.

**Kimin için değil:** tek seferlik soru-cevap kullanımı; Claude API/SDK entegrasyonu (bu bir
uygulama değil, çalışma sistemi). Cursor, Codex gibi başka ajanlara anayasa ve vault katmanı
uyarlanabilir, hook'lar Claude Code'a özgüdür.

## Sorun

- **Hafıza yok.** "Hatırla" dersin; yazılır ama bir sonraki oturumda okunmaz.
- **Koşullu talimat çalışmaz.** *"Geçmişle ilgiliyse notlara bak"* dediğinde karar modelin o anki
  yargısına kalır. Üç ay boyunca "bazen hafızası yokmuş gibi" davranmasının kök nedeni buydu.
- **Claude Code'un kendi hafıza dizini çalışma klasörüne bağlı.** Başka klasörde açınca yok; iki
  yerde aynı bilgi, sonunda çelişki.
- **İzin sorar, kapsam genişletir, "düşük risk" der.** Aynı düzeltmeyi her oturumda yeniden yaparsın.
- **Sessiz arızalar.** Hook çıktısı 10.000 karakteri aşınca Claude sadece 2 KB önizleme görür; bir
  sürüm hook değişkenlerini boşaltır ve yedekler iki hafta sessizce alınmaz. Kimse fark etmez.

## Çözüm: dört katman

```mermaid
flowchart TB
    subgraph M["🧠 HAFIZA — Obsidian vault"]
        direction LR
        m1["kullanici_ · kisisel_"] --- m2["feedback_ (Kural + Why + How)"] --- m3["reference_ · proje_ · HANDOFF_ · not_"]
    end
    subgraph A["📜 ANAYASA — ~/.claude/CLAUDE.md (global, tek)"]
        direction LR
        a1["hafıza protokolü"] --- a2["5 kanonik kural"] --- a3["🟢🟡🔴 otonomi"] --- a4["güvenlik"]
    end
    subgraph H["⚙️ REFLEKSLER — hooks (bash)"]
        direction LR
        h1["SessionStart: index enjekte (≤ 9,5 KB)"] --- h2["PreToolUse: yedek"] --- h3["PostToolUse: sır tarama · log"] --- h4["UserPromptSubmit: kısa hatırlatma"]
    end
    subgraph F["🗂️ DÜZEN — dosya sistemi"]
        direction LR
        f1["00-Projeler/Aktif · Arsiv"] --- f2[".backups/ · .curation-trash-tarih/"] --- f3["HANDOFF belgeleri"]
    end
    H -->|"her oturumda koşulsuz yükler"| M
    A -->|"okuma / yazma protokolü"| M
    H -->|"her prompt'ta hatırlatır"| A
    M -->|"proje notları tarif eder"| F
    F -->|"arşiv protokolü geri yazar"| M
```

| Katman | Ne yapar | Nerede |
|---|---|---|
| **Hafıza** | Düz `.md` notlar, prefix'li, frontmatter'lı. Index'i her oturuma **koşulsuz** gelir; kendini ölçer, 10K sınırına asla ulaşmaz. | `templates/vault/` → `~/Documents/ClaudeVault` |
| **Anayasa** | Davranış çekirdeği: hafıza protokolü, 5 kanonik kural, trafik ışığı, üç satırlık güvenlik, kurulum ilkeleri, anti-pattern listesi. Bilgi değil, davranış; envanter ve tarihçe vault'ta. | `templates/CLAUDE.md` → `~/.claude/CLAUDE.md` |
| **Refleksler** | Modelin iradesine bırakılmayan işler: index yükle, düzenlemeden önce yedekle, sır tara, kuralı hatırlat. | `hooks/` → `~/.claude/hooks/` + `settings.json` |
| **Düzen** | Aktif/arşiv klasörleri, geri-dönülebilir silme, devir belgeleri; proje aç/kapat script'leri. | `scripts/` |

## Bir oturum nasıl akar

1. Oturum açılır. Hook, vault index'ini basar: *"534 not · çekirdek: profil, 5 kural, skill routing · feedback: … · proje: …"*
2. Sen: *"örnek-site'nin hero'sunu canlıya al."*
3. Hook her prompt'a kısa bir hatırlatma ekler: vault'a bak ve yaz, brief'in sonunu tut, kırmızı dışında izin sorma.
4. Model index'te `proje_ornek_site` ve `HANDOFF_ornek_site` görür, **okumadan cevap vermez**: deploy komutu, yedek yolu, "bir daha yapma" listesi oradadır.
5. Deploy öncesi riski simüle eder (ana sayfa, apex domain, dil değişimi). Düzenlediği her dosyadan önce `.backups/`'a kopya düşer.
6. Canlıda doğrular, kanıt gösterir; "yükledim, oldu" demez.
7. Sen: *"bundan sonra hero videolarında ses olmasın."* Model `feedback_hero_video_ses.md` yazar (Kural + Why + How to apply), `MEMORY.md`'ye bir satır ekler, tek cümleyle bildirir.
8. Ertesi gün, başka klasörde: 1. adım aynen tekrar eder. **Hiçbir şey anlatmazsın.**

## 5 dakikada kurulum

Gereksinim: Claude Code ve bash. Windows'ta Git for Windows yeter; Claude Code onu zaten istiyor.
Node veya python3 varsa `settings.json` otomatik birleştirilir; yoksa elle birleştirmen için hazır
dosya bırakılır.

```bash
git clone https://github.com/Ilyas-jpg/saltay-kokpit.git
cd saltay-kokpit
bash scripts/install.sh --lang tr --name "Adın"
```

Windows PowerShell'den:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Lang tr -Name "Adın"
```

Kurulum idempotent: var olan dosyaya dokunmaz, gerektiğinde tarihli yedek alır. Önce görmek
istersen `--dry-run`.

| Adım | Hedef |
|---|---|
| Vault şablonları | `~/Documents/ClaudeVault/` (var olan notlara dokunmaz) |
| Proje klasörü iskeleti | `~/Desktop/00-Projeler/{Aktif,Arsiv,_araclar,_yedekler}` |
| Hook'lar, `vault.conf`, hatırlatıcı | `~/.claude/hooks/`, `~/.claude/vault.conf`, `~/.claude/session-reminder.json` |
| Anayasa | `~/.claude/CLAUDE.md`; **varsa dokunmaz**, yanına `CLAUDE.saltay.md` yazar |
| Hook kaydı | `~/.claude/settings.json`'a birleştirir (yedek alır, aynı komutu iki kez eklemez) |
| Doğrulama | index boyutu ve stdin JSON testi |

Seçenekler: `--lang en` · `--vault DIR` · `--projects DIR` · `--claude-home DIR` · `--dry-run`.

Sonra: Claude Code'u yeniden başlat; oturum başında index gelmeli. Obsidian'da *Open folder as
vault* ile vault'u aç. `kullanici_profil.md`'yi doldur ya da ilk oturumda Claude'a anlat, o yazar.

Sağlık kontrolü, Claude "unutuyor gibi" olduğunda ilk komut:

```bash
bash scripts/vault-health.sh
```

Proje açmak ve kapatmak:

```bash
bash scripts/new-project.sh "Müşteri Sitesi" --desc "Kurumsal site + teklif formu"
bash scripts/archive-project.sh "Müşteri Sitesi" --reason "teslim edildi"
```

### v1.0'dan yükseltme

```bash
git pull
bash scripts/install.sh --lang tr
```

Kurulum `settings.json`'daki iki eski hatırlatıcıyı birebir komut eşleşmesiyle çıkarır, yenisini
ekler, eski iki dosyayı `.<tarih>.bak` yapar; başka hook'una dokunmaz. `CLAUDE.md`'n ve vault notların
ezilmez: yeni anayasa `CLAUDE.saltay.md`'ye yazılır, üç yeni vault şablonu eklenir, vault'unda hâlâ
v1.0 metni duran şablonlar kurulumun sonunda listelenir (elle karşılaştır).

## Depo yapısı

```
saltay-kokpit/
├── README.md · README.en.md · LICENSE · CONTRIBUTING.md · SECURITY.md · CHANGELOG.md
├── docs/
│   ├── 01-neden.md              sorun, felsefe, dört katman, bir oturumun akışı
│   ├── 02-hafiza-vault.md       prefix sistemi, iki index, 10K sınırı, sıkışma seviyeleri, arşiv
│   ├── 03-anayasa.md            yükleme politikası, bölümler, K0-K5, trafik ışığı, bakım
│   ├── 04-dosya-sistemi.md      Aktif/Arşiv, teslim klasörü, geri-dönülebilir taşıma, yedek, HANDOFF
│   ├── 05-hooklar.md            her hook'un nedeni, kendini ölçen index, tek kısa hatırlatma
│   ├── 06-skill-agent-mcp.md    skill varsayılan değil, subagent, MCP, oturum başı yük
│   ├── 07-guvenlik-ve-yayin.md  kod güvenliği asgarisi, log silme yasağı, GitHub hijyeni
│   ├── 08-windows.md            iki kabuk, UTF-8, Bash tool tuzakları, Python, ASCII dışı yollar
│   ├── 09-sss.md                sorun giderme, v1.0'dan yükseltme
│   └── 10-dersler.md            38 gerçek olay → kural
├── templates/
│   ├── CLAUDE.md · CLAUDE.en.md            anayasa (yer tutucular kurulumda dolar)
│   ├── vault/ · vault-en/                  vault iskeleti: README, MEMORY, profil, 5 kural, skill routing,
│   │                                       doğrulama yüzeyi, kurulum envanteri, anayasa tarihçesi, şablonlar, arşiv
│   ├── reminders/                          UserPromptSubmit hatırlatıcısı (tr/en, ~500 B)
│   ├── project/.gitignore                  AI dosyalarını dışlayan proje .gitignore'u
│   ├── project/launch.json.example         Browser pane dev sunucu kaydı
│   └── auto-memory-redirect.md             Claude Code'un kendi hafıza dizini için yönlendirme
├── hooks/
│   ├── vault-index.sh           SessionStart: kendini ölçen index (seviye 0-5 + failsafe)
│   ├── hook-meta.sh             stdin JSON → tool_name|file_path
│   ├── settings.hooks.json      settings.json'a birleştirilecek blok
│   ├── settings.remove.json     eski sürümün komutları (yükseltmede kaldırılır)
│   └── README.md                hook tablosu + isteğe bağlı hook'lar
├── scripts/
│   ├── install.sh · install.ps1 kurulum (idempotent)
│   ├── vault-health.sh          sağlık kontrolü
│   ├── new-project.sh           Aktif/<ad> + .gitignore + git + vault notu + MEMORY satırı
│   ├── archive-project.sh       Aktif → Arsiv (geri alınabilir) + vault status + karar kaydı
│   └── merge-settings.js/.py    settings.json birleştirici
└── assets/                      banner
```

## Omurga: kurallar ve refleksler

**5 kanonik davranış kuralı** (anayasada kural başına tek satır; ayrıntı [docs/03-anayasa.md](docs/03-anayasa.md)):

| | Kural | Tek cümle |
|---|---|---|
| K0 | Brief'in sonu | Brief'in son paragrafı ve oturum içi yasaklar kaybolmaz |
| K1 | Literal yorum | "Sıfırdan" = %100, "denesene" = test, "kullanma" = yasak |
| K2 | Otonom devam | İzin sorma; gerçek tercih (A/B/C) ve 🔴 risk sorulabilir; yapabildiğin işi kullanıcıya atma |
| K3 | Riski sıkı değerlendir | Silme/deploy öncesi vault grep + kullanıcı yolunu simüle et; bu bilgisayardaki tarayıcıyı sür |
| K4 | Skill varsayılan değil | Sende olmayan, işe/sürüme özgü bilgi veriyorsa çağır; genel öğütse çağırma |
| K5 | Scope dar | Fiil + nesne; "daha iyi olur" ile genişletme yok; yan konuyu sessizce ölç, sonda raporla |

**Trafik ışığı:** 🟢 düzenle, oku, test et, kendi sitene doğrulanmış deploy: sorma · 🟡 refactor, DNS,
şema: yap, raporla · 🔴 para, geri alınamaz silme, yasal, müşterinin canlı sitesi, public yayın,
domain: dur, sor. "Tam yetki sende" kırmızıyı kaldırmaz.

**Subagent:** serbest, takılmak yasak. `Agent` çağrısı mesajı bloklar; araştırmada ajan yok, tek
mesajda 5-8 paralel arama; büyük işte süre sınırı ve tahmini süre.

**Vault prefix'leri:** `kullanici_` `kisisel_` `feedback_` `reference_` `proje_` `HANDOFF_` `not_`.
Hook adları prefix'e göre bölümler; `feedback_` adları hiçbir sıkışma seviyesinde kırpılmaz.

**Hook'lar:** `SessionStart` index · `UserPromptSubmit` kısa hatırlatma (~500 B) · `PreToolUse` yedek ·
`PostToolUse` sır tarama + değişiklik logu.

## Gerçek hatalardan çıkan dersler

Altı örnek; 38'inin tamamı [docs/10-dersler.md](docs/10-dersler.md)'de.

1. **Koşullu hafıza talimatı** üç ay boyunca "bazen unutuyor" üretti. Kural: hafıza koşulsuz yüklenir.
2. **Hook çıktısı 10K'yı aşınca** Claude index'in %85'ini görmüyordu. Kural: index kendini ölçer, kademeli sıkışır.
3. **Hook değişkeni bir sürümde boş geldi**, yedekler iki hafta sessizce alınmadı. Kural: stdin JSON + fiili test.
4. **Altı paralel subagent** 75 dakika sessizlik üretti, yasaklandı; iki ay sonra yasak kalktı, araştırma
   ajanları yine 56-60 dakika sustu. `Agent` çağrısı mesajı bloklar. Kural: araştırmada ajan yok, paralel arama.
5. **Her prompt'a eklenen hatırlatma** aynı kuralların dördüncü kopyasıydı; 24 KB'lık anayasanın yarısı
   envanterdi. Kural: anayasa yükleme politikasıdır, belge değil.
6. **`journalctl --vacuum`** on günlük saldırı logunu sildi. Kural: log hiç silinmez.

## Sözlük

| Terim | Anlamı |
|---|---|
| **Vault** | Obsidian'da açılan düz `.md` klasörü; Claude'un kalıcı hafızası. |
| **Index** | Vault'taki not *adlarının* listesi. Yalın hali hook'la her oturuma gelir; zengin hali `MEMORY.md`. |
| **Anayasa** | `~/.claude/CLAUDE.md`. Bilgi değil davranış taşır; tek ve global. |
| **Kanonik kural** | Tekrarlanan düzeltmelerin damıtıldığı 5 (+1) meta-kural. |
| **Feedback notu** | Bir düzeltmenin üç parçası: Kural + Why + How to apply. Bağlayıcıdır. |
| **HANDOFF** | Bir projenin operasyonel devir belgesi: durum, runbook, deploy, "bir daha yapma". |
| **Skill kararı** | Tek soru: bu skill bende olmayan, işe ya da sürüme özgü bir bilgi veriyor mu? Evetse çağır, hayırsa çağırma. |
| **Yükleme politikası** | Her oturumda yüklenen şeyin (anayasa, hatırlatma, plugin, agent tanımı) yalnız her oturumda geçerli çekirdeği taşıması. |
| **Geri-dönülebilir taşıma** | Silmek yerine `.curation-trash-<tarih>/`'e taşımak; manifest + geri alma komutu. |
| **Sıkışma seviyesi** | Index'in bütçeye sığmak için uyguladığı kademe (0-5). Seviye ≥4 = arşivleme zamanı. |

## Dürüst sınırlar

- **Tek kişinin kalibrasyonu.** Kurallar bir çalışma tarzından damıtıldı; fork'la, kendi olaylarını
  ekle. Sistem *senin* hatalarından öğrenmeye başladığında işe yarar.
- **Kök dağılır.** Altı ay sonra proje kökünde 399 öğe vardı. Arşiv protokolü ve geri-dönülebilir
  taşıma tam bu yüzden var; ara sıra temizlik oturumu gerekir.
- **Kurallar da şişer.** Yazarın anayasası 24 KB'tan 10,9 KB'a indirildi, üç haftada 13,6 KB'a geri
  çıktı; index'i bugün sıkışma seviyesi 4'te. Her yeni model neslinde yeniden ölçmek gerekir.
- **Hook'lar bash.** Windows'ta Git Bash şart. PowerShell'e çevirme, bozulur.
- **10K sınırı sürüme bağlı** (Claude Code ≥ 2.1.88'de görüldü). Script eski sürümlerde de zararsızdır.
- **Vault kişiseldir.** Public repoya asla; senkron ya da private yedek, credential dışarıda.
- **Dokümanlar şimdilik Türkçe.** README'nin İngilizcesi sistemi eksiksiz anlatır; doküman çevirisi
  katkıya açık.
- Bu depo, sistemin kendisi kullanılarak Claude Code ile birlikte hazırlandı; script'ler sanal bir
  HOME'da uçtan uca test edildi (TR temiz kurulum, EN mevcut ayarlara birleştirme, v1.0'dan yükseltme,
  tekrar çalıştırma, proje aç/arşivle, sağlık kontrolü).

## Yol haritası

- `docs/` İngilizce çevirisi.
- macOS ve Linux'ta topluluk testleri (script'ler POSIX; yazar Windows'ta geliştirdi).
- Anayasa ve vault katmanının Claude Code dışındaki ajanlar için uyarlama notu.

## Katkı, güvenlik, lisans

Çeviri, başka OS/kabuk için hook portu, kendi "olay → kural" derslerin (kişisel veri olmadan) hoş
gelir. Generic "best practice" listeleri gelmez; her kuralın bir hikâyesi olmalı.
[CONTRIBUTING.md](CONTRIBUTING.md) · [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) ·
güvenlik bildirimi için [SECURITY.md](SECURITY.md) · sürümler [CHANGELOG.md](CHANGELOG.md).

MIT lisansı. **İlyas Saltay** · [ilyassaltay.com](https://ilyassaltay.com) · [algow.net](https://algow.net) ·
[github.com/Ilyas-jpg](https://github.com/Ilyas-jpg)
