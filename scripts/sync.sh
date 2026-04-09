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
UPDATE_CHECK_FILE="${CACHE_DIR}/.last-update-check"
UPDATE_CHECK_INTERVAL_SECONDS=43200

API="${MOTION_STUDIO_API_URL:-https://motion-studio.up.railway.app}"
KEY="${MOTION_STUDIO_API_KEY:-}"

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
DIM='\033[0;90m'; BOLD='\033[1m'; RESET='\033[0m'
header() { echo -e "\n${BOLD}🎬 Motion Studio${RESET} — $1\n"; }

auth_header() {
  if [ -n "$KEY" ]; then echo "-H" "Authorization: Bearer $KEY"; fi
}

local_skill_version() {
  cat "$SKILL_DIR/VERSION" 2>/dev/null || echo "unknown"
}

fetch_remote_skill_info() {
  curl -sf --max-time 5 "$API/api/skill-version" 2>/dev/null
}

remote_skill_version_from_json() {
  python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null
}

remote_skill_url_from_json() {
  python3 -c "import sys,json; print(json.load(sys.stdin).get('download_url',''))" 2>/dev/null
}

check_for_skill_update() {
  local force="${1:-0}"
  mkdir -p "$CACHE_DIR"

  local now
  now=$(date +%s)

  local last=0
  if [ -f "$UPDATE_CHECK_FILE" ]; then
    last=$(cat "$UPDATE_CHECK_FILE" 2>/dev/null || echo 0)
  fi

  if [ "$force" != "1" ] && [ $((now - last)) -lt "$UPDATE_CHECK_INTERVAL_SECONDS" ]; then
    return 0
  fi

  echo "$now" > "$UPDATE_CHECK_FILE"

  local info
  info=$(fetch_remote_skill_info) || return 0

  local remote_version
  remote_version=$(echo "$info" | remote_skill_version_from_json)
  [ -z "$remote_version" ] && return 0

  local local_version
  local_version=$(local_skill_version)

  if [ "$remote_version" != "$local_version" ]; then
    echo -e "${YELLOW}↻ Skill update available${RESET}"
    echo -e "${DIM}  Local:  $local_version${RESET}"
    echo -e "${DIM}  Remote: $remote_version${RESET}"
    echo -e "${DIM}  Run 'bash scripts/sync.sh update' to install it${RESET}"
  fi
}

cmd_update() {
  header "Updating Motion Studio skill"

  local info
  info=$(fetch_remote_skill_info) || {
    echo -e "${RED}✗ Could not reach the Motion Studio update server${RESET}"
    return 1
  }

  local remote_version download_url local_version
  remote_version=$(echo "$info" | remote_skill_version_from_json)
  download_url=$(echo "$info" | remote_skill_url_from_json)
  local_version=$(local_skill_version)

  if [ -z "$download_url" ]; then
    download_url="$API/download/motion-studio.tgz"
  fi

  if [ -n "$remote_version" ] && [ "$remote_version" = "$local_version" ]; then
    echo -e "${GREEN}✓ Motion Studio is already up to date (${local_version})${RESET}"
    return 0
  fi

  local tmp_dir archive_path unpack_dir
  tmp_dir=$(mktemp -d)
  archive_path="$tmp_dir/motion-studio.tgz"
  unpack_dir="$tmp_dir/unpacked"
  mkdir -p "$unpack_dir"

  curl -fLsS --max-time 30 "$download_url" -o "$archive_path" || {
    rm -rf "$tmp_dir"
    echo -e "${RED}✗ Could not download the Motion Studio bundle${RESET}"
    return 1
  }

  tar -xzf "$archive_path" -C "$unpack_dir" || {
    rm -rf "$tmp_dir"
    echo -e "${RED}✗ Could not unpack the Motion Studio bundle${RESET}"
    return 1
  }

  if [ ! -d "$unpack_dir/motion-studio" ]; then
    rm -rf "$tmp_dir"
    echo -e "${RED}✗ Downloaded archive did not contain motion-studio/${RESET}"
    return 1
  fi

  cp -R "$unpack_dir/motion-studio/." "$SKILL_DIR/"
  chmod +x "$SKILL_DIR"/scripts/*.sh 2>/dev/null || true
  rm -rf "$tmp_dir"

  date +%s > "$UPDATE_CHECK_FILE" 2>/dev/null || true
  echo -e "${GREEN}✓ Motion Studio updated${RESET}"
  if [ -n "$remote_version" ]; then
    echo -e "${DIM}  Version: $remote_version${RESET}"
  fi
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
  check_for_skill_update
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
  check_for_skill_update

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
  check_for_skill_update

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
  check_for_skill_update

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
  update)  cmd_update ;;
  *)
    echo -e "${BOLD}🎬 Motion Studio${RESET}"
    echo ""
    echo "  pull      Get latest community patterns"
    echo "  capture   Classify git diffs & push to API"
    echo "  log       Log a fix: log \"open with the result before the explanation\""
    echo "  stats     Community stats"
    echo "  update    Download and install the latest Motion Studio bundle"
    echo ""
    echo -e "${DIM}  Server: $API${RESET}"
    ;;
esac
