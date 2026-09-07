---
name: Önemli kararlar günlüğü
description: İş / proje / altyapı ile ilgili verilen önemli kararlar, kronolojik — "bunu neden böyle yapmıştık?" sorusunun cevabı
type: note
---

# Önemli kararlar — kronolojik

Yeni karar geldiğinde **en üste**, tarihiyle ekle. Format: ne kararlaştırıldı · neden · kapsam dışı
bırakılanlar · etki. Kullanıcının kendi cümlesini alıntıla — gelecekte "kim istemişti?" sorusunu bitirir.

---

## YYYY-MM-DD — <Karar başlığı>

<Kullanıcı ne dedi — alıntı.>

**Karar:** <ne yapıldı / ne bırakıldı>
**Sebep:** <gerekçe>
**Kapsam dışı:** <bilinçli olarak yapılmayanlar — sonra "neden yok?" sorusunu keser>
**Etki / aksiyon:** <ne değişti, kim ne yapacak>

Detay: [[proje_...]]

---

## {{INSTALL_DATE}} — saltay-kokpit kuruldu

Vault + anayasa + hook'lar tek kaynağa bağlandı. Kalıcı bilgi yalnız vault'a yazılır; Claude Code'un
çalışma dizinine bağlı otomatik hafıza dizini kullanılmaz (klasör değişince kaybolur).
Detay: `~/.claude/CLAUDE.md` → Hafıza Protokolü.
