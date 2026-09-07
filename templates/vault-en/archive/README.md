# archive/ — Stale Note Archive

The vault index (`SessionStart` hook) lists **only the vault root**. Notes in here do not appear in the
index, but **Grep searches still find them** and Obsidian wiki-links (`[[name]]`) keep working.
**No deletion** — only reversible moves.

**When to move here:** when the index compression warning shows level ≥4; closed incident/maintenance
notes and projects untouched for 3+ months.

**Move protocol:**
1. Pick candidates (closed dated `note_` entries + dormant `project_` notes). `mtime` alone is not proof
   of death — read each candidate's `description`; leave umbrella / live / reusable notes alone.
2. `mv <file>.md archive/` + add a section to the manifest below + put 📦 next to the link in `MEMORY.md`.
3. Measure `bash ~/.claude/hooks/vault-index.sh | wc -c` — confirm it is back under budget.

**Restore (single file):**
```
mv <vault>/archive/<file>.md <vault>/
```

---

## Manifest

### YYYY-MM-DD — <reason> (<N> files)
- <file>.md (<why archived>)
