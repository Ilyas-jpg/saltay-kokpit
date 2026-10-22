# 01 · Neden — sorun ve felsefe

## Sorun: Claude Code her oturumu sıfırdan başlatır

Oturumu kapattığın an şunlar gider: sen kimsin, hangi projelerde çalışıyorsun, hangi stack'i seversin,
hangi sunucuya nasıl bağlanılır, geçen hafta "bunu bir daha yapma" dediğin şey, dün verdiğin mimari
karar ve *neden* verdiğin. Ertesi gün her şeyi yeniden anlatırsın; anlatmadığın yerde model tahmin
eder; tahmin ettiği yerde hata yapar; sen sinirlenirsin; döngü.

Bu depo, yedi ay boyunca tek bir bilgisayarda, yüzden fazla gerçek projede bu döngüyü kırmak için
kurulan sistemin **genel, kişisel verisi ayıklanmış** hali. Teori değil: her kuralın arkasında
tarihli bir olay var (bkz. [10-dersler.md](10-dersler.md)).

## Dört yanlış çözüm (hepsi denendi)

| Deneme | Neden yetmedi |
|---|---|
| **Her şeyi `CLAUDE.md`'ye yığmak** | Dosya şişer, her oturumda context yer, sayılar bayatlar, davranış kurallarıyla hesap bilgileri birbirine karışır. |
| **Koşullu talimat** — "görev geçmişle ilgiliyse notlara bak" | Karar modelin *o anki* yargısına kalır. "Hatırlıyor musun?" dendiğinde açar, "şu siteye şunu ekle" dendiğinde açmaz. Üç ay boyunca "bazen hafızası yokmuş gibi davranıyor" şikâyetinin kök nedeni tam olarak buydu; veri kaybı yoktu, **yükleme** yoktu. |
| **Claude Code'un otomatik hafıza dizini** (`~/.claude/projects/<dizin>/memory/`) | Çalışma dizinine bağlı: bir klasörde 2 dosya, ötekinde 18. Klasör değişince görünmez. Üstelik aynı bilgiyi vault'la iki yerde tutup **drift** üretir (17 dosyanın 16'sı vault'ta zaten vardı). |
| **"Hatırla" demek** | Yazılır ama okunmaz. Yazma tarafı her zaman canlıydı (bir ayda 140 dosya güncellenmiş); kırık olan **okuma / görünürlük** tarafıydı. |

## Felsefe — beş cümle

1. **Hafıza = okuma garantisi, yazma değil.** Not almak kolay; notu *her oturumda, koşulsuz* önüne
   koymak zor. Bunu modelin iradesine değil bir hook'a bağlarsın.
2. **Kural = olay + neden + uygulama.** "Otonom ol" demek işe yaramaz. "12 Mayıs'ta şunu sordun, ben
   şunu dedim, bu yüzden bundan sonra şu durumda sormayacaksın" işe yarar. Kuralın "why"ı yoksa model
   bir sonraki oturumda kendine istisna üretir.
3. **Otonomi = izin sormamak, ama kırmızı çizgi.** Model "komutu çalıştırayım mı?" diye sormaz;
   para, geri alınamaz silme, yasal anlaşma, müşterinin canlı sitesi ve public yayın için durur.
   "Tam yetki sende" bile bu çizgiyi kaldırmaz.
4. **Düzeni sistem hatırlatır, model değil.** Yedek almayı, sır taramayı, kuralı hatırlatmayı modele
   bırakırsan bir gün unutur. Hook unutmaz.
5. **Az ve doğru yerde (v1.1).** Her oturumda yüklenen her satır bir bedel öder. Güçlü model kısa
   talimatla yönlenir; aynı kuralın dördüncü kopyası, çelişen bir eklenti ya da kural sanılan bir olay
   günlüğü modeli dar kalıba çeker. Anayasada yalnız her oturumda geçerli olan çekirdek durur, gerisi
   vault'ta; sistem büyüdükçe bakım, kural eklemekten çok kural ayıklamaktır.

## Dört katman

```
┌────────────────────────────────────────────────────────────────────┐
│  HAFIZA  ·  Obsidian vault (düz .md + prefix + frontmatter)        │
│  ─ kullanici_ · feedback_ · reference_ · proje_ · HANDOFF_ · not_  │
│  ─ index her oturuma SessionStart hook'uyla gelir (≤ 9.5 KB)       │
├────────────────────────────────────────────────────────────────────┤
│  ANAYASA  ·  ~/.claude/CLAUDE.md (global, tek)                     │
│  ─ hafıza protokolü · 5 kanonik kural · 🟢🟡🔴 otonomi · güvenlik  │
├────────────────────────────────────────────────────────────────────┤
│  REFLEKSLER  ·  hooks (bash)                                       │
│  ─ index enjeksiyonu · düzenleme öncesi yedek · sır tarama         │
│  ─ her prompt'ta kısa hatırlatma (hafıza · brief'in sonu · 🔴)     │
├────────────────────────────────────────────────────────────────────┤
│  DÜZEN  ·  dosya sistemi                                           │
│  ─ 00-Projeler/{Aktif,Arsiv,_araclar,_yedekler}                    │
│  ─ .backups/ · .curation-trash-<tarih>/ · HANDOFF belgeleri        │
└────────────────────────────────────────────────────────────────────┘
```

Katmanlar birbirine bağımlı: anayasa vault'u işaret eder, hook vault'u yükler, vault dosya sistemini
tarif eder, dosya sistemi arşiv protokolüyle vault'a geri yazar.

## Bir oturum nasıl akar

1. Oturum açılır. `SessionStart` hook'u vault index'ini basar: "534 not; çekirdek: profil, 5 kural,
   skill routing; feedback_ adları: …; proje_ adları: …".
2. Sen yazarsın: *"örnek-site'nin hero'sunu canlıya al."*
3. `UserPromptSubmit` hook'u modele üç şeyi hatırlatır: vault'a bak ve yaz, brief'in son paragrafını
   tut, kırmızı dışında izin sorma.
4. Model index'te `proje_ornek_site` ve `HANDOFF_ornek_site` görür, **okumadan cevap vermez**: deploy
   komutu, yedek yolu, "bir daha yapma" listesi oradadır.
5. Deploy öncesi K3: vault'u grep'ler, kullanıcı yolunu simüle eder ("ana sayfaya girince bug tetiklenir mi?").
6. Düzenlediği her dosyadan önce `.backups/`'a kopya düşer (hook). Canlıda doğrular; "yükledim, oldu" demez, kanıt gösterir.
7. Sen: *"bundan sonra hero videolarında ses olmasın."* → model `feedback_hero_video_ses.md` yazar
   (Kural + Why + How to apply), `MEMORY.md`'ye bir satır ekler, tek cümleyle bildirir.
8. Oturum biterken: todo finalize, vault güncel, sabah özeti.

Ertesi gün başka klasörde oturum açtığında 1. adım aynen tekrar eder. Hiçbir şey anlatmazsın.

## Bu depo ne değildir

- Bir "prompt paketi" değil. Prompt'lar burada en az önemli parça.
- Skill/agent koleksiyonu değil. Skill'ler tabanı yükseltir, tavanı değil ([06](06-skill-agent-mcp.md)).
- Evrensel doğru değil. Tek kişinin yedi aylık kalibrasyonu; fork'la, kendi olaylarını ekle, kendi
  kurallarını yaz. Sistem **senin** hatalarından öğrenmeye başladığında işe yarar.
