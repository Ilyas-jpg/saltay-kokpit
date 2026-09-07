# 06 · Skill · Agent · MCP — ne değer, ne gürültü

## Tier sistemi — "varsa çağır" refleksinin yerine

Yazar üç kez "skill'leri kullanmıyorsun" diye şikâyet etti; dördüncüde dürüst soru geldi: *"skill'ler
gerçekten ne fark ediyor?"* Cevap tier sistemi oldu. Görev geldiğinde tek soru: **bu skill'in çıktısını
gerçekten kullanacak mıyım?**

| Tier | Ne | Karar |
|---|---|---|
| **1** | Tasarım/frontend kalibrasyonu · dosya deliverable (docx/xlsx/pptx/pdf) · sürüm-spesifik framework bilgisi (Next 15, Tailwind 4, Supabase, Claude API) · vault temizliği · dosya organizasyonu · çok adımlı plan | **ÇAĞIR + sebebi söyle** |
| **2** | code review · güvenlik denetimi · sistematik debug · TDD · SEO · DB şema | **kararı söyle** (durumla) |
| **3** | senior-X · clean-code · generic best-practice | **ATLA + sebebi söyle** ("içerik eğitimde var, ham yapıyorum") |

**Görünürlük şart.** Sessiz çağrı kullanıcının yatırımını gizler; sessiz atlama "skill'leri
kullanmıyorsun" şikâyetini doğurur. Karar her iki yönde de meşru, gizlisi değil.

## Signal vs noise — dürüst kalibrasyon

- **SIGNAL:** sürüm düzelticiler (eğitim kesme tarihini güncelleyen framework skill'leri) · tasarım
  kalibrasyonu (generic'e kaymayı frenler) · dosya deliverable tooling · MCP'ler · vault.
- **NOISE SHELF:** generic skill'ler (eğitimde zaten var) · agent'ların çoğu (solo işte "sticky-note'lu
  ben") · hook'lar capability değil, safety + hatırlatma · plugin'ler paketleme.
- **Tasarım çarpanı = model taste × net brief/referans × iterasyon.** Skill *tabanı* yükseltir (kötüye
  düşmeyi önler), *tavanı* değil. "Daha iyi tasarım" için yatırım skill'e değil, net brief + güçlü
  referans + 2-3 tur iterasyona.

## Global kurulum kuralı

Skill / agent / komut / hook / kural / feedback **her zaman** `~/.claude/` veya vault'a. Çalışma
dizininin `.claude/`'ına yazılan şey klasör değişince sessizce kaybolur. Hikâye: 16 tasarım skill'i
`00-Projeler/.claude/skills/`'e gömülmüştü, global sanılıyordu; başka klasörde açılan oturumlarda
"neden gelmedi bu skill" — kullanıcı bunu defalarca söylemişti ama hiç dosyalanmamıştı, her oturum
yeniden unutuldu. Dosyalandıktan sonra bitti.

`npx skills add <paket>` → `-g`. Kurduktan sonra doğrula: `test -d ~/.claude/skills/<isim>`.
İstisna: kullanıcı açıkça "bu projeye özel" derse ya da dosya gerçekten projeye özgüyse (`launch.json`).

## Subagent — neden varsayılan kapalı

Bir CMS işinde 6 paralel subagent (3 içerik tohumu + 3 panel ekranı) çalıştırıldı. Sonuç:
**1,4 milyon token ve 1 saat 15 dakika boyunca ekranda tek kelime yok.** Ajanlar işi **doğru**
yapmıştı; sorun kalite değil, **maliyet + sessizlik**. Paralel çağrı ana akışı bloke eder; kullanıcı
ilerleme göremez, "takıldı" sanır.

Kural: hacimli/mekanik iş bile olsa kendin yap, her 1-2 dosyada bir satır ilerleme göster. Görev çok
büyükse kapsamı söyle, parça parça teslim et. Kullanıcı açıkça "subagent kullan" derse kullan — ama
**süreyi önden söyle** ("2 ajan, ~10-15 dk, ekranda sayaç dönecek") ve kapsamı böl; paralel ajan
sayısı arttıkça süre en yavaşa eşitlenir.

Kardeş kural — **bekleme/background yasak:** komut içine `sleep` koyma, `&` ile başlatıp aynı
komutta bekleme, "notification bekliyorum" deme. Uzun işi kısa senkron adımlara böl; zaman zaten
tool çağrıları arasında geçer. `settings.json`'daki `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` bunu
harness düzeyinde kapatır.

## MCP — yapılandırılmış ≠ çalışıyor

Check-up günü: 19 MCP yapılandırılmış görünüyordu, **10'u çalışıyordu**. 5'i hiç çalışmamıştı çünkü
şablon kopyala-yapıştır kalıntısıydı — `token=YOUR_TOKEN`, `/path/to/allowed/files`,
`mysql://user:password@localhost/dbname`. Her oturum başında 5 kez spawn + fail üretiyorlardı. 4'ü
`"url"` vardı ama `"type"` alanı olmadığı için hiç yüklenmiyordu. GitHub MCP'nin tokeni literal
`<YOUR_TOKEN>` idi; aylardır `gh` CLI iş gördüğü için kimse fark etmemişti.

Denetim: `claude mcp list` → her satırın gerçekten bağlandığını gör. Placeholder kalıbı grep'le:
`grep -nE 'YOUR_|/path/to|user:password|<[A-Z_]+>' ~/.claude.json`. Çalışmayanı kaldır; silme değil
`.disabled-<tarih>` ile yana al.

## Curate protokolü (agent / skill / plugin ayıklama)

44 agent → 21 → 20; 33 plugin → 14 aktif. Yöntem her seferinde aynı:
1. Stack kanıtı: bu makinede gerçekten hangi dillerle/servislerle iş yapılıyor? (vault'taki proje
   notları söyler). Kanıtı olmayan agent gider.
2. Silme değil taşıma: `~/.claude/.curation-trash-<tarih>/` + `RESTORE.md`.
3. Bir ay sonra hiçbir şey geri istenmediyse boşalt.
4. Sayıları CLAUDE.md'ye yazma; komutla say.
