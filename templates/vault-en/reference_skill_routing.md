---
name: Skill routing — when to call, when not to
description: The table behind K4. A skill is not a default; call it only if it gives knowledge I don't have that is specific to the job or the version. General-advice skills are not called; if a skill's advice conflicts with a vault rule, the vault wins.
type: reference
priority: critical
---

# Skill Routing

> **One question:** *does this skill give me knowledge I don't have that is specific to the job or the version?*
> Yes → call it, say so in one sentence. No → don't call it, don't narrate.
>
> **Changed in v1.1:** v1.0's "call the Tier 1 design skill, state the decision in every task" rule was
> removed. Two reasons: (1) skills written for older models are prescriptive and pull a strong model into
> a narrow mould; half of one design skill's advice was exactly the "AI tells" the author's vault bans;
> (2) the "skill check: skipping because…" paragraph added noise to every answer.

## Call (carries specific knowledge)

| Job | Skill type | Why |
|---|---|---|
| Creating and editing Word / Excel / PowerPoint / PDF | docx / xlsx / pptx / pdf | Real tooling; can't be done by hand |
| Version-specific API or framework | claude-api, nextjs, tailwind v4, supabase … | Updates the training cutoff |
| A pipeline or process you wrote yourself | video pipeline, document production, deploy runbook | A process, not advice; carries machine-specific paths and traps |
| Writing plugins / hooks / extensions | the relevant official skill | The contract depends on the version |
| Systematic file organisation | file-organizer | Hundreds of files at once |

## Don't call (general advice; it's in training, and your vault holds the newer version)

| Job | Why |
|---|---|
| Design taste, "premium UI", aesthetic guides | First the design rules in your vault + real references + render-look-fix; a skill only for a concrete gap |
| senior-X, clean-code, best practice, code review, debugging, TDD, planning rituals | A strong model does these by default; the skill fills the context with dead weight |
| Corporate "bundle" packs (sales, legal, finance …) | Turn them off if unrelated to your work: they load descriptions into every session |

## Rules

- If a loaded skill's advice conflicts with a vault rule, the vault wins; that part of the skill is not applied.
- If a skill makes the output worse, tell the user and write its name in this file.
- Combine several skills only when each adds a separate layer of knowledge.

## Signal vs noise — honest calibration

- **Signal:** version correctors · file-output tooling · your own process skills · MCPs · the vault.
- **Noise:** generic skills · most agents for solo work · hooks (not capability, safety + reminders) ·
  plugins (packaging; their value is the MCP or skill inside).
- **Quality multiplier = model × a clear brief / strong reference × iteration.** For better output, invest
  in the brief, the reference and 2-3 rounds of iteration, not in more skills.

## Installation rule

Skills / agents / commands / hooks / rules are **always installed globally** (`~/.claude/…` or the
vault). Anything written into the working directory's `.claude/` silently disappears when the folder
changes. `npx skills add` → `-g`; afterwards `test -d ~/.claude/skills/<name>`. Exception: the file is
genuinely project-specific (`launch.json`).
