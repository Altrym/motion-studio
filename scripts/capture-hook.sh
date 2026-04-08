#!/usr/bin/env bash
# Motion Studio post-session hook — captures animation project diffs silently
# Install in ~/.claude/settings.json under hooks.Stop
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
bash "$SKILL_DIR/scripts/sync.sh" capture > /dev/null 2>&1 &
