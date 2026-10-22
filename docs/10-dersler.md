# 10 · Dersler — gerçek olaylardan çıkan kurallar

Bu depodaki her kural bir olaydan doğdu. Aşağıdaki liste, yazarın yedi aylık kayıt defterinin
kişisel/müşteri verisi ayıklanmış özeti. Her madde: **olay → maliyet → kural**. Kendi listeni
`feedback_` notlarında tut; on maddeyi geçince konsolide et.

1-21 ilk sürümle (v1.0) yayınlandı; 22-38 sonraki yedi haftanın dersleri (v1.1).

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
*(Kural iki ay sonra değişti: bkz. #26.)*

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

**22. Hatırlatma, kuralların dördüncü kopyasıydı.** Yeni model nesli gelince oturum başı yük ölçüldü:
kullanıcı tek kelime yazmadan tahminen 55-65 bin token yükleniyordu. Anayasa 24 KB'tı, yarısı envanter
ve tarihçe. Her prompt'a eklenen 1,7 KB hatırlatma aynı kuralları anayasa, vault notu ve Claude Code'un
kendi sistem promptundan sonra dördüncü kez söylüyordu; "skill kararını her görevde söyle" satırı her
cevaba bir gürültü paragrafı ekliyordu.
→ *Anayasa yükleme politikasıdır, belge değil: çekirdek kalır, envanter ve tarihçe vault'a. Hatırlatma tek ve kısa (~500 B). Her yeni model neslinde yeniden ölç: hangi satırı model artık kendiliğinden yapıyor?*

**23. Bir eklenti anayasayla taban tabana zıttı.** Aynı ölçümde, aylar önceki bir temizlikte "meşru"
sayılıp bırakılan bir öğrenme modu eklentisi bulundu: her oturuma "karar noktasında dur, kodun bir
kısmını kullanıcıya yazdır" diyordu; anayasa "izin sorma, bitir" diyordu. Yanında hiç çalışmayan bir
hafıza eklentisi her araç çağrısında bash başlatıyordu, kullanılmayan 24 agent tanımı (~9 bin token)
her oturuma yükleniyordu, MCP'lerin beşi ölü ya da çiftti.
→ *Kuralları değil, oturum başında yüklenen her şeyi denetle: output style, plugin, agent tanımı, MCP. Çelişen yük kuralı sessizce ezer. Tablo: vault `reference_kurulum_envanteri`.*

**24. Tasarım skill'i kendi kurallarınla çelişti.** Bir site inşasında tasarım skill'i "tabloda Tier 1"
diye refleksle yüklendi; öğütlerinin yarısı (gren, mesh gradyan, süs çerçevesi, özel imleç) yazarın
vault'unda "yapay zekâ izi" diye yasaklı olan şeylerdi. Kullanıcının uyarısı: bir skill seni
potansiyelinin altına çekiyorsa kullanma.
→ *K4 yeniden yazıldı: skill varsayılan değil. Sende olmayan, işe ya da sürüme özgü bilgi veriyorsa çağır; genel öğütse çağırma; çelişkide vault kazanır.*

**25. Olay günlüğü kural sanıldı.** Tasarım kuralları yedi olayın 16 KB'lık günlüğüydü; her tasarım
işinde baştan okunup kural yeniden çıkarılıyordu. İki not çelişti: biri bir yazı tipi ikilisini
öneriyor, öteki aynı ikiliyi "yapay zekâ varsayılanı" diye yasaklıyordu. Model ikisini uzlaştırmak
için üçüncü bir yol seçti; kullanıcı sonucu "aşırı vasat" buldu.
→ *Kuralları tek, tarihli, çelişkisiz bir sette topla; günlüğü arşive taşı. Yeni olay = sete bir satır + kaynak linki.*

**26. Subagent yasağı kalktı, sessizlik kalmadı.** #9'dan iki ay sonra yasak "takılmama" şartıyla
kaldırıldı. Sonraki iki haftada araştırma ajanları üç kez saatlerce sürdü: biri 60, biri 56 dakika;
iki ajan bir oturumu 5,5 saat kilitledi (860 bin token). Kök neden ikiydi. `Agent` çağrısı mesajı
bloklar: aynı mesajdaki kendi aramaların bile en yavaş ajan bitince döner, yani "ajanları başlatırken
kendi işini de yürüt" kuralı bu ortamda gerçekleşemiyordu. Doğru kural ise yalnız bir vault notunda
duruyordu, her oturum yüklenen anayasada değil. Aynı bulguların doğrulaması paralel sayfa okumayla
iki dakika sürdü.
→ *Araştırma ve soru-cevapta ajan yok: tek mesajda 5-8 paralel arama, kısa turlar, her turun arasına bir satır. Ajan yalnız büyük, bağımsız işte; prompta süre sınırı (≤ 15 dk), başlatırken tahmini süre, dönen sonucu doğrula. Bir kural üçüncü kez çiğneniyorsa yerini sorgula: her oturumda geçerli olacaksa anayasada tek satır olur.*

**27. `isLocal: true` başka birinin tarayıcısıydı.** Tarayıcı otomasyonunda iki Windows tarayıcısı
`isLocal: true` göründü; seçilen "Browser 2" aynı Claude hesabına bağlı başka bir kişinin Chrome profili
çıktı: bir giriş sayfası başka birinin hesabını önerdi, hesap yetkileri tutmadı. `isLocal` yalnız
işletim sistemi eşleşmesiydi.
→ *K3: bu bilgisayardaki tarayıcıyı sür (`onThisComputer`); yalnız uzak cihaz varsa sor. Yabancı profilde hesap ya da oturum işlemi yapılmaz; sekme kapatılıp çıkılır.*

**28. "Python yok" dendi, Python kuruluydu.** Bir komut *"Python was not found; run without arguments
to install from the Microsoft Store"* dedi. Model "Python yok" deyip başka araca geçti; oysa Python
kuruluydu ve bu bilgi vault'ta yazılıydı. Hata, PATH'te Microsoft Store kısayolunun gerçek Python'un
önünde durmasıydı.
→ *Bir araç için "yok" demeden önce vault'ta ara, `py` / tam yolu dene; eksik paketi sormadan kur. Kalıcı çözüm: PATH'te gerçek Python'u Store kısayolunun önüne al.*

**29. Heredoc metin taşıyıcı değildir.** Bash tool'unda ~12 KB'lık tek komut (`cat > dosya <<'EOF' …
EOF && …`) parse aşamasında "unexpected EOF" ile düştü; `&&` zincirindeki hiçbir adım, öndeki yedek
`cp`'si bile çalışmadı. Başka bir gün `\\` tırnaklı heredoc'un içinde bile teke indi: bir Windows yolu
görünmez bir kontrol karakterine (`\01`), bir regex `\u` SyntaxError'ına döndü. Bu sürüm hazırlanırken
bir `grep` deseninde bir kez daha yaşandı.
→ *≳ 8 KB dosya, Windows yolu, regex ya da kaçış dizisi taşıyan metin `Write` / `Edit` ile dosyaya; Bash küçük komutlar için. Yazdıktan sonra dosyada kontrol karakteri tara. Ayrıntı: [08-windows](08-windows.md).*

**30. Teslim görünmüyordu.** Kullanıcı üç iş verdi, birini "ondan önce, hızlıca" istedi (kısa bir
profil metni). Model metni araç çağrılarının önüne ara metin olarak yazıp öteki işlere geçti; kullanıcı
görmedi, uzun işin ortasında "metin nerede" diye sordu. Aynı aileden dört olay daha: ses, video, görsel
ve imza dosyaları proje klasörünün içinde bırakılıp "sohbete gönderdim" denmişti.
→ *Teslim kullanıcının kesin göreceği yerde olur: tek bir teslim klasörü, `<Proje>/01 - <İçerik adı>.<uzantı>`, mesajda tam yol; kısa metin teslimi ayrı mesajda ya da son mesajda tekrar. Turun ortasındaki metin teslim sayılmaz.*

**31. HTML belge teslim değildir; PDF de cihazda bozulabilir.** Kullanıcı bir onay listesini başkasına
iletmek istedi; liste yalnız HTML'di, telefonda ve mesajlaşmada açılmıyordu. Daha önce de bir PDF
masaüstünde kusursuz, iPhone'da her kartın arkasında siyah kutuyla görünmüştü: Chrome'un PDF çıktısı
bulanık ve saydam `box-shadow`'u yumuşak maske (`/SMask`) olarak gömüyor, iOS'un PDF görüntüleyicisi
bu maskeyi çözemiyordu.
→ *Okunacak / gönderilecek belge HTML ise yanına aynı adla PDF. Baskı CSS'inde gölge ve saydamlık yok, ayrım opak yüzey rengiyle; teslim öncesi PDF'te `/SMask` say → 0. "Bende düzgün görünüyor" bir PDF için kanıt değil.*

**32. Altı doğru kural, birlikte okununca yanlış.** Doğrulama üzerine altı ayrı not vardı (headless
ölçüm, kullanıcının tarayıcısı, görsel gösterme, demo, uygulama içi tarayıcı, mobil emülasyon); her
biri bir olaydan doğmuştu ve tek başına okununca bir diğerini çiğnetiyordu. `Read` ile açılan görseller
kullanıcıya "gösterildi" sanıldı, oysa yalnız modelin bağlamındaydı; uygulama içi tarayıcının "mobil"
modu %200 ölçekli ekranda 390 yerine ~765 px gösterdi, "mobilde taşma yok" denen sayfa telefonda taştı.
→ *Tek karar tablosu: vault `reference_dogrulama_yuzeyi`. Ölçüm headless (viewport'u `innerWidth` ile teyit et), kullanıcının gördüğü onun tarayıcısı, göstermek galeri + varsayılan tarayıcı, demo: hazırla, kontrolü bırak.*

**33. Düğmeyle oynamak araştırmanın yerini tutmaz.** Bir video kesim hattında kesim sınırları kelime
yutuyordu; model sessizlik eşiğini saatlerce gezdirdi (−28, −40, −48, −40 dB), ölçüt de aynı listeden
hesaplandığı için kayıyordu. Sektörün çözümü hazırdı: eşiksiz, sinir ağı tabanlı ses etkinliği tespiti
(VAD) + sabit pay. Kullanıcı modelin "at gözlüğüyle" baktığını söyledi.
→ *Aynı problem için ikinci kez parametre değiştirmek üzereysen dur: problemin sektördeki adı ne, onu çözmüş araçlar neler, bizim hat neyi iyi yapıyor. Ayrıntılı prosedür modeli düğmelere kilitleyebilir; prosedür araçtır, hedef değil.*

**34. Engel sonda söylendi.** Kullanıcı ev modemini sıfırlamasını istedi. Model işi yapacakmış gibi
konuştu, önce ölçüm yaptı, ancak sonra "şifre giremem" dedi: uygulamanın güvenlik kuralı şifreyle
girişi engelliyordu. Kullanıcıyı kızdıran kural değil, kurulan yanlış beklentiydi.
→ *Harness'ın engellediği bir adım varsa (şifreyle giriş gibi) ilk cümlede söyle ve en az emek isteyen yolu hemen ver: şifresiz yol (fişi 10 saniye çekmek aynı sıfırlamadır) ya da "giriş ekranını açarım, şifreyi sen yaz, gerisini ben yaparım".*

**35. Kullanıcının çalıştırdığı betik sessizdi.** Kendini yönetici olarak yeniden açan bir temizlik
betiği ilk pencereyi hemen kapattı; yönetici penceresinde 8 dakika tek satır yazmadan çalıştı.
Kullanıcı pencereye tıklayınca konsol "Seç" moduna (QuickEdit) girdi ve betik durdu. İş bitmişti ama
ekranda hiçbir iz yoktu.
→ *Kullanıcının elle çalıştıracağı betik canlı akar: numaralı adımlar, adım süresi, beklerken saniye sayacı, yüzde; QuickEdit kapatılır; kendini yükselten betik "asıl iş yeni pencerede" der. Sessiz bayraklar yalnız zamanlanmış arka plan görevlerinde.*

**36. Türkçe karakter iki kez sessiz arıza üretti.** Tarih biçimi için `setlocale(LC_ALL, 'tr_TR.UTF-8')`
çağıran bir PHP uygulamasında `glob('[a-z]*.php')` CLI'da 11, web isteğinde 9 dosya buldu: "i" ile
başlayanlar Türkçe sıralamada aralığın dışına düştü, 13 sayfa canlıda 404 verdi, lokal testte
görünmedi. Başka bir gün bir konuşma tanıma aracı, proje kökü "ü" içeren bir klasöre taşındıktan sonra
modelini açamadı: çıkış 127, çıktı boş; sonuç "seste konuşma yok" diye okunabilirdi.
→ *Glob / fnmatch'te harf aralığı kullanma: `*` ile al, adı ayrıca süz. ASCII dışı yolu her CLI'a verme (göreli yol ya da ASCII geçici klasör). Boş sonucu "veri yok" saymadan önce çıkış kodunu ve log'u oku.*

**37. Zengin index belgeye dönüştü.** `MEMORY.md` haziranda 11,5 KB'tı; ekimde 224 KB'a çıktı, sonra
280 KB'ı geçti. Her satır bir paragrafa dönüşmüştü; açmak bağlamın büyük bir kısmını yiyor, index
olarak işe yaramıyordu.
→ *`MEMORY.md`'de not başına tek satır, tek cümle. Büyüdüyse oturumda açma, Grep yap. `vault-health.sh` 100 KB'ta uyarır.*

**38. Kullanıcının koymadığı kural ona atfedildi.** Bir ağ denetiminde kullanıcı "uzaktan bağlan,
makineleri tek tek gözden geçir" dedi. Model, vault'ta yalnız adli bir aşama için (fişi çekilmiş tek
bir makinede iz korumak) yazılmış "toplamayı USB'den çalıştır" kuralını canlı makinelere genelledi ve
bunu "senin kuralın" diye sundu. Kullanıcı: öyle bir kural koymadım.
→ *Bağlamı dar kuralı geniş uygulama; kaynağın kullanıcı mı yoksa senin çıkarımın mı olduğunu ayır. Kendi altyapısında "uzaktan yap" diyorsa güvenli mekanizmayla yap; endişeni bir kez söyle.*

---

## Desen

Otuz sekiz maddenin ortak noktası değişmedi: hiçbirinde model "kötü kod" yazmadı. Hepsi **yargı**
hatası — niceleyiciyi yumuşatmak, riski küçümsemek, izin sorup durmak, sessiz kalmak, kuralı yazmamak,
mekanizmanın çalıştığını varsaymak. Bu yüzden sistemin merkezinde skill ya da prompt değil,
**olay + neden + uygulama** biçiminde dosyalanmış kurallar ve onları her oturumda koşulsuz önüne koyan
bir hook var.

İkinci yedi haftanın derslerinin yarısı yeni bir şey söylüyor: hata kuralın **eksikliğinden** değil,
**fazlalığından** ya da **yanlış yerde** durmasından çıktı. Dördüncü kopya hatırlatma, anayasayla
çelişen eklenti, kural sanılan olay günlüğü, birbirini çiğneten altı doğrulama notu, her oturumda
geçerli olması gerekirken yalnız vault'ta duran ajan kuralı. Sistem büyüdükçe bakım, kural eklemekten
çok kural ayıklamak ve doğru yere taşımaktır.
