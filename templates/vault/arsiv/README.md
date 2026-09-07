# arsiv/ — Bayat Not Arşivi

Vault index'i (`SessionStart` hook) **yalnız vault kökünü** listeler. Buradaki notlar index'te görünmez
ama **Grep aramaları bulmaya devam eder** ve Obsidian wiki-linkleri (`[[ad]]`) çalışır.
**Silme yok** — sadece geri-dönülebilir taşıma.

**Ne zaman buraya taşınır:** index sıkışma uyarısı seviye ≥4 gösterdiğinde; kapanmış olay/bakım notları
ve 3+ aydır dokunulmamış projeler.

**Taşıma protokolü:**
1. Adayları seç (kapanmış tarihli `not_` + uyuyan `proje_`). `mtime` tek başına ölüm kanıtı değil —
   her adayın `description`'ını oku; şemsiye / canlı / yeniden kullanılabilir olanı taşıma.
2. `mv <dosya>.md arsiv/` + aşağıdaki manifeste bölüm ekle + `MEMORY.md`'de linkin yanına 📦 koy.
3. `bash ~/.claude/hooks/vault-index.sh | wc -c` ölç — bütçe altına döndüğünü gör.

**Geri yükleme (tek dosya):**
```
mv <vault>/arsiv/<dosya>.md <vault>/
```

---

## Manifest

### YYYY-MM-DD — <sebep> (<N> dosya)
- <dosya>.md (<neden arşivlendi>)
