#!/bin/bash

# 系统检测模块
# 负责检测系统环境、安装依赖、验证兼容性

# 系统信息存储
declare -A SYSTEM_INFO
declare -A PACKAGE_INFO
declare -A SERVICE_INFO

# 支持的操作系统
SUPPORTED_OS=(
    "ubuntu" "debian" "centos" "rhel" "fedora" "rocky" "almalinux"
    "arch" "opensuse" "sles" "gentoo" "alpine"
)

# 支持的包管理器
SUPPORTED_PACKAGE_MANAGERS=(
    "apt" "yum" "dnf" "pacman" "zypper" "emerge" "apk"
)

# 必需的包
REQUIRED_PACKAGES=(
    "wireguard" "curl" "wget" "jq" "iproute2" "iptables"
)

# 可选的包
OPTIONAL_PACKAGES=(
    "bird" "bird6" "nginx" "apache2" "ufw" "firewalld"
    "nftables" "systemd" "rsyslog" "logrotate"
)

# 必需的服务
REQUIRED_SERVICES=(
    "systemd-resolved" "systemd-networkd"
)

# 可选的服务
OPTIONAL_SERVICES=(
    "wireguard" "bird" "bird6" "nginx" "apache2"
    "ufw" "firewalld" "nftables"
)

# 初始化系统检测
init_system_detection() {
    log_info "初始化系统检测..."
    
    # 检测操作系统
    detect_operating_system
    
    # 检测架构
    detect_architecture
    
    # 检测包管理器
    detect_package_manager
    
    # 检测内核版本
    detect_kernel_version
    
    # 检测网络接口
    detect_network_interfaces
    
    # 检测防火墙
    detect_firewall_system
    
    # 检测BIRD版本
    detect_bird_version
    
    # 检测WireGuard支持
    detect_wireguard_support
    
    log_info "系统检测完成"
}

# 检测操作系统
detect_operating_system() {
    log_info "检测操作系统..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        SYSTEM_INFO["os_id"]="$ID"
        SYSTEM_INFO["os_name"]="$NAME"
        SYSTEM_INFO["os_version"]="$VERSION_ID"
        SYSTEM_INFO["os_codename"]="${VERSION_CODENAME:-}"
        SYSTEM_INFO["os_pretty"]="$PRETTY_NAME"
    elif [[ -f /etc/redhat-release ]]; then
        local release_info=$(cat /etc/redhat-release)
        SYSTEM_INFO["os_id"]="rhel"
        SYSTEM_INFO["os_name"]="Red Hat Enterprise Linux"
        SYSTEM_INFO["os_version"]=$(echo "$release_info" | grep -oE '[0-9]+\.[0-9]+' | head -1)
        SYSTEM_INFO["os_pretty"]="$release_info"
    elif [[ -f /etc/debian_version ]]; then
        SYSTEM_INFO["os_id"]="debian"
        SYSTEM_INFO["os_name"]="Debian"
        SYSTEM_INFO["os_version"]=$(cat /etc/debian_version)
        SYSTEM_INFO["os_pretty"]="Debian $(cat /etc/debian_version)"
    else
        log_error "无法检测操作系统"
        return 1
    fi
    
    # 验证操作系统支持
    if ! array_contains "${SYSTEM_INFO["os_id"]}" "${SUPPORTED_OS[@]}"; then
        log_warn "操作系统可能不受支持: ${SYSTEM_INFO["os_id"]}"
    fi
    
    log_info "操作系统: ${SYSTEM_INFO["os_pretty"]}"
}

# 检测架构
detect_architecture() {
    log_info "检测系统架构..."
    
    SYSTEM_INFO["arch"]=$(uname -m)
    SYSTEM_INFO["arch_bits"]=$(getconf LONG_BIT)
    
    case "${SYSTEM_INFO["arch"]}" in
        "x86_64")
            SYSTEM_INFO["arch_name"]="AMD64"
            ;;
        "i386"|"i686")
            SYSTEM_INFO["arch_name"]="i386"
            ;;
        "aarch64"|"arm64")
            SYSTEM_INFO["arch_name"]="ARM64"
            ;;
        "armv7l")
            SYSTEM_INFO["arch_name"]="ARMv7"
            ;;
        *)
            SYSTEM_INFO["arch_name"]="${SYSTEM_INFO["arch"]}"
            ;;
    esac
    
    log_info "系统架构: ${SYSTEM_INFO["arch_name"]} (${SYSTEM_INFO["arch_bits"]}位)"
}

# 检测包管理器
detect_package_manager() {
    log_info "检测包管理器..."
    
    if command -v apt-get &> /dev/null; then
        SYSTEM_INFO["package_manager"]="apt"
        SYSTEM_INFO["package_manager_version"]=$(apt-get --version | head -1)
    elif command -v yum &> /dev/null; then
        SYSTEM_INFO["package_manager"]="yum"
        SYSTEM_INFO["package_manager_version"]=$(yum --version | head -1)
    elif command -v dnf &> /dev/null; then
        SYSTEM_INFO["package_manager"]="dnf"
        SYSTEM_INFO["package_manager_version"]=$(dnf --version | head -1)
    elif command -v pacman &> /dev/null; then
        SYSTEM_INFO["package_manager"]="pacman"
        SYSTEM_INFO["package_manager_version"]=$(pacman --version | head -1)
    elif command -v zypper &> /dev/null; then
        SYSTEM_INFO["package_manager"]="zypper"
        SYSTEM_INFO["package_manager_version"]=$(zypper --version | head -1)
    elif command -v emerge &> /dev/null; then
        SYSTEM_INFO["package_manager"]="emerge"
        SYSTEM_INFO["package_manager_version"]=$(emerge --version | head -1)
    elif command -v apk &> /dev/null; then
        SYSTEM_INFO["package_manager"]="apk"
        SYSTEM_INFO["package_manager_version"]=$(apk --version | head -1)
    else
        log_error "未找到支持的包管理器"
        return 1
    fi
    
    log_info "包管理器: ${SYSTEM_INFO["package_manager"]}"
}

# 检测内核版本
detect_kernel_version() {
    log_info "检测内核版本..."
    
    SYSTEM_INFO["kernel_version"]=$(uname -r)
    SYSTEM_INFO["kernel_release"]=$(uname -v)
    
    # 检测内核模块支持
    if [[ -d /lib/modules/$(uname -r) ]]; then
        SYSTEM_INFO["kernel_modules_available"]="true"
    else
        SYSTEM_INFO["kernel_modules_available"]="false"
    fi
    
    # 检测WireGuard内核模块
    if modinfo wireguard &> /dev/null; then
        SYSTEM_INFO["wireguard_kernel_module"]="true"
    else
        SYSTEM_INFO["wireguard_kernel_module"]="false"
    fi
    
    log_info "内核版本: ${SYSTEM_INFO["kernel_version"]}"
}

# 检测网络接口
detect_network_interfaces() {
    log_info "检测网络接口..."
    
    local interfaces=()
    local ipv4_interfaces=()
    local ipv6_interfaces=()
    
    # 获取所有网络接口
    while IFS= read -r interface; do
        if [[ "$interface" != "lo" ]]; then
            interfaces+=("$interface")
        fi
    done < <(ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' ')
    
    # 检测IPv4接口
    for interface in "${interfaces[@]}"; do
        if ip addr show "$interface" | grep -q "inet "; then
            ipv4_interfaces+=("$interface")
        fi
    done
    
    # 检测IPv6接口
    for interface in "${interfaces[@]}"; do
        if ip addr show "$interface" | grep -q "inet6 " && \
           ! ip addr show "$interface" | grep -q "inet6 ::1" && \
           ! ip addr show "$interface" | grep -q "inet6 fe80:"; then
            ipv6_interfaces+=("$interface")
        fi
    done
    
    SYSTEM_INFO["interfaces"]=$(array_join "," "${interfaces[@]}")
    SYSTEM_INFO["ipv4_interfaces"]=$(array_join "," "${ipv4_interfaces[@]}")
    SYSTEM_INFO["ipv6_interfaces"]=$(array_join "," "${ipv6_interfaces[@]}")
    
    # 获取主接口
    SYSTEM_INFO["primary_interface"]=$(ip route | grep default | head -1 | awk '{print $5}')
    SYSTEM_INFO["primary_ipv4"]=$(get_local_ipv4 "${SYSTEM_INFO["primary_interface"]}")
    SYSTEM_INFO["primary_ipv6"]=$(get_local_ipv6 "${SYSTEM_INFO["primary_interface"]}")
    
    log_info "网络接口: ${SYSTEM_INFO["interfaces"]}"
    log_info "主接口: ${SYSTEM_INFO["primary_interface"]} (IPv4: ${SYSTEM_INFO["primary_ipv4"]}, IPv6: ${SYSTEM_INFO["primary_ipv6"]})"
}

# 检测防火墙系统
detect_firewall_system() {
    log_info "检测防火墙系统..."
    
    local firewall_systems=()
    
    # 检测UFW
    if command -v ufw &> /dev/null; then
        firewall_systems+=("ufw")
        SERVICE_INFO["ufw_status"]=$(ufw status | head -1 | awk '{print $2}')
    fi
    
    # 检测firewalld
    if command -v firewall-cmd &> /dev/null; then
        firewall_systems+=("firewalld")
        SERVICE_INFO["firewalld_status"]=$(firewall-cmd --state 2>/dev/null || echo "not running")
    fi
    
    # 检测nftables
    if command -v nft &> /dev/null; then
        firewall_systems+=("nftables")
        SERVICE_INFO["nftables_status"]="available"
    fi
    
    # 检测iptables
    if command -v iptables &> /dev/null; then
        firewall_systems+=("iptables")
        SERVICE_INFO["iptables_status"]="available"
    fi
    
    SYSTEM_INFO["firewall_systems"]=$(array_join "," "${firewall_systems[@]}")
    
    if [[ ${#firewall_systems[@]} -gt 0 ]]; then
        log_info "检测到防火墙系统: ${SYSTEM_INFO["firewall_systems"]}"
    else
        log_warn "未检测到防火墙系统"
    fi
}

# 检测BIRD版本
detect_bird_version() {
    log_info "检测BIRD版本..."
    
    if command -v bird &> /dev/null; then
        local bird_version=$(bird --version 2>&1 | head -1)
        SYSTEM_INFO["bird_version"]="$bird_version"
        SYSTEM_INFO["bird_available"]="true"
        
        # 解析版本号
        if [[ $bird_version =~ ([0-9]+)\.([0-9]+) ]]; then
            SYSTEM_INFO["bird_major"]="${BASH_REMATCH[1]}"
            SYSTEM_INFO["bird_minor"]="${BASH_REMATCH[2]}"
        fi
        
        log_info "BIRD版本: $bird_version"
    else
        SYSTEM_INFO["bird_available"]="false"
        log_info "BIRD未安装"
    fi
    
    # 检测BIRD6
    if command -v bird6 &> /dev/null; then
        local bird6_version=$(bird6 --version 2>&1 | head -1)
        SYSTEM_INFO["bird6_version"]="$bird6_version"
        SYSTEM_INFO["bird6_available"]="true"
        log_info "BIRD6版本: $bird6_version"
    else
        SYSTEM_INFO["bird6_available"]="false"
        log_info "BIRD6未安装"
    fi
}

# 检测WireGuard支持
detect_wireguard_support() {
    log_info "检测WireGuard支持..."
    
    # 检测WireGuard工具
    if command -v wg &> /dev/null; then
        SYSTEM_INFO["wireguard_tools"]="true"
        SYSTEM_INFO["wireguard_version"]=$(wg --version 2>&1 | head -1)
        log_info "WireGuard工具: 已安装"
    else
        SYSTEM_INFO["wireguard_tools"]="false"
        log_info "WireGuard工具: 未安装"
    fi
    
    # 检测内核模块
    if [[ "${SYSTEM_INFO["wireguard_kernel_module"]}" == "true" ]]; then
        log_info "WireGuard内核模块: 可用"
    else
        log_warn "WireGuard内核模块: 不可用"
    fi
    
    # 检测用户空间实现
    if command -v wireguard-go &> /dev/null; then
        SYSTEM_INFO["wireguard_userspace"]="true"
        log_info "WireGuard用户空间实现: 可用"
    else
        SYSTEM_INFO["wireguard_userspace"]="false"
        log_info "WireGuard用户空间实现: 不可用"
    fi
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_packages=()
    local missing_services=()
    
    # 检查必需包
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! is_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done
    
    # 检查必需服务
    for service in "${REQUIRED_SERVICES[@]}"; do
        if ! is_service_available "$service"; then
            missing_services+=("$service")
        fi
    done
    
    # 报告结果
    if [[ ${#missing_packages[@]} -eq 0 && ${#missing_services[@]} -eq 0 ]]; then
        log_info "所有必需依赖已满足"
        return 0
    else
        if [[ ${#missing_packages[@]} -gt 0 ]]; then
            log_error "缺少必需包: ${missing_packages[*]}"
        fi
        if [[ ${#missing_services[@]} -gt 0 ]]; then
            log_error "缺少必需服务: ${missing_services[*]}"
        fi
        return 1
    fi
}

# 检查包是否已安装
is_package_installed() {
    local package="$1"
    
    case "${SYSTEM_INFO["package_manager"]}" in
        "apt")
            dpkg -l | grep -q "^ii  $package "
            ;;
        "yum"|"dnf")
            rpm -q "$package" &> /dev/null
            ;;
        "pacman")
            pacman -Q "$package" &> /dev/null
            ;;
        "zypper")
            zypper se -i "$package" | grep -q "^i"
            ;;
        "emerge")
            emerge -p "$package" | grep -q "\[ebuild"
            ;;
        "apk")
            apk info -e "$package" &> /dev/null
            ;;
        *)
            command -v "$package" &> /dev/null
            ;;
    esac
}

# 检查服务是否可用
is_service_available() {
    local service="$1"
    
    if command -v systemctl &> /dev/null; then
        systemctl list-unit-files | grep -q "^$service"
    elif command -v service &> /dev/null; then
        service --status-all 2>/dev/null | grep -q "$service"
    else
        return 1
    fi
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    local packages_to_install=()
    
    # 检查必需包
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! is_package_installed "$package"; then
            packages_to_install+=("$package")
        fi
    done
    
    # 检查可选包
    for package in "${OPTIONAL_PACKAGES[@]}"; do
        if ! is_package_installed "$package"; then
            if confirm "是否安装可选包: $package"; then
                packages_to_install+=("$package")
            fi
        fi
    done
    
    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_info "所有包已安装"
        return 0
    fi
    
    log_info "将安装以下包: ${packages_to_install[*]}"
    
    if confirm "确认安装这些包"; then
        for package in "${packages_to_install[@]}"; do
            install_package "$package" || log_error "安装包失败: $package"
        done
    else
        log_warn "用户取消安装"
        return 1
    fi
}

# 安装包
install_package() {
    local package="$1"
    
    log_info "安装包: $package"
    
    case "${SYSTEM_INFO["package_manager"]}" in
        "apt")
            apt-get update && apt-get install -y "$package"
            ;;
        "yum")
            yum install -y "$package"
            ;;
        "dnf")
            dnf install -y "$package"
            ;;
        "pacman")
            pacman -S --noconfirm "$package"
            ;;
        "zypper")
            zypper install -y "$package"
            ;;
        "emerge")
            emerge "$package"
            ;;
        "apk")
            apk add "$package"
            ;;
        *)
            log_error "不支持的包管理器: ${SYSTEM_INFO["package_manager"]}"
            return 1
            ;;
    esac
}

# 系统兼容性检查
check_system_compatibility() {
    log_info "检查系统兼容性..."
    
    local compatibility_issues=()
    
    # 检查操作系统兼容性
    if ! array_contains "${SYSTEM_INFO["os_id"]}" "${SUPPORTED_OS[@]}"; then
        compatibility_issues+=("不支持的操作系统: ${SYSTEM_INFO["os_id"]}")
    fi
    
    # 检查架构兼容性
    if [[ "${SYSTEM_INFO["arch"]}" != "x86_64" && "${SYSTEM_INFO["arch"]}" != "aarch64" ]]; then
        compatibility_issues+=("不支持的架构: ${SYSTEM_INFO["arch"]}")
    fi
    
    # 检查内核版本
    local kernel_version="${SYSTEM_INFO["kernel_version"]}"
    if [[ $kernel_version =~ ^([0-9]+)\.([0-9]+) ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        
        if [[ $major -lt 3 ]] || [[ $major -eq 3 && $minor -lt 10 ]]; then
            compatibility_issues+=("内核版本过低: $kernel_version (需要3.10+)")
        fi
    fi
    
    # 检查WireGuard支持
    if [[ "${SYSTEM_INFO["wireguard_tools"]}" != "true" && "${SYSTEM_INFO["wireguard_userspace"]}" != "true" ]]; then
        compatibility_issues+=("WireGuard支持不可用")
    fi
    
    # 报告结果
    if [[ ${#compatibility_issues[@]} -eq 0 ]]; then
        log_info "系统兼容性检查通过"
        return 0
    else
        log_error "发现兼容性问题:"
        for issue in "${compatibility_issues[@]}"; do
            log_error "  - $issue"
        done
        return 1
    fi
}

# 生成系统报告
generate_system_report() {
    local report_file="/tmp/ipv6-wireguard-system-report-$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
IPv6 WireGuard Manager 系统报告
生成时间: $(get_timestamp)
主机: $(hostname)
用户: $(whoami)

操作系统信息:
  ID: ${SYSTEM_INFO["os_id"]}
  名称: ${SYSTEM_INFO["os_name"]}
  版本: ${SYSTEM_INFO["os_version"]}
  代号: ${SYSTEM_INFO["os_codename"]}
  完整名称: ${SYSTEM_INFO["os_pretty"]}

系统架构:
  架构: ${SYSTEM_INFO["arch"]}
  名称: ${SYSTEM_INFO["arch_name"]}
  位数: ${SYSTEM_INFO["arch_bits"]}

包管理器:
  类型: ${SYSTEM_INFO["package_manager"]}
  版本: ${SYSTEM_INFO["package_manager_version"]}

内核信息:
  版本: ${SYSTEM_INFO["kernel_version"]}
  发布: ${SYSTEM_INFO["kernel_release"]}
  模块可用: ${SYSTEM_INFO["kernel_modules_available"]}
  WireGuard模块: ${SYSTEM_INFO["wireguard_kernel_module"]}

网络接口:
  所有接口: ${SYSTEM_INFO["interfaces"]}
  IPv4接口: ${SYSTEM_INFO["ipv4_interfaces"]}
  IPv6接口: ${SYSTEM_INFO["ipv6_interfaces"]}
  主接口: ${SYSTEM_INFO["primary_interface"]}
  主IPv4: ${SYSTEM_INFO["primary_ipv4"]}
  主IPv6: ${SYSTEM_INFO["primary_ipv6"]}

防火墙系统:
  可用系统: ${SYSTEM_INFO["firewall_systems"]}
  UFW状态: ${SERVICE_INFO["ufw_status"]}
  firewalld状态: ${SERVICE_INFO["firewalld_status"]}
  nftables状态: ${SERVICE_INFO["nftables_status"]}
  iptables状态: ${SERVICE_INFO["iptables_status"]}

BIRD信息:
  可用: ${SYSTEM_INFO["bird_available"]}
  版本: ${SYSTEM_INFO["bird_version"]}
  主版本: ${SYSTEM_INFO["bird_major"]}
  次版本: ${SYSTEM_INFO["bird_minor"]}
  BIRD6可用: ${SYSTEM_INFO["bird6_available"]}
  BIRD6版本: ${SYSTEM_INFO["bird6_version"]}

WireGuard信息:
  工具: ${SYSTEM_INFO["wireguard_tools"]}
  版本: ${SYSTEM_INFO["wireguard_version"]}
  内核模块: ${SYSTEM_INFO["wireguard_kernel_module"]}
  用户空间: ${SYSTEM_INFO["wireguard_userspace"]}

系统资源:
  内存使用: $(get_memory_usage)%
  磁盘使用: $(get_disk_usage)%
  系统负载: $(get_system_load)
EOF
    
    log_info "系统报告已生成: $report_file"
    echo "$report_file"
}

# 获取系统信息
get_system_info() {
    local key="$1"
    echo "${SYSTEM_INFO[$key]:-}"
}

# 获取包信息
get_package_info() {
    local package="$1"
    echo "${PACKAGE_INFO[$package]:-}"
}

# 获取服务信息
get_service_info() {
    local service="$1"
    echo "${SERVICE_INFO[$service]:-}"
}

# 导出函数
export -f init_system_detection detect_operating_system detect_architecture
export -f detect_package_manager detect_kernel_version detect_network_interfaces
export -f detect_firewall_system detect_bird_version detect_wireguard_support
export -f check_dependencies is_package_installed is_service_available
export -f install_dependencies install_package check_system_compatibility
export -f generate_system_report get_system_info get_package_info get_service_info
