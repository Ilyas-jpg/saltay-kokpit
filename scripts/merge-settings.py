#!/usr/bin/env python3
"""saltay-kokpit · scripts/merge-settings.py
Merges a hook block into an existing ~/.claude/settings.json without duplicating
commands that are already there. Optional third file (hooks/settings.remove.json):
commands an older release registered and this one replaces; they are removed first,
by exact command match. Fallback for machines without node.
Usage: python3 merge-settings.py <settings.json> <hooks.json> [remove.json]
"""
import json
import sys

if len(sys.argv) not in (3, 4):
    print("usage: merge-settings.py <settings.json> <hooks.json> [remove.json]")
    sys.exit(1)

settings_path, hooks_path = sys.argv[1], sys.argv[2]
remove_path = sys.argv[3] if len(sys.argv) == 4 else None
with open(settings_path, encoding="utf-8") as f:
    st = json.load(f)
with open(hooks_path, encoding="utf-8") as f:
    add = json.load(f)
rm = {}
if remove_path:
    with open(remove_path, encoding="utf-8") as f:
        rm = json.load(f)

st["env"] = {**st.get("env", {}), **add.get("env", {})}
st.setdefault("hooks", {})

removed = 0
for ev, commands in rm.items():
    if ev.startswith("_") or not isinstance(commands, list) or not isinstance(st["hooks"].get(ev), list):
        continue
    gone = set(commands)
    hit = 0
    kept_groups = []
    for g in st["hooks"][ev]:
        hooks = g.get("hooks")
        if not isinstance(hooks, list):
            kept_groups.append(g)
            continue
        keep = [h for h in hooks if h.get("command") not in gone]
        if len(keep) == len(hooks):
            kept_groups.append(g)
            continue
        hit += len(hooks) - len(keep)
        if keep:
            kept_groups.append({**g, "hooks": keep})
    st["hooks"][ev] = kept_groups
    removed += hit
    if hit and not kept_groups:
        del st["hooks"][ev]

added = 0
for ev, groups in add.get("hooks", {}).items():
    st["hooks"].setdefault(ev, [])
    existing = {h.get("command") for g in st["hooks"][ev] for h in g.get("hooks", [])}
    for grp in groups:
        fresh = [h for h in grp.get("hooks", []) if h.get("command") not in existing]
        if fresh:
            st["hooks"][ev].append({**grp, "hooks": fresh})
            added += len(fresh)

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(st, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(f"  hooks added: {added}" + (f", old hooks removed: {removed}" if remove_path else ""))
