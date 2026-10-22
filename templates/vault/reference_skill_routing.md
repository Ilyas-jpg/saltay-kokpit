---
name: Skill routing — ne zaman çağrılır, ne zaman çağrılmaz
description: K4'ün tablosu. Skill varsayılan değil; yalnız bende olmayan, işe ya da sürüme özgü bilgi veriyorsa çağrılır. Genel öğüt skill'leri çağrılmaz; skill öğüdü vault kuralıyla çelişirse vault kazanır.
type: reference
priority: critical
---

# Skill Routing

> **Tek soru:** *bu skill bende olmayan, işe ya da sürüme özgü bir bilgi veriyor mu?*
> Evet → çağır, tek cümleyle söyle. Hayır → çağırma, anlatma.
>
> **v1.1 değişikliği:** v1.0'daki "Tier 1 tasarım skill'ini çağır, her görevde kararı söyle" kuralı
> kaldırıldı. İki sebep: (1) eski modeller için yazılmış skill'ler kuralcıdır ve güçlü modeli dar bir
> kalıba çeker; bir tasarım skill'inin öğütlerinin yarısı yazarın vault'unda yasak olan "yapay zekâ
> izleri"ydi; (2) "skill kontrolü: atlıyorum çünkü…" paragrafı her cevaba gürültü ekliyordu.

## Çağır (spesifik bilgi taşıyor)

| İş | Skill türü | Neden |
|---|---|---|
| Word / Excel / PowerPoint / PDF üretimi ve düzenleme | docx / xlsx / pptx / pdf | Gerçek araç zinciri; elle yapılmaz |
| Sürüme özgü API ya da framework | claude-api, nextjs, tailwind v4, supabase … | Eğitim kesme tarihini günceller |
| Kendi yazdığın hat ya da süreç | video hattı, belge üretimi, deploy runbook'u | Süreçtir, öğüt değil; makineye özgü yol ve tuzak taşır |
| Eklenti / hook / plugin yazımı | ilgili resmî skill | Sözleşme sürüme bağlı |
| Sistemli dosya organizasyonu | file-organizer | Tek seferde yüzlerce dosya |

## Çağırma (genel öğüt; eğitimde var, vault'ta daha güncelini tutuyorsun)

| İş | Neden |
|---|---|
| Tasarım zevki, "premium UI", estetik kılavuzları | Önce vault'taki tasarım kuralları + gerçek referans + render-gör-düzelt; skill ancak somut bir boşluk varsa |
| senior-X, clean-code, best-practice, kod review, debug, TDD, plan ritüelleri | Güçlü model bunları varsayılan yapıyor; skill bağlamı boş yükle doldurur |
| Kurumsal "bundle" paketleri (sales, legal, finance …) | İşinle ilgisi yoksa kapat: her oturuma açıklama yükler |

## Kurallar

- Yüklenmiş bir skill'in öğüdü vault kuralıyla çelişirse vault kazanır; skill'in o kısmı uygulanmaz.
- Bir skill çıktıyı kötüleştiriyorsa kullanıcıya söyle ve adını bu dosyaya yaz.
- Birden fazla skill'i yalnız her biri ayrı bir bilgi katmanı ekliyorsa birleştir.

## Signal vs noise — dürüst kalibrasyon

- **Signal:** sürüm düzelticiler · dosya üretim araç zinciri · kendi süreç skill'lerin · MCP'ler · vault.
- **Noise:** generic skill'ler · solo işte çoğu agent · hook'lar (yetenek değil, güvenlik + hatırlatma) ·
  plugin'ler (paketleme; değeri içindeki MCP ya da skill).
- **Kalite çarpanı = model × net brief / güçlü referans × iterasyon.** Daha iyi çıktı için yatırım skill'e
  değil, brief'e, referansa ve 2-3 tur iterasyona.

## Kurulum kuralı

Skill / agent / komut / hook / kural **her zaman global**e kurulur (`~/.claude/…` veya vault). Çalışma
dizininin `.claude/`'ına yazılan şey klasör değişince sessizce kaybolur. `npx skills add` → `-g`;
kurduktan sonra `test -d ~/.claude/skills/<ad>`. İstisna: dosya gerçekten o projeye özgüyse (`launch.json`).
