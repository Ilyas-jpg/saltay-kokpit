# 02 · Hafıza — Obsidian vault

## Neden Obsidian (neden bir veritabanı değil)

- **Düz `.md` dosyaları.** Claude `Read`/`Grep`/`Write` ile doğrudan çalışır; ek araç, API, embedding yok.
- **İnsan da okur.** Obsidian'da açarsın, grafik görünümünde projeler–kişiler–kararlar arasındaki
  bağları görürsün, elle düzeltirsin. Sadece makinenin okuduğu hafıza bir gün güvenini kaybeder.
- **Wiki-link.** `[[proje_x]]` yazmak yeter; klasör hiyerarşisi yok, **düz** yapı. Bağlar klasörden önemlidir.
- **Git'e girmez, yerel kalır.** Kişisel veri, hesap işaretçileri, müşteri bilgisi. Yedeğini bulut
  senkronu ya da *private* bir depoyla al; public repoya koyma.

## Prefix sistemi

| Prefix | Ne | Kaç tane olur | Not |
|---|---|---|---|
| `kullanici_profil` | Sen kimsin, nasıl çalışırsın | 1 (büyür) | Çekirdek; index'te açıklamasıyla görünür |
| `kisisel_<konu>` | Aile, çevre, planlar, sağlık | az | İstersen. Kişisel bağlam tonu doğru kurar |
| `feedback_<konu>` | Düzeltme / tercih → **Kural + Why + How to apply** | çok (yazarda 128) | **Bağlayıcı.** Hook hiçbir sıkışma seviyesinde bu adları kırpmaz |
| `reference_<konu>` | Sunucu, hesap, panel, standart, marka | orta (51) | Tablo halinde; sırlar parola yöneticisinde |
| `proje_<isim>` | Her projenin bağlamı, kararları, durumu | çok (89) | `status:` alanı: active / paused / live / archived |
| `HANDOFF_<isim>` | Oturumlar arası devir: runbook, deploy, "bir daha yapma" | az (12) | Uzun/aktif projelerin operasyonel ikizi |
| `not_<konu>` | Karar günlüğü, olay, denetim, öğrenme | çok (76) | `not_kararlar` kronolojik tek dosya |

Prefix'ler kozmetik değil: `hooks/vault-index.sh` adları prefix'e göre bölümler ve bölümleri farklı
önceliklerle sıkıştırır. Yeni bir prefix icat edersen index'te "Prefixsiz dosyalar" bölümüne düşer
(görünür ama bölümsüz).

## Frontmatter — üç alan, biri kritik

```yaml
---
name: Kısa başlık
description: Tek satır. Gelecek oturumda "bu not ne işe yarar" sorusunun cevabı.
type: user | feedback | project | reference | note | personal
status: active        # proje_ için
created: 2026-05-27   # feedback_ için (kuralın yaşı önemlidir)
---
```

`description` **index'te görünür** (çekirdek notlarda tam, ötekilerde `MEMORY.md` üzerinden). Kötü
description = "proje notu". İyi description = *"ornek-site.com — kurumsal site + teklif formu, PHP 8.3
+ MariaDB, paylaşımlı hosting, canlı 2026-06-01"*. Model neyi açacağına buna bakarak karar verir.

## İki index

| | Yalın index (hook) | Zengin index (`MEMORY.md`) |
|---|---|---|
| Kim üretir | `vault-index.sh`, her oturumda otomatik | Claude + sen, elle |
| İçerik | not **adları** bölümlere ayrılmış, çekirdekte açıklama | her nota bir satır: link + kanca cümle + durum emojisi |
| Boyut | ≤ 9.500 byte (kendini ölçer) | sınırsız (yazarda ~190 KB) |
| Amaç | "hangi notlar var" — koşulsuz görünürlük | "hangi not ne halde" — derinlik gerekince açılır |

Yeni not yazınca hook onu kendiliğinden listeler; ekstra iş yok. Ama `MEMORY.md`'ye **tek satır**
eklemeye devam et — Obsidian'da okunan, öyküsü olan index odur.

## Okuma protokolü (koşulsuz)

1. Context'in başındaki index'te konuyla ilgili ad var mı → **`Read`**. Hatırladığını varsayma.
2. Yoksa **`Grep`** (`grep -rli "<anahtar>" <vault>`; arşiv dahil).
3. Kullanıcı / proje / tercih / hesap / karar / tasarım geçiyorsa ilgili notu **okumadan cevap yok**.
4. Çakışma → kullanıcıya teyit → güncelle.
5. Derinlik → `MEMORY.md`.

**Grep > isim tahmini.** Yazarın vault'unda iki kez neredeyse duplike not üretildi: konu vault'ta
başka bir adla zaten vardı. İsim tahmini yetmez, içerik grep'i şart.

## Yazma tetikleyicileri (sormadan yaz, kısaca bildir)

| Tetikleyici | Dosya |
|---|---|
| Yeni hesap / sunucu / domain / panel | `reference_<konu>` |
| Yeni müşteri / proje | `proje_<isim>` (+ aktifse `HANDOFF_<isim>`) |
| "Öyle değil, şöyle" / "bundan sonra X yapma" | `feedback_<konu>` |
| "Bunu şöyle yapalım" / "X'i bıraktık" | `not_kararlar` (tarihli satır) |
| "Kaydet / hatırla / unutma" | uygun dosya |
| "Bunu her seferinde anlatıyorum" | mutlaka kaydet + kısa özür |
| Kişisel bağlam | `kisisel_<konu>` |

**Yön ayrımı:** *yeni* bilgi → sessiz yaz + bildir. Mevcut bilgiyi *ezen* düzeltme → önce teyit,
sonra yaz. **Bildirim biçimi:** *"vault'a `feedback_x.md` olarak ekledim."* Detay verme.

**Kalite kapısı:** *"3 ay sonra bir görevde bunu arar mıyım?"* Hayırsa yazma. İsim / proje / karar /
tercih / erişim / ilişki = her zaman evet. Geçici akış-içi ara adım = hayır.

## 10.000 karakter sınırı ve sıkışma seviyeleri

Claude Code (≥ 2.1.88) bir hook'un çıktısı ~10.000 karakteri aşınca çıktıyı dosyaya kaydedip context'e
**2 KB önizleme** koyar. Yazarın index'i vault 354 nota ulaşınca 20.740 byte'a çıktı: davranış
kurallarının çoğu, **tüm proje adları**, tüm referanslar görünmez oldu. "Hatırlamıyor" değil,
**görmüyordu**. Kaynak: anthropics/claude-code#44086.

Çözüm: index kendini ölçer, `BUDGET=9500` byte'ı aşarsa kademeli sıkışır.

| Seviye | Ne olur |
|---|---|
| 0 | Her not ayrı satır; çekirdekte 56 karakter açıklama |
| 1 | `reference_` bölümü virgülle sarılır |
| 2 | Tüm bölümler sarılır; açıklama 40 karakter |
| 3 | Açıklama yok |
| 4 | `proje_` en yeni 25 + sayaç; `not_` en yeni 15 + sayaç; **uyarı basılır** |
| 5 | `proje_`/`not_` sadece sayaç |
| failsafe | Seviye 5 bile sığmazsa bütçede kontrollü kes + `[INDEX ZORLA KESİLDİ]` işareti |

`feedback_` adları **hiçbir seviyede** kırpılmaz. Çekirdek blok en başta durur: bir gün yine kesilse
bile 2 KB önizlemede o üç not hayatta kalır.

**Seviye ≥4 uyarısı görünce:** arşivleme zamanı. Kapanmış tarihli `not_` kayıtlarını ve 3+ aydır
dokunulmamış `proje_` notlarını `arsiv/`e taşı — ama `mtime` tek başına ölüm kanıtı değil; her adayın
`description`'ını oku, şemsiye / canlı / yeniden kullanılabilir olanı bırak. `arsiv/README.md`
manifestine ekle, `MEMORY.md`'de linkin yanına 📦 koy, `bash ~/.claude/hooks/vault-index.sh | wc -c`
ile ölç. Arşiv index dışıdır ama Grep bulur, wiki-link çalışır, `mv` ile geri gelir.

## Büyüme gerçeği (yazarın sayıları)

Nisan 20 · Mayıs 46 · Haziran 62 · Temmuz 86 · Ağustos 140 dosya dokunuldu. Vault 245 → 375 nota
büyüdü. Bu hızda index ayda bir bakım ister; yukarıdaki seviyeler ve arşiv katmanı bu yüzden var.
Konsolidasyon da gerekir: 12 davranışsal `feedback_` notu tek bir "5 kanonik kural" notuna indirildi,
eskiler `archive_superseded_by_5_kanonik/` altına taşındı.

## Sırlar

Vault kişisel; yine de parola/anahtar yazmak yerine "1Password'de X kaydında" yazmak daha iyidir.
Tek bir credential dosyası tutuyorsan onu git dışında tut ve `reference_` notlarından **işaret et**,
kopyalama. Hook'lardaki sır tarayıcı (`password = "..."` kalıbı) kod dosyaları içindir, vault için değil.

## Claude Code'un kendi hafıza dizini ne olacak

Kullanma. Her proje dizininde açılan `~/.claude/projects/<dizin>/memory/MEMORY.md` dosyasına
`templates/auto-memory-redirect.md` içeriğini koy: "kanonik hafıza burası değil, vault'a bak".
Anayasa da aynı şeyi söyler. Tek kaynak, tek doğru.
