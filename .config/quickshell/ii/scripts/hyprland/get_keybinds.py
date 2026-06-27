#!/usr/bin/env python3
"""
Fetch Hyprland keybinds via `hyprctl binds -j` and output structured JSON
for the QuickShell CheatsheetKeybinds component.

Output format:
  {
    "children": [
      { "children": [ { "name": "Category", "keybinds": [ { "mods": [...], "key": "...", "comment": "..." } ] }, ... ] },
      { "children": [ ... ] }
    ]
  }
"""

import json
import subprocess
import sys


def modmask_to_list(modmask: int) -> list:
    # Order matches CheatsheetKeybindsCategory.qml: Ctrl, Super, Shift, Alt, ...
    result = []
    if modmask & (1 << 2): result.append("Ctrl")
    if modmask & (1 << 6): result.append("Super")
    if modmask & (1 << 0): result.append("Shift")
    if modmask & (1 << 3): result.append("Alt")
    if modmask & (1 << 1): result.append("Caps")
    if modmask & (1 << 4): result.append("Mod2")
    if modmask & (1 << 5): result.append("Mod3")
    if modmask & (1 << 7): result.append("Mod5")
    return result


EMPTY = {"children": [{"children": []}, {"children": []}]}

try:
    proc = subprocess.run(
        ["hyprctl", "binds", "-j"],
        capture_output=True, text=True, timeout=5
    )
    binds = json.loads(proc.stdout)
except Exception as e:
    print(json.dumps(EMPTY), file=sys.stderr)
    print(json.dumps(EMPTY))
    sys.exit(0)

# Group by category (description prefix before ":")
category_order = []
category_map = {}

for bind in binds:
    desc = bind.get("description", "").strip()
    if not desc or "[hidden]" in desc:
        continue

    key = bind.get("key", "")
    modmask = bind.get("modmask", 0)

    if ":" in desc:
        colon = desc.index(":")
        category = desc[:colon].strip()
        comment = desc[colon + 1:].strip()
    else:
        category = "General"
        comment = desc

    if category not in category_map:
        category_map[category] = []
        category_order.append(category)

    category_map[category].append({
        "mods": modmask_to_list(modmask),
        "key": key,
        "comment": comment,
    })

sections = [
    {"name": cat, "keybinds": category_map[cat]}
    for cat in category_order
    if category_map.get(cat)
]

num_cols = 4
n = len(sections)
base, remainder = divmod(n, num_cols)
cols = []
idx = 0
for i in range(num_cols):
    size = base + (1 if i < remainder else 0)
    cols.append({"children": sections[idx:idx + size]})
    idx += size

print(json.dumps({"children": cols}))
