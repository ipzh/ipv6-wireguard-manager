#!/bin/bash

# 增强的系统兼容性模块
# 提供多平台支持、架构兼容性和包管理器适配

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# =============================================================================
# 系统兼容性配置
# =============================================================================

# 支持的Linux发行版
declare -A IPV6WGM_SUPPORTED_DISTROS=(
    ["ubuntu"]="18.04,20.04,22.04,24.04"
    ["debian"]="9,10,11,12"
    ["centos"]="7,8"
    ["rhel"]="7,8,9"
    ["rocky"]="8,9"
    ["alma"]="8,9"
    ["fedora"]="35,36,37,38,39,40"
    ["opensuse"]="15.3,15.4,15.5"
    ["sles"]="15.3,15.4,15.5"
    ["arch"]="rolling"
    ["manjaro"]="rolling"
    ["gentoo"]="rolling"
)

# 支持的架构
declare -A IPV6WGM_SUPPORTED_ARCHITECTURES=(
    ["x86_64"]="amd64"
    ["aarch64"]="arm64"
    ["armv7l"]="armhf"
    ["ppc64le"]="ppc64el"
    ["s390x"]="s390x"
)

# 包管理器映射
declare -A IPV6WGM_PACKAGE_MANAGERS=(
    ["ubuntu"]="apt"
    ["debian"]="apt"
    ["centos"]="yum"
    ["rhel"]="yum"
    ["rocky"]="dnf"
    ["alma"]="dnf"
    ["fedora"]="dnf"
    ["opensuse"]="zypper"
    ["sles"]="zypper"
    ["arch"]="pacman"
    ["manjaro"]="pacman"
    ["gentoo"]="emerge"
)

# 系统检测结果
declare -A IPV6WGM_SYSTEM_INFO=()

# =============================================================================
# 系统检测函数
# =============================================================================

# 检测操作系统
detect_operating_system() {
    log_info "检测操作系统..."
    
    # 检测发行版
    if [[ -f /etc/os-release ]]; then
        # 安全地source文件，避免unbound variable错误
        set +u
        source /etc/os-release 2>/dev/null || true
        set -u
        
        # 使用临时变量避免unbound variable错误
        local os_id="unknown"
        local os_version="unknown"
        local os_name="unknown"
        local os_codename="unknown"
        
        # 安全地获取变量值
        [[ -n "${ID:-}" ]] && os_id="${ID}"
        [[ -n "${VERSION_ID:-}" ]] && os_version="${VERSION_ID}"
        [[ -n "${NAME:-}" ]] && os_name="${NAME}"
        [[ -n "${VERSION_CODENAME:-}" ]] && os_codename="${VERSION_CODENAME}"
        
        # 设置系统信息，临时禁用set -u模式
        set +u
        IPV6WGM_SYSTEM_INFO["distro"]="$os_id"
        IPV6WGM_SYSTEM_INFO["version"]="$os_version"
        IPV6WGM_SYSTEM_INFO["name"]="$os_name"
        IPV6WGM_SYSTEM_INFO["codename"]="$os_codename"
        set -u
    elif [[ -f /etc/redhat-release ]]; then
        local release_info=$(cat /etc/redhat-release)
        if [[ "$release_info" =~ "CentOS" ]]; then
            IPV6WGM_SYSTEM_INFO["distro"]="centos"
            IPV6WGM_SYSTEM_INFO["version"]=$(echo "$release_info" | grep -oE '[0-9]+\.[0-9]+')
        elif [[ "$release_info" =~ "Red Hat" ]]; then
            IPV6WGM_SYSTEM_INFO["distro"]="rhel"
            IPV6WGM_SYSTEM_INFO["version"]=$(echo "$release_info" | grep -oE '[0-9]+\.[0-9]+')
        fi
    elif [[ -f /etc/debian_version ]]; then
        IPV6WGM_SYSTEM_INFO["distro"]="debian"
        IPV6WGM_SYSTEM_INFO["version"]=$(cat /etc/debian_version)
    else
        log_warn "无法检测操作系统类型"
        IPV6WGM_SYSTEM_INFO["distro"]="unknown"
        IPV6WGM_SYSTEM_INFO["version"]="unknown"
    fi
    
    # 检测架构
    set +u
    IPV6WGM_SYSTEM_INFO["arch"]=$(uname -m)
    
    # 检测内核版本
    IPV6WGM_SYSTEM_INFO["kernel"]=$(uname -r)
    
    # 检测Shell
    IPV6WGM_SYSTEM_INFO["shell"]="$SHELL"
    set -u
    
    # 检测包管理器
    detect_package_manager
    
    # 临时禁用set -u模式来访问数组
    set +u
    if [[ -n "${IPV6WGM_SYSTEM_INFO["distro"]:-}" ]]; then
        log_success "操作系统检测完成: ${IPV6WGM_SYSTEM_INFO["distro"]} ${IPV6WGM_SYSTEM_INFO["version"]:-} (${IPV6WGM_SYSTEM_INFO["arch"]:-})"
    else
        log_warning "操作系统检测未完成"
    fi
    set -u
}

# 检测包管理器
detect_package_manager() {
    set +u
    local distro="${IPV6WGM_SYSTEM_INFO["distro"]:-}"
    local package_manager=""
    case "$distro" in
        "ubuntu"|"debian") package_manager="apt" ;;
        "centos"|"rhel") package_manager="yum" ;;
        "rocky"|"fedora") package_manager="dnf" ;;
        "arch") package_manager="pacman" ;;
        "opensuse"|"sles") package_manager="zypper" ;;
        "alpine") package_manager="apk" ;;
    esac
    set -u
    
    if [[ -n "$package_manager" ]]; then
        # 检查包管理器是否可用
        if command -v "$package_manager" &> /dev/null; then
            IPV6WGM_SYSTEM_INFO["package_manager"]="$package_manager"
        else
            # 尝试替代包管理器
            case "$distro" in
                "centos"|"rhel"|"rocky"|"alma"|"fedora")
                    if command -v dnf &> /dev/null; then
                        IPV6WGM_SYSTEM_INFO["package_manager"]="dnf"
                    elif command -v yum &> /dev/null; then
                        IPV6WGM_SYSTEM_INFO["package_manager"]="yum"
                    fi
                    ;;
                "ubuntu"|"debian")
                    if command -v apt &> /dev/null; then
                        IPV6WGM_SYSTEM_INFO["package_manager"]="apt"
                    elif command -v apt-get &> /dev/null; then
                        IPV6WGM_SYSTEM_INFO["package_manager"]="apt-get"
                    fi
                    ;;
            esac
        fi
    else
        # 自动检测可用的包管理器
        for pm in apt apt-get yum dnf zypper pacman emerge; do
            if command -v "$pm" &> /dev/null; then
                IPV6WGM_SYSTEM_INFO["package_manager"]="$pm"
                break
            fi
        done
    fi
    
    if [[ -z "${IPV6WGM_SYSTEM_INFO["package_manager"]:-}" ]]; then
        log_warn "未检测到包管理器"
    else
        log_info "包管理器: ${IPV6WGM_SYSTEM_INFO["package_manager"]}"
    fi
}

# 检查系统兼容性
check_system_compatibility() {
    local distro="${IPV6WGM_SYSTEM_INFO["distro"]}"
    local version="${IPV6WGM_SYSTEM_INFO["version"]}"
    local arch="${IPV6WGM_SYSTEM_INFO["arch"]}"
    
    log_info "检查系统兼容性..."
    
    local compatible=true
    
    # 检查发行版支持
    if [[ "$distro" == "unknown" ]]; then
        log_error "不支持的操作系统"
        compatible=false
    elif [[ -n "${IPV6WGM_SUPPORTED_DISTROS[$distro]:-}" ]]; then
        local supported_versions="${IPV6WGM_SUPPORTED_DISTROS[$distro]}"
        if [[ "$supported_versions" == "rolling" ]]; then
            log_info "支持滚动发行版: $distro"
        elif [[ "$supported_versions" =~ "$version" ]]; then
            log_info "支持版本: $distro $version"
        else
            log_warn "版本可能不受支持: $distro $version (支持: $supported_versions)"
        fi
    else
        log_warn "未测试的发行版: $distro $version"
    fi
    
    # 检查架构支持
    if [[ -n "${IPV6WGM_SUPPORTED_ARCHITECTURES[$arch]:-}" ]]; then
        log_info "支持架构: $arch"
    else
        log_warn "未测试的架构: $arch"
    fi
    
    # 检查内核版本
    check_kernel_compatibility
    
    # 检查必要工具
    check_required_tools
    
    if [[ "$compatible" == "true" ]]; then
        log_success "系统兼容性检查通过"
        return 0
    else
        log_error "系统兼容性检查失败"
        return 1
    fi
}

# 检查内核兼容性
check_kernel_compatibility() {
    local kernel="${IPV6WGM_SYSTEM_INFO["kernel"]}"
    local kernel_version=$(echo "$kernel" | cut -d. -f1-2)
    
    # 检查内核版本
    if [[ $(echo "$kernel_version" | cut -d. -f1) -lt 4 ]]; then
        log_error "内核版本过低: $kernel (需要 4.0+)"
        return 1
    elif [[ $(echo "$kernel_version" | cut -d. -f1) -eq 4 && $(echo "$kernel_version" | cut -d. -f2) -lt 9 ]]; then
        log_warn "内核版本较旧: $kernel (推荐 4.9+)"
    else
        log_info "内核版本: $kernel"
    fi
    
    # 检查WireGuard支持
    if modinfo wireguard &> /dev/null; then
        log_info "WireGuard内核模块已加载"
    elif lsmod | grep -q wireguard; then
        log_info "WireGuard内核模块已加载"
    else
        log_warn "WireGuard内核模块未加载，可能需要安装"
    fi
    
    # 检查IPv6支持
    if [[ -f /proc/net/if_inet6 ]]; then
        log_info "IPv6支持已启用"
    else
        log_warn "IPv6支持未启用"
    fi
}

# 检查必要工具
check_required_tools() {
    local required_tools=("bash" "curl" "wget" "grep" "sed" "awk" "cut" "sort" "uniq")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        return 1
    else
        log_info "必要工具检查通过"
        return 0
    fi
}

# =============================================================================
# 包管理器适配
# =============================================================================

# 安装软件包
install_package() {
    local package_name="$1"
    local package_manager="${IPV6WGM_SYSTEM_INFO["package_manager"]}"
    
    if [[ -z "$package_manager" ]]; then
        log_error "未检测到包管理器"
        return 1
    fi
    
    log_info "安装软件包: $package_name (使用 $package_manager)"
    
    case "$package_manager" in
        "apt"|"apt-get")
            if ! apt update && apt install -y "$package_name"; then
                log_error "APT安装失败: $package_name"
                return 1
            fi
            ;;
        "yum")
            if ! yum install -y "$package_name"; then
                log_error "YUM安装失败: $package_name"
                return 1
            fi
            ;;
        "dnf")
            if ! dnf install -y "$package_name"; then
                log_error "DNF安装失败: $package_name"
                return 1
            fi
            ;;
        "zypper")
            if ! zypper install -y "$package_name"; then
                log_error "Zypper安装失败: $package_name"
                return 1
            fi
            ;;
        "pacman")
            if ! pacman -S --noconfirm "$package_name"; then
                log_error "Pacman安装失败: $package_name"
                return 1
            fi
            ;;
        "emerge")
            if ! emerge -q "$package_name"; then
                log_error "Emerge安装失败: $package_name"
                return 1
            fi
            ;;
        *)
            log_error "不支持的包管理器: $package_manager"
            return 1
            ;;
    esac
    
    log_success "软件包安装成功: $package_name"
    return 0
}

# 检查软件包是否已安装
is_package_installed() {
    local package_name="$1"
    local package_manager="${IPV6WGM_SYSTEM_INFO["package_manager"]}"
    
    case "$package_manager" in
        "apt"|"apt-get")
            dpkg -l | grep -q "^ii.*$package_name "
            ;;
        "yum"|"dnf")
            rpm -q "$package_name" &> /dev/null
            ;;
        "zypper")
            zypper se -i "$package_name" | grep -q "^i.*$package_name"
            ;;
        "pacman")
            pacman -Q "$package_name" &> /dev/null
            ;;
        "emerge")
            emerge -p "$package_name" | grep -q "\[ebuild"
            ;;
        *)
            # 通用检查方法
            command -v "$package_name" &> /dev/null
            ;;
    esac
}

# 更新软件包列表
update_package_list() {
    local package_manager="${IPV6WGM_SYSTEM_INFO["package_manager"]}"
    
    log_info "更新软件包列表 (使用 $package_manager)"
    
    case "$package_manager" in
        "apt"|"apt-get")
            apt update
            ;;
        "yum")
            yum check-update
            ;;
        "dnf")
            dnf check-update
            ;;
        "zypper")
            zypper refresh
            ;;
        "pacman")
            pacman -Sy
            ;;
        "emerge")
            emerge --sync
            ;;
        *)
            log_warn "无法更新软件包列表: $package_manager"
            return 1
            ;;
    esac
    
    log_success "软件包列表更新完成"
    return 0
}

# =============================================================================
# 架构兼容性
# =============================================================================

# 检查架构兼容性
check_architecture_compatibility() {
    local arch="${IPV6WGM_SYSTEM_INFO["arch"]}"
    
    log_info "检查架构兼容性: $arch"
    
    # 检查是否支持
    if [[ -n "${IPV6WGM_SUPPORTED_ARCHITECTURES[$arch]:-}" ]]; then
        local arch_name="${IPV6WGM_SUPPORTED_ARCHITECTURES[$arch]}"
        log_info "支持架构: $arch ($arch_name)"
        return 0
    else
        log_warn "未测试的架构: $arch"
        return 1
    fi
}

# 获取架构特定的包名
get_architecture_package_name() {
    local base_package="$1"
    local arch="${IPV6WGM_SYSTEM_INFO["arch"]}"
    
    case "$arch" in
        "x86_64")
            echo "$base_package"
            ;;
        "aarch64")
            echo "${base_package}-arm64"
            ;;
        "armv7l")
            echo "${base_package}-armhf"
            ;;
        "ppc64le")
            echo "${base_package}-ppc64el"
            ;;
        "s390x")
            echo "${base_package}-s390x"
            ;;
        *)
            echo "$base_package"
            ;;
    esac
}

# =============================================================================
# 环境适配
# =============================================================================

# 适配环境变量
adapt_environment() {
    local distro="${IPV6WGM_SYSTEM_INFO["distro"]}"
    
    log_info "适配环境变量: $distro"
    
    case "$distro" in
        "ubuntu"|"debian")
            # Ubuntu/Debian特定设置
            export DEBIAN_FRONTEND=noninteractive
            ;;
        "centos"|"rhel"|"rocky"|"alma"|"fedora")
            # RHEL系列特定设置
            export LANG=en_US.UTF-8
            ;;
        "opensuse"|"sles")
            # openSUSE特定设置
            export LANG=en_US.UTF-8
            ;;
        "arch"|"manjaro")
            # Arch系列特定设置
            export LANG=en_US.UTF-8
            ;;
        "gentoo")
            # Gentoo特定设置
            export LANG=en_US.UTF-8
            ;;
    esac
    
    log_success "环境变量适配完成"
}

# 适配路径
adapt_paths() {
    local distro="${IPV6WGM_SYSTEM_INFO["distro"]}"
    
    log_info "适配系统路径: $distro"
    
    case "$distro" in
        "ubuntu"|"debian")
            # Ubuntu/Debian路径
            IPV6WGM_SYSTEM_INFO["bin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["sbin_dir"]="/usr/sbin"
            IPV6WGM_SYSTEM_INFO["lib_dir"]="/usr/lib"
            IPV6WGM_SYSTEM_INFO["etc_dir"]="/etc"
            ;;
        "centos"|"rhel"|"rocky"|"alma"|"fedora")
            # RHEL系列路径
            IPV6WGM_SYSTEM_INFO["bin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["sbin_dir"]="/usr/sbin"
            IPV6WGM_SYSTEM_INFO["lib_dir"]="/usr/lib64"
            IPV6WGM_SYSTEM_INFO["etc_dir"]="/etc"
            ;;
        "opensuse"|"sles")
            # openSUSE路径
            IPV6WGM_SYSTEM_INFO["bin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["sbin_dir"]="/usr/sbin"
            IPV6WGM_SYSTEM_INFO["lib_dir"]="/usr/lib64"
            IPV6WGM_SYSTEM_INFO["etc_dir"]="/etc"
            ;;
        "arch"|"manjaro")
            # Arch系列路径
            IPV6WGM_SYSTEM_INFO["bin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["sbin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["lib_dir"]="/usr/lib"
            IPV6WGM_SYSTEM_INFO["etc_dir"]="/etc"
            ;;
        "gentoo")
            # Gentoo路径
            IPV6WGM_SYSTEM_INFO["bin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["sbin_dir"]="/usr/sbin"
            IPV6WGM_SYSTEM_INFO["lib_dir"]="/usr/lib64"
            IPV6WGM_SYSTEM_INFO["etc_dir"]="/etc"
            ;;
        *)
            # 默认路径
            IPV6WGM_SYSTEM_INFO["bin_dir"]="/usr/bin"
            IPV6WGM_SYSTEM_INFO["sbin_dir"]="/usr/sbin"
            IPV6WGM_SYSTEM_INFO["lib_dir"]="/usr/lib"
            IPV6WGM_SYSTEM_INFO["etc_dir"]="/etc"
            ;;
    esac
    
    log_success "系统路径适配完成"
}

# =============================================================================
# 兼容性测试
# =============================================================================

# 运行兼容性测试
run_compatibility_test() {
    local test_type="${1:-full}"
    
    log_info "运行兼容性测试: $test_type"
    
    local test_results=()
    local passed=0
    local failed=0
    
    # 基础测试
    if [[ "$test_type" == "basic" || "$test_type" == "full" ]]; then
        test_results+=("basic_system_detection")
        test_results+=("package_manager_detection")
        test_results+=("architecture_compatibility")
    fi
    
    # 功能测试
    if [[ "$test_type" == "functional" || "$test_type" == "full" ]]; then
        test_results+=("required_tools_check")
        test_results+=("kernel_compatibility")
        test_results+=("network_functionality")
    fi
    
    # 性能测试
    if [[ "$test_type" == "performance" || "$test_type" == "full" ]]; then
        test_results+=("memory_availability")
        test_results+=("disk_space_check")
        test_results+=("cpu_compatibility")
    fi
    
    # 运行测试
    for test in "${test_results[@]}"; do
        if run_single_test "$test"; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    # 报告结果
    log_info "兼容性测试完成: $passed 通过, $failed 失败"
    
    if [[ $failed -eq 0 ]]; then
        log_success "所有兼容性测试通过"
        return 0
    else
        log_error "部分兼容性测试失败"
        return 1
    fi
}

# 运行单个测试
run_single_test() {
    local test_name="$1"
    
    case "$test_name" in
        "basic_system_detection")
            detect_operating_system
            ;;
        "package_manager_detection")
            detect_package_manager
            ;;
        "architecture_compatibility")
            check_architecture_compatibility
            ;;
        "required_tools_check")
            check_required_tools
            ;;
        "kernel_compatibility")
            check_kernel_compatibility
            ;;
        "network_functionality")
            test_network_functionality
            ;;
        "memory_availability")
            test_memory_availability
            ;;
        "disk_space_check")
            test_disk_space
            ;;
        "cpu_compatibility")
            test_cpu_compatibility
            ;;
        *)
            log_warn "未知测试: $test_name"
            return 1
            ;;
    esac
}

# 测试网络功能
test_network_functionality() {
    log_info "测试网络功能..."
    
    # 测试IPv4连接
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_info "IPv4连接正常"
    else
        log_warn "IPv4连接异常"
        return 1
    fi
    
    # 测试IPv6连接
    if ping6 -c 1 2001:4860:4860::8888 &> /dev/null; then
        log_info "IPv6连接正常"
    else
        log_warn "IPv6连接异常"
    fi
    
    return 0
}

# 测试内存可用性
test_memory_availability() {
    log_info "测试内存可用性..."
    
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    local available_mem=$(free -m | awk 'NR==2{print $7}')
    
    if [[ $available_mem -lt 512 ]]; then
        log_warn "可用内存不足: ${available_mem}MB (推荐 512MB+)"
        return 1
    else
        log_info "内存充足: ${available_mem}MB"
        return 0
    fi
}

# 测试磁盘空间
test_disk_space() {
    log_info "测试磁盘空间..."
    
    local available_space=$(df / | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt 1048576 ]]; then  # 1GB in KB
        log_warn "磁盘空间不足: ${available_space}KB (推荐 1GB+)"
        return 1
    else
        log_info "磁盘空间充足: ${available_space}KB"
        return 0
    fi
}

# 测试CPU兼容性
test_cpu_compatibility() {
    log_info "测试CPU兼容性..."
    
    local cpu_count=$(nproc)
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    
    if [[ $cpu_count -lt 1 ]]; then
        log_warn "CPU核心数不足: $cpu_count"
        return 1
    else
        log_info "CPU: $cpu_model ($cpu_count 核心)"
        return 0
    fi
}

# 导出函数
export -f detect_operating_system detect_package_manager check_system_compatibility
export -f install_package is_package_installed update_package_list
export -f check_architecture_compatibility get_architecture_package_name
export -f adapt_environment adapt_paths
export -f run_compatibility_test run_single_test
