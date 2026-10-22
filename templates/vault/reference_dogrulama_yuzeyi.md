---
name: Doğrulama yüzeyi — hangi iş, hangi araç
description: Ölçüm, kullanıcının gördüğü, kullanıcıya gösterim, teslim, deploy kontrolü ve demo için hangi tarayıcı ya da araç kullanılır. Ayrı olaylardan doğan doğrulama kurallarının tek karar tablosu; tek başına okunan kural bir diğerini çiğnetiyordu.
type: reference
created: {{INSTALL_DATE}}
---

# Doğrulama yüzeyi

> Doğrulama kuralları ayrı olaylardan doğar ve tek tek okununca birbirini çiğnetir: "kullanıcının
> tarayıcısında bak" kuralı bir ölçüm işine uygulanır, `Read` ile açılan görsel kullanıcıya gösterilmiş
> sanılır. Önce bu tabloya bak; satırlara kendi makinenin tuzaklarını ekle.

| İş | Araç | Neden |
|---|---|---|
| Responsive / mobil ölçüm (taşma, bbox) | Headless tarayıcı (örn. Playwright): viewport'u kur, sonra `innerWidth`'i sayfaya sor; `scrollWidth - innerWidth > 0` ise taşma var | Emülasyona güvenme: %200 ölçekli bir Windows ekranında bazı panellerin "mobil" modu 390 istenince sayfaya ~765 px gösterdi; "mobilde taşma yok" denen sayfa telefonda taştı |
| Görsel çıktıyı kendi gözünle QA | Headless ekran görüntüsü → `Read` ile bak, her iterasyonda | Kör teslim yok; programatik kontrol ekle ama yerine koyma |
| Kullanıcının gördüğü canlı hâl (cache, gerçek viewport) | Kullanıcının kendi tarayıcısı (tarayıcı eklentisi; bu bilgisayardakini seç, K3) | Headless ayrı bir örnektir; cache ve viewport farklı |
| Deploy doğru gitti mi | `curl` + canlı HTML'de grep, HTTP 200, cache-buster `?v=` artışı | Hızlı ve kesin; kompozisyon için ayrıca ekran görüntüsü |
| Kullanıcıya görsel göstermek / seçtirmek | Küçük bir HTML galeri → kullanıcının varsayılan tarayıcısında aç (Windows `Start-Process`, macOS `open`); açık + koyu zemin, etiketli | `Read` ile açtığın görsel yalnız senin bağlamında kalır, kullanıcıya görünmez |
| Teslim (ses, video, görsel, PDF, belge) | Görünür teslim klasörü, `<Proje>/01 - <İçerik adı>.<uzantı>`; belge HTML ise yanında aynı adla PDF | Aramak zorunda kalmasın; HTML telefonda ve mesajlaşmada açılmaz |
| PDF (HTML'den üretilmiş) | `box-shadow` ve saydamlık yok, ayrım opak yüzey rengiyle; teslim öncesi PDF'te `/SMask` say → 0 | Masaüstü görüntüleyici düzgün gösterir, iOS PDF görüntüleyici gölgeyi siyah kutu basar |
| Demo / canlı tur ("gezdir") | Hazırla (seed, giriş, sayfa listesi), kontrolü kullanıcıya bırak | Otomatik tur yavaş ve değersiz; hazırlık değerli |
| Uygulama içi tarayıcı paneli | Yalnız DOM / metin / taşma ölçümü | Panel gizliyken animasyon donar, ekran görüntüsü boş gelir, lazy içerik yüklenmez: site hatası değil, ölçüm artefaktı |
| "Linkiniz kırık" demeden önce | Temiz oturumda, telefon görünümünde aç; varılan adresi ve sayfa metnini ölç | Tek tarayıcıda görülen sonuçla hüküm verme |

**Kısa karar:** ölçüm → headless; kullanıcının gördüğü → onun tarayıcısı; ona göstermek → galeri +
varsayılan tarayıcı + teslim klasörü; demo → hazırla, gezdirme; uygulama içi panel → yalnız ölçüm.

İlgili: [[feedback_5_kanonik_davranis_kurali]] (K3)
