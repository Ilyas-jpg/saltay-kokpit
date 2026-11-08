#!/usr/bin/env python3
"""saltay-kokpit · scripts/merge-settings.py
Python twin of merge-settings.js for machines without node. Same arguments:

  python3 merge-settings.py <settings.json> <block.json> [remove.json] [--home DIR] [--uninstall]

See merge-settings.js for what each argument does.
"""
import json
import os
import re
import sys

args = sys.argv[1:]
home = None
uninstall = False
pos = []
i = 0
while i < len(args):
    if args[i] == "--home":
        home = args[i + 1]
        i += 2
        continue
    if args[i] == "--uninstall":
        uninstall = True
    else:
        pos.append(args[i])
    i += 1

if len(pos) < 2:
    print("usage: merge-settings.py <settings.json> <block.json> [remove.json] [--home DIR] [--uninstall]")
    sys.exit(1)
settings_path, block_path = pos[0], pos[1]
remove_path = pos[2] if len(pos) > 2 else None


def read_json(p):
    if not p or not os.path.exists(p):
        return {}
    with open(p, encoding="utf-8-sig") as f:
        raw = f.read()
    return json.loads(raw) if raw.strip() else {}


def fill(s, h=None):
    h = h or home
    return s.replace("__CLAUDE_HOME__", h) if h and isinstance(s, str) else s


# Windows: the same folder is /c/Users/x in Git Bash and C:/Users/x for native
# programs; v1.1 wrote the /c/ form, so removal matches both spellings.
def home_forms():
    if not home:
        return [None]
    forms = [home]
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", home)
    if m:
        forms.append("/" + m.group(1).lower() + "/" + m.group(2).replace("\\", "/"))
    m = re.match(r"^/([A-Za-z])/(.*)$", home)
    if m:
        forms.append(m.group(1).upper() + ":/" + m.group(2))
    return forms


st = read_json(settings_path)
add = read_json(block_path)
rm = read_json(remove_path)

gone = {}
for ev, cmds in rm.items():
    if ev.startswith("_") or not isinstance(cmds, list):
        continue
    for c in cmds:
        for hf in home_forms():
            gone.setdefault(ev, set()).add(fill(c, hf))
for ev, groups in add.get("hooks", {}).items():
    for g in groups:
        for h in g.get("hooks", []):
            # uninstall: every spelling; install: only the OTHER spellings (no duplicates on reinstall)
            for hf in (home_forms() if uninstall else home_forms()[1:]):
                gone.setdefault(ev, set()).add(fill(h.get("command"), hf))

st.setdefault("hooks", {})
removed = 0
for ev, cmds in gone.items():
    if not isinstance(st["hooks"].get(ev), list):
        continue
    kept_groups = []
    for g in st["hooks"][ev]:
        hooks = g.get("hooks")
        if not isinstance(hooks, list):
            kept_groups.append(g)
            continue
        keep = [h for h in hooks if h.get("command") not in cmds]
        removed += len(hooks) - len(keep)
        if keep:
            kept_groups.append({**g, "hooks": keep})
    if kept_groups:
        st["hooks"][ev] = kept_groups
    else:
        del st["hooks"][ev]

added = 0
if not uninstall:
    if add.get("env"):
        st["env"] = {**st.get("env", {}), **add["env"]}
    for ev, groups in add.get("hooks", {}).items():
        st["hooks"].setdefault(ev, [])
        existing = {h.get("command") for g in st["hooks"][ev] for h in g.get("hooks", [])}
        for grp in groups:
            fresh = [{**h, "command": fill(h.get("command"))} for h in grp.get("hooks", [])]
            fresh = [h for h in fresh if h["command"] not in existing]
            if fresh:
                st["hooks"][ev].append({**grp, "hooks": fresh})
                added += len(fresh)
if not st["hooks"]:
    del st["hooks"]

tmp = settings_path + ".saltay-tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(st, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, settings_path)
print(f"  hooks removed: {removed}" if uninstall else f"  hooks added: {added}, old hooks removed: {removed}")
