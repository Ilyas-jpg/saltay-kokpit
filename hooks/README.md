# hooks/ — Claude Code refleksleri

Hook'lar, Claude'un *kendi kararına* bırakılmayan davranışlardır: oturum başında hafızayı yükle,
her düzenlemeden önce yedek al, her prompt'ta kuralları hatırlat. Model "unutabilir"; hook unutmaz.

| Dosya | Olay | Ne yapar |
|---|---|---|
| `vault-index.sh` | `SessionStart` | Vault index'ini (not adları) her oturuma enjekte eder. Kendini ölçer, 10K sınırına asla ulaşmaz. Düz (`flat`, önekli notlar) ve klasörlü (`folders`, mevcut Obsidian kasası) düzeni okur. |
| `hook-meta.sh` | (yardımcı) | Diğer hook'lara stdin JSON'dan `tool_name|file_path` verir (`jq` varsa onunla). |
| `backup.sh` | `PreToolUse` | Düzenlemeden ya da üzerine yazmadan önce yedek. |
| `secret-scan.sh` | `PostToolUse` | Sabit sır arar, bulursa Claude'a bildirir (exit 2). |
| `change-log.sh` | `PostToolUse` | Değişiklik günlüğü, 1 MB'ta döner. |
| `session-track.sh` | `PostToolUse` | Oturum başına ne iş yapıldığını (düzenleme / komut) `~/.claude/saltay-state/` altına not eder. |
| `journal-reminder.sh` | `Stop` | Gerçek bir iş parçası günlüğe yazılmadan bittiyse Claude'dan bir kez oturum özeti ister. |
| `settings.hooks.json` | — | `~/.claude/settings.json`'a birleştirilecek hook bloğu (install.sh yapar). |
| `settings.remove.json` | — | Eski sürümlerin kaydettiği ve bu sürümün yerine koyduğu komutlar; install.sh birleştirmeden önce, uninstall.sh her zaman bunları birebir eşleşmeyle kaldırır. |
| `settings.env.json` | — | İsteğe bağlı env bloğu; yalnız `install.sh --disable-background-tasks` ile. |

`settings.hooks.json` içindeki hook'lar (yollar tırnaklı; boşluklu ev klasörü çalışır):

| Olay | Eşleşme | İş |
|---|---|---|
| `SessionStart` | — | `vault-index.sh` |
| `UserPromptSubmit` | — | `session-reminder.json` içeriğini (~500 B) her prompt'a ekler: vault'a bak ve yaz, brief'in son paragrafını tut, kırmızı dışında izin sorma. Uzun oturumda context sıkıştırılsa bile geri gelir. Klasörlü kasada `session-reminder.folders.json` kurulur (MOC'a link ekle). |
| `PreToolUse` | `Edit\|MultiEdit\|Write` | `backup.sh`: var olan dosyanın `<ad>.<yol-checksum>.<zaman>.bak` kopyası. Dosya bir git reposundaysa `<repo kökü>/.backups/`, değilse `~/.claude/saltay-backups/` (sabit klasör için `vault.conf`'ta `SALTAY_BACKUP_DIR`). Her yedek klasörü ilk açılışta kendi `.gitignore`'unu (`*`) yazar. Hiçbir şey silinmez. |
| `PostToolUse` | `Edit\|MultiEdit\|Write` | `secret-scan.sh`: `password/api_key/... = "…"` ya da `"api_key": "…"` atamaları ve bilinen anahtar biçimleri (`sk-ant-`, `ghp_`, `AKIA`, `PRIVATE KEY` …). Bulursa satır numarasını (değeri değil) **exit 2** ile Claude'a verir; Claude değeri env'e taşır. `.env` ve `*.example` atlanır; kasıtlı sahte anahtar içeren satıra `saltay:allow` yaz. |
| `PostToolUse` | `Edit\|MultiEdit\|Write` | `change-log.sh`: `~/.claude/changes.log`'a `[zaman] Araç yol`; 1 MB'ta `changes.<tarih>.log` olur. |
| `PostToolUse` | `Edit\|MultiEdit\|Write\|NotebookEdit\|Bash` | `session-track.sh`: `saltay-state/<oturum>.log`'a `E <yol>` ya da `B` satırı. Her komuttan sonra çalıştığı için alt süreç açmaz. |
| `Stop` | — | `journal-reminder.sh`: son sıfırlama noktasından beri vault dışında ≥`JOURNAL_MIN_EDITS` (3) düzenleme ya da ≥`JOURNAL_MIN_COMMANDS` (15) komut varsa ve günlüğe (klasörlü kasada `Günlük/Journal/Daily` klasörü, düz kasada vault'un tamamı) hiçbir şey yazılmadıysa **exit 2** ile Claude'dan kısa oturum özeti ya da "günlük gerekmez" ister, sonra sıfırlar. `stop_hook_active` doluysa susar (döngü yok). Kapatmak: `vault.conf`'ta `JOURNAL_REMIND=0`. |

> **Neden `Stop`, neden `SessionEnd` değil:** `SessionEnd` çalıştığında oturum bitmiştir, Claude'a bir şey
> yaptırılamaz. `Stop` her cevabın sonunda tetiklenir; hatırlatıcı bu yüzden eşik ve sıfırlama noktasıyla
> çalışır: iş parçası başına bir kez, yalnız gerçek iş olduysa.

> v1.1'e kadar stderr + exit 0 ile basılan sır uyarısı **modele hiç ulaşmıyordu**: Claude Code exit 0'daki
> stderr'i yalnız transcript'te gösterir. Modelin görmesi gereken her hook mesajı exit 2 (ya da JSON
> `additionalContext`) ile verilmeli.

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
