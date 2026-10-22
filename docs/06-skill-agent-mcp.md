# 06 · Skill · Agent · MCP — ne değer, ne gürültü

## Skill varsayılan değil (v1.1)

v1.0'da tier sistemi vardı: tasarım, dosya üretimi ve sürüm bilgisi Tier 1 ("çağır + sebebini söyle"),
generic skill'ler Tier 3 ("atla + sebebini söyle"). Doğuşu meşruydu: yazar üç kez "skill'leri
kullanmıyorsun" diye şikâyet etmişti. Yedi hafta sonra iki olay kuralı değiştirdi:

1. **Gürültü.** "Her görevde tier kararını söyle" kuralı her cevaba "skill kontrolü: … atlıyorum,
   çünkü …" paragrafı ekliyordu. Anthropic'in yeni modeller için uyarısı tam buydu: araç ve skill
   çağırmayı zorlayan sert dil, önceki nesillerde eksik tetiklenmeyi düzeltirken bugün aşırı tetiklenme
   üretiyor ([10-dersler](10-dersler.md) #22).
2. **Dar kalıp.** Bir site inşasında tasarım skill'i "Tier 1" diye refleksle yüklendi; öğütlerinin
   yarısı (gren, mesh gradyan, süs çerçevesi, özel imleç) yazarın vault'unda "yapay zekâ izi" diye
   yasaklı olan şeylerdi. Kullanıcının uyarısı netti: bir skill seni potansiyelinin altına çekiyorsa
   kullanma (#24).

Yeni kural tek soru: **bu skill bende olmayan, işe ya da sürüme özgü bir bilgi veriyor mu?**

| | Ne | Karar |
|---|---|---|
| **Çağır** | dosya üretimi (docx/xlsx/pptx/pdf) · sürüme özgü API ya da framework (Claude API, Next, Tailwind v4, Supabase) · kendi yazdığın hat ya da süreç (video hattı, belge üretimi) · eklenti / hook yazımı · sistemli dosya organizasyonu | çağır, tek cümleyle söyle |
| **Çağırma** | tasarım zevki, "premium UI" kılavuzları · senior-X, clean-code, best-practice · kod review, debug, TDD, plan ritüelleri · kurumsal bundle paketleri | çağırma, anlatma |

Skill öğüdü vault kuralıyla çelişirse **vault kazanır**: o kısım uygulanmaz. Bir skill çıktıyı
kötüleştiriyorsa kullanıcıya söylenir ve adı `reference_skill_routing` notuna yazılır. Tasarımda sıra:
vault'taki tasarım kuralları + gerçek referans + render-gör-düzelt; skill ancak somut bir boşluk varsa.

## Signal vs noise — dürüst kalibrasyon

- **SIGNAL:** sürüm düzelticiler (eğitim kesme tarihini güncelleyen framework skill'leri) · dosya
  üretim araç zinciri · kendi süreç skill'lerin · MCP'ler · vault.
- **NOISE SHELF:** generic skill'ler (eğitimde zaten var) · agent'ların çoğu (solo işte "sticky-note'lu
  ben") · hook'lar yetenek değil, güvenlik + hatırlatma · plugin'ler paketleme.
- **Kalite çarpanı = model × net brief / güçlü referans × iterasyon.** Skill *tabanı* yükseltebilir,
  *tavanı* değil; güçlü modelde kuralcı bir skill tavanı aşağı da çekebilir. "Daha iyi çıktı" için
  yatırım skill'e değil, net brief + güçlü referans + 2-3 tur iterasyona.

## Global kurulum kuralı

Skill / agent / komut / hook / kural / feedback **her zaman** `~/.claude/` veya vault'a. Çalışma
dizininin `.claude/`'ına yazılan şey klasör değişince sessizce kaybolur. Hikâye: 16 tasarım skill'i
`00-Projeler/.claude/skills/`'e gömülmüştü, global sanılıyordu; başka klasörde açılan oturumlarda
"neden gelmedi bu skill" — kullanıcı bunu defalarca söylemişti ama hiç dosyalanmamıştı, her oturum
yeniden unutuldu. Dosyalandıktan sonra bitti.

`npx skills add <paket>` → `-g`. Kurduktan sonra doğrula: `test -d ~/.claude/skills/<isim>`.
İstisna: kullanıcı açıkça "bu projeye özel" derse ya da dosya gerçekten projeye özgüyse (`launch.json`).

## Subagent — yasaktan "serbest, takılmak yasak"a

Kuralın üç evresi var; üçü de olaydan doğdu.

1. **Yasak.** Bir CMS işinde 6 paralel subagent (3 içerik tohumu + 3 panel ekranı) çalıştırıldı:
   **1,4 milyon token ve 1 saat 15 dakika boyunca ekranda tek kelime yok.** Ajanlar işi doğru yapmıştı;
   sorun kalite değil, maliyet + sessizlikti ([10-dersler](10-dersler.md) #9).
2. **Serbest, şartlı.** İki ay sonra bir site inşası tek elden, ~50 dosya ve ~40 ekran görüntüsü turu
   olarak sırayla yapıldı ve uzun sürdü. Kullanıcı yasağı "takılmayacaksan" şartıyla kaldırdı.
3. **Araştırmada yok.** Sonraki iki haftada araştırma ajanları üç kez saatlerce sürdü (60 dk, 56 dk,
   iki ajanla 5,5 saat). Kök neden: `Agent` çağrısı **mesajı bloklar**. Aynı mesajdaki diğer araç
   çağrılarının sonucu, kendi aramaların dahil, en yavaş ajan bitince gelir; o sürede kullanıcıya tek
   satır yazılamaz. "Ajanları başlatırken kendi işini de yürüt" kuralı bu yüzden işe yaramıyordu (#26).

Güncel kural:

- **Araştırma ve soru-cevapta ajan açma.** Tek mesajda 5-8 paralel arama ya da sayfa aç, kısa turlarla
  ilerle, her turun arasına bir satır ilerleme yaz. Hedefli aramalar saniyeler içinde döner.
- **Ajan yalnız büyük, bağımsız işte:** birbirinden bağımsız modül ya da sayfa yazımı, salt-okuma
  paralel kontroller. Aynı dosyalara dokunan ajanlar, belirsiz brief ve tek cümlelik görev kötü gider.
- Prompta **süre sınırı** yaz ("en fazla 15 dakika ve 12 arama; süre dolunca elindekiyle bitir"),
  başlatırken tahmini süreyi söyle, brief'i kendi başına yeterli yaz (hedef, dosya yolları, kurallar,
  neyin kanıtla döneceği).
- Ajanın "bitti" demesi kanıt değil: **dönen sonucu doğrula** (dosya, ekran, ölçüm), sonra teslim et.
- Küçük iş için ajan açma: ajan başına yüz binlerce token.

Kardeş kural — **bekleme / background yasak:** komut içine `sleep` koyma, `&` ile başlatıp aynı
komutta bekleme, "bildirim bekliyorum" deme. Uzun işi kısa senkron adımlara böl; zaman zaten araç
çağrıları arasında geçer. `settings.json`'daki `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` bunu harness
düzeyinde kapatır. Sessizlik yalnız ajanla olmaz: uzun bir düşünme ya da uzun komut da aynı etkiyi
yapar; uzun işte her 2-3 araç turunda bir satır yaz.

## MCP — yapılandırılmış ≠ çalışıyor

Check-up günü: 19 MCP yapılandırılmış görünüyordu, **10'u çalışıyordu**. 5'i hiç çalışmamıştı çünkü
şablon kopyala-yapıştır kalıntısıydı: `token=YOUR_TOKEN`, `/path/to/allowed/files`,
`mysql://user:password@localhost/dbname`. Her oturum başında 5 kez spawn + fail üretiyorlardı. 4'ü
`"url"` vardı ama `"type"` alanı olmadığı için hiç yüklenmiyordu. GitHub MCP'nin tokeni literal
`<YOUR_TOKEN>` idi; aylardır `gh` CLI iş gördüğü için kimse fark etmemişti.

Denetim: `claude mcp list` → her satırın gerçekten bağlandığını gör. Placeholder kalıbını grep'le:
`grep -nE 'YOUR_|/path/to|user:password|<[A-Z_]+>' ~/.claude.json`. Çalışmayanı kaldır; silme değil
`.disabled-<tarih>` ile yana al.

## Oturum başı yük — kuralları değil, yüklenen her şeyi ölç (v1.1)

Kullanıcı tek kelime yazmadan her oturuma yüklenen her şey bağlam yer ve davranışı etkiler. Yazarın
ölçümünde asıl kısıt kuralların kendisi değil, onların yanında sessizce yüklenen yüktü
([10-dersler](10-dersler.md) #23):

- Aylar önce "meşru" sayılıp bırakılan bir **öğrenme modu eklentisi** her oturuma "karar noktasında
  dur, kodun bir kısmını kullanıcıya yazdır" diyordu; anayasa "izin sorma, bitir" diyordu.
- Hiç çalışmayan bir **hafıza eklentisi** her araç çağrısında bash başlatıyordu.
- Yasaklı bir özellik için **24 agent tanımı** (~9 bin token) her oturuma yükleniyordu.
- MCP'lerin beşi ölü ya da çiftti; kurumsal bundle eklentileri her oturumda onlarca başarısız bağlantı
  ve işle ilgisiz yüzlerce skill açıklaması getiriyordu.

Ayda bir ve her yeni model neslinde ölç: CLAUDE.md boyutu, index boyutu, prompt hatırlatıcısı, seçili
output style, açık plugin'ler, agent tanımları, MCP listesi. Tablo ve komutlar vault şablonunda:
`reference_kurulum_envanteri`.

## Curate protokolü (agent / skill / plugin ayıklama)

44 agent → 21 → 20; 33 plugin → 14 aktif. Yöntem her seferinde aynı:
1. Stack kanıtı: bu makinede gerçekten hangi dillerle/servislerle iş yapılıyor? (vault'taki proje
   notları söyler). Kanıtı olmayan agent gider.
2. Silme değil taşıma: `~/.claude/.curation-trash-<tarih>/` + `RESTORE.md`.
3. Bir ay sonra hiçbir şey geri istenmediyse boşalt.
4. Sayıları CLAUDE.md'ye yazma; komutla say.
