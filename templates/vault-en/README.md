# Vault — the shared memory of you + Claude

This folder is both an **Obsidian vault** and the **persistent knowledge pool** Claude reads and writes
in every session. Claude Code starts every session from zero by default; this vault is the antidote.

- You stop re-explaining "who I am, which server, which preference" every time.
- Claude remembers past decisions, corrections and account pointers.
- Whatever folder the session opens in, the vault is active — the `SessionStart` hook injects its index.

## Folder layout (flat — Obsidian links matter more than folders)

```
MEMORY.md                  → Rich index. Read in Obsidian; one line per note.
README.md                  → This file.
user_profile.md            → Who you are, how you want to work (living document, keeps growing)
personal_<topic>.md        → Personal context (family, people, health, plans) — optional
feedback_<topic>.md        → Correction/preference: Rule + Why + How to apply (BINDING)
reference_<topic>.md       → Servers, accounts, panels, standards, brand
project_<name>.md          → Each project's context, decisions, status
HANDOFF_<name>.md          → Session-to-session handoff (runbook, deploy, "never again")
note_<topic>.md            → Decision log, incidents, audits, learnings
archive/                   → Stale notes (outside the index; Grep still finds them; reversible)
```

The prefixes are not cosmetic: the hook groups names by prefix and **never trims `feedback_` names at
any compression level** — they are behaviour rules.

## Writing rules (for Claude)

Every file needs YAML frontmatter:

```yaml
---
name: Short title
description: One line — answers "what is this note for" in a future session (shown in the index)
type: user | feedback | project | reference | note | personal
---
```

Use wiki-links: `[[other-note]]`. Write the source and the date. Quote the user's own sentence — the
"why" of a rule is usually that sentence.

## Never written here

- Temporary task details (an in-session todo is enough)
- Code conventions (the code is readable)
- Git history (git log exists)
- One-time tokens, short-lived in-session secrets

**Quality gate:** a one-second test before writing — *"will I search for this in a task three months
from now?"* If not, don't write it. Name / project / decision / preference / access / relationship = always yes.

## Opening in Obsidian

Obsidian → *Open folder as vault* → this folder. No special settings; `.obsidian/` appears by itself.
