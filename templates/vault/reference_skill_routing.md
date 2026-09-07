---
name: Skill routing — tier bazlı karar rehberi
description: Görev geldiğinde hangi skill ÇAĞIR / DUR DÜŞÜN / ATLA. Defansif "varsa çağır" değil, değer bazlı. Karar her zaman kullanıcıya görünür.
type: reference
priority: critical
---

# Skill Routing — Tier Rehberi

> Görev geldiğinde ilk soru: *"Bu skill'in çıktısını gerçekten kullanacak mıyım?"*
> **Evet, spesifik bilgi gerek** → Tier 1, ÇAĞIR. **Belki** → Tier 2, kararını söyle.
> **Hayır, eğitimde zaten var** → Tier 3, ATLA + sebebini söyle.
> Her iki yön de meşru. **Sessiz çağrı veya sessiz atlama yasak.**

## TIER 1 — HEMEN ÇAĞIR (skill spesifik değer üretiyor)

| Görev | Skill türü | Neden |
|---|---|---|
| Frontend tasarım, sayfa, component | tasarım/frontend-design skill'i | Modelin varsayılan "AI estetiği"ne kaymasını frenler |
| Word / Excel / PowerPoint / PDF üretimi | docx / xlsx / pptx / pdf skill'leri | Gerçek tooling, elle yapılamaz |
| Sürüm-spesifik framework bilgisi | nextjs / tailwind / supabase / claude-api | Eğitim kesme tarihini günceller (v4, v15 vb.) |
| Vault temizliği / konsolidasyon | memory konsolidasyon skill'i | Sistemli işlem, elle dağınık olur |
| Bilgisayar dosya organizasyonu | file-organizer | Sistemli |
| Çok adımlı kod planı | writing-plans | Plan disiplini |

**Kural:** Bu kategorilerde skill atlamak = kalite düşüşü. Kullanıcı bu skill'leri kurduysa yatırımına saygı.

## TIER 2 — DUR DÜŞÜN (durumla)

| Görev | Skill | Çağırma kriteri |
|---|---|---|
| Kod review | code-reviewer | İnsan-gözü son okuma istiyorsan; spot-check ham yeter |
| Güvenlik denetimi | security / pentest skill'leri | Sistematik checklist gerekiyorsa |
| Karmaşık debug | systematic-debugging | Çok katmanlı bug ise |
| Test yazımı | test-driven-development | TDD disiplini kuruyorsan |
| SEO | seo-audit | SEO odaklı görevse |
| DB şeması | database-design | Yeni şema kuruyorsan |

## TIER 3 — ATLA (söyle, sessiz olma)

Generic "senior-X" / "clean-code" / "best-practices" skill'leri. İçerik eğitim verisinde zaten var;
çağırmak = context'i boş yükle doldurmak.

**Atlama formülü (söylenmesi gerek):**
> *"Skill check: bu görev için tabloda eşleşme var (`senior-backend`) ama içerik generic. Atlıyorum, ham yapıyorum."*

## Signal vs Noise — dürüst kalibrasyon

- **SIGNAL:** sürüm düzelticiler (framework skill'leri) · tasarım kalibrasyonu · dosya deliverable skill'leri · MCP'ler · vault.
- **NOISE SHELF (dursun, medet umma):** generic skill'ler · çoğu agent (solo işte "sticky-note'lu ben") · hook'lar capability değil, safety + hatırlatma.
- **Tasarım çarpanı = model taste × kullanıcının net brief'i/referansı × iterasyon.** Skill *tabanı* yükseltir (kötüye düşmeyi önler), *tavanı* değil. Daha iyi tasarım için yatırım skill'e değil, net brief + güçlü referans + 2-3 tur iterasyona.

## Anti-pattern

❌ "Tabloda var, çağırırım" (ne eklediğini sormadan) · ❌ sessiz çağrı · ❌ sessiz atlama ·
❌ Tier 3 skill'i çağırıp çıktının %5'ini kullanmak · ❌ Tier 1 skill'i atlayıp ham yazmak.

✅ Tier 1: ÇAĞIR + sebebi · ✅ Tier 2: KARARI söyle · ✅ Tier 3: ATLA + sebebi.

## Kurulum kuralı

Skill / agent / komut / hook / kural **her zaman global**a kurulur (`~/.claude/…` veya vault). Çalışma
dizininin `.claude/`'ına yazılan şey klasör değişince sessizce kaybolur. `npx skills add` → `-g` bayrağı.
İstisna: kullanıcı açıkça "bu projeye özel" derse veya dosya gerçekten o projeye özgüyse (`launch.json`).
