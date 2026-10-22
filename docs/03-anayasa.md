# 03 · Anayasa — `~/.claude/CLAUDE.md`

## Görevi

Tek bir global dosya: `~/.claude/CLAUDE.md`. Her oturumda, her klasörde yüklenir. **Davranış
çekirdeğini** taşır; bilgi taşımaz (bilgi vault'ta). Bu ayrım korunmazsa dosya şişer, bayatlar ve
kurallarla hesap bilgileri birbirine karışır.

Model adını dosyaya sabitleme: yazar bir ay boyunca eski model adı yazan bir satırla yaşadı, hiçbir
işe yaramadı. Oturumda hangisi çalışıyorsa o.

## Belge değil, yükleme politikası (v1.1)

Yazarın kendi anayasası 24 KB'a, 276 satıra ulaşmıştı. Yeni model nesli geldiğinde ölçüldü: oturum
başında, kullanıcı tek kelime yazmadan tahminen 55-65 bin token yükleniyordu. Anayasanın yarısı envanter
(kaç skill, hangi MCP), tarihçe ve hikâyeydi. Her prompt'a eklenen 1,7 KB hatırlatma aynı kuralların
**dördüncü kopyasıydı**: anayasada, vault notunda, hatırlatmada ve Claude Code'un kendi sistem
promptunda (otonom çalışma ve işi teslim etme blokları zaten orada).

Anthropic'in yeni modeller için rehberi de aynı yöne işaret ediyordu: yetenek arttıkça hangi talimatın,
aracın ve korkuluğun hâlâ gerektiğini yeniden değerlendir; çoğu davranış her birini tek tek saymadan
kısa bir talimatla yönlendirilir; araç ve skill çağırmayı zorlayan sert dil artık aşırı tetiklenme
üretir; eski modeller için yazılmış skill'ler fazla kuralcı kalabilir.

Uygulanan:

| Ne | Nereye |
|---|---|
| Envanter, sayılar, oturum başı yük ölçümü | vault `reference_kurulum_envanteri` |
| Revizyon tarihçesi | vault `not_claude_md_revizyon_gecmisi` (anayasada yalnız son satır) |
| K0-K5'in uzun hali, kanıtlar | vault `feedback_5_kanonik_davranis_kurali` (anayasada kural başına tek satır) |
| Doğrulama araçları | vault `reference_dogrulama_yuzeyi` (altı ayrı kuralın tek tablosu) |
| Kod güvenliği listesi | [07-guvenlik-ve-yayin](07-guvenlik-ve-yayin.md); anayasada üç satır |
| İki uzun hatırlatma (1,7 KB / prompt) | tek kısa hatırlatma (~500 B) |
| Self-test bloğu, "skill kararını her görevde söyle" | kaldırıldı (ritüel) |

Yazarın dosyası 24,4 KB'tan 10,9 KB'a indi; sonraki üç haftada olaylarla gelen eklerle 13,6 KB'a
çıktı. Dosya kendiliğinden yeniden büyür; ölçüm bu yüzden tekrarlanır. Bu depodaki şablon ~11 KB. Kalan
her satır şu testi geçmeli: *her oturumda, her klasörde geçerli mi ve model bunu kendiliğinden yapmıyor mu?*

## Bölümler ve neden orada oldukları

| Bölüm | Neden var |
|---|---|
| 🧠 **Hafıza Protokolü** (en başta) | Index'in koşulsuz geldiğini, okuma/yazma kurallarını ve sıkışma uyarısını söyler. En üstte, çünkü en çok ihlal edilen kural "vault'a bakmadan cevap vermek". |
| 🎯 **Felsefe** | "Prototip değil ürün", "yükle = çalışır teslim et". Tasarım kurallarını ayrı bir vault notuna işaret eder. |
| 🚨 **Davranış çekirdeği (K0-K5)** | Tekrarlanan düzeltmelerin damıtılmış hali; kural başına tek satır, uzun hali vault'ta. |
| 🚦 **Otonom sınırlar** | Yeşil / sarı / kırmızı. "Sorma" ile "dur" arasındaki çizgi. |
| 🔒 **Güvenlik** | Üç satır: modelin zaten bildiğini tekrarlamaz, pazarlık konusu olmayanı yazar. |
| 🧰 **Kurulum ilkeleri** | Global kurulum, iki kabuk, metin taşıma tuzakları, "yok" demeden önce ara. |
| ⚠️ **Anti-pattern** | Yaşanmış hataların yasak listesi; her satırın bir hikâyesi var ([10-dersler](10-dersler.md)). |
| 🔁 **Oturum sonu** | Todo, vault, son rapor, yedek yolları. |

## 5 kanonik kural — kısa

- **K0 — Brief'in son paragrafı ve oturum içi yasaklar.** Brief'in sonu en kritik kuraldır ("onay
  sorma, devam et" tipi). Oturum içinde verilen "X kullanma" yasakları oturum boyunca geçerli; vault'a
  yazılmaz. (v1.0'da "son 5 mesajı tara" idi; özü aynı, ritüeli kalktı.)
- **K1 — Literal yorum.** "Sıfırdan" = %100. "Denesene" = sadece test. "Kullanma" = yasak. Belirsizse
  tek satır teyit, sonra literal.
- **K2 — Otonom devam.** İzin sorma ("çalıştırayım mı?", "devam edeyim mi?"). Gerçek tercih (A/B/C) ve
  kırmızı risk sorulabilir. Eksik bilgiyi önce kendin avla. v1.1 eki: yetki verilmiş işte tekrar eden
  güvenlik uyarısı ve faz sonu rapor töreni yok; yapabildiğin operasyonel işi kullanıcıya atma.
- **K3 — Riski sıkı değerlendir.** Silme/deploy/cihaz öncesi vault grep + kullanıcı yolunu simüle et.
  v1.1 eki: tarayıcı otomasyonunda `onThisComputer` alanına bak; `isLocal` yalnız işletim sistemi
  eşleşmesidir ([10-dersler](10-dersler.md) #27).
- **K4 — Skill varsayılan değil (v1.1).** Yalnız sende olmayan, işe ya da sürüme özgü bilgi veriyorsa
  çağır; genel öğüt veren skill'i çağırma; skill öğüdü vault kuralıyla çelişirse vault kazanır.
  v1.0'daki "Tier 1 çağır, her görevde kararı söyle" hali iki olayla değişti (#22, #24).
- **K5 — Scope dar.** Fiil + nesne. "Daha iyi olur" ile genişletme yok. v1.1 eki: yan konuları iş
  kalemi gibi anlatma; sessizce ölç, sonda 2-3 satırla raporla.

Neden bu beşi? Yazarın vault'undaki ilk 33 feedback'in 12'si davranışsaldı ve hepsi bu beşten birine
indirgeniyordu. Beşi ezberlemek on ikiyi hatırlamaktan kolay; hata olunca "hangisi tetiklenmedi?"
sorusu teşhisi hızlandırır. Her kuralın vault'taki uzun halinin sonunda **kanıt satırları** vardır:
tarih + olay + kullanıcının cümlesi. Kendi kanıtlarını eklemeden kural senin olmaz.

## Trafik ışığı

| | Örnek | Davranış |
|---|---|---|
| 🟢 Yeşil | dosya düzenleme (hook yedek alıyor), salt-okuma komut, vault yazma, smoke test, geri-dönülebilir taşıma, **kendi varlıklarında doğrulanmış deploy** | sor durma, yap |
| 🟡 Sarı | prod refactor (yedek önce), DB şema, DNS kaydı, process kill, global config | yap, özet raporda belirt |
| 🔴 Kırmızı | para, geri alınamaz silme, ToS, üçüncü kişiye mesaj, **müşterinin canlı sitesi**, sosyal medya, repoyu public yapmak, domain, iş durumunu değiştiren anahtarlar (satış, fiyat, ödeme) | dur, sor |

"Tam yetki sende" denmesi kırmızıyı kaldırmaz. Şüphede sarıyı kırmızı say. v1.1'de iki çizgi netleşti:
kendi alan adında, demo sitende biten işi canlıya almak yeşildir (lokal doğrulama + sunucuda yedek +
cache-buster + canlıda HTTP 200 ile); bir müşterinin gerçek alan adı ise her zaman kırmızıdır.

Yeşil listedeki "hook yedek alıyor" varsayımının bir gün sessizce kırık olduğu görüldü
([10-dersler](10-dersler.md) #3): yeşil izinlerin dayandığı mekanizmayı ara sıra fiilen test et.

## Anayasa nasıl bakılır

1. Düzenlemeden önce yedek: `.backups/CLAUDE.md.<tarih>_<sebep>.bak`.
2. Dosyanın sonundaki *"Son revize"* satırını güncelle; eski satırı vault'taki
   `not_claude_md_revizyon_gecmisi` notuna taşı. Dosyada tek satır kalır.
3. Davranış çekirdeğine (hafıza · K0-K5 · trafik ışığı · güvenlik) **olay olmadan dokunma**. Bir olay
   olduysa önce vault'a `feedback_` notu; anayasaya ancak her oturumda geçerli olması gerekiyorsa tek
   satır. Kural yalnız vault'ta duruyorsa o not açılmadıkça işlemez ([10-dersler](10-dersler.md) #26).
4. Sayı yazma; komutla say (`reference_kurulum_envanteri`).
5. Boyut: ≤ 12 KB hedef. `vault-health.sh` 15 KB'ı geçince uyarır.
6. Her yeni model neslinde yeniden ölç: hangi satırı model artık kendiliğinden yapıyor, hangi sert
   ifade aşırı tetiklenme üretiyor? Onları çıkar.

## Global vs proje-local

- Anayasa **tek ve global**. Projelerde ayrı `CLAUDE.md` tutma; projeye özgü şey `README.md`'ye ya da
  vault `proje_` notuna gider.
- Bir projede yine de `CLAUDE.md` üretildiyse **repoya girmez** (`templates/project/.gitignore`).
- Proje-local `.claude/` içinde meşru olan tek şey: `launch.json` (dev sunucu kaydı) ve
  `settings.local.json` (o projenin izinleri). Skill/agent/komut/hook oraya konmaz: klasör değişince
  kaybolur ([10-dersler](10-dersler.md) #11).

## Mevcut bir CLAUDE.md'n varsa

`install.sh` dosyana dokunmaz; yanına `CLAUDE.saltay.md` yazar. Önce **Hafıza Protokolü** bölümünü
al (sistemin çalışması için tek zorunlu parça), sonra K0-K5 + trafik ışığı, sonra gerisi.

v1.0 ile kurduysan aynı şey olur: yeni şablon `CLAUDE.saltay.md`'ye yazılır, seninki kalır. Farklar
[CHANGELOG](../CHANGELOG.md)'da; en büyükleri K4, subagent satırı, güvenlik bölümünün üç satıra inmesi
ve self-test bloğunun kalkması.
