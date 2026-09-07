#!/usr/bin/env python3
"""saltay-kokpit · scripts/merge-settings.py
Merges a hook block into an existing ~/.claude/settings.json without duplicating
commands that are already there. Fallback for machines without node.
Usage: python3 merge-settings.py <settings.json> <hooks.json>
"""
import json
import sys

if len(sys.argv) != 3:
    print("usage: merge-settings.py <settings.json> <hooks.json>")
    sys.exit(1)

settings_path, hooks_path = sys.argv[1], sys.argv[2]
with open(settings_path, encoding="utf-8") as f:
    st = json.load(f)
with open(hooks_path, encoding="utf-8") as f:
    add = json.load(f)

st["env"] = {**st.get("env", {}), **add.get("env", {})}
st.setdefault("hooks", {})

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
print(f"  hooks added: {added}")
