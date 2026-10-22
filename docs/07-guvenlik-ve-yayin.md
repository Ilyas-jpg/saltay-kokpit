# 07 · Güvenlik ve yayın hijyeni

İki ayrı konu: **üretilen kodun** güvenliği ve **çalışma sisteminin** (vault, AI dosyaları, repo) hijyeni.

## Üretilen kodda tartışmasız asgari

v1.0'da bu liste anayasanın içindeydi. v1.1'de anayasada üç satır kaldı: sır depoya ve log'a girmez;
doğrulama ve yetki sunucuda, uçlarda hız sınırı; deploy öncesi `audit` HIGH/CRITICAL çözülür. Sebep:
güçlü model aşağıdaki standartları zaten uyguluyor; her oturumda listeyi yeniden yüklemek bedel, değer
değil. Yazarın kararı: *"zaten güvenli iş yapıyorsun, bir de ekstradan kontrol ederiz."* Liste referans
olarak burada durur; denetimde, kod incelemesinde ve "neden böyle?" sorusunda açılır.

- Parameterized query · bcrypt/argon2 · CORS whitelist · rate limit (login/signup/form/API) ·
  production'da stack trace yok · `.env` commit edilmez (`.env.example` var) · HTTPS + güvenlik
  başlıkları (HSTS, X-Frame-Options, X-Content-Type-Options, CSP).
- Validation **backend'de** (frontend = UX) · XSS: context'e göre escape, `textContent` · CSRF token/SameSite.
- Session cookie `httpOnly + secure + SameSite=Lax` · kısa ömürlü JWT + refresh.
- Upload: MIME + uzantı + magic byte · path traversal: normalize + whitelist · her endpoint'te yetki (IDOR).
- Hardcoded secret yok · dependency audit HIGH/CRITICAL deploy öncesi · sır log'a yazılmaz · PII maskelenir.

**Pragmatizm:** tek-admin bir panelde 2FA varken 12 karakter + özel karakter dayatmak tehdit modelini
abartır, UX'i bozar. Saldırgan şifre-değiştir ekranına gelmek için zaten admin oturumunu ele
geçirmiş olmalı; şifre politikası o noktada savunma değil ergonomidir. Min 8 + "yeni ≠ eski" yeter;
kullanıcı "paranoid mod" derse sıkılaştır. Önce **kaç kullanıcı?** sor.

**Kod ve sırlar web kökünün dışında.** Paylaşımlı hosting'de `.env`, `inc/`, `vendor/` `public_html`
dışında durur; giriş noktaları `dirname(__DIR__).'/uygulama/…'` ile bağlanır. `.htaccess` bir gün
bozulsa bile sızacak bir şey kalmaz. Ölçülebilir hedef: *web kökünde şifre geçen dosya sayısı = 0.*

## Log silme yasak — mutlak

Bir VM'de disk temizliği sırasında `journalctl --vacuum-size=50M` çalıştırıldı. Web sunucusu erişim
loglarını journald'a yazıyordu → **etkinlik günü dahil on günlük trafik ve saldırı kaydı kalıcı
silindi.** Ertesi gün güvenlik raporu istendiğinde veri yoktu.

Kural: hiçbir makinede log silinmez, kısaltılmaz, retention düşürülmez (`vacuum`, `truncate`,
`rm *.log*`, `logrotate` kısaltma). Yer gerekiyorsa **arşivle** (tar.gz + indir). Retention artırmak
serbest. Disk temizliğinde hedef: paket cache, eski build, `.venv` artığı, geçici dosya.

## GitHub'a AI çalışma dosyası pushlama

Bir vitrin denetiminde çıktı: **pinli** üç repoda `CLAUDE.md`, `AGENTS.md`, `.claude/` ve 15 dosyalık
`scratchpad/` public duruyordu. Bir müşteri deposunda ise `MUSTERI-SORULARI.md`: müşterinin adı,
hangi e-postasının ölü olduğu, logosunun kaç piksel olduğu — internette.

İki ayrı zarar: (1) iş başvurusu/müşteri repoyu açınca çalışma masası görüntüsü, vitrin değil;
(2) başkasının eksiklerini yayınlamış olursun.

**Çizgi:** *AI konusunda dürüst ol ama açık verme.* Profil README'sinde "kodu AI destekli
geliştiriyorum, her çıktıyı kendim doğruluyor/test ediyor/ölçüyorum, sorumluluk ve son karar bende"
yazmak dürüstlüktür; `.claude/` klasörünü repoya koymak açık vermektir.

**Uygulama:**
- Her yeni projede **ilk commit'ten önce** `templates/project/.gitignore` (CLAUDE.md, AGENTS.md,
  .claude/, .cursor/, scratchpad/, .shots/, .backups/, müşteri notları).
- Repo public yapılmadan önce kök dizini gözden geçir.
- Zaten pushlanmışsa: `git rm -r --cached <yol>` (dosya diskte kalır) + `.gitignore` + commit.
  Public repoda **history rewrite yok** (`filter-branch`/force-push) — bundan sonrasını temizle, geçmiş kalsın.
- Public'e açmadan önce tüm git geçmişinde sır taraması (env değişken adı ≠ sır; literal değer ara).

## Vault'un kendisi

- Kişisel veri, hesap işaretçileri, müşteri bilgisi içerir → **public repoya asla**.
- Yedek: bulut senkronu (Obsidian Sync / iCloud / Syncthing) veya *private* repo. Credential dosyası
  tutuyorsan onu senkron/repo dışında tut; vault'tan **işaret et**.
- Hook'lardaki sır tarayıcısı kod dosyaları içindir; vault notlarında "şifre 1Password'de" yazmak
  tarayıcıyı tetiklemez ve doğru pratiktir.

## Kullanıcı verisi araç üstündedir

Kullanıcı somut bir değer verdiyse (proje ID, URL, anahtar, yol) **otorite odur**. Bir MCP'ye "doğrula"
diye sorup aracın döndürdüğünü onunkinin yerine koyma — araç başka projeye bağlı olabilir; "doğrulama"
doğruyu yanlışla değiştirir. Araç çelişirse **aracı sorgula**. Kardeş ders: "elle yapılmalı" demeden
önce ikinci yolu ara (CLI, API) — "panel tıklanmıyor" diye iki gün beklenen iş `vercel env rm` ile
400 ms sürdü.
