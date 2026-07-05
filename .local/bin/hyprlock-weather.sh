#!/usr/bin/env bash
# Outputs just the weather "text" field for hyprlock's weather label.
# Called by absolute path from hyprlock (its cmd env has a minimal PATH).
export PATH="$HOME/.local/bin:/usr/bin:/bin"
"$HOME/.local/bin/hyde-shell" weather.py 2>/dev/null \
  | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("text", ""))
except Exception:
    pass' 2>/dev/null
