# 10 · Dersler — gerçek olaylardan çıkan kurallar

Bu depodaki her kural bir olaydan doğdu. Aşağıdaki liste, yazarın altı aylık kayıt defterinin
kişisel/müşteri verisi ayıklanmış özeti. Her madde: **olay → maliyet → kural**. Kendi listeni
`feedback_` notlarında tut; on maddeyi geçince konsolide et.

---

**1. Koşullu hafıza talimatı.** `CLAUDE.md`'de *"görev geçmişle ilgiliyse vault'tan başla"* yazıyordu.
Üç ay boyunca "bazen hafızası yokmuş gibi" davrandı. Ölçüldü: veri kaybı yok, **yükleme mekanizması
yok** — tek erişim yolu modelin o anki yargısına bırakılmış koşuldu.
→ *Hafıza koşulsuz yüklenir (`SessionStart` hook). "İlgili mi?" sorusu yasak.*

**2. 10.000 karakter sınırı.** Vault 354 nota büyüyünce index 20.740 byte oldu; Claude Code çıktıyı
dosyaya kaydedip 2 KB önizleme gösterdi. Index'in %85'i — tüm proje adları dahil — her oturumda
görünmezdi. "Hatırlamıyor" değil, **görmüyordu**.
→ *Index kendini ölçer, kademeli sıkışır, asla sınıra ulaşmaz. Seviye ≥4 uyarısı = arşivle.*

**3. Hook tetikleniyor ≠ hook çalışıyor.** `$CLAUDE_TOOL_FILE_PATH` bir sürümde boş gelmeye başladı.
`changes.log`'a boş satırlar düştü, `.backups/` iki hafta hiç oluşmadı. Yeşil ışık ("düzenle, hook
yedek alıyor") yanlış varsayıma dayanıyordu.
→ *Dosya yolu stdin JSON'dan (`hook-meta.sh`). Hook'u denetlerken çıktının içeriğine bak; ara sıra fiilen test et.*

**4. Çalışma dizinine bağlı hafıza.** Claude Code'un otomatik hafıza dizini bir klasörde 2, ötekinde
18 dosya taşıyordu; 17'sinin 16'sı vault'ta zaten vardı. Klasör değişince görünmez, üstelik drift.
→ *Tek kaynak: vault. Otomatik dizinde sadece yönlendirme.*

**5. "Sıfırdan" pragmatik yorumlandı.** Kullanıcı "sıfırdan yap" dedi; model mimariyi koruyup üst
katmanı yeniledi. Kullanıcı sert tepki verdi.
→ *K1: niceleyici literal. "Sıfırdan" = tüm dosyalar atılır. Belirsizse tek satır teyit.*

**6. "Denesene" deploy sanıldı.** "Denesene yapmayı" → canlıya basıldı → site karardı.
→ *"Denesene" = sadece test. Deploy explicit ister; K1 + K3.*

**7. "Düşük risk" apex yönlendirmesi.** Bir redirect değişikliği "düşük risk" denilerek yapıldı;
24 saat production kesintisi.
→ *K3: "düşük risk" cümlesinden önce kullanıcı yolunu simüle et (ana sayfa, apex domain, dil değişimi).*

**8. Staging klasörü silindi, production düştü.** Temizlikte "kullanılmayan" sanılan klasör canlı
siteyi taşıyordu.
→ *Silme öncesi vault grep + geri-dönülebilir taşıma (`.curation-trash-<tarih>/` + RESTORE.md).*

**9. Altı paralel subagent.** İş doğru bitti; ama 1,4 M token yandı ve 75 dakika ekranda tek kelime
çıkmadı. Kullanıcı "takıldı" sandı, subagent'ı yasakladı.
→ *Varsayılan: kendin yap, görünür ilerleme. Kullanıcı isterse süreyi önden söyle, kapsamı böl.*

**10. `sleep` içeren komutlar.** Sunucu testleri için `sleep` konulan SSH komutları "background'da
çalışıyor, bildirim bekleniyor" moduna düştü; oturum kapanınca kayboldu.
→ *Komut içine `sleep` yok; başlat → sonraki adımda kontrol et. Background task harness'ta kapalı.*

**11. Skill'ler proje klasörüne kuruldu.** 16 tasarım skill'i `<proje>/.claude/skills/`'e gömülüydü,
global sanılıyordu. Kullanıcı "elli defa söyledim" dedi — hiç dosyalanmamıştı.
→ *Her şey global (`~/.claude/` veya vault). Sözlü kural = dosyalanmamış kural = yok.*

**12. AI çalışma dosyaları public repoda.** Pinli üç depoda `CLAUDE.md`, `.claude/`, 15 dosyalık
`scratchpad/`; bir müşteri deposunda müşterinin adı ve eksikleri.
→ *İlk commit'ten önce `.gitignore`. Dürüst ol (README'de yaz), açık verme (masayı gösterme).*

**13. `journalctl --vacuum`.** Disk temizliğinde çalıştırıldı; web erişim logları journald'daydı —
etkinlik günü dahil on günlük kayıt gitti, ertesi gün güvenlik raporu istendi.
→ *Log hiç silinmez. Yer gerekiyorsa arşivle.*

**14. "Marjinal" diye ertelenen 307.** Denetimde apex kökün geçici (307) yönlendirdiği görüldü,
"kırılgan build'e değmez" denip ertelendi — iki kez. 46 gün sonra arama konsolu gerçeği verdi: Google
canonical olarak yönlendiren kökü seçmiş, ana sayfa hiç indexlenmiyordu. Fix `.htaccess`'te tek
satırdı; build gerekmedi.
→ *"Marjinal" bir hipotezdir, bulgu değil. Aynı semptom + aynı anomali ikinci kez = erteleme hakkı biter. Riski gerekçe göstereceksen riskin var olduğunu doğrula.*

**15. Kod incelemeden yüklendi.** "Bu kodu karta yükle" dendi; model yükledi. Kodda bellek taşması ve
donanım tutarsızlığı vardı, ekran ve buzzer çalışmadı.
→ *"Yükle/çalıştır/deploy" = çalışır teslim et. Önce oku, bariz hatayı düzelt, sonra doğrula. K5 bunu ezmez.*

**16. Diskte aramadan kod uyduruldu.** "Yaptığımız projeyi rapora koy" dendi; model generic bir kod
yazdı. Gerçek kod masaüstündeydi, vault notu her şeyi içeriyordu — görev "basit belge işi" sanılıp
hafızaya bakılmamıştı.
→ *"Bizim kod" geçiyorsa önce vault, sonra `Desktop/**` — uydurma yok. Bulamazsan sor.*

**17. Placeholder MCP'ler.** 19 yapılandırılmış MCP'nin 5'i `YOUR_TOKEN`, `/path/to/...`,
`user:password@localhost` ile hiç çalışmamıştı; her oturum 5 kez spawn + fail. 4'ü eksik `type`
alanı yüzünden hiç yüklenmemişti.
→ *`claude mcp list` ile denetle; placeholder grep'le; çalışmayanı `.disabled-<tarih>` yap.*

**18. "Sonra bakılsın" kartı.** Kapsam dışı bir hata için arayüzde öneri kartı bırakıldı; kart
kayboldu, kullanıcı "kaybolsa nereden görücem, gerek varsa sen yap" dedi.
→ *Gerekliyse o an yap; karar gerekiyorsa açık soru; kalıcıysa vault. Arayüz bildirimi hafıza değildir.*

**19. Headless tarayıcı ≠ kullanıcının ekranı.** Model kendi headless örneğinde "düzeldi" diyordu;
kullanıcı kendi tarayıcısında (cache'li, farklı viewport) hâlâ bozuk görüyordu.
→ *Görsel doğrulamada kullanıcının gerçek ekranından/tarayıcısından bak; headless yalnız çok-viewport matrisi için. Ölçüm hakemdir, screenshot değil.*

**20. Kullanıcı verisi yerine aracın cevabı.** Kullanıcı bir proje ID'si verdi; model MCP'ye "doğrula"
diye sordu, MCP başka projeye bağlıydı, başka ID döndürdü — "doğrulama" doğruyu yanlışla
değiştirecekti.
→ *Kullanıcının verdiği somut değer otoritedir; araç çelişirse aracı sorgula.*

**21. Sözlü düzeltme dosyalanmadı.** 11 ve 18 numaralı dersler aynı kök nedeni paylaşır: kullanıcı
kuralı defalarca söylemişti, model her oturumda yeniden unuttu — çünkü hiç yazılmamıştı.
→ *"Bunu her seferinde anlatıyorum" cümlesi duyulduğu an `feedback_` notu + kısa özür. Vault'a girmeyen kural yoktur.*

---

## Desen

Yirmi bir maddenin ortak noktası: hiçbirinde model "kötü kod" yazmadı. Hepsi **yargı** hatası —
niceleyiciyi yumuşatmak, riski küçümsemek, izin sorup durmak, sessiz kalmak, kuralı yazmamak,
mekanizmanın çalıştığını varsaymak. Bu yüzden sistemin merkezinde skill ya da prompt değil,
**olay + neden + uygulama** biçiminde dosyalanmış kurallar ve onları her oturumda koşulsuz önüne
koyan bir hook var.
