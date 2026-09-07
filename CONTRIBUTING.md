# Katkı · Contributing

## 🇹🇷

**Hoş gelen katkılar**
- Çeviri (`docs/` İngilizce, README'ler başka diller).
- Hook portları: başka kabuk/OS için aynı davranışı veren script'ler (`hooks/` altında ayrı dosya, `settings.hooks.json`'a eşdeğer blok).
- Kendi **"olay → kural"** derslerin: [📚 Ders önerisi](.github/ISSUE_TEMPLATE/lesson.md) şablonuyla issue aç ya da doğrudan `docs/10-dersler.md`'ye PR gönder. Biçim: *olay, maliyet, kural*. Kişisel veri, müşteri adı, sunucu adresi olmadan.
- `vault-index.sh` için sıkıştırma/ölçüm iyileştirmeleri. Bütçe değişmez: çıktı 10.000 byte'a asla ulaşmamalı; `bash hooks/vault-index.sh | wc -c` ile kanıtla.
- Hata raporu: [🐛 Hata](.github/ISSUE_TEMPLATE/bug_report.md) şablonu; Claude Code sürümü, OS ve `scripts/vault-health.sh` çıktısıyla.

**Gelmeyen katkılar**
- Generic "best practice" listeleri, prompt koleksiyonları, skill/agent yığınları. Her kuralın bir hikâyesi olmalı; yoksa eğitim verisinde zaten vardır.
- Anayasanın davranış çekirdeğini (hafıza protokolü · 5 kanonik kural · trafik ışığı) olay göstermeden değiştiren PR'lar.

**Biçim**
- Feedback/kural metinleri: **Kural + Why + How to apply**.
- Script'ler: bash + POSIX araçları; `set -euo pipefail`; sandbox HOME'da test edilmiş (`HOME=$(mktemp -d) bash scripts/install.sh ...`). Satır sonu LF (`.gitattributes` zorlar).
- Windows'ta çalıştığını iddia ediyorsan Git Bash'te dene; PowerShell 5.1'de `&&` yok.
- Commit mesajı: `feat:` / `fix:` / `docs:` / `chore:` ön eki, kısa özet, gerekiyorsa gövdede olay.

**Süreç**
1. Issue aç ya da doğrudan PR gönder (küçük düzeltmeler için issue gerekmez).
2. PR şablonundaki kontrol listesini doldur.
3. Bakımcı 7 gün içinde yanıt verir.

## 🇬🇧

**Welcome**
- Translations (`docs/` into English, READMEs into other languages).
- Hook ports: scripts giving the same behaviour on other shells/OSes (separate file under `hooks/`, an equivalent block for `settings.hooks.json`).
- Your own **"incident → rule"** lessons: open an issue with the [📚 Lesson proposal](.github/ISSUE_TEMPLATE/lesson.md) template or send a PR to `docs/10-dersler.md`. Format: *incident, cost, rule*. No personal data, client names or server addresses.
- Compression/measurement improvements to `vault-index.sh`. The budget is fixed: output must never reach 10,000 bytes; prove it with `bash hooks/vault-index.sh | wc -c`.
- Bug reports: the [🐛 Bug](.github/ISSUE_TEMPLATE/bug_report.md) template with Claude Code version, OS and the output of `scripts/vault-health.sh`.

**Not welcome**
- Generic "best practice" lists, prompt collections, skill/agent piles. Every rule needs a story; without one it is already in the training data.
- PRs that change the constitution's behaviour core (memory protocol · 5 canonical rules · traffic light) without an incident.

**Style**
- Rule texts: **Rule + Why + How to apply**.
- Scripts: bash + POSIX tools; `set -euo pipefail`; tested in a sandbox HOME (`HOME=$(mktemp -d) bash scripts/install.sh ...`). LF line endings (`.gitattributes` enforces it).
- If you claim it works on Windows, try it in Git Bash; PowerShell 5.1 has no `&&`.
- Commit messages: `feat:` / `fix:` / `docs:` / `chore:` prefix, short summary, the incident in the body if relevant.

**Process**
1. Open an issue or send a PR directly (small fixes need no issue).
2. Fill in the PR template checklist.
3. The maintainer replies within 7 days.
