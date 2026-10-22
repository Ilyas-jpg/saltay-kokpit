# hooks/ — Claude Code refleksleri

Hook'lar, Claude'un *kendi kararına* bırakılmayan davranışlardır: oturum başında hafızayı yükle,
her düzenlemeden önce yedek al, her prompt'ta kuralları hatırlat. Model "unutabilir"; hook unutmaz.

| Dosya | Olay | Ne yapar |
|---|---|---|
| `vault-index.sh` | `SessionStart` | Vault index'ini (not adları) her oturuma enjekte eder. Kendini ölçer, 10K sınırına asla ulaşmaz. |
| `hook-meta.sh` | (yardımcı) | Diğer hook'lara stdin JSON'dan `tool_name|file_path` verir. |
| `settings.hooks.json` | — | `~/.claude/settings.json`'a birleştirilecek hook bloğu (install.sh yapar). |
| `settings.remove.json` | — | Eski bir sürümün kaydettiği ve bu sürümün yerine koyduğu komutlar; install.sh birleştirmeden önce bunları birebir eşleşmeyle kaldırır. |

`settings.hooks.json` içindeki hook'lar:

| Olay | Eşleşme | İş |
|---|---|---|
| `SessionStart` | — | `vault-index.sh` |
| `UserPromptSubmit` | — | `session-reminder.json` içeriğini (~500 B) her prompt'a ekler: vault'a bak ve yaz, brief'in son paragrafını tut, kırmızı dışında izin sorma. Uzun oturumda context sıkıştırılsa bile geri gelir. v1.0'daki iki uzun hatırlatmanın (1,7 KB) yerini aldı. |
| `PreToolUse` | `Edit\|MultiEdit` | Dosyayı düzenlemeden önce `./.backups/<ad>.<zaman>.bak` kopyası alır (cwd'ye göre). |
| `PostToolUse` | `Edit\|Write` | Dosyada `password = "…"` biçiminde sabit sır arar, bulursa stderr'e uyarı basar. |
| `PostToolUse` | `Edit\|MultiEdit\|Write` | `~/.claude/changes.log`'a `[zaman] Araç yol` satırı ekler. |

## İsteğe bağlı hook'lar (varsayılan kurulumda YOK)

Yazarın kendi kurulumunda iki hook daha vardır; herkes istemeyebilir diye bloğa konmadı.
İstersen `settings.json`'daki `PostToolUse` dizisine ekle:

**Git auto-add** — düzenlenen dosya bir git deposundaysa otomatik `git add` (hassas dosyalar hariç).
Commit yine sen atarsın; sadece staging'i unutmazsın.

```json
{
  "matcher": "Edit|MultiEdit|Write",
  "hooks": [{ "type": "command",
    "command": "m=$(bash __CLAUDE_HOME__/hooks/hook-meta.sh); f=${m#*|}; if [[ -n \"$f\" ]] && git rev-parse --git-dir >/dev/null 2>&1; then case \"$f\" in *.env|*.env.*|*.bak|*.log|*.sql|*.tar.gz|*.zip|*node_modules*|*.backups*|*credentials*|*secret*) : ;; *) git add \"$f\" 2>/dev/null || true ;; esac; fi" }]
}
```

**İlgili testleri koştur** — `.js/.ts` düzenlemesinde `jest --findRelatedTests` / `vitest related`,
`.py`'de `pytest <dosya>`. Sadece değişen dosyaya bağlı testler (tüm suite değil).

```json
{
  "matcher": "Edit",
  "hooks": [{ "type": "command",
    "command": "m=$(bash __CLAUDE_HOME__/hooks/hook-meta.sh); f=${m#*|}; if [[ \"$f\" == *.js || \"$f\" == *.ts ]] && [[ -f package.json ]]; then (npx --no-install jest --findRelatedTests \"$f\" --passWithNoTests 2>/dev/null || npx --no-install vitest related --run \"$f\" 2>/dev/null) || true; elif [[ \"$f\" == *.py ]] && [[ -f pytest.ini || -f setup.cfg || -f pyproject.toml ]]; then pytest \"$f\" 2>/dev/null || python -m pytest \"$f\" 2>/dev/null || true; fi" }]
}
```

## İki tuzak (ikisi de gerçekten yaşandı)

1. **Hook çıktısı 10.000 karakteri geçerse Claude onu görmez.** Claude Code çıktıyı dosyaya kaydedip
   modele 2 KB önizleme verir. `vault-index.sh` bu yüzden kendini ölçer ve kademeli sıkışır.
   Kontrol: `bash ~/.claude/hooks/vault-index.sh | wc -c` → `BUDGET` (9500) altında olmalı.
2. **"Hook tetikleniyor" ≠ "hook çalışıyor".** `$CLAUDE_TOOL_FILE_PATH` bir sürümde boş gelmeye başladı;
   log'a boş satırlar düştü, yedek hiç alınmadı, kimse iki hafta fark etmedi. `hook-meta.sh` bu yüzden
   stdin JSON'u okur. Ara sıra fiilen test et: bir dosyayı düzenle → `.backups/` oluştu mu bak.

Bir de ölçü: hook çıktısı her oturumda ya da her prompt'ta bağlama girer. Hatırlatma kısa kalır;
aynı kuralları anayasa zaten söylüyorsa hatırlatma onları dördüncü kez tekrar etmez (v1.1 dersi).

Sağlık kontrolü tek komut: `bash scripts/vault-health.sh`
