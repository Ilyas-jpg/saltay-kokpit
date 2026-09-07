---
name: Decision log
description: Important decisions about work / projects / infrastructure, chronological — the answer to "why did we do it this way?"
type: note
---

# Decisions — chronological

When a new decision arrives, add it **at the top** with its date. Format: what was decided · why · what
was deliberately left out · impact. Quote the user's own sentence — it ends the future "who asked for this?".

---

## YYYY-MM-DD — <Decision title>

<What the user said — quote.>

**Decision:** <what was done / dropped>
**Reason:** <rationale>
**Out of scope:** <deliberately not done — prevents the later "why is this missing?">
**Impact / action:** <what changed, who does what>

Details: [[project_...]]

---

## {{INSTALL_DATE}} — saltay-kokpit installed

Vault + constitution + hooks bound to a single source. Permanent knowledge is written only to the vault;
Claude Code's working-directory-bound auto-memory folder is not used (it is lost when the folder changes).
Details: `~/.claude/CLAUDE.md` → Memory Protocol.
