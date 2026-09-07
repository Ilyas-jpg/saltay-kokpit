---
name: reference_<topic> — <server / account / panel / standard>
description: <What it is looked up for: "SSH aliases", "hosting panel + API", "brand colours", "document code standard">
type: reference
last_updated: YYYY-MM-DD
---

# <Topic>

> A reference note = **"where to look, how to access, which rule applies"**. Tables, not prose.

## Access

| Thing | Value / path | Note |
|---|---|---|
| Panel | https://… | |
| SSH | `ssh <alias>` (`~/.ssh/config`) | |
| API | | token → credentials note |

## Where the secrets are

Secrets are **not** in this file. If you keep a single `reference_credentials.md` in the vault, keep it
**out of git**; a password manager is better. Telling Claude "the password is in 1Password under X" works too.

## Known traps (about this system)

- <e.g. "LiteSpeed cache — version CSS with ?v=N after changes">
- <e.g. "panel API has no filter parameter; bulk-delete risk">

## Related

[[user_profile]] · [[project_...]]
