#!/bin/bash

# IPv6 WireGuard Manager 公共函数库
# 版本: 1.13
# 包含所有重复的函数定义，用于统一管理

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 统一的日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "DEBUG")
            if [[ "${LOG_LEVEL:-info}" == "debug" ]]; then
                echo -e "${BLUE}[$timestamp] [$level] $message${NC}" >&2
            fi
            ;;
        *)
            echo -e "[$timestamp] [$level] $message" >&2
            ;;
    esac
    
    # 写入日志文件（如果LOG_DIR存在）
    if [[ -n "${LOG_DIR:-}" ]] && [[ -d "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_DIR/manager.log"
    fi
}

# 统一的错误处理函数
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# 警告函数
warn() {
    log "WARN" "$1"
}

# 信息函数
info() {
    log "INFO" "$1"
}

# 调试函数
debug() {
    log "DEBUG" "$1"
}

# 统一的菜单显示函数
show_menu_header() {
    local title="$1"
    local title_length=${#title}
    local padding=$(( (60 - title_length) / 2 ))
    
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${WHITE}║%*s%s%*s║${NC}\n" $padding "" "$title" $((60 - title_length - padding))
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# 菜单选项显示函数
show_menu_option() {
    local number="$1"
    local description="$2"
    echo -e "  ${GREEN}$number.${NC} $description"
}

# 获取用户菜单选择
get_menu_choice() {
    local max_option="$1"
    local prompt="${2:-请选择操作}"
    read -p "$prompt (0-$max_option): " choice
    echo "$choice"
}

# 验证菜单选择
validate_menu_choice() {
    local choice="$1"
    local max_option="$2"
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 0 ]] && [[ "$choice" -le "$max_option" ]]; then
        return 0
    else
        log "ERROR" "Invalid choice: $choice (must be between 0 and $max_option)"
        return 1
    fi
}

# 统一的用户确认函数
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " response
        response="${response:-y}"
    else
        read -p "$message [y/N]: " response
        response="${response:-n}"
    fi
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 统一的文件存在检查
check_file_exists() {
    local file_path="$1"
    local error_message="${2:-File not found: $file_path}"
    
    if [[ -f "$file_path" ]]; then
        return 0
    else
        log "ERROR" "$error_message"
        return 1
    fi
}

# 统一的目录存在检查
check_directory_exists() {
    local dir_path="$1"
    local error_message="${2:-Directory not found: $dir_path}"
    
    if [[ -d "$dir_path" ]]; then
        return 0
    else
        log "ERROR" "$error_message"
        return 1
    fi
}

# 创建目录（如果不存在）
ensure_directory() {
    local dir_path="$1"
    local permissions="${2:-755}"
    
    if [[ ! -d "$dir_path" ]]; then
        if mkdir -p "$dir_path"; then
            chmod "$permissions" "$dir_path"
            log "INFO" "Created directory: $dir_path"
            return 0
        else
            log "ERROR" "Failed to create directory: $dir_path"
            return 1
        fi
    fi
    return 0
}

# 统一的权限检查
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

# 统一的系统检测
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 统一的端口检查
is_port_in_use() {
    local port="$1"
    local protocol="${2:-tcp}"
    
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tuln | grep -q ":$port "; then
            return 0
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":$port "; then
            return 0
        fi
    fi
    return 1
}

# 统一的IPv6检查
check_ipv6() {
    if [[ -f /proc/net/if_inet6 ]]; then
        return 0
    else
        return 1
    fi
}

# 统一的网络接口获取
get_network_interfaces() {
    if command -v ip >/dev/null 2>&1; then
        ip -o link show | awk -F': ' '{print $2}' | grep -v lo
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig -a | grep -o '^[^ ]*' | grep -v lo
    else
        log "WARN" "Cannot detect network interfaces"
        return 1
    fi
}

# 统一的清理函数
cleanup_temp_files() {
    local temp_files=("$@")
    for file in "${temp_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log "DEBUG" "Cleaned up temp file: $file"
        fi
    done
}

# 统一的进度显示
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}$message: [${NC}"
    printf "%*s" $filled | tr ' ' '='
    printf "%*s" $empty | tr ' ' ' '
    printf "${CYAN}] %d%% (%d/%d)${NC}" $percent $current $total
}

# 统一的等待函数
wait_for_condition() {
    local condition="$1"
    local timeout="${2:-30}"
    local message="${3:-Waiting for condition}"
    
    local count=0
    while ! eval "$condition" && [[ $count -lt $timeout ]]; do
        printf "\r${YELLOW}$message... (%d/%d)${NC}" $((count + 1)) $timeout
        sleep 1
        ((count++))
    done
    echo
    
    if eval "$condition"; then
        log "INFO" "Condition met: $condition"
        return 0
    else
        log "ERROR" "Timeout waiting for condition: $condition"
        return 1
    fi
}

# 统一的配置验证
validate_config() {
    local config_file="$1"
    local required_fields=("$@")
    
    if [[ ! -f "$config_file" ]]; then
        log "ERROR" "Configuration file not found: $config_file"
        return 1
    fi
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field" "$config_file"; then
            log "ERROR" "Required field missing in config: $field"
            return 1
        fi
    done
    
    return 0
}

# 统一的备份函数
backup_file() {
    local file_path="$1"
    local backup_dir="${2:-/tmp/backups}"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    if [[ -f "$file_path" ]]; then
        ensure_directory "$backup_dir"
        local backup_file="$backup_dir/$(basename "$file_path").$timestamp"
        if cp "$file_path" "$backup_file"; then
            log "INFO" "Backed up $file_path to $backup_file"
            echo "$backup_file"
            return 0
        else
            log "ERROR" "Failed to backup $file_path"
            return 1
        fi
    else
        log "WARN" "File not found for backup: $file_path"
        return 1
    fi
}

# 统一的恢复函数
restore_file() {
    local backup_file="$1"
    local target_file="$2"
    
    if [[ -f "$backup_file" ]]; then
        if cp "$backup_file" "$target_file"; then
            log "INFO" "Restored $target_file from $backup_file"
            return 0
        else
            log "ERROR" "Failed to restore $target_file"
            return 1
        fi
    else
        log "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
}

# 统一的版本比较
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    if [[ "$version1" == "$version2" ]]; then
        echo "equal"
    elif [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version1" ]]; then
        echo "less"
    else
        echo "greater"
    fi
}

# 统一的IP地址验证
validate_ipv4() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a ip_parts=($ip)
        for part in "${ip_parts[@]}"; do
            if [[ $part -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

validate_ipv6() {
    local ip="$1"
    if [[ $ip =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$ ]] || [[ $ip =~ ^::1$ ]] || [[ $ip =~ ^::$ ]]; then
        return 0
    fi
    return 1
}

# 统一的CIDR验证
validate_cidr() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local prefix="${cidr#*/}"
    
    if [[ $prefix =~ ^[0-9]+$ ]] && [[ $prefix -ge 0 ]] && [[ $prefix -le 128 ]]; then
        if validate_ipv4 "$ip" || validate_ipv6 "$ip"; then
            return 0
        fi
    fi
    return 1
}

# 统一的随机字符串生成
generate_random_string() {
    local length="${1:-16}"
    local charset="${2:-a-zA-Z0-9}"
    
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 $((length * 3/4)) | tr -d "=+/" | cut -c1-$length
    else
        cat /dev/urandom | tr -dc "$charset" | head -c $length
    fi
}

# 统一的密钥生成
generate_wireguard_key() {
    if command -v wg >/dev/null 2>&1; then
        wg genkey
    else
        generate_random_string 32 "a-zA-Z0-9+/"
    fi
}

# 统一的公钥生成
generate_wireguard_public_key() {
    local private_key="$1"
    if command -v wg >/dev/null 2>&1; then
        echo "$private_key" | wg pubkey
    else
        log "WARN" "WireGuard tools not available, cannot generate public key"
        return 1
    fi
}

# 统一的文件权限设置
set_secure_permissions() {
    local file_path="$1"
    local permissions="${2:-600}"
    
    if [[ -f "$file_path" ]]; then
        chmod "$permissions" "$file_path"
        log "DEBUG" "Set permissions $permissions for $file_path"
        return 0
    else
        log "WARN" "File not found for permission setting: $file_path"
        return 1
    fi
}

# 统一的服务状态检查
check_service_status() {
    local service_name="$1"
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet "$service_name"; then
            echo "active"
        elif systemctl is-failed --quiet "$service_name"; then
            echo "failed"
        else
            echo "inactive"
        fi
    elif command -v service >/dev/null 2>&1; then
        if service "$service_name" status >/dev/null 2>&1; then
            echo "active"
        else
            echo "inactive"
        fi
    else
        log "WARN" "Cannot check service status: $service_name"
        echo "unknown"
    fi
}

# 统一的服务管理
manage_service() {
    local action="$1"
    local service_name="$2"
    
    case "$action" in
        "start")
            if command -v systemctl >/dev/null 2>&1; then
                systemctl start "$service_name"
            elif command -v service >/dev/null 2>&1; then
                service "$service_name" start
            else
                log "ERROR" "Cannot start service: $service_name"
                return 1
            fi
            ;;
        "stop")
            if command -v systemctl >/dev/null 2>&1; then
                systemctl stop "$service_name"
            elif command -v service >/dev/null 2>&1; then
                service "$service_name" stop
            else
                log "ERROR" "Cannot stop service: $service_name"
                return 1
            fi
            ;;
        "restart")
            if command -v systemctl >/dev/null 2>&1; then
                systemctl restart "$service_name"
            elif command -v service >/dev/null 2>&1; then
                service "$service_name" restart
            else
                log "ERROR" "Cannot restart service: $service_name"
                return 1
            fi
            ;;
        "enable")
            if command -v systemctl >/dev/null 2>&1; then
                systemctl enable "$service_name"
            elif command -v chkconfig >/dev/null 2>&1; then
                chkconfig "$service_name" on
            else
                log "WARN" "Cannot enable service: $service_name"
            fi
            ;;
        "disable")
            if command -v systemctl >/dev/null 2>&1; then
                systemctl disable "$service_name"
            elif command -v chkconfig >/dev/null 2>&1; then
                chkconfig "$service_name" off
            else
                log "WARN" "Cannot disable service: $service_name"
            fi
            ;;
        *)
            log "ERROR" "Unknown service action: $action"
            return 1
            ;;
    esac
}

# 统一的包管理器检测
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# 统一的包安装
install_package() {
    local package_name="$1"
    local package_manager=$(detect_package_manager)
    
    case "$package_manager" in
        "apt")
            apt update && apt install -y "$package_name"
            ;;
        "yum")
            yum install -y "$package_name"
            ;;
        "dnf")
            dnf install -y "$package_name"
            ;;
        "pacman")
            pacman -S --noconfirm "$package_name"
            ;;
        "zypper")
            zypper install -y "$package_name"
            ;;
        *)
            log "ERROR" "Unsupported package manager: $package_manager"
            return 1
            ;;
    esac
}

# 统一的包检查
is_package_installed() {
    local package_name="$1"
    local package_manager=$(detect_package_manager)
    
    case "$package_manager" in
        "apt")
            dpkg -l | grep -q "^ii  $package_name "
            ;;
        "yum"|"dnf")
            rpm -q "$package_name" >/dev/null 2>&1
            ;;
        "pacman")
            pacman -Q "$package_name" >/dev/null 2>&1
            ;;
        "zypper")
            zypper se -i "$package_name" >/dev/null 2>&1
            ;;
        *)
            log "WARN" "Cannot check package installation: $package_name"
            return 1
            ;;
    esac
}

# 统一的防火墙检测
detect_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables"
    else
        echo "none"
    fi
}

# 统一的防火墙管理
manage_firewall() {
    local action="$1"
    local rule="$2"
    local firewall_type=$(detect_firewall)
    
    case "$firewall_type" in
        "ufw")
            case "$action" in
                "allow")
                    ufw allow "$rule"
                    ;;
                "deny")
                    ufw deny "$rule"
                    ;;
                "delete")
                    ufw delete "$rule"
                    ;;
            esac
            ;;
        "firewalld")
            case "$action" in
                "allow")
                    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' port protocol='tcp' port='$rule' accept"
                    firewall-cmd --reload
                    ;;
                "deny")
                    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' port protocol='tcp' port='$rule' reject"
                    firewall-cmd --reload
                    ;;
            esac
            ;;
        "iptables")
            case "$action" in
                "allow")
                    iptables -A INPUT -p tcp --dport "$rule" -j ACCEPT
                    ;;
                "deny")
                    iptables -A INPUT -p tcp --dport "$rule" -j REJECT
                    ;;
            esac
            ;;
        *)
            log "WARN" "Unsupported firewall: $firewall_type"
            return 1
            ;;
    esac
}

# 统一的配置模板替换
replace_template_vars() {
    local template_file="$1"
    local output_file="$2"
    shift 2
    local replacements=("$@")
    
    if [[ ! -f "$template_file" ]]; then
        log "ERROR" "Template file not found: $template_file"
        return 1
    fi
    
    cp "$template_file" "$output_file"
    
    for replacement in "${replacements[@]}"; do
        local var_name="${replacement%%=*}"
        local var_value="${replacement#*=}"
        sed -i "s|${var_name}|${var_value}|g" "$output_file"
    done
    
    log "DEBUG" "Template processed: $template_file -> $output_file"
    return 0
}

# 统一的JSON处理（简单版本）
json_get_value() {
    local json_string="$1"
    local key="$2"
    
    echo "$json_string" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# 统一的CSV处理
csv_get_field() {
    local csv_line="$1"
    local field_number="$2"
    local delimiter="${3:-,}"
    
    echo "$csv_line" | cut -d"$delimiter" -f"$field_number"
}

# 统一的URL验证
validate_url() {
    local url="$1"
    
    if [[ $url =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# 统一的文件下载
download_file() {
    local url="$1"
    local output_file="$2"
    
    if ! validate_url "$url"; then
        log "ERROR" "Invalid URL: $url"
        return 1
    fi
    
    if command -v wget >/dev/null 2>&1; then
        wget -O "$output_file" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$output_file" "$url"
    else
        log "ERROR" "No download tool available (wget or curl)"
        return 1
    fi
}

# 统一的文件哈希验证
verify_file_hash() {
    local file_path="$1"
    local expected_hash="$2"
    local hash_type="${3:-sha256}"
    
    if [[ ! -f "$file_path" ]]; then
        log "ERROR" "File not found: $file_path"
        return 1
    fi
    
    local actual_hash
    case "$hash_type" in
        "md5")
            actual_hash=$(md5sum "$file_path" | cut -d' ' -f1)
            ;;
        "sha1")
            actual_hash=$(sha1sum "$file_path" | cut -d' ' -f1)
            ;;
        "sha256")
            actual_hash=$(sha256sum "$file_path" | cut -d' ' -f1)
            ;;
        *)
            log "ERROR" "Unsupported hash type: $hash_type"
            return 1
            ;;
    esac
    
    if [[ "$actual_hash" == "$expected_hash" ]]; then
        log "INFO" "File hash verification passed: $file_path"
        return 0
    else
        log "ERROR" "File hash verification failed: $file_path"
        log "ERROR" "Expected: $expected_hash"
        log "ERROR" "Actual: $actual_hash"
        return 1
    fi
}

# 统一的临时文件创建
create_temp_file() {
    local prefix="${1:-temp}"
    local suffix="${2:-.tmp}"
    
    mktemp "/tmp/${prefix}.XXXXXX${suffix}"
}

# 统一的临时目录创建
create_temp_dir() {
    local prefix="${1:-temp}"
    
    mktemp -d "/tmp/${prefix}.XXXXXX"
}

# 统一的进程检查
is_process_running() {
    local process_name="$1"
    
    if pgrep -f "$process_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 统一的进程管理
manage_process() {
    local action="$1"
    local process_name="$2"
    
    case "$action" in
        "start")
            if ! is_process_running "$process_name"; then
                nohup "$process_name" >/dev/null 2>&1 &
                log "INFO" "Started process: $process_name"
            else
                log "WARN" "Process already running: $process_name"
            fi
            ;;
        "stop")
            if is_process_running "$process_name"; then
                pkill -f "$process_name"
                log "INFO" "Stopped process: $process_name"
            else
                log "WARN" "Process not running: $process_name"
            fi
            ;;
        "restart")
            manage_process "stop" "$process_name"
            sleep 2
            manage_process "start" "$process_name"
            ;;
        *)
            log "ERROR" "Unknown process action: $action"
            return 1
            ;;
    esac
}

# 统一的系统资源检查
check_system_resources() {
    local min_memory="${1:-512}"  # MB
    local min_disk="${2:-1024}"   # MB
    
    # 检查内存
    local total_memory=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_memory -lt $min_memory ]]; then
        log "WARN" "Insufficient memory: ${total_memory}MB (minimum: ${min_memory}MB)"
        return 1
    fi
    
    # 检查磁盘空间
    local available_disk=$(df / | awk 'NR==2{print $4}')
    local available_disk_mb=$((available_disk / 1024))
    if [[ $available_disk_mb -lt $min_disk ]]; then
        log "WARN" "Insufficient disk space: ${available_disk_mb}MB (minimum: ${min_disk}MB)"
        return 1
    fi
    
    log "INFO" "System resources check passed"
    return 0
}

# 统一的网络连接测试
test_network_connectivity() {
    local host="${1:-8.8.8.8}"
    local port="${2:-53}"
    local timeout="${3:-5}"
    
    if command -v nc >/dev/null 2>&1; then
        if timeout "$timeout" nc -z "$host" "$port" 2>/dev/null; then
            return 0
        fi
    elif command -v telnet >/dev/null 2>&1; then
        if timeout "$timeout" telnet "$host" "$port" 2>/dev/null | grep -q "Connected"; then
            return 0
        fi
    fi
    
    return 1
}

# 统一的DNS解析测试
test_dns_resolution() {
    local hostname="${1:-google.com}"
    
    if command -v nslookup >/dev/null 2>&1; then
        if nslookup "$hostname" >/dev/null 2>&1; then
            return 0
        fi
    elif command -v dig >/dev/null 2>&1; then
        if dig "$hostname" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    return 1
}

# 统一的日志轮转
rotate_log() {
    local log_file="$1"
    local max_size="${2:-10485760}"  # 10MB
    local max_files="${3:-5}"
    
    if [[ -f "$log_file" ]]; then
        local file_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
        if [[ $file_size -gt $max_size ]]; then
            # 轮转日志文件
            for i in $(seq $((max_files - 1)) -1 1); do
                if [[ -f "${log_file}.$i" ]]; then
                    mv "${log_file}.$i" "${log_file}.$((i + 1))"
                fi
            done
            mv "$log_file" "${log_file}.1"
            touch "$log_file"
            chmod 644 "$log_file"
            log "INFO" "Rotated log file: $log_file"
        fi
    fi
}

# 统一的配置备份
backup_config() {
    local config_dir="$1"
    local backup_dir="${2:-/opt/ipv6-wireguard-manager/backups}"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    ensure_directory "$backup_dir"
    local backup_name="config_backup_$timestamp"
    local backup_path="$backup_dir/$backup_name"
    
    if cp -r "$config_dir" "$backup_path"; then
        log "INFO" "Configuration backed up to: $backup_path"
        echo "$backup_path"
        return 0
    else
        log "ERROR" "Failed to backup configuration"
        return 1
    fi
}

# 统一的配置恢复
restore_config() {
    local backup_path="$1"
    local config_dir="$2"
    
    if [[ -d "$backup_path" ]]; then
        if cp -r "$backup_path"/* "$config_dir/"; then
            log "INFO" "Configuration restored from: $backup_path"
            return 0
        else
            log "ERROR" "Failed to restore configuration"
            return 1
        fi
    else
        log "ERROR" "Backup directory not found: $backup_path"
        return 1
    fi
}

# 统一的模块加载
load_common_functions() {
    # 此函数用于加载公共函数库
    # 如果已经加载，则跳过
    if [[ -n "${COMMON_FUNCTIONS_LOADED:-}" ]]; then
        return 0
    fi
    
    # 标记为已加载
    export COMMON_FUNCTIONS_LOADED=1
    
    log "DEBUG" "Common functions library loaded"
    return 0
}

# 自动加载公共函数
load_common_functions
