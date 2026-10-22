// saltay-kokpit · scripts/merge-settings.js
// Merges a hook block (hooks/settings.hooks.json, placeholders replaced) into an
// existing ~/.claude/settings.json without duplicating commands that are already there.
// Optional third file (hooks/settings.remove.json): commands an older release registered
// and this one replaces; they are removed first, by exact command match.
// Usage: node merge-settings.js <settings.json> <hooks.json> [remove.json]
const fs = require("fs");
const [settingsPath, hooksPath, removePath] = process.argv.slice(2);
if (!settingsPath || !hooksPath) {
  console.error("usage: node merge-settings.js <settings.json> <hooks.json> [remove.json]");
  process.exit(1);
}
const st = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
const add = JSON.parse(fs.readFileSync(hooksPath, "utf8"));
const rm = removePath ? JSON.parse(fs.readFileSync(removePath, "utf8")) : {};

st.env = Object.assign({}, st.env || {}, add.env || {});
st.hooks = st.hooks || {};

let removed = 0;
for (const ev of Object.keys(rm)) {
  if (ev.startsWith("_") || !Array.isArray(rm[ev]) || !Array.isArray(st.hooks[ev])) continue;
  const gone = new Set(rm[ev]);
  let hit = 0;
  st.hooks[ev] = st.hooks[ev].filter((g) => {
    if (!Array.isArray(g.hooks)) return true;
    const keep = g.hooks.filter((h) => !gone.has(h.command));
    if (keep.length === g.hooks.length) return true;
    hit += g.hooks.length - keep.length;
    g.hooks = keep;
    return keep.length > 0;
  });
  removed += hit;
  if (hit && st.hooks[ev].length === 0) delete st.hooks[ev];
}

let added = 0;
for (const ev of Object.keys(add.hooks || {})) {
  st.hooks[ev] = st.hooks[ev] || [];
  const existing = new Set();
  for (const g of st.hooks[ev]) for (const h of g.hooks || []) existing.add(h.command);
  for (const grp of add.hooks[ev]) {
    const fresh = (grp.hooks || []).filter((h) => !existing.has(h.command));
    if (fresh.length) {
      st.hooks[ev].push(Object.assign({}, grp, { hooks: fresh }));
      added += fresh.length;
    }
  }
}
fs.writeFileSync(settingsPath, JSON.stringify(st, null, 2) + "\n");
console.log(`  hooks added: ${added}` + (removePath ? `, old hooks removed: ${removed}` : ""));
