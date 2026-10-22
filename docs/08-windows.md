# 08 · Windows notları — iki kabuk, bir sürü tuzak

Sistem Windows 11'de doğdu. macOS/Linux'ta hook'lar aynen çalışır; bu sayfa Windows'a özgü.

## Git Bash zorunlu

Claude Code Windows'ta zaten Git for Windows ister. Hook komutları **Git Bash**'te çalışır:
`bash ~/.claude/hooks/...`, `/c/Users/...` yolu, `[[ ]]`, `$(date)`. Hook'ları PowerShell'e çevirme —
bozulur. `install.ps1` sadece Git Bash'i bulup `install.sh`'i çağıran ince bir sarmalayıcıdır.

**PATH'teki ilk `bash.exe` WSL olabilir.** WSL kurulu bir makinede `bash.exe` adı (`WindowsApps` ya da
`System32` altında) Git Bash'i değil, WSL'in Linux kabuğunu başlatır; orada `/c/...` ya da `/d/...`
yolları yoktur. v1.0'ın sarmalayıcısı PATH'teki ilk `bash.exe`'yi alıyordu: WSL kurulduktan sonra
kurulum "No such file or directory" ve çıkış 127 ile hiç başlamadı. v1.1 yalnız Git Bash'i arar
(`CLAUDE_CODE_GIT_BASH_PATH`, `Program Files\Git`, `git.exe`'nin yanı) ve WSL başlatıcısını atlar.
Kendi betiklerinde de bash'i adıyla değil yeriyle bul; emin değilsen `bash -c 'uname -a'` çalıştır:
`MINGW64` Git Bash, `Linux … microsoft` WSL'dir.

## İki AYRI tool, iki AYRI sözdizimi

Claude Code'un `PowerShell` tool'u ile `Bash` tool'u farklı programlardır; hangisini çağırdıysan onun
dilini yaz. "Bash tool aslında PowerShell'dir" varsayımı yanlıştır.

| | `PowerShell` tool (PS 5.1) | `Bash` tool (Git Bash / POSIX) |
|---|---|---|
| Zincirleme | `&&` **yok** → `A; if ($?) { B }` | `&&` var |
| Ternary / `??` / `?.` | yok | — |
| Sayım | `(Get-ChildItem x).Count` | `ls x \| wc -l` |
| Taşıma | `Move-Item` | `mv` |
| Yol | `C:\Users\...` | `/c/Users/...` |
| stderr | `2>&1` native exe'de **ErrorRecord'a sarar**, `$?` yalan söyler — kullanma | normal |
| UTF-8 yazma | `Set-Content`/`Add-Content` varsayılan **ANSI** → `-Encoding utf8` şart; `>` BOM'lu UTF-8 | UTF-8 (BOM'suz) |
| JSON | `ConvertFrom-Json` PSCustomObject döner, `-AsHashtable` yok | `node -e` / `jq` |

PS 5.1'de `Add-Content` ile yazılmış bir Türkçe dosya bir sonraki oturumda bozuk görünür — kaynak
neredeyse hep encoding'dir.

**Okuma tarafı da tuzak.** `Get-Content -Raw` encoding verilmezse PS 5.1'de sistemin ANSI kod sayfasıyla
(Türkçe Windows'ta 1254) okur. UTF-8 bir dosyayı böyle okuyup `Set-Content -Encoding UTF8` ile yazınca
byte'lar **çift kodlanır**: `ı` (`c4 b1`) → `Ä±` (`c3 84 c2 b1`). Bir deploy betiği canlı sitede tüm
Türkçe karakterleri böyle bozdu. Türkçe dosyayı PowerShell'de okuyup yazacaksan .NET API kullan:

```powershell
$t = [System.IO.File]::ReadAllText($src, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($dst, $t, (New-Object System.Text.UTF8Encoding($false)))
```

Dosyayı olduğu gibi taşıyacaksan metin işleme hiç yapma: byte'ı byte'ına kopyala (`scp`, `Copy-Item`).

## Git Bash'te UTF-8

`LANG` boş gelir → `cut -c`, `sed`, `${s:0:n}`, `awk` **byte** sayar, Türkçe karakteri ortadan böler.
Script'lerin başına `export LC_ALL=C.UTF-8`; kısaltmayı `awk substr` ile yap. `iconv` bazı Git Bash
kurulumlarında **yoktur** — ona güvenme. `vault-index.sh` tam bu yüzden böyle yazıldı.

## Bash tool metin taşıyıcı değildir

Claude Code'un Bash tool'u komutu Git Bash'e bir köprüden geçirerek verir. Bu köprüde üç tuzak
ölçüldü; üçü de aynı sonuca götürür: **metni dosyaya `Write` / `Edit` ile yaz, Bash'i küçük komutlara ayır.**

1. **Backtick komut çalıştırır.** Çift tırnaklı bir string içindeki `` `metin` `` shell tarafından
   komut olarak çalıştırılır. Bir seferinde bir vault notundaki `` `vercel login` `` ifadesi gerçekten
   `vercel login` koşturdu. Markdown / Türkçe metni `echo "..."` ile shell'e sokma.
2. **~12 KB üstü komut hiç çalışmaz.** `cat > dosya <<'EOF' … EOF && …` biçiminde ~12 KB'ı aşan tek
   komut "unexpected EOF while looking for matching `'`" ile **parse aşamasında** düşer; `&&`
   zincirindeki hiçbir adım, öndeki yedek `cp`'si bile çalışmaz. "Kısmen uygulandı" sanma, dosyaya bak.
   4-9 KB'lık heredoc'lar sorunsuzdu; sınır ~12 KB civarında.
3. **`\\` teke iner, tırnaklı heredoc'ta bile.** `'EOF'` ile tırnaklanmış heredoc'ta bile `\\` → `\`
   oluyor. Bir Python betiğindeki Windows yolu `\01` (görünmez kontrol karakteri) üretti, bir regex
   `\u` ile SyntaxError verdi, bir `sed` deseni "unterminated s command" dedi. Bu sürüm hazırlanırken
   `grep '\\|'` deseni `\|`'ye inip her satırı eşleştirdi. Belirtiler: "truncated \uXXXX escape",
   "unterminated s command", dosyada görünmez `\x01`.

Uygulama: ≳ 8 KB dosya, Windows yolu, regex ya da kaçış dizisi taşıyan metin → `Write` ile dosyaya
(scratchpad'de bir betik), sonra Bash'le çalıştır. Desen aramak için Bash'teki `grep` yerine
Claude Code'un `Grep` tool'u (desen kabuktan geçmez). Yazdıktan sonra dosyada kontrol karakteri tara.
Satır sonu sayarken `grep -c $'\r'` yanlış pozitif verebilir; `tr -dc '\r' < dosya | wc -c` güvenilir.

## "Python yok" deme

Bir komut *"Python was not found; run without arguments to install from the Microsoft Store"* derse bu
Python'un yokluğu değil, `WindowsApps\python.exe` **Store kısayolunun** PATH'te gerçek Python'un önünde
durmasıdır. Model bir kez bunu "Python yok" diye okuyup başka araca geçti; Python kuruluydu ve bilgi
vault'ta yazılıydı ([10-dersler](10-dersler.md) #28).

- Sıra: `python` → çalışmazsa `py` (Python Launcher) → o da olmazsa tam yol.
- Kalıcı çözüm: kullanıcı PATH'inde gerçek Python klasörünü `…\Microsoft\WindowsApps`'in önüne al
  (önce PATH'i dosyaya yedekle). Önceden açılmış uygulamalar eski PATH'i taşır; yeniden başlatılana
  kadar onlarda çıplak `python` yine Store'a düşebilir.
- Eksik paket varsa `python -m pip install <paket>`; sormadan.
- `install.sh` bu yüzden `python3 -c 'import sys'` ile gerçek çalıştırma testi yapar: Store kısayolu
  bu testi geçemez.

## ASCII dışı yollar

Proje kökünü adında `ü` olan bir klasöre taşıdıktan sonra bir konuşma tanıma CLI'ı (yerel derleme)
Git Bash'ten mutlak yolla çağrılınca modelini açamadı: log'da yol `Masa�st�` diye bozuldu, çıkış 127,
çıktı boş. Boş sonuç "seste konuşma yok" diye okunabilirdi ([10-dersler](10-dersler.md) #36).

- Eski ya da yerel derlenmiş CLI'lara ASCII dışı mutlak yol verme: aracın klasörüne `cd` edip **göreli
  yol** ver ya da girdiyi ASCII bir geçici klasöre kopyala.
- Boş çıktıyı sonuç saymadan önce çıkış kodunu ve log'u oku.
- Aynı aile, dosya sisteminde değil kodda: `setlocale(LC_ALL, 'tr_TR.UTF-8')` çağıran bir PHP
  uygulamasında `glob('[a-z]*.php')` "i" ile başlayan dosyaları atladı (Türkçe sıralamada `ı`/`i`).
  Glob / fnmatch'te harf aralığı yerine `*` + ayrı süzgeç kullan.

## Yollar ve JSON

- Windows yolu JSON'da kaçışlı gelir: `C:\\Users\\...`. `hook-meta.sh` bunu `/`'ye çevirir.
- `cygpath -w /c/Users/x` → `C:\Users\x` (görüntü için); `cygpath -u` tersi. `install.sh` CLAUDE.md'ye
  Windows yolunu, `vault.conf`'a bash yolunu yazar.
- `~` Git Bash'te `/c/Users/<sen>`; `$HOME` aynı. PowerShell'de `$env:USERPROFILE`.

## `claude` CLI PATH'te olmayabilir

Masaüstü uygulaması kendi paketinin içinde bir CLI taşır; `claude --version` terminalde bulunamayabilir.
`%APPDATA%\npm\claude.cmd` + küçük bir `claude-shim.ps1` ile köprü kurulur; `setx PATH` kullanma
(1024 karakter sınırı, PATH'i budar). MCP OAuth login'i sandbox'tan tamamlanmaz — gerçek konsolda
`Start-Process` ile.

Shim'i sabit bir klasör yapısına bağlama: bir güncellemeyle CLI'ın yeri
`claude-code\<sürüm>\claude.exe`'den `claude-code\<sürüm>\<hash>\claude.exe`'ye kaydı ve kökte exe arayan
shim her çağrıda "bulunamadı" dedi. Shim sürüm klasörünü özyinelemeli tarasın (`Get-ChildItem -Recurse
-Filter claude.exe`); çalışan sürümün yolunu bulmanın en kısa yolu `Get-Process claude | Select-Object Path`.
`.cmd` dosyasına ASCII dışı karakter koyma (yorum satırına bile): kod sayfası tuzağı.

## Hook çıktısı ve `.bat`/`cmd` pencereleri

Oturum başında görünüp kaybolan `cmd` pencereleri çoğu zaman **başlayıp çöken MCP sunucularıdır**
(placeholder token, eksik `type`) — hook değil. `claude mcp list` ile bul, çalışmayanı `.disabled-<tarih>` yap.

## Görev Zamanlayıcı ile 7/24 bot

Bulut VM'i kapanınca bir Telegram botu dizüstüne taşındı: `run-bot.ps1` + Görev Zamanlayıcı
(oturum açılışında, hata sonrası yeniden başlat). Geçici çözüm — dizüstü kapanınca susar; yine de
"sunucuya bağlanıp bakayım" refleksine düşmemek için vault notunda ⛔ ile işaretlendi. Ders:
altyapı taşınınca **eski runbook'u tarihsel işaretle**, yoksa model eski komutları dener.
