#!/usr/bin/env bash

# Module: cache_api
# Version: 1.0.0
# Depends: common_functions, enhanced_cache_system, smart_caching, config_cache

set -euo pipefail

# 统一缓存API封装，规范跨模块的缓存使用入口，避免绕过底层实现。

# 清理可能存在的同名别名，确保函数生效
unalias cache_set 2>/dev/null || true
unalias cache_get 2>/dev/null || true
unalias cache_exec 2>/dev/null || true
unalias cache_stats 2>/dev/null || true
unalias cache_clear 2>/dev/null || true

cache_api_log_debug() { echo "[DEBUG][cache_api] $*"; }
cache_api_log_warn()  { echo "[WARN][cache_api] $*"; }
cache_api_log_error() { echo "[ERROR][cache_api] $*"; }

# 检测底层缓存实现可用性
_cache_impl() {
  # 优先使用增强缓存系统
  if declare -F enhanced_cache_get >/dev/null 2>&1; then echo "enhanced"; return; fi
  # 其次使用智能缓存
  if declare -F smart_cache_get >/dev/null 2>&1; then echo "smart"; return; fi
  # 回退到配置缓存
  if declare -F config_cache_get >/dev/null 2>&1; then echo "config"; return; fi
  echo "none"
}

cache_get() {
  local key="$1"
  local impl=$(_cache_impl)
  case "$impl" in
    enhanced) enhanced_cache_get "$key" ;;
    smart)    smart_cache_get "$key" ;;
    config)   config_cache_get "$key" ;;
    none)     cache_api_log_warn "No cache backend available for get: $key"; return 1 ;;
  esac
}

cache_set() {
  local key="$1"; shift
  local value="$1"; shift || true
  local ttl="${1:-}"
  local impl=$(_cache_impl)
  case "$impl" in
    enhanced) enhanced_cache_set "$key" "$value" "$ttl" ;;
    smart)    smart_cache_set    "$key" "$value" "$ttl" ;;
    config)   config_cache_set   "$key" "$value" "$ttl" ;;
    none)     cache_api_log_warn "No cache backend available for set: $key"; return 1 ;;
  esac
}

cache_invalidate() {
  local key="$1"
  local impl=$(_cache_impl)
  case "$impl" in
    enhanced) enhanced_cache_invalidate "$key" ;;
    smart)    smart_cache_invalidate    "$key" ;;
    config)   config_cache_invalidate   "$key" ;;
    none)     cache_api_log_warn "No cache backend available for invalidate: $key"; return 1 ;;
  esac
}

cache_exists() {
  local key="$1"
  local impl=$(_cache_impl)
  case "$impl" in
    enhanced) enhanced_cache_exists "$key" ;;
    smart)    smart_cache_exists    "$key" ;;
    config)   config_cache_exists   "$key" ;;
    none)     return 1 ;;
  esac
}