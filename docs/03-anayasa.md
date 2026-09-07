# 03 · Anayasa — `~/.claude/CLAUDE.md`

## Görevi

Tek bir global dosya: `~/.claude/CLAUDE.md`. Her oturumda, her klasörde yüklenir. **Davranış
çekirdeğini** taşır; bilgi taşımaz (bilgi vault'ta). Bu ayrım korunmazsa dosya şişer, bayatlar ve
kurallarla hesap bilgileri birbirine karışır.

Bakım ilkesi dosyanın başında yazar: *sayılar ve araç bilgisi bayatlar (kaç skill, hangi MCP, hangi
model); davranış kuralları değişmez çekirdektir.* Model adını dosyaya sabitleme — yazar bir ay boyunca
eski model adı yazan bir satırla yaşadı, hiçbir işe yaramadı.

## Bölümler ve neden orada oldukları

| Bölüm | Neden var |
|---|---|
| 🧠 **Hafıza Protokolü** (en başta) | Index'in koşulsuz geldiğini, okuma/yazma kurallarını ve 10K uyarısını söyler. En üstte çünkü en çok ihlal edilen kural "vault'a bakmadan cevap vermek". |
| 🎯 **Felsefe / kalite çıtası** | "Prototip değil ürün", "generic AI çıktısı yasak", "yükle = çalışır teslim et". Tasarım kurallarını ayrı bir vault notuna (`reference_tasarim_anayasasi`) işaret ederek dosyayı şişirmez. |
| 🚨 **5 Kanonik Davranış Kuralı** | Tekrarlanan düzeltmelerin damıtılmış hali; aşağıda. |
| 🚦 **Otonom Çalışma Sınırları** | Yeşil / sarı / kırmızı. "Sorma" ile "dur" arasındaki çizgi. |
| 🎯 **Skill Kullanım Refleksi** | Tier 1 çağır, Tier 3 atla, kararı söyle. |
| 🔒 **Güvenlik** | Üretilen kod için tartışmasız asgari. |
| 🧰 **Ortam** | Klasör düzeni, global kurulum kuralı, OS/shell tuzakları, sayım komutları. |
| 🔁 **Konuşma Sonu Refleksi** | Todo finalize, vault yaz, sabah özeti, yedek yolları. |
| ⚠️ **Anti-pattern** | Yaşanmış hataların yasak listesi — her satırın bir hikâyesi var. |

## 5 Kanonik Kural — kısa

- **K0 — Son 5 mesajı tara.** Oturum-içi yasaklar ("X kullanma") ve brief'in son paragrafındaki
  kritik kural ("onay sorma, devam et") kaybolmasın. Brief'in sonu = en kritik kural.
- **K1 — Literal yorum.** "Sıfırdan" = %100. "Denesene" = sadece test. "Kullanma" = yasak. Belirsizse
  tek satır teyit, sonra literal.
- **K2 — Otonom devam.** İzin sorma yasak ("çalıştırayım mı?", "devam edeyim mi?"). Gerçek tercih
  (A/B/C) ve kırmızı risk sorulabilir. Ayrım: *judgment* → sor, *permission* → sorma. Eksik bilgiyi
  önce kendin avla.
- **K3 — Riski sıkı değerlendir.** Silme/deploy/cihaz öncesi vault grep + kullanıcı yolunu simüle et.
  "Düşük risk" cümlesini kurmadan dur.
- **K4 — Skill görünür.** Sessiz çağrı/atlama yasak.
- **K5 — Scope dar.** Fiil + nesne. "Daha iyi olur" ile genişletme yok.

Neden bu beşi? Yazarın vault'undaki 33 feedback'in 12'si davranışsaldı ve hepsi bu beşten birine
indirgeniyordu. Beşi ezberlemek 12'yi hatırlamaktan kolay; hata olunca "hangisi tetiklenmedi?" sorusu
teşhisi hızlandırır. Her kuralın vault'taki uzun halinde **kanıt satırları** vardır: tarih + olay +
kullanıcının cümlesi. Kendi kanıtlarını eklemeden kural senin olmaz.

## Trafik ışığı

| | Örnek | Davranış |
|---|---|---|
| 🟢 Yeşil | dosya düzenleme (hook yedek alıyor), salt-okuma komut, vault yazma, smoke test, geri-dönülebilir taşıma | sor durma, yap |
| 🟡 Sarı | prod refactor (yedek-önce), DB şema, DNS kaydı, process kill, global config | yap, özet raporda belirt |
| 🔴 Kırmızı | para, geri alınamaz silme, ToS, üçüncü kişiye mesaj, public yayın, domain transfer | dur, sor |

"Tam yetki sende" denmesi kırmızıyı kaldırmaz. Şüphede sarıyı kırmızı say. Yeşil listedeki "hook yedek
alıyor" varsayımının bir gün sessizce kırık olduğu görüldü ([10-dersler](10-dersler.md) #3) — yeşil
izinlerin dayandığı mekanizmayı ara sıra fiilen test et.

## Anayasa nasıl bakılır

1. Düzenlemeden önce yedek: `.backups/CLAUDE.md.<tarih>_<sebep>.bak`.
2. Dosyanın sonundaki *"Son revize"* satırını güncelle; bir önceki satırı altına kaydır (değişiklik
   günlüğü dosyanın içinde yaşar).
3. Davranış çekirdeğine (hafıza · 5 kural · trafik ışığı · güvenlik) **olay olmadan dokunma**. Bir
   olay olduysa önce vault'a `feedback_` notu, sonra anayasaya tek satır.
4. Sayı yazma; komutla say (`ls ~/.claude/skills | wc -l`).
5. Boyut: 12–25 KB makul. Her oturumda yüklendiğini unutma.

## Global vs proje-local

- Anayasa **tek ve global**. Projelerde ayrı `CLAUDE.md` tutma; projeye özgü şey `README.md`'ye ya da
  vault `proje_` notuna gider.
- Bir projede yine de `CLAUDE.md` üretildiyse **repoya girmez** (`templates/project/.gitignore`).
- Proje-local `.claude/` içinde meşru olan tek şey: `launch.json` (dev sunucu kaydı) ve
  `settings.local.json` (o projenin izinleri). Skill/agent/komut/hook oraya konmaz — klasör değişince
  kaybolur ([10-dersler](10-dersler.md) #11).

## Mevcut bir CLAUDE.md'n varsa

`install.sh` dosyana dokunmaz; yanına `CLAUDE.saltay.md` yazar. Önce **Hafıza Protokolü** bölümünü
al (sistemin çalışması için tek zorunlu parça), sonra 5 kural + trafik ışığı, sonra gerisi.
