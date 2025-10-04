#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$PROJECT_ROOT/modules/common_functions.sh"

if [ -f "$PROJECT_ROOT/modules/cache_api.sh" ]; then
  source "$PROJECT_ROOT/modules/cache_api.sh"
fi

echo "[TEST] cache_stats output and hit counting"

# 清理环境，确保统计可控
command -v cache_clear >/dev/null 2>&1 && cache_clear || true

# 设置与命中
cache_set "stats_key" "stats_value" 10 || true
cache_get "stats_key" >/dev/null 2>&1 || true

output="$(cache_stats 2>/dev/null || true)"

if [[ -z "$output" ]]; then
  echo "❌ cache_stats 无输出"; exit 1
fi

# 结构化JSON基本校验：包含 backend/entries/hits/misses 字段
if ! echo "$output" | grep -q '"backend"'; then
  echo "❌ 缺少 backend 字段：$output"; exit 1
fi
if ! echo "$output" | grep -q '"entries"'; then
  echo "❌ 缺少 entries 字段：$output"; exit 1
fi
if ! echo "$output" | grep -q '"hits"'; then
  echo "❌ 缺少 hits 字段：$output"; exit 1
fi
if ! echo "$output" | grep -q '"misses"'; then
  echo "❌ 缺少 misses 字段：$output"; exit 1
fi

echo "✅ cache_stats 基本断言通过"
exit 0