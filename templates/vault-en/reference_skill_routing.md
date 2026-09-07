---
name: Skill routing — tier-based decision guide
description: When a task arrives, which skill to CALL / STOP AND THINK / SKIP. Value-based, not the defensive "call it if it exists". The decision is always visible to the user.
type: reference
priority: critical
---

# Skill Routing — Tier Guide

> First question when a task arrives: *"Will I actually use this skill's output?"*
> **Yes, I need specific knowledge** → Tier 1, CALL. **Maybe** → Tier 2, say the decision.
> **No, it's already in training** → Tier 3, SKIP + say why.
> Both directions are legitimate. **A silent call or a silent skip is forbidden.**

## TIER 1 — CALL IMMEDIATELY (the skill produces specific value)

| Task | Skill type | Why |
|---|---|---|
| Frontend design, pages, components | design / frontend-design skill | Brakes the model's drift into "AI aesthetic" defaults |
| Word / Excel / PowerPoint / PDF output | docx / xlsx / pptx / pdf skills | Real tooling, cannot be done by hand |
| Version-specific framework knowledge | nextjs / tailwind / supabase / claude-api | Updates the training cutoff (v4, v15 …) |
| Vault cleanup / consolidation | memory consolidation skill | Systematic; by hand it gets messy |
| File organisation on the machine | file-organizer | Systematic |
| Multi-step code plan | writing-plans | Plan discipline |

**Rule:** skipping a skill in these categories = quality loss. If the user installed them, respect the investment.

## TIER 2 — STOP AND THINK (depends)

| Task | Skill | Call criterion |
|---|---|---|
| Code review | code-reviewer | If a human-eye final read is wanted; a spot check is fine raw |
| Security audit | security / pentest skills | If a systematic checklist is needed |
| Complex debugging | systematic-debugging | Multi-layer bugs |
| Writing tests | test-driven-development | If building TDD discipline |
| SEO | seo-audit | SEO-focused tasks |
| DB schema | database-design | New schemas |

## TIER 3 — SKIP (say it, don't be silent)

Generic "senior-X" / "clean-code" / "best-practices" skills. The content is already in training data;
calling them fills the context with dead weight.

**Skip formula (must be said):**
> *"Skill check: there is a table match for this task (`senior-backend`) but the content is generic. Skipping, doing it raw."*

## Signal vs Noise — honest calibration

- **SIGNAL:** version correctors (framework skills) · design calibration · file deliverable skills · MCPs · the vault.
- **NOISE SHELF (keep, don't rely on):** generic skills · most agents (for solo work: "me with a sticky note") · hooks are not capability, they are safety + reminders.
- **Design multiplier = model taste × the user's clear brief/reference × iteration.** A skill raises the *floor* (prevents bad), not the *ceiling*. For better design invest in a clear brief + strong reference + 2–3 rounds of iteration, not in more skills.

## Anti-patterns

❌ "It's in the table, I'll call it" (without asking what it adds) · ❌ silent call · ❌ silent skip ·
❌ calling a Tier 3 skill and using 5 % of its output · ❌ skipping a Tier 1 skill and writing raw.

✅ Tier 1: CALL + reason · ✅ Tier 2: SAY the decision · ✅ Tier 3: SKIP + reason.

## Installation rule

Skills / agents / commands / hooks / rules are **always installed globally** (`~/.claude/…` or the vault).
Anything written into the working directory's `.claude/` silently disappears when the folder changes.
`npx skills add` → the `-g` flag. Exception: the user explicitly says "project-only", or the file is
genuinely project-specific (`launch.json`).
