#!/bin/bash

# 增强的配置管理系统
# 提供配置验证、历史记录、导入导出和冲突检测功能

# =============================================================================
# 配置管理变量
# =============================================================================

# 配置历史记录
declare -A IPV6WGM_CONFIG_HISTORY=()
declare -g IPV6WGM_CONFIG_BACKUP_DIR="${IPV6WGM_CONFIG_BACKUP_DIR:-$IPV6WGM_CONFIG_DIR/backups}"
declare -g IPV6WGM_CONFIG_MAX_BACKUPS="${IPV6WGM_CONFIG_MAX_BACKUPS:-10}"

# 配置验证规则
declare -A IPV6WGM_CONFIG_RULES=(
    ["WIREGUARD_PORT"]="port:1:65535"
    ["WEB_PORT"]="port:1:65535"
    ["IPV6_PREFIX"]="ipv6_cidr"
    ["BGP_AS"]="number:1:4294967295"
    ["LOG_LEVEL"]="enum:DEBUG,INFO,WARN,ERROR,FATAL"
    ["AUTO_UPDATE"]="boolean"
    ["DEBUG"]="boolean"
    ["VERBOSE"]="boolean"
)

# 配置模板
declare -A IPV6WGM_CONFIG_TEMPLATES=(
    ["basic"]="basic_config_template"
    ["advanced"]="advanced_config_template"
    ["minimal"]="minimal_config_template"
)

# =============================================================================
# 配置验证函数
# =============================================================================

# 验证配置项
validate_config_item() {
    local key="$1"
    local value="$2"
    local rule="${IPV6WGM_CONFIG_RULES[$key]:-}"
    
    if [[ -z "$rule" ]]; then
        log_debug "配置项 '$key' 无验证规则"
        return 0
    fi
    
    local rule_type=$(echo "$rule" | cut -d: -f1)
    local rule_params=$(echo "$rule" | cut -d: -f2-)
    
    case "$rule_type" in
        "port")
            local min_port=$(echo "$rule_params" | cut -d: -f1)
            local max_port=$(echo "$rule_params" | cut -d: -f2)
            
            if [[ ! "$value" =~ ^[0-9]+$ ]]; then
                log_error "配置项 '$key' 必须是数字: $value"
                return 1
            fi
            
            if [[ $value -lt $min_port || $value -gt $max_port ]]; then
                log_error "配置项 '$key' 超出范围 [$min_port-$max_port]: $value"
                return 1
            fi
            ;;
        "ipv6_cidr")
            if [[ ! "$value" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
                log_error "配置项 '$key' 必须是有效的IPv6 CIDR: $value"
                return 1
            fi
            ;;
        "number")
            local min_val=$(echo "$rule_params" | cut -d: -f1)
            local max_val=$(echo "$rule_params" | cut -d: -f2)
            
            if [[ ! "$value" =~ ^[0-9]+$ ]]; then
                log_error "配置项 '$key' 必须是数字: $value"
                return 1
            fi
            
            if [[ $value -lt $min_val || $value -gt $max_val ]]; then
                log_error "配置项 '$key' 超出范围 [$min_val-$max_val]: $value"
                return 1
            fi
            ;;
        "enum")
            local valid_values=$(echo "$rule_params" | tr ',' ' ')
            local is_valid=false
            
            for valid_val in $valid_values; do
                if [[ "$value" == "$valid_val" ]]; then
                    is_valid=true
                    break
                fi
            done
            
            if [[ "$is_valid" == "false" ]]; then
                log_error "配置项 '$key' 必须是以下值之一 [$valid_values]: $value"
                return 1
            fi
            ;;
        "boolean")
            if [[ ! "$value" =~ ^(true|false|yes|no|1|0)$ ]]; then
                log_error "配置项 '$key' 必须是布尔值: $value"
                return 1
            fi
            ;;
        "string")
            if [[ -z "$value" ]]; then
                log_error "配置项 '$key' 不能为空"
                return 1
            fi
            ;;
        *)
            log_debug "未知的验证规则类型: $rule_type"
            ;;
    esac
    
    return 0
}

# 验证配置文件
validate_config_file() {
    local config_file="$1"
    local errors=0
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    log_info "验证配置文件: $config_file"
    
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # 移除前后空格
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # 验证配置项
        if ! validate_config_item "$key" "$value"; then
            ((errors++))
        fi
    done < "$config_file"
    
    if [[ $errors -eq 0 ]]; then
        log_success "配置文件验证通过"
        return 0
    else
        log_error "配置文件验证失败，发现 $errors 个错误"
        return 1
    fi
}

# =============================================================================
# 配置历史记录管理
# =============================================================================

# 创建配置备份
create_config_backup() {
    local config_file="$1"
    local backup_name="${2:-backup_$(date +%Y%m%d_%H%M%S)}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    # 创建备份目录
    mkdir -p "$IPV6WGM_CONFIG_BACKUP_DIR" || {
        log_error "无法创建备份目录: $IPV6WGM_CONFIG_BACKUP_DIR"
        return 1
    }
    
    local backup_file="$IPV6WGM_CONFIG_BACKUP_DIR/${backup_name}.conf"
    
    # 复制配置文件
    cp "$config_file" "$backup_file" || {
        log_error "无法创建配置备份: $backup_file"
        return 1
    }
    
    # 记录备份信息
    local backup_info="$(date '+%Y-%m-%d %H:%M:%S')|$backup_file|$(stat -c%s "$config_file")"
    IPV6WGM_CONFIG_HISTORY[$backup_name]="$backup_info"
    
    log_success "配置备份已创建: $backup_file"
    echo "$backup_file"
}

# 列出配置备份
list_config_backups() {
    local config_file="$1"
    local config_name=$(basename "$config_file" .conf)
    
    echo "=== 配置备份列表 ==="
    echo "配置文件: $config_file"
    echo ""
    
    if [[ -d "$IPV6WGM_CONFIG_BACKUP_DIR" ]]; then
        local backup_count=0
        for backup in "$IPV6WGM_CONFIG_BACKUP_DIR"/*.conf; do
            if [[ -f "$backup" ]]; then
                local backup_name=$(basename "$backup" .conf)
                local backup_time=$(stat -c%y "$backup" 2>/dev/null || echo "未知时间")
                local backup_size=$(stat -c%s "$backup" 2>/dev/null || echo "0")
                
                echo "$backup_name:"
                echo "  文件: $backup"
                echo "  时间: $backup_time"
                echo "  大小: $backup_size 字节"
                echo ""
                
                ((backup_count++))
            fi
        done
        
        if [[ $backup_count -eq 0 ]]; then
            echo "无配置备份"
        else
            echo "总计: $backup_count 个备份"
        fi
    else
        echo "备份目录不存在: $IPV6WGM_CONFIG_BACKUP_DIR"
    fi
}

# 恢复配置备份
restore_config_backup() {
    local config_file="$1"
    local backup_name="$2"
    
    local backup_file="$IPV6WGM_CONFIG_BACKUP_DIR/${backup_name}.conf"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    # 创建当前配置的备份
    create_config_backup "$config_file" "pre_restore_$(date +%Y%m%d_%H%M%S)"
    
    # 恢复配置
    cp "$backup_file" "$config_file" || {
        log_error "无法恢复配置备份: $backup_file"
        return 1
    }
    
    log_success "配置已从备份恢复: $backup_name"
    return 0
}

# 清理旧备份
cleanup_old_backups() {
    local config_file="$1"
    local max_backups="${2:-$IPV6WGM_CONFIG_MAX_BACKUPS}"
    
    if [[ ! -d "$IPV6WGM_CONFIG_BACKUP_DIR" ]]; then
        return 0
    fi
    
    # 按修改时间排序，删除最旧的备份
    local mapfile -t backup_files < <(ls -t "$IPV6WGM_CONFIG_BACKUP_DIR"/*.conf 2>/dev/null)
    local backup_count=${#backup_files[@]}
    
    if [[ $backup_count -gt $max_backups ]]; then
        local files_to_delete=$((backup_count - max_backups))
        
        for ((i=backup_count-1; i>=max_backups; i--)); do
            local file_to_delete="${backup_files[$i]}"
            rm -f "$file_to_delete" && {
                log_info "已删除旧备份: $(basename "$file_to_delete")"
            }
        done
        
        log_success "已清理 $files_to_delete 个旧备份"
    fi
}

# =============================================================================
# 配置导入导出
# =============================================================================

# 导出配置
export_config() {
    local config_file="$1"
    local export_file="$2"
    local format="${3:-plain}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    if [[ -z "$export_file" ]]; then
        export_file="/tmp/ipv6wgm_config_export_$(date +%Y%m%d_%H%M%S).$format"
    fi
    
    case "$format" in
        "plain"|"conf")
            cp "$config_file" "$export_file"
            ;;
        "json")
            {
                echo "{"
                echo "  \"config_file\": \"$config_file\","
                echo "  \"export_time\": \"$(date -Iseconds)\","
                echo "  \"settings\": {"
                
                local first=true
                while IFS='=' read -r key value; do
                    [[ "$key" =~ ^[[:space:]]*# ]] && continue
                    [[ -z "$key" ]] && continue
                    
                    key=$(echo "$key" | xargs)
                    value=$(echo "$value" | xargs)
                    
                    if [[ "$first" == "true" ]]; then
                        first=false
                    else
                        echo ","
                    fi
                    
                    echo -n "    \"$key\": \"$value\""
                done < "$config_file"
                
                echo ""
                echo "  }"
                echo "}"
            } > "$export_file"
            ;;
        "yaml")
            {
                echo "# IPv6 WireGuard Manager 配置导出"
                echo "# 导出时间: $(date -Iseconds)"
                echo ""
                
                while IFS='=' read -r key value; do
                    [[ "$key" =~ ^[[:space:]]*# ]] && continue
                    [[ -z "$key" ]] && continue
                    
                    key=$(echo "$key" | xargs)
                    value=$(echo "$value" | xargs)
                    
                    echo "$key: $value"
                done < "$config_file"
            } > "$export_file"
            ;;
        *)
            log_error "不支持的导出格式: $format"
            return 1
            ;;
    esac
    
    log_success "配置已导出: $export_file"
    echo "$export_file"
}

# 导入配置
import_config() {
    local import_file="$1"
    local config_file="$2"
    local format="${3:-auto}"
    
    if [[ ! -f "$import_file" ]]; then
        log_error "导入文件不存在: $import_file"
        return 1
    fi
    
    if [[ -z "$config_file" ]]; then
        config_file="$IPV6WGM_CONFIG_DIR/manager.conf"
    fi
    
    # 自动检测格式
    if [[ "$format" == "auto" ]]; then
        case "$import_file" in
            *.json) format="json" ;;
            *.yaml|*.yml) format="yaml" ;;
            *.conf|*.cfg) format="plain" ;;
            *) format="plain" ;;
        esac
    fi
    
    # 创建当前配置的备份
    create_config_backup "$config_file" "pre_import_$(date +%Y%m%d_%H%M%S)"
    
    case "$format" in
        "plain"|"conf")
            cp "$import_file" "$config_file"
            ;;
        "json")
            if command -v jq &> /dev/null; then
                jq -r '.settings | to_entries | .[] | "\(.key)=\(.value)"' "$import_file" > "$config_file"
            else
                log_error "导入JSON格式需要jq命令"
                return 1
            fi
            ;;
        "yaml")
            if command -v yq &> /dev/null; then
                yq eval 'to_entries | .[] | "\(.key)=\(.value)"' "$import_file" > "$config_file"
            else
                log_error "导入YAML格式需要yq命令"
                return 1
            fi
            ;;
        *)
            log_error "不支持的导入格式: $format"
            return 1
            ;;
    esac
    
    # 验证导入的配置
    if validate_config_file "$config_file"; then
        log_success "配置已导入并验证: $config_file"
        return 0
    else
        log_error "导入的配置验证失败"
        return 1
    fi
}

# =============================================================================
# 配置冲突检测
# =============================================================================

# 检测配置冲突
detect_config_conflicts() {
    local config_file="$1"
    local conflicts=()
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    log_info "检测配置冲突: $config_file"
    
    # 检查端口冲突
    local wireguard_port=$(grep "^WIREGUARD_PORT=" "$config_file" | cut -d= -f2 | xargs)
    local web_port=$(grep "^WEB_PORT=" "$config_file" | cut -d= -f2 | xargs)
    
    if [[ "$wireguard_port" == "$web_port" ]]; then
        conflicts+=("端口冲突: WIREGUARD_PORT 和 WEB_PORT 使用相同端口 $wireguard_port")
    fi
    
    # 检查IPv6前缀冲突
    local ipv6_prefix=$(grep "^IPV6_PREFIX=" "$config_file" | cut -d= -f2 | xargs)
    if [[ -n "$ipv6_prefix" ]]; then
        # 检查是否与系统现有网络冲突
        if command -v ip &> /dev/null; then
            local existing_prefixes=$(ip -6 route show | grep -o '[0-9a-fA-F:]*/[0-9]*' | head -5)
            for existing in $existing_prefixes; do
                if [[ "$ipv6_prefix" == "$existing" ]]; then
                    conflicts+=("IPv6前缀冲突: 系统已存在相同前缀 $ipv6_prefix")
                fi
            done
        fi
    fi
    
    # 检查BGP AS号冲突
    local bgp_as=$(grep "^BGP_AS=" "$config_file" | cut -d= -f2 | xargs)
    if [[ -n "$bgp_as" ]]; then
        # 检查是否为私有AS号范围
        if [[ $bgp_as -ge 64512 && $bgp_as -le 65535 ]]; then
            log_info "使用私有BGP AS号: $bgp_as"
        elif [[ $bgp_as -ge 4200000000 && $bgp_as -le 4294967294 ]]; then
            log_info "使用私有BGP AS号: $bgp_as"
        else
            log_warn "使用公有BGP AS号: $bgp_as，请确保已注册"
        fi
    fi
    
    if [[ ${#conflicts[@]} -eq 0 ]]; then
        log_success "未发现配置冲突"
        return 0
    else
        log_error "发现配置冲突:"
        for conflict in "${conflicts[@]}"; do
            log_error "  $conflict"
        done
        return 1
    fi
}

# =============================================================================
# 配置模板管理
# =============================================================================

# 生成配置模板
generate_config_template() {
    local template_type="$1"
    local output_file="$2"
    
    if [[ -z "$output_file" ]]; then
        output_file="/tmp/ipv6wgm_config_template_${template_type}_$(date +%Y%m%d_%H%M%S).conf"
    fi
    
    case "$template_type" in
        "basic")
            cat > "$output_file" << 'EOF'
# IPv6 WireGuard Manager 基础配置模板
# 生成时间: $(date)

# 基本设置
WIREGUARD_PORT=51820
WEB_PORT=8080
LOG_LEVEL=INFO
DEBUG=false
VERBOSE=false

# IPv6设置
IPV6_PREFIX=2001:db8::/64
IPV6_GATEWAY=2001:db8::1

# BGP设置
BGP_ENABLED=true
BGP_AS=65001
BGP_ROUTER_ID=192.168.1.1

# 安全设置
AUTO_UPDATE=true
FIREWALL_ENABLED=true
EOF
            ;;
        "advanced")
            cat > "$output_file" << 'EOF'
# IPv6 WireGuard Manager 高级配置模板
# 生成时间: $(date)

# 基本设置
WIREGUARD_PORT=51820
WEB_PORT=8080
LOG_LEVEL=INFO
DEBUG=false
VERBOSE=false

# IPv6设置
IPV6_PREFIX=2001:db8::/64
IPV6_GATEWAY=2001:db8::1
IPV6_DHCP_ENABLED=true

# BGP设置
BGP_ENABLED=true
BGP_AS=65001
BGP_ROUTER_ID=192.168.1.1
BGP_NEIGHBORS=2001:db8::100,2001:db8::101

# 安全设置
AUTO_UPDATE=true
FIREWALL_ENABLED=true
SSL_ENABLED=true
SSL_CERT_PATH=/etc/ssl/certs/ipv6wgm.crt
SSL_KEY_PATH=/etc/ssl/private/ipv6wgm.key

# 监控设置
MONITORING_ENABLED=true
ALERT_EMAIL=admin@example.com
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=80
ALERT_THRESHOLD_DISK=80

# 备份设置
BACKUP_ENABLED=true
BACKUP_INTERVAL=24
BACKUP_RETENTION_DAYS=30
EOF
            ;;
        "minimal")
            cat > "$output_file" << 'EOF'
# IPv6 WireGuard Manager 最小配置模板
# 生成时间: $(date)

# 基本设置
WIREGUARD_PORT=51820
WEB_PORT=8080
LOG_LEVEL=WARN

# IPv6设置
IPV6_PREFIX=2001:db8::/64

# BGP设置
BGP_ENABLED=false
EOF
            ;;
        *)
            log_error "未知的模板类型: $template_type"
            return 1
            ;;
    esac
    
    log_success "配置模板已生成: $output_file"
    echo "$output_file"
}

# 导出函数
export -f validate_config_item validate_config_file
export -f create_config_backup list_config_backups restore_config_backup cleanup_old_backups
export -f export_config import_config
export -f detect_config_conflicts
export -f generate_config_template
