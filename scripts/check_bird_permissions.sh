#!/bin/bash

# BIRD权限检查脚本
# 用于检查和修复BIRD相关的权限问题

set -euo pipefail

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
}

# 检查BIRD用户和组
check_bird_user_group() {
    log "INFO" "Checking BIRD user and group..."
    
    local issues=0
    
    # 检查bird用户
    if ! id "bird" >/dev/null 2>&1; then
        log "WARN" "BIRD user 'bird' does not exist"
        ((issues++))
    else
        log "INFO" "BIRD user 'bird' exists"
        
        # 检查用户主目录
        local home_dir=$(getent passwd bird | cut -d: -f6)
        if [[ "$home_dir" != "/var/lib/bird" ]]; then
            log "WARN" "BIRD user home directory is not /var/lib/bird (current: $home_dir)"
            ((issues++))
        fi
        
        # 检查用户shell
        local shell=$(getent passwd bird | cut -d: -f7)
        if [[ "$shell" != "/bin/false" ]]; then
            log "WARN" "BIRD user shell is not /bin/false (current: $shell)"
            ((issues++))
        fi
    fi
    
    # 检查bird组
    if ! getent group "bird" >/dev/null 2>&1; then
        log "WARN" "BIRD group 'bird' does not exist"
        ((issues++))
    else
        log "INFO" "BIRD group 'bird' exists"
    fi
    
    # 检查bird用户是否在bird组中
    if id "bird" >/dev/null 2>&1 && getent group "bird" >/dev/null 2>&1; then
        if ! groups bird | grep -q "bird"; then
            log "WARN" "BIRD user is not in BIRD group"
            ((issues++))
        else
            log "INFO" "BIRD user is in BIRD group"
        fi
    fi
    
    return $issues
}

# 检查BIRD目录权限
check_bird_directories() {
    log "INFO" "Checking BIRD directories..."
    
    local issues=0
    local directories=(
        "/etc/bird"
        "/var/lib/bird"
        "/var/log/bird"
        "/var/run/bird"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "$dir" ]]; then
            local owner=$(stat -c '%U:%G' "$dir")
            local perms=$(stat -c '%a' "$dir")
            
            if [[ "$owner" != "bird:bird" ]]; then
                log "WARN" "Directory $dir has wrong ownership: $owner (should be bird:bird)"
                ((issues++))
            else
                log "INFO" "Directory $dir has correct ownership: $owner"
            fi
            
            if [[ "$perms" != "755" ]]; then
                log "WARN" "Directory $dir has wrong permissions: $perms (should be 755)"
                ((issues++))
            else
                log "INFO" "Directory $dir has correct permissions: $perms"
            fi
        else
            log "WARN" "Directory $dir does not exist"
            ((issues++))
        fi
    done
    
    return $issues
}

# 检查BIRD配置文件权限
check_bird_config_files() {
    log "INFO" "Checking BIRD configuration files..."
    
    local issues=0
    local config_files=(
        "/etc/bird/bird.conf"
        "/etc/bird/bird.conf.d/logging.conf"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            local owner=$(stat -c '%U:%G' "$file")
            local perms=$(stat -c '%a' "$file")
            
            if [[ "$owner" != "bird:bird" ]]; then
                log "WARN" "Config file $file has wrong ownership: $owner (should be bird:bird)"
                ((issues++))
            else
                log "INFO" "Config file $file has correct ownership: $owner"
            fi
            
            if [[ "$perms" != "644" ]]; then
                log "WARN" "Config file $file has wrong permissions: $perms (should be 644)"
                ((issues++))
            else
                log "INFO" "Config file $file has correct permissions: $perms"
            fi
        else
            log "DEBUG" "Config file $file does not exist (this may be normal)"
        fi
    done
    
    return $issues
}

# 检查BIRD systemd服务
check_bird_systemd_service() {
    log "INFO" "Checking BIRD systemd service..."
    
    local issues=0
    
    if [[ -f "/etc/systemd/system/bird.service" ]]; then
        log "INFO" "BIRD systemd service file exists"
        
        # 检查服务文件中的用户配置
        if grep -q "User=bird" "/etc/systemd/system/bird.service"; then
            log "INFO" "BIRD service configured to run as user 'bird'"
        else
            log "WARN" "BIRD service not configured to run as user 'bird'"
            ((issues++))
        fi
        
        if grep -q "Group=bird" "/etc/systemd/system/bird.service"; then
            log "INFO" "BIRD service configured to run as group 'bird'"
        else
            log "WARN" "BIRD service not configured to run as group 'bird'"
            ((issues++))
        fi
        
        # 检查ExecStart中的用户参数
        if grep -q "ExecStart.*-u bird -g bird" "/etc/systemd/system/bird.service"; then
            log "INFO" "BIRD service ExecStart configured with correct user parameters"
        else
            log "WARN" "BIRD service ExecStart not configured with correct user parameters"
            ((issues++))
        fi
    else
        log "WARN" "BIRD systemd service file does not exist"
        ((issues++))
    fi
    
    return $issues
}

# 检查BIRD进程
check_bird_process() {
    log "INFO" "Checking BIRD process..."
    
    local issues=0
    
    if pgrep -f "bird.*-u bird -g bird" >/dev/null 2>&1; then
        local pid=$(pgrep -f "bird.*-u bird -g bird")
        local process_user=$(ps -o user= -p "$pid" 2>/dev/null | tr -d ' ')
        
        if [[ "$process_user" == "bird" ]]; then
            log "INFO" "BIRD process is running as user 'bird' (PID: $pid)"
        else
            log "WARN" "BIRD process is not running as user 'bird' (current: $process_user, PID: $pid)"
            ((issues++))
        fi
    else
        log "INFO" "BIRD process is not running (this may be normal if BIRD is not started)"
    fi
    
    return $issues
}

# 修复BIRD权限问题
fix_bird_permissions() {
    log "INFO" "Fixing BIRD permissions..."
    
    # 创建bird用户和组（如果不存在）
    if ! id "bird" >/dev/null 2>&1; then
        useradd -r -s /bin/false -d /var/lib/bird -c "BIRD BGP daemon" bird
        log "INFO" "Created BIRD user"
    fi
    
    if ! getent group "bird" >/dev/null 2>&1; then
        groupadd -r bird
        log "INFO" "Created BIRD group"
    fi
    
    # 确保bird用户在bird组中
    usermod -a -G bird bird
    
    # 创建BIRD相关目录
    mkdir -p /etc/bird
    mkdir -p /var/lib/bird
    mkdir -p /var/log/bird
    mkdir -p /var/run/bird
    mkdir -p /etc/bird/bird.conf.d
    
    # 设置目录权限
    chown -R bird:bird /etc/bird
    chown -R bird:bird /var/lib/bird
    chown -R bird:bird /var/log/bird
    chown -R bird:bird /var/run/bird
    
    chmod 755 /etc/bird
    chmod 755 /var/lib/bird
    chmod 755 /var/log/bird
    chmod 755 /var/run/bird
    chmod 755 /etc/bird/bird.conf.d
    
    # 设置配置文件权限
    if [[ -f /etc/bird/bird.conf ]]; then
        chown bird:bird /etc/bird/bird.conf
        chmod 644 /etc/bird/bird.conf
    fi
    
    if [[ -f /etc/bird/bird.conf.d/logging.conf ]]; then
        chown bird:bird /etc/bird/bird.conf.d/logging.conf
        chmod 644 /etc/bird/bird.conf.d/logging.conf
    fi
    
    log "INFO" "BIRD permissions fixed"
}

# 创建正确的BIRD systemd服务文件
create_bird_systemd_service() {
    log "INFO" "Creating BIRD systemd service file..."
    
    cat > /etc/systemd/system/bird.service << 'EOF'
[Unit]
Description=BIRD Internet Routing Daemon
Documentation=man:bird(8)
After=network.target
Wants=network.target

[Service]
Type=notify
User=bird
Group=bird
ExecStart=/usr/sbin/bird -f -u bird -g bird -c /etc/bird/bird.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/bird /var/log/bird /var/run/bird
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Network settings
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true

# Capabilities
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload
    
    log "INFO" "BIRD systemd service file created"
}

# 主函数
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                BIRD权限检查工具                            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # 检查root权限
    check_root
    
    local total_issues=0
    
    # 检查各项权限
    check_bird_user_group
    ((total_issues += $?))
    
    check_bird_directories
    ((total_issues += $?))
    
    check_bird_config_files
    ((total_issues += $?))
    
    check_bird_systemd_service
    ((total_issues += $?))
    
    check_bird_process
    ((total_issues += $?))
    
    echo
    if [[ $total_issues -eq 0 ]]; then
        log "INFO" "所有BIRD权限检查通过，没有发现问题"
    else
        log "WARN" "发现 $total_issues 个权限问题"
        echo
        read -p "是否自动修复这些问题? (y/N): " fix_choice
        
        if [[ "${fix_choice,,}" == "y" ]]; then
            fix_bird_permissions
            create_bird_systemd_service
            log "INFO" "BIRD权限修复完成"
        else
            log "INFO" "请手动修复权限问题"
        fi
    fi
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
