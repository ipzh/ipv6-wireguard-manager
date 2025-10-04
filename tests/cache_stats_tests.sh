#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$PROJECT_ROOT/modules/common_functions.sh"

if [ -f "$PROJECT_ROOT/modules/cache_api.sh" ]; then
  source "$PROJECT_ROOT/modules/cache_api.sh"
fi

echo "[TEST] cache_stats output and jq-based numeric assertions"

# 清理环境，确保统计可控
command -v cache_clear >/dev/null 2>&1 && cache_clear || true

# 设置与命中
cache_set "stats_key" "stats_value" 10 || true
cache_get "stats_key" >/dev/null 2>&1 || true

output="$(cache_stats 2>/dev/null || true)"

if [[ -z "$output" ]]; then
  echo "❌ cache_stats 无输出"; exit 1
fi

# 需要 jq 进行严格断言
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ 依赖缺失：jq 未安装"; exit 1
fi

# 基本字段存在性检查
for field in backend entries hits misses; do
  if ! echo "$output" | jq -e ". | has(\"$field\")" >/dev/null; then
    echo "❌ 缺少 $field 字段：$output"; exit 1
  fi
done

# 数值字段类型与范围检查（允许为 null）
check_numeric_or_null() {
  local field="$1"
  local type
  type=$(echo "$output" | jq -r "if .${field} == null then \"null\" else (.${field} | type) end")
  if [[ "$type" != "number" && "$type" != "null" ]]; then
    echo "❌ 字段 ${field} 类型无效（需 number 或 null）：$type"; exit 1
  fi
}

check_numeric_or_null entries
check_numeric_or_null hits
check_numeric_or_null misses
check_numeric_or_null evictions
check_numeric_or_null total_size

# 命中率范围检查（0 ≤ hit_rate ≤ 1，允许 null）
hit_rate_type=$(echo "$output" | jq -r 'if .hit_rate == null then "null" else (.hit_rate | type) end')
if [[ "$hit_rate_type" == "number" ]]; then
  valid=$(echo "$output" | jq -r '(.hit_rate >= 0) and (.hit_rate <= 1)')
  if [[ "$valid" != "true" ]]; then
    echo "❌ hit_rate 超出范围：$output"; exit 1
  fi
elif [[ "$hit_rate_type" != "null" ]]; then
  echo "❌ 字段 hit_rate 类型无效（需 number 或 null）：$hit_rate_type"; exit 1
fi

echo "✅ cache_stats 严格断言通过"
exit 0