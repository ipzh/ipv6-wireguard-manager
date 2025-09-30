#!/bin/bash

# 配置文件版本控制模块
# 提供配置文件版本管理、升级和回滚功能

# =============================================================================
# 版本控制配置
# =============================================================================

# 版本控制目录
declare -g IPV6WGM_CONFIG_VERSION_DIR="${CONFIG_DIR}/versions"
declare -g IPV6WGM_CONFIG_VERSION_FILE="${CONFIG_DIR}/version_history.json"
declare -g IPV6WGM_CONFIG_CURRENT_VERSION_FILE="${CONFIG_DIR}/current_version"

# 版本控制设置
declare -g IPV6WGM_MAX_VERSION_HISTORY=50
declare -g IPV6WGM_VERSION_AUTO_BACKUP=true
declare -g IPV6WGM_VERSION_COMPRESSION=true

# 版本信息存储
declare -A IPV6WGM_VERSION_INFO=()
declare -g IPV6WGM_CURRENT_VERSION=""
declare -g IPV6WGM_VERSION_COUNTER=0

# =============================================================================
# 版本控制函数
# =============================================================================

# 初始化版本控制系统
init_version_control() {
    log_info "初始化配置文件版本控制系统..."
    
    # 创建版本控制目录
    if ! mkdir -p "$IPV6WGM_CONFIG_VERSION_DIR"; then
        log_error "无法创建版本控制目录: $IPV6WGM_CONFIG_VERSION_DIR"
        return 1
    fi
    
    # 创建版本历史文件
    if [[ ! -f "$IPV6WGM_CONFIG_VERSION_FILE" ]]; then
        create_version_history_file
    fi
    
    # 加载版本信息
    load_version_info
    
    # 设置当前版本
    if [[ -f "$IPV6WGM_CONFIG_CURRENT_VERSION_FILE" ]]; then
        IPV6WGM_CURRENT_VERSION=$(cat "$IPV6WGM_CONFIG_CURRENT_VERSION_FILE" 2>/dev/null || echo "1.0.0")
    else
        IPV6WGM_CURRENT_VERSION="1.0.0"
        echo "$IPV6WGM_CURRENT_VERSION" > "$IPV6WGM_CONFIG_CURRENT_VERSION_FILE"
    fi
    
    log_success "版本控制系统初始化完成，当前版本: $IPV6WGM_CURRENT_VERSION"
    return 0
}

# 创建版本历史文件
create_version_history_file() {
    local version_history='{
        "metadata": {
            "created": "'$(date -Iseconds)'",
            "version": "1.0.0",
            "description": "IPv6 WireGuard Manager 配置版本历史"
        },
        "versions": []
    }'
    
    echo "$version_history" > "$IPV6WGM_CONFIG_VERSION_FILE"
    log_info "版本历史文件已创建: $IPV6WGM_CONFIG_VERSION_FILE"
}

# 加载版本信息
load_version_info() {
    if [[ ! -f "$IPV6WGM_CONFIG_VERSION_FILE" ]]; then
        log_warn "版本历史文件不存在，将创建新文件"
        create_version_history_file
        return 0
    fi
    
    # 使用jq解析JSON（如果可用），否则使用简单的文本处理
    if command -v jq >/dev/null 2>&1; then
        load_version_info_json
    else
        load_version_info_text
    fi
}

# 使用jq加载版本信息
load_version_info_json() {
    local version_count=$(jq '.versions | length' "$IPV6WGM_CONFIG_VERSION_FILE" 2>/dev/null || echo "0")
    IPV6WGM_VERSION_COUNTER=$version_count
    
    # 加载版本信息到关联数组
    for ((i=0; i<version_count; i++)); do
        local version=$(jq -r ".versions[$i].version" "$IPV6WGM_CONFIG_VERSION_FILE" 2>/dev/null)
        local timestamp=$(jq -r ".versions[$i].timestamp" "$IPV6WGM_CONFIG_VERSION_FILE" 2>/dev/null)
        local description=$(jq -r ".versions[$i].description" "$IPV6WGM_CONFIG_VERSION_FILE" 2>/dev/null)
        
        if [[ "$version" != "null" && -n "$version" ]]; then
            IPV6WGM_VERSION_INFO["$version"]="$timestamp|$description"
        fi
    done
    
    log_debug "已加载 $version_count 个版本信息"
}

# 使用文本处理加载版本信息
load_version_info_text() {
    local version_count=0
    
    # 简单的文本解析（当jq不可用时）
    while IFS= read -r line; do
        if [[ "$line" =~ \"version\"\s*:\s*\"([^\"]+)\" ]]; then
            local version="${BASH_REMATCH[1]}"
            ((version_count++))
            IPV6WGM_VERSION_INFO["$version"]="$(date -Iseconds)|版本 $version"
        fi
    done < "$IPV6WGM_CONFIG_VERSION_FILE"
    
    IPV6WGM_VERSION_COUNTER=$version_count
    log_debug "已加载 $version_count 个版本信息（文本模式）"
}

# 创建新版本
create_version() {
    local description="${1:-配置更新}"
    local config_file="${2:-$CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    # 生成新版本号
    local new_version=$(generate_version_number)
    local timestamp=$(date -Iseconds)
    local version_file="${IPV6WGM_CONFIG_VERSION_DIR}/config_v${new_version}.conf"
    
    # 备份配置文件
    if ! cp "$config_file" "$version_file"; then
        log_error "无法创建版本备份: $version_file"
        return 1
    fi
    
    # 如果启用压缩，压缩备份文件
    if [[ "$IPV6WGM_VERSION_COMPRESSION" == "true" ]]; then
        if command -v gzip >/dev/null 2>&1; then
            gzip "$version_file"
            version_file="${version_file}.gz"
        fi
    fi
    
    # 更新版本历史
    if ! update_version_history "$new_version" "$timestamp" "$description" "$version_file"; then
        log_error "无法更新版本历史"
        rm -f "$version_file"
        return 1
    fi
    
    # 更新当前版本
    IPV6WGM_CURRENT_VERSION="$new_version"
    echo "$new_version" > "$IPV6WGM_CONFIG_CURRENT_VERSION_FILE"
    
    # 更新版本信息
    IPV6WGM_VERSION_INFO["$new_version"]="$timestamp|$description"
    ((IPV6WGM_VERSION_COUNTER++))
    
    log_success "已创建新版本: $new_version"
    log_info "版本文件: $version_file"
    log_info "描述: $description"
    
    return 0
}

# 生成版本号
generate_version_number() {
    local major=1
    local minor=0
    local patch=0
    
    # 解析当前版本号
    if [[ "$IPV6WGM_CURRENT_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
    fi
    
    # 增加补丁版本号
    ((patch++))
    
    # 如果补丁版本超过99，增加次版本号
    if [[ $patch -gt 99 ]]; then
        patch=0
        ((minor++))
    fi
    
    # 如果次版本号超过99，增加主版本号
    if [[ $minor -gt 99 ]]; then
        minor=0
        ((major++))
    fi
    
    echo "${major}.${minor}.${patch}"
}

# 更新版本历史
update_version_history() {
    local version="$1"
    local timestamp="$2"
    local description="$3"
    local version_file="$4"
    
    if command -v jq >/dev/null 2>&1; then
        update_version_history_json "$version" "$timestamp" "$description" "$version_file"
    else
        update_version_history_text "$version" "$timestamp" "$description" "$version_file"
    fi
}

# 使用jq更新版本历史
update_version_history_json() {
    local version="$1"
    local timestamp="$2"
    local description="$3"
    local version_file="$4"
    
    # 创建新版本条目
    local new_version_entry=$(jq -n \
        --arg version "$version" \
        --arg timestamp "$timestamp" \
        --arg description "$description" \
        --arg file "$version_file" \
        '{
            version: $version,
            timestamp: $timestamp,
            description: $description,
            file: $file
        }')
    
    # 添加到版本历史
    local temp_file=$(mktemp)
    jq --argjson new_version "$new_version_entry" '.versions += [$new_version]' "$IPV6WGM_CONFIG_VERSION_FILE" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$IPV6WGM_CONFIG_VERSION_FILE"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# 使用文本处理更新版本历史
update_version_history_text() {
    local version="$1"
    local timestamp="$2"
    local description="$3"
    local version_file="$4"
    
    # 简单的文本追加（当jq不可用时）
    local version_entry="    {
        \"version\": \"$version\",
        \"timestamp\": \"$timestamp\",
        \"description\": \"$description\",
        \"file\": \"$version_file\"
    }"
    
    # 在最后一个版本条目后添加新条目
    local temp_file=$(mktemp)
    sed "s/]/$version_entry,\n]/" "$IPV6WGM_CONFIG_VERSION_FILE" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$IPV6WGM_CONFIG_VERSION_FILE"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# 列出所有版本
list_versions() {
    log_info "配置文件版本列表:"
    echo
    
    if [[ ${#IPV6WGM_VERSION_INFO[@]} -eq 0 ]]; then
        log_warn "没有找到版本信息"
        return 0
    fi
    
    printf "%-12s %-20s %-50s\n" "版本" "时间" "描述"
    printf "%-12s %-20s %-50s\n" "----" "----" "----"
    
    # 按版本号排序显示
    for version in $(printf '%s\n' "${!IPV6WGM_VERSION_INFO[@]}" | sort -V); do
        local info="${IPV6WGM_VERSION_INFO[$version]}"
        local timestamp="${info%%|*}"
        local description="${info#*|}"
        
        # 格式化时间戳
        local formatted_time=$(date -d "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        
        # 标记当前版本
        local marker=""
        if [[ "$version" == "$IPV6WGM_CURRENT_VERSION" ]]; then
            marker=" (当前)"
        fi
        
        printf "%-12s %-20s %-50s%s\n" "$version" "$formatted_time" "$description" "$marker"
    done
    
    echo
    log_info "当前版本: $IPV6WGM_CURRENT_VERSION"
    log_info "总版本数: ${#IPV6WGM_VERSION_INFO[@]}"
}

# 回滚到指定版本
rollback_to_version() {
    local target_version="$1"
    local config_file="${2:-$CONFIG_FILE}"
    
    if [[ -z "$target_version" ]]; then
        log_error "请指定要回滚的版本号"
        return 1
    fi
    
    # 检查版本是否存在
    if [[ -z "${IPV6WGM_VERSION_INFO[$target_version]}" ]]; then
        log_error "版本不存在: $target_version"
        return 1
    fi
    
    # 检查是否为当前版本
    if [[ "$target_version" == "$IPV6WGM_CURRENT_VERSION" ]]; then
        log_warn "目标版本与当前版本相同，无需回滚"
        return 0
    fi
    
    # 查找版本文件
    local version_file="${IPV6WGM_CONFIG_VERSION_DIR}/config_v${target_version}.conf"
    local compressed_file="${version_file}.gz"
    
    if [[ -f "$compressed_file" ]]; then
        version_file="$compressed_file"
    elif [[ ! -f "$version_file" ]]; then
        log_error "版本文件不存在: $version_file"
        return 1
    fi
    
    # 备份当前配置
    if [[ "$IPV6WGM_VERSION_AUTO_BACKUP" == "true" ]]; then
        create_version "回滚前备份"
    fi
    
    # 恢复配置文件
    if [[ "$version_file" == *.gz ]]; then
        if ! gunzip -c "$version_file" > "$config_file"; then
            log_error "无法解压版本文件: $version_file"
            return 1
        fi
    else
        if ! cp "$version_file" "$config_file"; then
            log_error "无法恢复版本文件: $version_file"
            return 1
        fi
    fi
    
    # 更新当前版本
    IPV6WGM_CURRENT_VERSION="$target_version"
    echo "$target_version" > "$IPV6WGM_CONFIG_CURRENT_VERSION_FILE"
    
    log_success "已回滚到版本: $target_version"
    log_info "配置文件已恢复: $config_file"
    
    return 0
}

# 比较版本差异
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    if [[ -z "$version1" || -z "$version2" ]]; then
        log_error "请指定两个版本号进行比较"
        return 1
    fi
    
    # 检查版本是否存在
    if [[ -z "${IPV6WGM_VERSION_INFO[$version1]}" ]]; then
        log_error "版本不存在: $version1"
        return 1
    fi
    
    if [[ -z "${IPV6WGM_VERSION_INFO[$version2]}" ]]; then
        log_error "版本不存在: $version2"
        return 1
    fi
    
    # 查找版本文件
    local file1="${IPV6WGM_CONFIG_VERSION_DIR}/config_v${version1}.conf"
    local file2="${IPV6WGM_CONFIG_VERSION_DIR}/config_v${version2}.conf"
    
    # 检查压缩文件
    if [[ -f "${file1}.gz" ]]; then
        file1="${file1}.gz"
    fi
    if [[ -f "${file2}.gz" ]]; then
        file2="${file2}.gz"
    fi
    
    # 解压文件进行比较
    local temp1=$(mktemp)
    local temp2=$(mktemp)
    
    if [[ "$file1" == *.gz ]]; then
        gunzip -c "$file1" > "$temp1"
    else
        cp "$file1" "$temp1"
    fi
    
    if [[ "$file2" == *.gz ]]; then
        gunzip -c "$file2" > "$temp2"
    else
        cp "$file2" "$temp2"
    fi
    
    # 使用diff比较文件
    log_info "比较版本 $version1 和 $version2:"
    echo
    
    if command -v diff >/dev/null 2>&1; then
        diff -u "$temp1" "$temp2" || true
    else
        log_warn "diff命令不可用，无法比较文件差异"
    fi
    
    # 清理临时文件
    rm -f "$temp1" "$temp2"
    
    return 0
}

# 清理旧版本
cleanup_old_versions() {
    local keep_versions="${1:-$IPV6WGM_MAX_VERSION_HISTORY}"
    
    if [[ ${#IPV6WGM_VERSION_INFO[@]} -le $keep_versions ]]; then
        log_info "版本数量未超过限制，无需清理"
        return 0
    fi
    
    # 按版本号排序，保留最新的版本
    local sorted_versions=($(printf '%s\n' "${!IPV6WGM_VERSION_INFO[@]}" | sort -V))
    local versions_to_remove=(${sorted_versions[@]:0:$((${#sorted_versions[@]} - keep_versions))})
    
    log_info "开始清理旧版本，保留最新 $keep_versions 个版本"
    
    local removed_count=0
    for version in "${versions_to_remove[@]}"; do
        local version_file="${IPV6WGM_CONFIG_VERSION_DIR}/config_v${version}.conf"
        local compressed_file="${version_file}.gz"
        
        # 删除版本文件
        if [[ -f "$compressed_file" ]]; then
            rm -f "$compressed_file"
        elif [[ -f "$version_file" ]]; then
            rm -f "$version_file"
        fi
        
        # 从版本信息中移除
        unset IPV6WGM_VERSION_INFO["$version"]
        ((removed_count++))
        
        log_debug "已删除版本: $version"
    done
    
    # 更新版本历史文件
    update_version_history_file_after_cleanup
    
    log_success "已清理 $removed_count 个旧版本"
    return 0
}

# 清理后更新版本历史文件
update_version_history_file_after_cleanup() {
    if command -v jq >/dev/null 2>&1; then
        # 使用jq重建版本历史
        local temp_file=$(mktemp)
        echo '{"metadata":{"created":"'$(date -Iseconds)'","version":"1.0.0","description":"IPv6 WireGuard Manager 配置版本历史"},"versions":[]}' > "$temp_file"
        
        for version in "${!IPV6WGM_VERSION_INFO[@]}"; do
            local info="${IPV6WGM_VERSION_INFO[$version]}"
            local timestamp="${info%%|*}"
            local description="${info#*|}"
            
            jq --arg version "$version" \
               --arg timestamp "$timestamp" \
               --arg description "$description" \
               --arg file "${IPV6WGM_CONFIG_VERSION_DIR}/config_v${version}.conf" \
               '.versions += [{"version":$version,"timestamp":$timestamp,"description":$description,"file":$file}]' \
               "$temp_file" > "${temp_file}.tmp" && mv "${temp_file}.tmp" "$temp_file"
        done
        
        mv "$temp_file" "$IPV6WGM_CONFIG_VERSION_FILE"
    else
        # 简单的文本重建
        create_version_history_file
    fi
}

# 获取版本统计信息
get_version_statistics() {
    echo "=== 配置版本统计 ==="
    echo "当前版本: $IPV6WGM_CURRENT_VERSION"
    echo "总版本数: ${#IPV6WGM_VERSION_INFO[@]}"
    echo "版本目录: $IPV6WGM_CONFIG_VERSION_DIR"
    echo "最大保留版本: $IPV6WGM_MAX_VERSION_HISTORY"
    echo "自动备份: $IPV6WGM_VERSION_AUTO_BACKUP"
    echo "压缩备份: $IPV6WGM_VERSION_COMPRESSION"
    
    # 计算版本目录大小
    if [[ -d "$IPV6WGM_CONFIG_VERSION_DIR" ]]; then
        local dir_size=$(du -sh "$IPV6WGM_CONFIG_VERSION_DIR" 2>/dev/null | cut -f1 || echo "未知")
        echo "版本目录大小: $dir_size"
    fi
    
    # 显示最新5个版本
    echo
    echo "最新版本:"
    local sorted_versions=($(printf '%s\n' "${!IPV6WGM_VERSION_INFO[@]}" | sort -V -r))
    local count=0
    for version in "${sorted_versions[@]}"; do
        if [[ $count -ge 5 ]]; then
            break
        fi
        
        local info="${IPV6WGM_VERSION_INFO[$version]}"
        local timestamp="${info%%|*}"
        local description="${info#*|}"
        local formatted_time=$(date -d "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        
        echo "  $version - $formatted_time - $description"
        ((count++))
    done
}

# 导出函数
export -f init_version_control
export -f create_version
export -f list_versions
export -f rollback_to_version
export -f compare_versions
export -f cleanup_old_versions
export -f get_version_statistics
