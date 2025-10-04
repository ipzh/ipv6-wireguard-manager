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

# 统一的带缓存执行入口
cache_exec() {
  local command="$1"
  local cache_key="$2"
  local ttl="${3:-300}"
  local force_refresh="${4:-false}"
  local impl=$(_cache_impl)
  case "$impl" in
    enhanced)
      if declare -F execute_with_cache >/dev/null 2>&1; then
        execute_with_cache "$command" "$cache_key" "$ttl" "$force_refresh"
        return $?
      fi
      ;;
    smart)
      # 简单回退：若命中则返回，否则执行并写入
      local val=""
      if val=$(smart_cache_get "$cache_key" "$ttl" 2>/dev/null); then
        echo "$val"; return 0
      fi
      local result
      if result=$(bash -c "$command" 2>&1); then
        smart_cache_set "$cache_key" "$result" "$ttl" || true
        echo "$result"; return 0
      else
        return 1
      fi
      ;;
    config)
      # 配置缓存不适合通用命令缓存，直接执行命令
      bash -c "$command"
      return $?
      ;;
    none)
      cache_api_log_warn "No cache backend available for exec: $cache_key"
      bash -c "$command"
      return $?
      ;;
  esac
}

# 统一缓存统计输出
cache_stats() {
  local impl=$(_cache_impl)

  # 尝试获取后端原始输出（可选，用于后续解析）
  local raw=""
  case "$impl" in
    enhanced)
      declare -F get_cache_stats >/dev/null 2>&1 && raw="$(get_cache_stats 2>/dev/null || true)" || true
      ;;
    smart)
      declare -F get_cache_stats >/dev/null 2>&1 && raw="$(get_cache_stats 2>/dev/null || true)" || true
      ;;
    config)
      declare -F get_config_cache_stats >/dev/null 2>&1 && raw="$(get_config_cache_stats 2>/dev/null || true)" || true
      ;;
  esac

  # 结构化字段，默认 null（解析不到则保持）
  local entries="null"
  local hits="null"
  local misses="null"
  local evictions="null"
  local total_size="null"
  local hit_rate="null"

  # 轻量解析（匹配中文/英文常见关键字），尽可能提取数值
  if [[ -n "$raw" ]]; then
    # 缓存条目数 / entries
    entries=$(echo "$raw" | sed -n -E 's/.*(缓存条目数|entries)[:：] *([0-9]+).*/\2/p' | head -n1)
    [[ -z "$entries" ]] && entries="null"

    # 命中 / hits
    hits=$(echo "$raw" | sed -n -E 's/.*(缓存命中|hits)[:：] *([0-9]+).*/\2/p' | head -n1)
    [[ -z "$hits" ]] && hits="null"

    # 未命中 / misses
    misses=$(echo "$raw" | sed -n -E 's/.*(缓存未命中|misses)[:：] *([0-9]+).*/\2/p' | head -n1)
    [[ -z "$misses" ]] && misses="null"

    # 淘汰 / evictions
    evictions=$(echo "$raw" | sed -n -E 's/.*(淘汰|evictions)[:：] *([0-9]+).*/\2/p' | head -n1)
    [[ -z "$evictions" ]] && evictions="null"

    # 总大小 / total_size
    total_size=$(echo "$raw" | sed -n -E 's/.*(缓存大小|total_size)[:：] *([0-9]+).*/\2/p' | head -n1)
    [[ -z "$total_size" ]] && total_size="null"

    # 命中率 / hit_rate（去掉百分号）
    hit_rate=$(echo "$raw" | sed -n -E 's/.*(命中率|hit[_ ]?rate)[:：] *([0-9]+)%.*/\2/p' | head -n1)
    [[ -z "$hit_rate" ]] && hit_rate="null"
  fi

  # 输出结构化 JSON
  echo "{\"backend\":\"$impl\",\"entries\":$entries,\"hits\":$hits,\"misses\":$misses,\"evictions\":$evictions,\"total_size\":$total_size,\"hit_rate\":$hit_rate}"
  return 0
}

# 统一缓存清理入口
cache_clear() {
  local impl=$(_cache_impl)
  case "$impl" in
    enhanced)
      declare -F clear_all_cache >/dev/null 2>&1 && clear_all_cache && return 0
      ;;
    smart)
      declare -F clear_cache >/dev/null 2>&1 && clear_cache && return 0
      ;;
    config)
      declare -F clear_config_cache >/dev/null 2>&1 && clear_config_cache && return 0
      ;;
  esac
  cache_api_log_warn "No cache backend available for clear"; return 1
}