# Vault — sen + Claude'un ortak hafızası

Bu klasör hem bir **Obsidian vault**'u hem de Claude'un her oturumda okuyup yazdığı **kalıcı bilgi havuzu**.
Claude Code varsayılan olarak her oturumu sıfırdan başlatır; bu vault o sıfırlamanın panzehridir.

- Sen her seferinde "ben kimim, hangi sunucu, hangi tercih" anlatmazsın.
- Claude geçmiş kararları, düzeltmeleri, hesap bilgilerini hatırlar.
- Hangi klasörde oturum açılırsa açılsın vault aktif — index'i `SessionStart` hook'u getirir.

## Klasör yapısı (düz — Obsidian linkleri klasörden önemli)

```
MEMORY.md                  → Zengin index. Obsidian'da okunur; her nota bir satır.
README.md                  → Burası.
kullanici_profil.md        → Sen kimsin, nasıl çalışmak istersin (canlı belge, sürekli büyür)
kisisel_<konu>.md          → Kişisel bağlam (aile, çevre, sağlık, planlar) — istersen
feedback_<konu>.md         → Düzeltme/tercih: Kural + Why + How to apply (BAĞLAYICI)
reference_<konu>.md        → Sunucu, hesap, panel, standart, marka
proje_<isim>.md            → Her projenin bağlamı, kararları, durumu
HANDOFF_<isim>.md          → Oturumlar arası devir notu (runbook, deploy, "bir daha yapma")
not_<konu>.md              → Karar günlüğü, olay kaydı, denetim, öğrenme
arsiv/                     → Bayat notlar (index dışı; Grep bulur; geri alınabilir)
```

Prefix'ler rastgele değil: hook, adları prefix'e göre bölümlere ayırır ve `feedback_` adlarını
**hiçbir sıkışma seviyesinde kırpmaz** — çünkü onlar davranış kuralı.

## Yazma kuralları (Claude için)

Her dosyada YAML frontmatter zorunlu:

```yaml
---
name: Kısa başlık
description: Tek satır — gelecek oturumda "bu not ne işe yarar" sorusuna cevap (index'te görünür)
type: user | feedback | project | reference | note | personal
---
```

Wiki-link kullan: `[[diger-not]]`. Kaynağı ve tarihi yaz. Kullanıcının kendi cümlesini alıntıla — bir
kuralın "neden"i çoğu zaman o cümledir.

## Yazılmaz

- Geçici görev detayı (oturum içi todo yeter)
- Kod konvansiyonu (kod zaten okunabilir)
- Git geçmişi (git log var)
- Tek seferlik token, oturum-içi kısa ömürlü sır

**Kalite kapısı:** yazmadan önce bir saniyelik test — *"3 ay sonra bir görevde bunu arar mıyım?"*
Hayırsa yazma. İsim / proje / karar / tercih / erişim / ilişki = her zaman evet.

## Obsidian'da açmak

Obsidian → *Open folder as vault* → bu klasör. Özel ayar gerekmez; `.obsidian/` kendiliğinden oluşur.
