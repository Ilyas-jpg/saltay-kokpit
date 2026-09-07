// saltay-kokpit · scripts/merge-settings.js
// Merges a hook block (hooks/settings.hooks.json, placeholders replaced) into an
// existing ~/.claude/settings.json without duplicating commands that are already there.
// Usage: node merge-settings.js <settings.json> <hooks.json>
const fs = require("fs");
const [settingsPath, hooksPath] = process.argv.slice(2);
if (!settingsPath || !hooksPath) {
  console.error("usage: node merge-settings.js <settings.json> <hooks.json>");
  process.exit(1);
}
const st = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
const add = JSON.parse(fs.readFileSync(hooksPath, "utf8"));

st.env = Object.assign({}, st.env || {}, add.env || {});
st.hooks = st.hooks || {};

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
console.log(`  hooks added: ${added}`);
