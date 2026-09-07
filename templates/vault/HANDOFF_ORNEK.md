---
name: HANDOFF_<proje> — oturumlar arası devir notu
description: "<Proje> için yeni oturum BURADAN başlar: durum, runbook, deploy, bir daha yapılmayacaklar. Uzun/aktif projelerde proje_ notunun operasyonel ikizi."
type: project
priority: normal
---

# HANDOFF — <Proje> (YYYY-MM-DD)

## Durum: 🟢 CANLI / 🟡 GELİŞTİRMEDE / ⚫ KAPANDI — <tek satır>

<Şu an ne çalışıyor, ne çalışmıyor. Son doğrulanmış sürüm/bundle/commit. Kimin onayı alındı.>

## Runbook (operasyon anı)

- **Sağlık kontrolü:** `curl -s -o /dev/null -w "%{http_code}\n" https://…`
- **Log:** <nerede, nasıl okunur>
- **Yük artarsa / kriz anında:** <tek komutluk düğmeler>

## Deploy (⚠️ önemli — burada yazmayan yoldan deploy etme)

- **Frontend:** `<komut>`
- **Backend:** `<komut>`
- **Yedek:** <deploy öncesi ne yedeklenir, nereye>
- **Rollback:** <geri dönüş yolu — tek komut olmalı>

## Bir daha YAPILMAYACAKLAR (bu projede yaşanan)

- <hata> → <kural> ([[feedback_...]] varsa linkle)

## Açık işler (öncelik sırasıyla)

1.
2.

## İlgili

[[proje_<proje>]] · [[reference_...]] · [[not_kararlar]]
