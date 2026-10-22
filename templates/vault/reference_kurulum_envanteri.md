---
name: Kurulum envanteri — skill, agent, komut, plugin, MCP, hook
description: ~/.claude altında ne kurulu, nasıl sayılır, oturum başı yük nasıl ölçülür, hook sözleşmesi. CLAUDE.md'ye sayı yazılmaz (bayatlar); güncel liste komutla alınır, bu not yalnız komutları ve kararları tutar.
type: reference
created: {{INSTALL_DATE}}
---

# Kurulum envanteri

> Anayasada (CLAUDE.md) sayı ve envanter durmaz: her oturumda yüklenir ve ilk kurulumda bayatlar.
> Burada yalnız **sayma komutları**, **oturum başı yük ölçümü** ve **neyin neden kurulduğu / kaldırıldığı** durur.

## Say (sayıyı buraya yazma, komutla al)

```bash
ls ~/.claude/skills | wc -l                    # skill
ls ~/.claude/agents | wc -l                    # agent
ls ~/.claude/commands | wc -l                  # slash komutu
claude mcp list                                # MCP: her satır gerçekten bağlanıyor mu?
grep -c '"command"' ~/.claude/settings.json    # kayıtlı hook komutu
```

## Oturum başı yükü ölç (ayda bir ve her yeni model neslinde)

Kullanıcı tek kelime yazmadan her oturuma yüklenen her şey bağlam yer ve davranışı etkiler. Kuralların
değil, bu yükün çelişmesi daha sık görülür (örn. "karar noktasında dur, kodu kullanıcıya yazdır" diyen
bir output style ile "izin sorma" diyen anayasa aynı anda yüklü).

| Kaynak | Nasıl ölçülür | Hedef |
|---|---|---|
| CLAUDE.md | `wc -c ~/.claude/CLAUDE.md` | ≤ 12 KB |
| Vault index | `bash ~/.claude/hooks/vault-index.sh \| wc -c` | < 9.500 B |
| Prompt hatırlatıcısı | `wc -c ~/.claude/session-reminder.json` | ~500 B (her prompt'ta gelir) |
| Output style / plugin'ler | `settings.json` → `enabledPlugins`, seçili output style | Anayasayla çelişen yok |
| Agent tanımları | `ls ~/.claude/agents` | Kullanmadığın agent yok (her oturuma açıklaması yüklenir) |
| MCP | `claude mcp list` | Ölü, çift ya da placeholder'lı yok |

## Hook sözleşmesi

- Hook'lar dosya yolunu **stdin JSON**'dan alır (`hooks/hook-meta.sh`); ortam değişkenleri bir sürümde boş gelmişti.
- Hook çıktısı ~10.000 karakteri aşarsa model yalnız 2 KB önizleme görür; index hook'u kendini ölçer.

## Kurulu / kaldırılan (tarihli)

| Tarih | Ne | Neden |
|---|---|---|
| {{INSTALL_DATE}} | saltay-kokpit v1.1 | vault + anayasa + hook'lar |
