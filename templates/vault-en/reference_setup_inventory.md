---
name: Setup inventory — skills, agents, commands, plugins, MCP, hooks
description: What is installed under ~/.claude, how to count it, how to measure the session-start load, the hook contract. No numbers in CLAUDE.md (they go stale); the current list comes from commands, this note keeps only the commands and the decisions.
type: reference
created: {{INSTALL_DATE}}
---

# Setup inventory

> No numbers or inventory in the constitution (CLAUDE.md): it loads in every session and goes stale with
> the first install. This note keeps only the **counting commands**, the **session-start load
> measurement** and **what was installed / removed and why**.

## Count (don't write the number here, get it from a command)

```bash
ls ~/.claude/skills | wc -l                    # skills
ls ~/.claude/agents | wc -l                    # agents
ls ~/.claude/commands | wc -l                  # slash commands
claude mcp list                                # MCP: does every line really connect?
grep -c '"command"' ~/.claude/settings.json    # registered hook commands
```

## Measure the session-start load (monthly, and with every new model generation)

Everything loaded into every session before the user types a word takes context and steers behaviour.
Conflicts in this load are more common than conflicts in the rules (e.g. an output style saying "stop at
decision points, let the user write the code" loaded next to a constitution saying "never ask for permission").

| Source | How to measure | Target |
|---|---|---|
| CLAUDE.md | `wc -c ~/.claude/CLAUDE.md` | ≤ 12 KB |
| Vault index | `bash ~/.claude/hooks/vault-index.sh \| wc -c` | < 9,500 B |
| Prompt reminder | `wc -c ~/.claude/session-reminder.json` | ~500 B (arrives with every prompt) |
| Output style / plugins | `settings.json` → `enabledPlugins`, the selected output style | Nothing that contradicts the constitution |
| Agent definitions | `ls ~/.claude/agents` | No agent you don't use (each description loads into every session) |
| MCP | `claude mcp list` | No dead, duplicate or placeholder servers |

## Hook contract

- Hooks read the file path from **stdin JSON** (`hooks/hook-meta.sh`); the environment variables once arrived empty after a release.
- If a hook's output exceeds ~10,000 characters the model sees only a 2 KB preview; the index hook measures itself.

## Installed / removed (dated)

| Date | What | Why |
|---|---|---|
| {{INSTALL_DATE}} | saltay-kokpit v1.1 | vault + constitution + hooks |
