#!/bin/bash

# 配置备份和自动恢复模块
# 提供配置文件的自动备份、恢复和灾难恢复功能

# =============================================================================
# 备份配置
# =============================================================================

# 备份目录
declare -g IPV6WGM_BACKUP_DIR="${CONFIG_DIR}/backups"
declare -g IPV6WGM_BACKUP_METADATA_FILE="${IPV6WGM_BACKUP_DIR}/backup_metadata.json"

# 备份设置
declare -g IPV6WGM_AUTO_BACKUP_ENABLED=true
declare -g IPV6WGM_BACKUP_RETENTION_DAYS=30
declare -g IPV6WGM_BACKUP_COMPRESSION=true
declare -g IPV6WGM_BACKUP_ENCRYPTION=false
declare -g IPV6WGM_BACKUP_SCHEDULE="daily"

# 备份文件列表
declare -a IPV6WGM_BACKUP_FILES=(
    "$CONFIG_FILE"
    "$CONFIG_DIR/manager.conf"
    "$CONFIG_DIR/bird.conf"
    "$CONFIG_DIR/firewall_rules.conf"
    "$CONFIG_DIR/client_template.conf"
    "$CONFIG_DIR/bird_template.conf"
    "$CONFIG_DIR/bird_v2_template.conf"
    "$CONFIG_DIR/bird_v3_template.conf"
)

# 备份状态
declare -A IPV6WGM_BACKUP_STATUS=()
declare -g IPV6WGM_LAST_BACKUP_TIME=""
declare -g IPV6WGM_BACKUP_COUNT=0

# =============================================================================
# 备份函数
# =============================================================================

# 初始化备份系统
init_backup_system() {
    log_info "初始化配置备份系统..."
    
    # 创建备份目录
    if ! mkdir -p "$IPV6WGM_BACKUP_DIR"; then
        log_error "无法创建备份目录: $IPV6WGM_BACKUP_DIR"
        return 1
    fi
    
    # 创建备份元数据文件
    if [[ ! -f "$IPV6WGM_BACKUP_METADATA_FILE" ]]; then
        create_backup_metadata_file
    fi
    
    # 加载备份信息
    load_backup_metadata
    
    # 检查自动备份
    if [[ "$IPV6WGM_AUTO_BACKUP_ENABLED" == "true" ]]; then
        check_auto_backup_needed
    fi
    
    log_success "配置备份系统初始化完成"
    return 0
}

# 创建备份元数据文件
create_backup_metadata_file() {
    local metadata='{
        "metadata": {
            "created": "'$(date -Iseconds)'",
            "version": "1.0.0",
            "description": "IPv6 WireGuard Manager 配置备份元数据"
        },
        "backups": [],
        "settings": {
            "auto_backup_enabled": true,
            "retention_days": 30,
            "compression": true,
            "encryption": false,
            "schedule": "daily"
        }
    }'
    
    echo "$metadata" > "$IPV6WGM_BACKUP_METADATA_FILE"
    log_info "备份元数据文件已创建: $IPV6WGM_BACKUP_METADATA_FILE"
}

# 加载备份元数据
load_backup_metadata() {
    if [[ ! -f "$IPV6WGM_BACKUP_METADATA_FILE" ]]; then
        log_warn "备份元数据文件不存在，将创建新文件"
        create_backup_metadata_file
        return 0
    fi
    
    # 使用jq解析JSON（如果可用），否则使用简单的文本处理
    if command -v jq >/dev/null 2>&1; then
        load_backup_metadata_json
    else
        load_backup_metadata_text
    fi
}

# 使用jq加载备份元数据
load_backup_metadata_json() {
    # 加载设置
    IPV6WGM_AUTO_BACKUP_ENABLED=$(jq -r '.settings.auto_backup_enabled' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "true")
    IPV6WGM_BACKUP_RETENTION_DAYS=$(jq -r '.settings.retention_days' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "30")
    IPV6WGM_BACKUP_COMPRESSION=$(jq -r '.settings.compression' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "true")
    IPV6WGM_BACKUP_ENCRYPTION=$(jq -r '.settings.encryption' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "false")
    IPV6WGM_BACKUP_SCHEDULE=$(jq -r '.settings.schedule' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "daily")
    
    # 加载备份信息
    local backup_count=$(jq '.backups | length' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "0")
    IPV6WGM_BACKUP_COUNT=$backup_count
    
    # 获取最后一次备份时间
    if [[ $backup_count -gt 0 ]]; then
        IPV6WGM_LAST_BACKUP_TIME=$(jq -r '.backups[-1].timestamp' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null || echo "")
    fi
    
    log_debug "已加载 $backup_count 个备份信息"
}

# 使用文本处理加载备份元数据
load_backup_metadata_text() {
    # 简单的文本解析（当jq不可用时）
    IPV6WGM_AUTO_BACKUP_ENABLED="true"
    IPV6WGM_BACKUP_RETENTION_DAYS="30"
    IPV6WGM_BACKUP_COMPRESSION="true"
    IPV6WGM_BACKUP_ENCRYPTION="false"
    IPV6WGM_BACKUP_SCHEDULE="daily"
    IPV6WGM_BACKUP_COUNT=0
    IPV6WGM_LAST_BACKUP_TIME=""
    
    log_debug "已加载备份元数据（文本模式）"
}

# 创建配置备份
create_backup() {
    local backup_name="${1:-}"
    local description="${2:-手动备份}"
    local force="${3:-false}"
    
    # 生成备份名称
    if [[ -z "$backup_name" ]]; then
        backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    local backup_dir="${IPV6WGM_BACKUP_DIR}/${backup_name}"
    local timestamp=$(date -Iseconds)
    
    # 检查备份是否已存在
    if [[ -d "$backup_dir" && "$force" != "true" ]]; then
        log_error "备份已存在: $backup_name"
        return 1
    fi
    
    log_info "创建配置备份: $backup_name"
    
    # 创建备份目录
    if ! mkdir -p "$backup_dir"; then
        log_error "无法创建备份目录: $backup_dir"
        return 1
    fi
    
    # 备份配置文件
    local backup_success=true
    local backed_up_files=()
    
    for file in "${IPV6WGM_BACKUP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local backup_file="${backup_dir}/${filename}"
            
            if cp "$file" "$backup_file"; then
                backed_up_files+=("$filename")
                log_debug "已备份: $filename"
            else
                log_error "备份失败: $filename"
                backup_success=false
            fi
        else
            log_debug "文件不存在，跳过: $file"
        fi
    done
    
    # 备份系统信息
    create_system_info_backup "$backup_dir"
    
    # 创建备份清单
    create_backup_manifest "$backup_dir" "${backed_up_files[@]}"
    
    # 压缩备份（如果启用）
    if [[ "$IPV6WGM_BACKUP_COMPRESSION" == "true" ]]; then
        compress_backup "$backup_dir"
    fi
    
    # 加密备份（如果启用）
    if [[ "$IPV6WGM_BACKUP_ENCRYPTION" == "true" ]]; then
        encrypt_backup "$backup_dir"
    fi
    
    # 更新备份元数据
    if ! update_backup_metadata "$backup_name" "$timestamp" "$description" "$backup_dir" "${#backed_up_files[@]}"; then
        log_error "无法更新备份元数据"
        backup_success=false
    fi
    
    if [[ "$backup_success" == "true" ]]; then
        IPV6WGM_LAST_BACKUP_TIME="$timestamp"
        ((IPV6WGM_BACKUP_COUNT++))
        log_success "配置备份创建成功: $backup_name"
        log_info "备份目录: $backup_dir"
        log_info "备份文件数: ${#backed_up_files[@]}"
        return 0
    else
        log_error "配置备份创建失败"
        rm -rf "$backup_dir"
        return 1
    fi
}

# 创建系统信息备份
create_system_info_backup() {
    local backup_dir="$1"
    local system_info_file="${backup_dir}/system_info.txt"
    
    {
        echo "=== 系统信息备份 ==="
        echo "备份时间: $(date)"
        echo "系统信息: $(uname -a)"
        echo "操作系统: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "unknown")"
        echo "内核版本: $(uname -r)"
        echo "架构: $(uname -m)"
        echo "用户: $(whoami)"
        echo "工作目录: $(pwd)"
        echo "脚本版本: ${IPV6WGM_VERSION:-unknown}"
        echo
        echo "=== 网络配置 ==="
        ip addr show 2>/dev/null || echo "无法获取网络信息"
        echo
        echo "=== 磁盘使用 ==="
        df -h 2>/dev/null || echo "无法获取磁盘信息"
        echo
        echo "=== 内存使用 ==="
        free -h 2>/dev/null || echo "无法获取内存信息"
    } > "$system_info_file"
    
    log_debug "系统信息已备份: $system_info_file"
}

# 创建备份清单
create_backup_manifest() {
    local backup_dir="$1"
    shift
    local files=("$@")
    local manifest_file="${backup_dir}/MANIFEST.txt"
    
    {
        echo "=== 备份清单 ==="
        echo "备份时间: $(date)"
        echo "备份文件数: ${#files[@]}"
        echo
        echo "文件列表:"
        for file in "${files[@]}"; do
            echo "  - $file"
        done
        echo
        echo "=== 文件校验 ==="
        for file in "${files[@]}"; do
            local file_path="${backup_dir}/${file}"
            if [[ -f "$file_path" ]]; then
                local checksum=$(md5sum "$file_path" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
                echo "  $file: $checksum"
            fi
        done
    } > "$manifest_file"
    
    log_debug "备份清单已创建: $manifest_file"
}

# 压缩备份
compress_backup() {
    local backup_dir="$1"
    
    if ! command -v tar >/dev/null 2>&1; then
        log_warn "tar命令不可用，跳过压缩"
        return 0
    fi
    
    local backup_name=$(basename "$backup_dir")
    local parent_dir=$(dirname "$backup_dir")
    local compressed_file="${parent_dir}/${backup_name}.tar.gz"
    
    if tar -czf "$compressed_file" -C "$parent_dir" "$backup_name"; then
        rm -rf "$backup_dir"
        log_debug "备份已压缩: $compressed_file"
    else
        log_error "备份压缩失败"
        return 1
    fi
}

# 加密备份
encrypt_backup() {
    local backup_dir="$1"
    
    if ! command -v gpg >/dev/null 2>&1; then
        log_warn "gpg命令不可用，跳过加密"
        return 0
    fi
    
    # 这里需要实现加密逻辑
    # 由于需要密钥管理，暂时跳过
    log_warn "加密功能暂未实现"
}

# 更新备份元数据
update_backup_metadata() {
    local backup_name="$1"
    local timestamp="$2"
    local description="$3"
    local backup_dir="$4"
    local file_count="$5"
    
    if command -v jq >/dev/null 2>&1; then
        update_backup_metadata_json "$backup_name" "$timestamp" "$description" "$backup_dir" "$file_count"
    else
        update_backup_metadata_text "$backup_name" "$timestamp" "$description" "$backup_dir" "$file_count"
    fi
}

# 使用jq更新备份元数据
update_backup_metadata_json() {
    local backup_name="$1"
    local timestamp="$2"
    local description="$3"
    local backup_dir="$4"
    local file_count="$5"
    
    # 创建新备份条目
    local new_backup_entry=$(jq -n \
        --arg name "$backup_name" \
        --arg timestamp "$timestamp" \
        --arg description "$description" \
        --arg dir "$backup_dir" \
        --argjson file_count "$file_count" \
        '{
            name: $name,
            timestamp: $timestamp,
            description: $description,
            directory: $dir,
            file_count: $file_count
        }')
    
    # 添加到备份列表
    local temp_file=$(mktemp)
    jq --argjson new_backup "$new_backup_entry" '.backups += [$new_backup]' "$IPV6WGM_BACKUP_METADATA_FILE" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$IPV6WGM_BACKUP_METADATA_FILE"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# 使用文本处理更新备份元数据
update_backup_metadata_text() {
    local backup_name="$1"
    local timestamp="$2"
    local description="$3"
    local backup_dir="$4"
    local file_count="$5"
    
    # 简单的文本追加（当jq不可用时）
    local backup_entry="    {
        \"name\": \"$backup_name\",
        \"timestamp\": \"$timestamp\",
        \"description\": \"$description\",
        \"directory\": \"$backup_dir\",
        \"file_count\": $file_count
    }"
    
    # 在最后一个备份条目后添加新条目
    local temp_file=$(mktemp)
    sed "s/]/$backup_entry,\n]/" "$IPV6WGM_BACKUP_METADATA_FILE" > "$temp_file"
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$IPV6WGM_BACKUP_METADATA_FILE"
        return 0
    else
        rm -f "$temp_file"
        return 1
    fi
}

# 列出所有备份
list_backups() {
    log_info "配置备份列表:"
    echo
    
    if [[ $IPV6WGM_BACKUP_COUNT -eq 0 ]]; then
        log_warn "没有找到备份"
        return 0
    fi
    
    printf "%-20s %-20s %-50s %-10s\n" "备份名称" "时间" "描述" "文件数"
    printf "%-20s %-20s %-50s %-10s\n" "--------" "----" "----" "------"
    
    # 从元数据文件读取备份信息
    if command -v jq >/dev/null 2>&1; then
        jq -r '.backups[] | "\(.name)|\(.timestamp)|\(.description)|\(.file_count)"' "$IPV6WGM_BACKUP_METADATA_FILE" | while IFS='|' read -r name timestamp description file_count; do
            local formatted_time=$(date -d "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
            printf "%-20s %-20s %-50s %-10s\n" "$name" "$formatted_time" "$description" "$file_count"
        done
    else
        # 简单的目录列表
        for backup_dir in "$IPV6WGM_BACKUP_DIR"/*; do
            if [[ -d "$backup_dir" ]]; then
                local name=$(basename "$backup_dir")
                local file_count=$(find "$backup_dir" -type f | wc -l)
                printf "%-20s %-20s %-50s %-10s\n" "$name" "未知" "目录备份" "$file_count"
            fi
        done
    fi
    
    echo
    log_info "总备份数: $IPV6WGM_BACKUP_COUNT"
    log_info "最后备份: $IPV6WGM_LAST_BACKUP_TIME"
}

# 恢复配置备份
restore_backup() {
    local backup_name="$1"
    local target_dir="${2:-$CONFIG_DIR}"
    local force="${3:-false}"
    
    if [[ -z "$backup_name" ]]; then
        log_error "请指定要恢复的备份名称"
        return 1
    fi
    
    local backup_dir="${IPV6WGM_BACKUP_DIR}/${backup_name}"
    local compressed_backup="${backup_dir}.tar.gz"
    
    # 检查备份是否存在
    if [[ -f "$compressed_backup" ]]; then
        backup_dir="$compressed_backup"
    elif [[ ! -d "$backup_dir" ]]; then
        log_error "备份不存在: $backup_name"
        return 1
    fi
    
    log_info "恢复配置备份: $backup_name"
    
    # 创建目标目录
    if ! mkdir -p "$target_dir"; then
        log_error "无法创建目标目录: $target_dir"
        return 1
    fi
    
    # 恢复文件
    if [[ "$backup_dir" == *.tar.gz ]]; then
        # 解压并恢复
        if ! tar -xzf "$backup_dir" -C "$IPV6WGM_BACKUP_DIR"; then
            log_error "无法解压备份文件: $backup_dir"
            return 1
        fi
        backup_dir="${IPV6WGM_BACKUP_DIR}/${backup_name}"
    fi
    
    # 复制文件
    local restored_count=0
    for file in "$backup_dir"/*; do
        if [[ -f "$file" && "$(basename "$file")" != "MANIFEST.txt" && "$(basename "$file")" != "system_info.txt" ]]; then
            local filename=$(basename "$file")
            local target_file="${target_dir}/${filename}"
            
            if cp "$file" "$target_file"; then
                ((restored_count++))
                log_debug "已恢复: $filename"
            else
                log_error "恢复失败: $filename"
            fi
        fi
    done
    
    log_success "配置备份恢复成功: $backup_name"
    log_info "恢复文件数: $restored_count"
    log_info "目标目录: $target_dir"
    
    return 0
}

# 检查自动备份需求
check_auto_backup_needed() {
    if [[ "$IPV6WGM_AUTO_BACKUP_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local current_time=$(date +%s)
    local last_backup_time=0
    
    if [[ -n "$IPV6WGM_LAST_BACKUP_TIME" ]]; then
        last_backup_time=$(date -d "$IPV6WGM_LAST_BACKUP_TIME" +%s 2>/dev/null || echo "0")
    fi
    
    local time_diff=$((current_time - last_backup_time))
    local backup_interval=86400  # 24小时
    
    case "$IPV6WGM_BACKUP_SCHEDULE" in
        "hourly") backup_interval=3600 ;;
        "daily") backup_interval=86400 ;;
        "weekly") backup_interval=604800 ;;
    esac
    
    if [[ $time_diff -ge $backup_interval ]]; then
        log_info "执行自动备份..."
        create_backup "auto_backup_$(date +%Y%m%d_%H%M%S)" "自动备份"
    fi
}

# 清理过期备份
cleanup_expired_backups() {
    local retention_days="${1:-$IPV6WGM_BACKUP_RETENTION_DAYS}"
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - retention_days * 86400))
    
    log_info "清理 $retention_days 天前的备份..."
    
    local removed_count=0
    for backup_dir in "$IPV6WGM_BACKUP_DIR"/*; do
        if [[ -d "$backup_dir" ]]; then
            local backup_name=$(basename "$backup_dir")
            local backup_time=$(stat -c %Y "$backup_dir" 2>/dev/null || echo "0")
            
            if [[ $backup_time -lt $cutoff_time ]]; then
                rm -rf "$backup_dir"
                ((removed_count++))
                log_debug "已删除过期备份: $backup_name"
            fi
        fi
    done
    
    # 清理压缩备份
    for compressed_file in "$IPV6WGM_BACKUP_DIR"/*.tar.gz; do
        if [[ -f "$compressed_file" ]]; then
            local backup_name=$(basename "$compressed_file" .tar.gz)
            local backup_time=$(stat -c %Y "$compressed_file" 2>/dev/null || echo "0")
            
            if [[ $backup_time -lt $cutoff_time ]]; then
                rm -f "$compressed_file"
                ((removed_count++))
                log_debug "已删除过期压缩备份: $backup_name"
            fi
        fi
    done
    
    log_success "已清理 $removed_count 个过期备份"
    return 0
}

# 获取备份统计信息
get_backup_statistics() {
    echo "=== 配置备份统计 ==="
    echo "自动备份: $IPV6WGM_AUTO_BACKUP_ENABLED"
    echo "保留天数: $IPV6WGM_BACKUP_RETENTION_DAYS"
    echo "压缩备份: $IPV6WGM_BACKUP_COMPRESSION"
    echo "加密备份: $IPV6WGM_BACKUP_ENCRYPTION"
    echo "备份计划: $IPV6WGM_BACKUP_SCHEDULE"
    echo "总备份数: $IPV6WGM_BACKUP_COUNT"
    echo "最后备份: $IPV6WGM_LAST_BACKUP_TIME"
    echo "备份目录: $IPV6WGM_BACKUP_DIR"
    
    # 计算备份目录大小
    if [[ -d "$IPV6WGM_BACKUP_DIR" ]]; then
        local dir_size=$(du -sh "$IPV6WGM_BACKUP_DIR" 2>/dev/null | cut -f1 || echo "未知")
        echo "备份目录大小: $dir_size"
    fi
    
    # 显示最新5个备份
    echo
    echo "最新备份:"
    if command -v jq >/dev/null 2>&1; then
        jq -r '.backups[-5:] | .[] | "\(.name) - \(.timestamp) - \(.description)"' "$IPV6WGM_BACKUP_METADATA_FILE" 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        # 简单的目录列表
        local count=0
        for backup_dir in "$IPV6WGM_BACKUP_DIR"/*; do
            if [[ -d "$backup_dir" && $count -lt 5 ]]; then
                local name=$(basename "$backup_dir")
                echo "  $name - 目录备份"
                ((count++))
            fi
        done
    fi
}

# 导出函数
export -f init_backup_system
export -f create_backup
export -f list_backups
export -f restore_backup
export -f cleanup_expired_backups
export -f get_backup_statistics
