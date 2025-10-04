#!/usr/bin/env bash

# 简单的统一缓存 API 单元测试
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$PROJECT_ROOT/modules/common_functions.sh"

if [ -f "$PROJECT_ROOT/modules/cache_api.sh" ]; then
  source "$PROJECT_ROOT/modules/cache_api.sh"
else
  echo "cache_api.sh not found"; exit 1
fi

echo "[TEST] cache_set/get/invalidate"
cache_set "unit_key" "unit_value" 2
val="$(cache_get "unit_key")"
if [[ "$val" != "unit_value" ]]; then
  echo "❌ cache_get returned unexpected value: $val"; exit 1
fi

cache_invalidate "unit_key"
if cache_get "unit_key" >/dev/null 2>&1; then
  echo "❌ cache_invalidate did not remove key"; exit 1
fi

echo "✅ cache_api basic operations passed"

echo "[TEST] TTL expiration"
cache_set "ttl_key" "ttl_value" 1
sleep 2
if cache_get "ttl_key" >/dev/null 2>&1; then
  echo "❌ TTL expiration failed"; exit 1
fi

echo "✅ TTL expiration passed"

exit 0