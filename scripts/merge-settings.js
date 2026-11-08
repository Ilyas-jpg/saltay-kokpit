// saltay-kokpit · scripts/merge-settings.js
// Merges a hook block (hooks/settings.hooks.json) into ~/.claude/settings.json
// without duplicating commands that are already there.
//
// Usage:
//   node merge-settings.js <settings.json> <block.json> [remove.json] [--home DIR] [--uninstall]
//
//   block.json   hooks and/or env to add (hooks/settings.hooks.json, hooks/settings.env.json)
//   remove.json  commands an older release registered (hooks/settings.remove.json);
//                removed first, by exact command match
//   --home DIR   replaces __CLAUDE_HOME__ in every command (after JSON parsing, so a
//                path with spaces, & or | needs no shell escaping)
//   --uninstall  adds nothing; removes every command found in block.json AND remove.json.
//                env is left alone (the user may have set it on purpose).
//
// The settings file is created when missing and written atomically (tmp + rename).
// Python twin for machines without node: merge-settings.py (same arguments).
const fs = require("fs");

const args = process.argv.slice(2);
let home = null;
let uninstall = false;
const pos = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--home") home = args[++i];
  else if (args[i] === "--uninstall") uninstall = true;
  else pos.push(args[i]);
}
const [settingsPath, blockPath, removePath] = pos;
if (!settingsPath || !blockPath) {
  console.error("usage: node merge-settings.js <settings.json> <block.json> [remove.json] [--home DIR] [--uninstall]");
  process.exit(1);
}

const readJson = (p) => {
  if (!p || !fs.existsSync(p)) return {};
  const raw = fs.readFileSync(p, "utf8").replace(/^﻿/, "");
  return raw.trim() ? JSON.parse(raw) : {};
};
const fill = (s, h = home) => (h && typeof s === "string" ? s.split("__CLAUDE_HOME__").join(h) : s);
// On Windows the same folder has two spellings: Git Bash /c/Users/x and C:/Users/x
// (MSYS rewrites /c/... arguments to C:/... when it starts node). v1.1 wrote the
// /c/ form with sed, so removal must match both.
const homeForms = (() => {
  if (!home) return [null];
  const forms = new Set([home]);
  let m = home.match(/^([A-Za-z]):[\\/](.*)$/);
  if (m) forms.add("/" + m[1].toLowerCase() + "/" + m[2].replace(/\\/g, "/"));
  m = home.match(/^\/([A-Za-z])\/(.*)$/);
  if (m) forms.add(m[1].toUpperCase() + ":/" + m[2]);
  return [...forms];
})();

const st = readJson(settingsPath);
const add = readJson(blockPath);
const rm = readJson(removePath);

// commands to remove: { event: Set(command) }
const gone = {};
const mark = (ev, cmd) => { for (const h of homeForms) (gone[ev] = gone[ev] || new Set()).add(fill(cmd, h)); };
for (const ev of Object.keys(rm)) {
  if (ev.startsWith("_") || !Array.isArray(rm[ev])) continue;
  for (const c of rm[ev]) mark(ev, c);
}
for (const ev of Object.keys(add.hooks || {})) {
  for (const g of add.hooks[ev]) for (const h of g.hooks || []) {
    if (uninstall) mark(ev, h.command);
    // install: this release's commands written with the OTHER spelling of the same
    // home folder are replaced too, so a reinstall never leaves duplicates.
    else for (const hf of homeForms.slice(1)) (gone[ev] = gone[ev] || new Set()).add(fill(h.command, hf));
  }
}

st.hooks = st.hooks || {};
let removed = 0;
for (const ev of Object.keys(gone)) {
  if (!Array.isArray(st.hooks[ev])) continue;
  st.hooks[ev] = st.hooks[ev].filter((g) => {
    if (!Array.isArray(g.hooks)) return true;
    const keep = g.hooks.filter((h) => !gone[ev].has(h.command));
    removed += g.hooks.length - keep.length;
    g.hooks = keep;
    return keep.length > 0;
  });
  if (st.hooks[ev].length === 0) delete st.hooks[ev];
}

let added = 0;
if (!uninstall) {
  if (add.env) st.env = Object.assign({}, st.env || {}, add.env);
  for (const ev of Object.keys(add.hooks || {})) {
    st.hooks[ev] = st.hooks[ev] || [];
    const existing = new Set();
    for (const g of st.hooks[ev]) for (const h of g.hooks || []) existing.add(h.command);
    for (const grp of add.hooks[ev]) {
      const fresh = (grp.hooks || [])
        .map((h) => Object.assign({}, h, { command: fill(h.command) }))
        .filter((h) => !existing.has(h.command));
      if (fresh.length) {
        st.hooks[ev].push(Object.assign({}, grp, { hooks: fresh }));
        added += fresh.length;
      }
    }
  }
}
if (Object.keys(st.hooks).length === 0) delete st.hooks;

const tmp = settingsPath + ".saltay-tmp";
fs.writeFileSync(tmp, JSON.stringify(st, null, 2) + "\n");
fs.renameSync(tmp, settingsPath);
console.log(uninstall ? `  hooks removed: ${removed}` : `  hooks added: ${added}, old hooks removed: ${removed}`);
