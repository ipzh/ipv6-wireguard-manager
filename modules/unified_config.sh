#!/bin/bash

# IPv6 WireGuard Manager 统一配置管理模块
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

# 配置版本
CONFIG_VERSION="1.0.0"

# 统一配置路径定义
CONFIG_PATHS=(
    "INSTALL_DIR=/opt/ipv6-wireguard-manager"
    "CONFIG_DIR=/etc/ipv6-wireguard-manager"
    "LOG_DIR=/var/log/ipv6-wireguard-manager"
    "BIN_DIR=/usr/local/bin"
    "SERVICE_DIR=/etc/systemd/system"
    "BACKUP_DIR=/var/backups/ipv6-wireguard"
    "CLIENT_CONFIG_DIR=/etc/wireguard/clients"
    "MODULES_DIR=/opt/ipv6-wireguard-manager/modules"
    "SCRIPTS_DIR=/opt/ipv6-wireguard-manager/scripts"
    "EXAMPLES_DIR=/opt/ipv6-wireguard-manager/examples"
    "DOCS_DIR=/opt/ipv6-wireguard-manager/docs"
)

# 默认配置值
DEFAULT_CONFIG=(
    "WIREGUARD_PORT=51820"
    "WIREGUARD_INTERFACE=wg0"
    "WIREGUARD_NETWORK=10.0.0.0/24"
    "IPV6_PREFIX=2001:db8::/56"
    "BIRD_VERSION=auto"
    "FIREWALL_TYPE=auto"
    "WEB_PORT=8080"
    "WEB_USER=admin"
    "WEB_PASS=${WEB_ADMIN_PASSWORD:-$(openssl rand -base64 12)}"
    "LOG_LEVEL=INFO"
    "INSTALL_WIREGUARD=true"
    "INSTALL_BIRD=true"
    "INSTALL_FIREWALL=true"
    "INSTALL_WEB_INTERFACE=true"
    "INSTALL_MONITORING=true"
    "SECURE_PERMISSIONS=true"
    "AUTO_UPDATE=false"
    "BACKUP_ENABLED=true"
    "LAZY_LOADING=true"
    "CACHE_ENABLED=true"
    "CACHE_TTL=300"
)

# 初始化配置系统
init_config_system() {
    log_info "初始化统一配置系统..."
    
    # 设置配置路径
    for config_path in "${CONFIG_PATHS[@]}"; do
        export "$config_path"
    done
    
    # 设置默认配置值
    for default_config in "${DEFAULT_CONFIG[@]}"; do
        local key=$(echo "$default_config" | cut -d'=' -f1)
        local value=$(echo "$default_config" | cut -d'=' -f2-)
        if [[ -z "${!key:-}" ]]; then
            # 使用安全的变量设置方式，避免eval
            declare "$key=$value"
            export "$key"
        fi
    done
    
    log_success "统一配置系统初始化完成"
}

# 统一的配置加载函数
load_config() {
    local config_file="$1"
    local config_dir="$(dirname "$config_file")"
    
    # 确保配置目录存在
    execute_command "mkdir -p '$config_dir'" "创建配置目录" "true"
    
    # 如果配置文件不存在，创建默认配置
    if [[ ! -f "$config_file" ]]; then
        create_default_config "$config_file"
    fi
    
    # 验证配置文件版本
    validate_config_version "$config_file"
    
    # 加载配置文件
    source "$config_file"
    log_info "配置文件已加载: $config_file"
}

# 创建默认配置文件
create_default_config() {
    local config_file="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$config_file" << EOF
# IPv6 WireGuard Manager 配置文件
# 版本: $CONFIG_VERSION
# 生成时间: $timestamp

# 基本配置
INSTALL_DIR="$INSTALL_DIR"
CONFIG_DIR="$CONFIG_DIR"
LOG_DIR="$LOG_DIR"
LOG_FILE="\$LOG_DIR/manager.log"
LOG_LEVEL="$LOG_LEVEL"

# 功能开关
INSTALL_WIREGUARD="$INSTALL_WIREGUARD"
INSTALL_BIRD="$INSTALL_BIRD"
INSTALL_FIREWALL="$INSTALL_FIREWALL"
INSTALL_WEB_INTERFACE="$INSTALL_WEB_INTERFACE"
INSTALL_MONITORING="$INSTALL_MONITORING"

# 安全配置
SECURE_PERMISSIONS="$SECURE_PERMISSIONS"
AUTO_UPDATE="$AUTO_UPDATE"
BACKUP_ENABLED="$BACKUP_ENABLED"

# 性能配置
LAZY_LOADING="$LAZY_LOADING"
CACHE_ENABLED="$CACHE_ENABLED"
CACHE_TTL="$CACHE_TTL"

# WireGuard配置
WIREGUARD_PORT="$WIREGUARD_PORT"
WIREGUARD_INTERFACE="$WIREGUARD_INTERFACE"
WIREGUARD_NETWORK="$WIREGUARD_NETWORK"

# IPv6配置
IPV6_PREFIX="$IPV6_PREFIX"

# BIRD配置
BIRD_VERSION="$BIRD_VERSION"

# 防火墙配置
FIREWALL_TYPE="$FIREWALL_TYPE"

# Web界面配置
WEB_PORT="$WEB_PORT"
WEB_USER="$WEB_USER"
WEB_PASS="$WEB_PASS"

# 备份配置
BACKUP_DIR="$BACKUP_DIR"
CLIENT_CONFIG_DIR="$CLIENT_CONFIG_DIR"
EOF
    
    log_info "默认配置文件已创建: $config_file"
}

# 验证配置版本
validate_config_version() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        local file_version=$(grep "^# 版本:" "$config_file" | cut -d' ' -f3 2>/dev/null || echo "unknown")
        
        if [[ "$file_version" != "$CONFIG_VERSION" ]]; then
            log_warn "配置文件版本不匹配: 文件版本=$file_version, 当前版本=$CONFIG_VERSION"
            
            # 备份旧配置文件
            local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
            execute_command "cp '$config_file' '$backup_file'" "备份旧配置文件" "true"
            log_info "旧配置文件已备份到: $backup_file"
            
            # 创建新配置文件
            create_default_config "$config_file"
            log_info "已创建新版本配置文件"
        fi
    fi
}

# 配置项验证
validate_config_item() {
    local key="$1"
    local value="$2"
    local validation_type="$3"
    
    case "$validation_type" in
        "port")
            if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 1 && value <= 65535 )); then
                return 0
            else
                log_error "无效的端口号: $value"
                return 1
            fi
            ;;
        "ipv4")
            if validate_ipv4 "$value"; then
                return 0
            else
                log_error "无效的IPv4地址: $value"
                return 1
            fi
            ;;
        "ipv6")
            if validate_ipv6 "$value"; then
                return 0
            else
                log_error "无效的IPv6地址: $value"
                return 1
            fi
            ;;
        "cidr")
            if validate_cidr "$value"; then
                return 0
            else
                log_error "无效的CIDR格式: $value"
                return 1
            fi
            ;;
        "boolean")
            if [[ "$value" == "true" || "$value" == "false" ]]; then
                return 0
            else
                log_error "无效的布尔值: $value"
                return 1
            fi
            ;;
        "log_level")
            if [[ "$value" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
                return 0
            else
                log_error "无效的日志级别: $value"
                return 1
            fi
            ;;
        *)
            return 0
            ;;
    esac
}

# 验证所有配置项
validate_all_config() {
    log_info "验证配置项..."
    
    local validation_errors=0
    
    # 验证端口配置
    if ! validate_config_item "WIREGUARD_PORT" "$WIREGUARD_PORT" "port"; then
        ((validation_errors++))
    fi
    
    if ! validate_config_item "WEB_PORT" "$WEB_PORT" "port"; then
        ((validation_errors++))
    fi
    
    # 验证网络配置
    if ! validate_config_item "WIREGUARD_NETWORK" "$WIREGUARD_NETWORK" "cidr"; then
        ((validation_errors++))
    fi
    
    if ! validate_config_item "IPV6_PREFIX" "$IPV6_PREFIX" "cidr"; then
        ((validation_errors++))
    fi
    
    # 验证日志级别
    if ! validate_config_item "LOG_LEVEL" "$LOG_LEVEL" "log_level"; then
        ((validation_errors++))
    fi
    
    # 验证布尔值配置
    local boolean_configs=("INSTALL_WIREGUARD" "INSTALL_BIRD" "INSTALL_FIREWALL" "INSTALL_WEB_INTERFACE" "SECURE_PERMISSIONS" "AUTO_UPDATE" "BACKUP_ENABLED" "LAZY_LOADING" "CACHE_ENABLED")
    
    for config in "${boolean_configs[@]}"; do
        if ! validate_config_item "$config" "${!config}" "boolean"; then
            ((validation_errors++))
        fi
    done
    
    if [[ $validation_errors -eq 0 ]]; then
        log_success "所有配置项验证通过"
        return 0
    else
        log_error "发现 $validation_errors 个配置项验证错误"
        return 1
    fi
}

# 获取配置值
get_config_value() {
    local key="$1"
    local default_value="${2:-}"
    
    if [[ -n "${!key:-}" ]]; then
        echo "${!key}"
    else
        echo "$default_value"
    fi
}

# 设置配置值
set_config_value() {
    local key="$1"
    local value="$2"
    local config_file="${3:-$CONFIG_FILE}"
    
    # 验证配置值
    case "$key" in
        "WIREGUARD_PORT"|"WEB_PORT")
            if ! validate_config_item "$key" "$value" "port"; then
                return 1
            fi
            ;;
        "WIREGUARD_NETWORK"|"IPV6_PREFIX")
            if ! validate_config_item "$key" "$value" "cidr"; then
                return 1
            fi
            ;;
        "LOG_LEVEL")
            if ! validate_config_item "$key" "$value" "log_level"; then
                return 1
            fi
            ;;
    esac
    
    # 更新配置值，使用安全的变量设置方式
    declare "$key=$value"
    export "$key"
    
    # 更新配置文件
    if [[ -f "$config_file" ]]; then
        if grep -q "^$key=" "$config_file"; then
            execute_command "sed -i 's/^$key=.*/$key=\"$value\"/' '$config_file'" "更新配置项: $key" "true"
        else
            execute_command "echo '$key=\"$value\"' >> '$config_file'" "添加配置项: $key" "true"
        fi
    fi
    
    log_info "配置项已更新: $key=$value"
}

# 显示配置信息
show_config_info() {
    echo -e "${CYAN}=== 配置信息 ===${NC}"
    echo -e "${GREEN}配置版本: $CONFIG_VERSION${NC}"
    echo -e "${GREEN}配置文件: $CONFIG_FILE${NC}"
    echo -e "${GREEN}安装目录: $INSTALL_DIR${NC}"
    echo -e "${GREEN}配置目录: $CONFIG_DIR${NC}"
    echo -e "${GREEN}日志目录: $LOG_DIR${NC}"
    echo -e "${GREEN}日志级别: $LOG_LEVEL${NC}"
    echo
    echo -e "${YELLOW}功能开关:${NC}"
    echo -e "  WireGuard: $INSTALL_WIREGUARD"
    echo -e "  BIRD: $INSTALL_BIRD"
    echo -e "  防火墙: $INSTALL_FIREWALL"
    echo -e "  Web界面: $INSTALL_WEB_INTERFACE"
    echo -e "  监控: $INSTALL_MONITORING"
    echo
    echo -e "${YELLOW}性能配置:${NC}"
    echo -e "  懒加载: $LAZY_LOADING"
    echo -e "  缓存: $CACHE_ENABLED"
    echo -e "  缓存TTL: $CACHE_TTL秒"
}

# 导出配置函数
export -f init_config_system load_config create_default_config validate_config_version
export -f validate_config_item validate_all_config get_config_value set_config_value show_config_info
