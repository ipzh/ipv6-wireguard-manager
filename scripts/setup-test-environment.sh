#!/bin/bash

# IPv6 WireGuard Manager 测试环境配置脚本
# 版本: 1.0.0

set -euo pipefail

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)" || exit

# 导入公共函数
if [[ -f "$PROJECT_ROOT/modules/common_functions.sh" ]]; then
    source "$PROJECT_ROOT/modules/common_functions.sh"
else
    echo "错误: 无法导入公共函数模块" >&2
    exit 1
fi

# 测试环境配置
TEST_ENV_NAME="ipv6wgm-test"
TEST_CONFIG_DIR="/tmp/${TEST_ENV_NAME}/config"
TEST_LOG_DIR="/tmp/${TEST_ENV_NAME}/logs"
TEST_RESULTS_DIR="/tmp/${TEST_ENV_NAME}/results"
TEST_TEMP_DIR="/tmp/${TEST_ENV_NAME}/temp"

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 测试环境配置脚本

用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -c, --clean             清理现有测试环境
  -f, --force             强制重新创建测试环境
  -v, --verbose           详细输出
  -d, --directory DIR     指定测试目录（默认: /tmp/ipv6wgm-test）

示例:
  $0 --verbose
  $0 --clean --force
  $0 --directory /custom/test/dir
EOF
}

# 清理测试环境
cleanup_test_environment() {
    log_info "清理测试环境..."
    
    # 停止可能运行的测试进程
    pkill -f "ipv6-wireguard-manager" 2>/dev/null || true
    pkill -f "test.*ipv6wgm" 2>/dev/null || true
    
    # 清理测试目录
    if [[ -d "$TEST_CONFIG_DIR" ]]; then
        rm -rf "$TEST_CONFIG_DIR"
        log_info "已清理配置目录: $TEST_CONFIG_DIR"
    fi
    
    if [[ -d "$TEST_LOG_DIR" ]]; then
        rm -rf "$TEST_LOG_DIR"
        log_info "已清理日志目录: $TEST_LOG_DIR"
    fi
    
    if [[ -d "$TEST_RESULTS_DIR" ]]; then
        rm -rf "$TEST_RESULTS_DIR"
        log_info "已清理结果目录: $TEST_RESULTS_DIR"
    fi
    
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        log_info "已清理临时目录: $TEST_TEMP_DIR"
    fi
    
    log_success "测试环境清理完成"
}

# 创建测试环境
create_test_environment() {
    log_info "创建测试环境..."
    
    # 创建测试目录
    mkdir -p "$TEST_CONFIG_DIR" "$TEST_LOG_DIR" "$TEST_RESULTS_DIR" "$TEST_TEMP_DIR"
    log_info "已创建测试目录"
    
    # 创建测试配置文件
    create_test_config_files
    
    # 创建测试数据
    create_test_data
    
    # 设置权限
    chmod -R 755 "$TEST_CONFIG_DIR" "$TEST_LOG_DIR" "$TEST_RESULTS_DIR" "$TEST_TEMP_DIR"
    
    log_success "测试环境创建完成"
}

# 创建测试配置文件
create_test_config_files() {
    log_info "创建测试配置文件..."
    
    # 主配置文件
    cat > "$TEST_CONFIG_DIR/manager.conf" << 'EOF'
# IPv6 WireGuard Manager 测试配置

# 系统配置
SYSTEM_NAME="IPv6 WireGuard Manager Test"
SYSTEM_VERSION="1.0.0-test"
SYSTEM_DEBUG=true

# 网络配置
NETWORK_IPV6_PREFIX="2001:db8::/64"
NETWORK_IPV4_PREFIX="10.0.0.0/24"
WIREGUARD_INTERFACE="wg0"
WIREGUARD_PORT="51820"

# 功能开关
WIREGUARD_ENABLED=true
BIRD_ENABLED=false
FIREWALL_ENABLED=false
WEB_UI_ENABLED=false

# 日志配置
LOG_LEVEL="DEBUG"
LOG_FILE="/tmp/ipv6wgm-test/logs/test.log"

# 测试配置
TEST_MODE=true
TEST_TIMEOUT=30
EOF

    # 客户端配置模板
    cat > "$TEST_CONFIG_DIR/client_template.conf" << 'EOF'
# 客户端配置模板

[Interface]
PrivateKey = {{PRIVATE_KEY}}
Address = {{CLIENT_IPV4}}/32, {{CLIENT_IPV6}}/128
DNS = {{DNS_SERVER}}

[Peer]
PublicKey = {{SERVER_PUBLIC_KEY}}
Endpoint = {{SERVER_ENDPOINT}}:{{SERVER_PORT}}
AllowedIPs = {{ALLOWED_IPS}}
PersistentKeepalive = 25
EOF

    # BIRD配置模板
    cat > "$TEST_CONFIG_DIR/bird_template.conf" << 'EOF'
# BIRD BGP 配置模板

router id {{ROUTER_ID}};

protocol device {
    scan time 10;
}

protocol static {
    route {{IPV6_PREFIX}} via {{NEXT_HOP}};
    import all;
    export all;
}

protocol bgp {{PEER_NAME}} {
    local as {{LOCAL_AS}};
    neighbor {{PEER_IP}} as {{PEER_AS}};
    import all;
    export all;
}
EOF

    log_success "测试配置文件创建完成"
}

# 创建测试数据
create_test_data() {
    log_info "创建测试数据..."
    
    # 测试客户端数据
    cat > "$TEST_CONFIG_DIR/test_clients.csv" << 'EOF'
name,public_key,allowed_ips,description
test-client-1,test-public-key-1,10.0.0.2/32,fd00:dead:beef::2/128,测试客户端1
test-client-2,test-public-key-2,10.0.0.3/32,fd00:dead:beef::3/128,测试客户端2
test-client-3,test-public-key-3,10.0.0.4/32,fd00:dead:beef::4/128,测试客户端3
EOF

    # 测试IPv6前缀数据
    cat > "$TEST_CONFIG_DIR/test_ipv6_prefixes.conf" << 'EOF'
# 测试IPv6前缀配置

# 主要前缀
2001:db8::/64

# 测试前缀
2001:db8:1::/64
2001:db8:2::/64
2001:db8:3::/64

# 客户端前缀
fd00:dead:beef::/64
EOF

    # 测试BGP邻居数据
    cat > "$TEST_CONFIG_DIR/test_bgp_neighbors.conf" << 'EOF'
# 测试BGP邻居配置

# 测试邻居1
neighbor test-peer-1 {
    remote-as 65001;
    neighbor 2001:db8::1;
    description "测试BGP邻居1";
}

# 测试邻居2
neighbor test-peer-2 {
    remote-as 65002;
    neighbor 2001:db8::2;
    description "测试BGP邻居2";
}
EOF

    log_success "测试数据创建完成"
}

# 验证测试环境
validate_test_environment() {
    log_info "验证测试环境..."
    
    local validation_passed=true
    
    # 检查目录是否存在
    local required_dirs=("$TEST_CONFIG_DIR" "$TEST_LOG_DIR" "$TEST_RESULTS_DIR" "$TEST_TEMP_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "缺少必需目录: $dir"
            validation_passed=false
        fi
    done
    
    # 检查配置文件是否存在
    local required_files=(
        "$TEST_CONFIG_DIR/manager.conf"
        "$TEST_CONFIG_DIR/client_template.conf"
        "$TEST_CONFIG_DIR/bird_template.conf"
        "$TEST_CONFIG_DIR/test_clients.csv"
        "$TEST_CONFIG_DIR/test_ipv6_prefixes.conf"
        "$TEST_CONFIG_DIR/test_bgp_neighbors.conf"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "缺少必需文件: $file"
            validation_passed=false
        fi
    done
    
    # 检查权限
    for dir in "${required_dirs[@]}"; do
        if [[ ! -w "$dir" ]]; then
            log_error "目录不可写: $dir"
            validation_passed=false
        fi
    done
    
    if [[ "$validation_passed" == "true" ]]; then
        log_success "测试环境验证通过"
        return 0
    else
        log_error "测试环境验证失败"
        return 1
    fi
}

# 显示测试环境信息
show_test_environment_info() {
    log_info "测试环境信息:"
    echo "  配置目录: $TEST_CONFIG_DIR"
    echo "  日志目录: $TEST_LOG_DIR"
    echo "  结果目录: $TEST_RESULTS_DIR"
    echo "  临时目录: $TEST_TEMP_DIR"
    echo
    
    log_info "配置文件:"
    find "$TEST_CONFIG_DIR" -type f -name "*.conf" -o -name "*.csv" | while read -r file; do
        echo "  $(basename "$file"): $(wc -l < "$file") 行"
    done
    echo
    
    log_info "目录大小:"
    du -sh "$TEST_CONFIG_DIR" "$TEST_LOG_DIR" "$TEST_RESULTS_DIR" "$TEST_TEMP_DIR" 2>/dev/null || true
}

# 主函数
main() {
    local clean=false
    local force=false
    local verbose=false
    local custom_dir=""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -d|--directory)
                custom_dir="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 设置详细输出
    if [[ "$verbose" == "true" ]]; then
        set -x
    fi
    
    # 设置自定义目录
    if [[ -n "$custom_dir" ]]; then
        TEST_CONFIG_DIR="$custom_dir/config"
        TEST_LOG_DIR="$custom_dir/logs"
        TEST_RESULTS_DIR="$custom_dir/results"
        TEST_TEMP_DIR="$custom_dir/temp"
    fi
    
    log_info "IPv6 WireGuard Manager 测试环境配置"
    log_info "====================================="
    
    # 清理现有环境
    if [[ "$clean" == "true" ]]; then
        cleanup_test_environment
    fi
    
    # 检查现有环境
    if [[ -d "$TEST_CONFIG_DIR" ]] && [[ "$force" != "true" ]]; then
        log_warning "测试环境已存在: $TEST_CONFIG_DIR"
        log_info "使用 --force 选项强制重新创建"
        exit 0
    fi
    
    # 创建测试环境
    create_test_environment
    
    # 验证测试环境
    if validate_test_environment; then
        show_test_environment_info
        log_success "测试环境配置完成！"
        exit 0
    else
        log_error "测试环境配置失败！"
        exit 1
    fi
}

# 运行主函数
main "$@"
