# Güvenlik · Security

## 🇹🇷

Bu depo, kullanıcının makinesinde **kabuk komutları çalıştıran hook'lar** ve **`~/.claude`
altına yazan bir kurulum script'i** içerir. Bu yüzden güvenlik bildirimlerini ciddiye alıyoruz.

**Kapsam**
- `hooks/*.sh`: Claude Code her oturumda ve her düzenlemede bunları çalıştırır. Girdi olarak
  Claude Code'un stdin'e verdiği JSON'u ve vault dosya adlarını okurlar.
- `scripts/install.sh` / `install.ps1`: `~/.claude/settings.json`, `CLAUDE.md`, `vault.conf` ve
  vault klasörüne yazar; var olan dosyayı yedeksiz ezmez.
- `templates/`: kurulumda kopyalanan metinler.

**Bildirim**
Bir zafiyet bulduysan (örn. hook'a sızan bir dosya adıyla komut enjeksiyonu, kurulumun yanlış
yola yazması, sır tarayıcısının bir sırrı log'a düşürmesi) lütfen **public issue açma**:
- GitHub'ın özel zafiyet bildirimi (*Security → Report a vulnerability*), ya da
- e-posta: `info@algow.net` (konu: `saltay-kokpit security`).

72 saat içinde yanıt verilir. Düzeltme yayınlanana kadar ayrıntıyı gizli tutmanı rica ederiz;
düzeltmede adın (istersen) `CHANGELOG.md`'de anılır.

**Kullanıcıya öneriler**
- Vault'unu public repoya koyma; sırları parola yöneticisinde tut, vault'tan işaret et.
- Kurulumdan önce `--dry-run` ile ne yazılacağını gör.
- Hook'ları kendi makinene kopyaladıktan sonra `scripts/vault-health.sh` ile doğrula.

## 🇬🇧

This repository contains **hooks that run shell commands** on the user's machine and an
**installer that writes under `~/.claude`**. We take security reports seriously.

**Scope**
- `hooks/*.sh`: Claude Code runs them at every session start and every edit. They read the JSON
  Claude Code pipes to stdin and the vault's file names.
- `scripts/install.sh` / `install.ps1`: write `~/.claude/settings.json`, `CLAUDE.md`, `vault.conf`
  and the vault folder; never overwrite an existing file without a backup.
- `templates/`: text copied during installation.

**Reporting**
If you found a vulnerability (e.g. command injection through a crafted file name reaching a hook,
the installer writing to a wrong path, the secret scanner leaking a secret into a log), please
**do not open a public issue**:
- GitHub private vulnerability reporting (*Security → Report a vulnerability*), or
- email: `info@algow.net` (subject: `saltay-kokpit security`).

You will get a reply within 72 hours. Please keep details private until a fix is released; with
your consent you will be credited in `CHANGELOG.md`.

**Advice for users**
- Never put your vault in a public repository; keep secrets in a password manager and point to them from the vault.
- Run the installer with `--dry-run` first to see what will be written.
- After copying the hooks to your machine, verify with `scripts/vault-health.sh`.
