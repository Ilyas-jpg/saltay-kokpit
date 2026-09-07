---
name: HANDOFF_<project> — session-to-session handoff
description: "A new session on <project> STARTS HERE: status, runbook, deploy, never-again list. The operational twin of the project_ note for long/active projects."
type: project
priority: normal
---

# HANDOFF — <Project> (YYYY-MM-DD)

## Status: 🟢 LIVE / 🟡 IN DEVELOPMENT / ⚫ CLOSED — <one line>

<What works right now, what doesn't. Last verified version/bundle/commit. Whose approval was obtained.>

## Runbook (operations)

- **Health check:** `curl -s -o /dev/null -w "%{http_code}\n" https://…`
- **Logs:** <where, how to read>
- **Under load / in a crisis:** <one-command buttons>

## Deploy (⚠️ important — never deploy by a path not written here)

- **Frontend:** `<command>`
- **Backend:** `<command>`
- **Backup:** <what is backed up before deploy, where>
- **Rollback:** <the way back — should be one command>

## NEVER AGAIN (things that happened in this project)

- <mistake> → <rule> (link the [[feedback_...]] if one exists)

## Open items (by priority)

1.
2.

## Related

[[project_<project>]] · [[reference_...]] · [[note_decisions]]
