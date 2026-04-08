#!/usr/bin/env bash
# Motion Studio Sync — community learning for animation work
#
# Usage:
#   bash scripts/sync.sh pull                # Get latest community patterns
#   bash scripts/sync.sh capture             # Classify git diffs & push to API
#   bash scripts/sync.sh log "description"   # Push a manual correction to API
#   bash scripts/sync.sh stats               # Show community stats from API

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${HOME}/.cache/motion-studio"

API="${MOTION_STUDIO_API_URL:-https://motion-studio-web-production.up.railway.app}"
KEY="${MOTION_STUDIO_API_KEY:-}"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
DIM='\033[0;90m'; BOLD='\033[1m'; RESET='\033[0m'
header() { echo -e "\n${BOLD}🎬 Motion Studio${RESET} — $1\n"; }

auth_header() {
  if [ -n "$KEY" ]; then echo "-H" "Authorization: Bearer $KEY"; fi
}

flush_cache() {
  if [ ! -d "$CACHE_DIR" ] || [ -z "$(ls -A "$CACHE_DIR"/*.json 2>/dev/null)" ]; then
    return 0
  fi

  echo -e "${DIM}  Flushing cached offline corrections...${RESET}"
  for f in "$CACHE_DIR"/*.json; do
    curl -sf --max-time 10 -X POST \
      -H "Content-Type: application/json" \
      $(auth_header) \
      -d @"$f" \
      "$API/api/corrections" > /dev/null 2>&1 && rm "$f" && echo -e "${DIM}    ✓ flushed $(basename "$f")${RESET}" || true
  done
}

cmd_pull() {
  header "Pulling community animation patterns"
  flush_cache

  local response
  response=$(curl -sf --max-time 10 \
    -H "Content-Type: application/json" \
    $(auth_header) \
    "$API/api/patterns" 2>/dev/null) || {
    echo -e "${YELLOW}⚠ Server unreachable. Using seed patterns from references/animation-patterns.md${RESET}"
    echo -e "${DIM}  Set MOTION_STUDIO_API_URL and MOTION_STUDIO_API_KEY in your environment${RESET}"
    return 0
  }

  local count
  count=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('pattern_count',0))" 2>/dev/null || echo "?")
  echo -e "${GREEN}✓ $count community animation patterns available${RESET}"

  echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
patterns = data.get('patterns', [])[:5]
for p in patterns:
    cat = p.get('category', '?')
    txt = p.get('pattern', '')[:70]
    conf = p.get('confirmations', 0)
    print(f'  \033[0;90m[{cat}] ×{conf}\033[0m {txt}')
" 2>/dev/null || true
}

cmd_capture() {
  header "Capturing animation corrections from git diffs"

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo -e "${RED}✗ Not in a git repository${RESET}"; return 1
  }

  local extensions="md|txt|json|js|ts|jsx|tsx|html|css|svg|xml|yml|yaml|csv|srt|vtt"
  local modified
  modified=$(cd "$git_root" && git diff --name-only -- . | grep -E "\.($extensions)$" 2>/dev/null) || true

  if [ -z "$modified" ]; then
    echo -e "${DIM}  No modified animation-related files.${RESET}"; return 0
  fi

  local captured=0
  while IFS= read -r file; do
    local diff
    diff=$(cd "$git_root" && git diff -- "$file" 2>/dev/null)
    local lines=$(echo "$diff" | grep -c "^[+-]" 2>/dev/null || echo 0)
    [ "$lines" -lt 3 ] && continue

    echo -e "  📝 $file ($lines changes)"

    local trunc_diff
    trunc_diff=$(echo "$diff" | head -80)

    local payload
    payload=$(python3 -c "
import json,sys
d = sys.stdin.read()
print(json.dumps({'file': '$file', 'diff': d}))
" <<< "$trunc_diff" 2>/dev/null)

    local result
    result=$(curl -sf --max-time 10 -X POST \
      -H "Content-Type: application/json" \
      $(auth_header) \
      -d "$payload" \
      "$API/api/classify" 2>/dev/null) || {
      result=$(python3 "$SKILL_DIR/scripts/classify-local.py" "$file" <<< "$trunc_diff" 2>/dev/null) || {
        echo -e "${YELLOW}    ⚠ Classification failed${RESET}"; continue
      }
      mkdir -p "$CACHE_DIR"
      local ts=$(date +%s)
      echo "{\"corrections\":[{\"file\":\"$file\",\"diff_lines\":$lines,$(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'\"category\":\"{d.get(\"category\",\"general\")}\",\"pattern\":\"{d.get(\"pattern\",\"\")}\"')" 2>/dev/null)}]}" > "$CACHE_DIR/${ts}-${RANDOM}.json"
      echo -e "${YELLOW}    ⚠ Server offline — cached locally${RESET}"
    }

    local is_relevant=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('is_animation_relevant',False))" 2>/dev/null)
    if [ "$is_relevant" = "True" ] || [ "$is_relevant" = "true" ]; then
      local cat=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('category','general'))" 2>/dev/null)
      local pat=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('pattern',''))" 2>/dev/null)
      echo -e "${GREEN}    ✓ [$cat] $pat${RESET}"
      captured=$((captured + 1))
    else
      echo -e "${DIM}    ⏭ Not animation-relevant${RESET}"
    fi
  done <<< "$modified"

  echo -e "\n${GREEN}✓ $captured correction(s) pushed to the animation community${RESET}"
}

cmd_log() {
  local desc="$1"
  header "Logging correction"

  if [ -z "$desc" ]; then
    echo -e "${RED}✗ Usage: bash scripts/sync.sh log \"what you fixed\"${RESET}"; return 1
  fi

  local result
  result=$(curl -sf --max-time 10 -X POST \
    -H "Content-Type: application/json" \
    $(auth_header) \
    -d "{\"description\": \"$desc\"}" \
    "$API/api/classify-text" 2>/dev/null) || {
    echo -e "${YELLOW}⚠ Server unreachable. Cached for later.${RESET}"
    mkdir -p "$CACHE_DIR"
    echo "{\"corrections\":[{\"file\":\"manual\",\"category\":\"general\",\"pattern\":\"$desc\",\"diff_lines\":0}]}" > "$CACHE_DIR/$(date +%s)-${RANDOM}.json"
    return 0
  }

  local cat=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('category','general'))" 2>/dev/null)
  local pat=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('pattern','$desc'))" 2>/dev/null)
  echo -e "${GREEN}✓ [$cat] $pat${RESET}"
}

cmd_stats() {
  header "Community stats"

  local response
  response=$(curl -sf --max-time 10 \
    $(auth_header) \
    "$API/api/stats" 2>/dev/null) || {
    echo -e "${YELLOW}⚠ Server unreachable${RESET}"; return 0
  }

  python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'  Patterns:      \033[1m{d.get(\"total_patterns\",0)}\033[0m')
print(f'  Confirmed:     \033[1m{d.get(\"confirmed_patterns\",0)}\033[0m')
print(f'  Corrections:   \033[1m{d.get(\"total_corrections_received\",0)}\033[0m')
print(f'  Contributors:  \033[1m{d.get(\"unique_contributors\",0)}\033[0m')
print()
cats = d.get('categories', {})
for cat, count in sorted(cats.items(), key=lambda x: -x[1]):
    bar = '█' * min(count, 30)
    print(f'  {cat:<16} {count:>3}  {bar}')
" <<< "$response" 2>/dev/null || echo -e "${DIM}  (requires python3)${RESET}"

  local cached=0
  if [ -d "$CACHE_DIR" ]; then
    cached=$(ls "$CACHE_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [ "$cached" -gt 0 ]; then
    echo -e "\n${YELLOW}  $cached cached correction(s) pending upload${RESET}"
    echo -e "${DIM}  Run 'bash scripts/sync.sh pull' to flush${RESET}"
  fi
}

case "${1:-help}" in
  pull)    cmd_pull ;;
  capture) cmd_capture ;;
  log)     cmd_log "${2:-}" ;;
  stats)   cmd_stats ;;
  *)
    echo -e "${BOLD}🎬 Motion Studio${RESET}"
    echo ""
    echo "  pull      Get latest community patterns"
    echo "  capture   Classify git diffs & push to API"
    echo "  log       Log a fix: log \"open with the result before the explanation\""
    echo "  stats     Community stats"
    echo ""
    echo -e "${DIM}  Server: $API${RESET}"
    ;;
esac
