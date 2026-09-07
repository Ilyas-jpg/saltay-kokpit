# 08 · Windows notları — iki kabuk, bir sürü tuzak

Sistem Windows 11'de doğdu. macOS/Linux'ta hook'lar aynen çalışır; bu sayfa Windows'a özgü.

## Git Bash zorunlu

Claude Code Windows'ta zaten Git for Windows ister. Hook komutları **Git Bash**'te çalışır:
`bash ~/.claude/hooks/...`, `/c/Users/...` yolu, `[[ ]]`, `$(date)`. Hook'ları PowerShell'e çevirme —
bozulur. `install.ps1` sadece `bash.exe`'yi bulup `install.sh`'i çağıran ince bir sarmalayıcıdır.

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

## Git Bash'te UTF-8

`LANG` boş gelir → `cut -c`, `sed`, `${s:0:n}`, `awk` **byte** sayar, Türkçe karakteri ortadan böler.
Script'lerin başına `export LC_ALL=C.UTF-8`; kısaltmayı `awk substr` ile yap. `iconv` bazı Git Bash
kurulumlarında **yoktur** — ona güvenme. `vault-index.sh` tam bu yüzden böyle yazıldı.

## Bash tool'da backtick komut çalıştırır

Çift tırnaklı bir string içindeki `` `metin` `` shell tarafından **komut olarak çalıştırılır**.
Markdown/Türkçe metni `echo "..."` ile shell'e sokma. Bir seferinde bir vault notundaki `` `vercel
login` `` ifadesi gerçekten `vercel login` koşturdu. Metni `Write` ile dosyaya yaz ya da tek tırnaklı
heredoc (`<<'EOF'`) kullan. Çok uzun heredoc'lar Bash tool'unda parse sorunu da çıkarabiliyor —
büyük dosyalar için `Write`.

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

## Hook çıktısı ve `.bat`/`cmd` pencereleri

Oturum başında görünüp kaybolan `cmd` pencereleri çoğu zaman **başlayıp çöken MCP sunucularıdır**
(placeholder token, eksik `type`) — hook değil. `claude mcp list` ile bul, çalışmayanı `.disabled-<tarih>` yap.

## Görev Zamanlayıcı ile 7/24 bot

Bulut VM'i kapanınca bir Telegram botu dizüstüne taşındı: `run-bot.ps1` + Görev Zamanlayıcı
(oturum açılışında, hata sonrası yeniden başlat). Geçici çözüm — dizüstü kapanınca susar; yine de
"sunucuya bağlanıp bakayım" refleksine düşmemek için vault notunda ⛔ ile işaretlendi. Ders:
altyapı taşınınca **eski runbook'u tarihsel işaretle**, yoksa model eski komutları dener.
