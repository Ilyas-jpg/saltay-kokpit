---
name: reference_<konu> — <sunucu / hesap / panel / standart>
description: <Ne için bakılır: "SSH alias'ları", "hosting paneli + API", "marka renkleri", "belge kodu standardı">
type: reference
last_updated: YYYY-MM-DD
---

# <Konu>

> Referans notu = **"nereye bakılır, nasıl erişilir, hangi kural geçerli"**. Anlatı değil, tablo.

## Erişim

| Şey | Değer / yol | Not |
|---|---|---|
| Panel | https://… | |
| SSH | `ssh <alias>` (`~/.ssh/config`) | |
| API | | token → credentials notunda |

## Sırlar nerede

Sırlar bu dosyada **değil**. Vault'ta tek bir `reference_credentials.md` tutmak istiyorsan onu
**git dışında** tut, bir parola yöneticisi kullanmak daha iyi. Claude'a "şifre şu" demek yerine
"şifre 1Password'de X kaydında" yazmak da çalışır.

## Tuzaklar (bu sistemle ilgili bilinen)

- <örn. "LiteSpeed cache — CSS değişince ?v=N ile sürümle">
- <örn. "panel API'si filtre parametresini desteklemiyor, toplu silme riski">

## İlgili

[[kullanici_profil]] · [[proje_...]]
