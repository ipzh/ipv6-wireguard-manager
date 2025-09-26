#!/bin/bash

# IPv6 WireGuard Manager 测试框架
# 版本: 1.0.0

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试配置
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
MODULES_DIR="$PROJECT_ROOT/modules"
CONFIG_DIR="$PROJECT_ROOT/config"

# 测试统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 测试结果存储
TEST_RESULTS=()

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  IPv6 WireGuard Manager 测试框架"
    echo "=========================================="
    echo -e "${NC}"
}

# 测试函数
run_test() {
    local test_name="$1"
    local test_function="$2"
    local test_type="${3:-basic}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}🧪 运行测试: $test_name${NC}"
    
    if [[ "$test_type" == "advanced" && "$1" == "--basic" ]]; then
        echo -e "${YELLOW}⏭️  跳过高级测试: $test_name${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return 0
    fi
    
    if [[ "$test_type" == "basic" && "$1" == "--advanced" ]]; then
        echo -e "${YELLOW}⏭️  跳过基础测试: $test_name${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return 0
    fi
    
    if $test_function; then
        echo -e "${GREEN}✅ 测试通过: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        TEST_RESULTS+=("✅ $test_name")
    else
        echo -e "${RED}❌ 测试失败: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TEST_RESULTS+=("❌ $test_name")
    fi
}

# 测试公共函数库
test_common_functions() {
    echo "测试公共函数库..."
    
    # 加载公共函数
    source "$MODULES_DIR/common_functions.sh"
    
    # 测试IP验证函数
    if validate_ipv4 "192.168.1.1"; then
        echo "  ✓ IPv4验证通过"
    else
        echo "  ✗ IPv4验证失败"
        return 1
    fi
    
    if validate_ipv6 "2001:db8::1"; then
        echo "  ✓ IPv6验证通过"
    else
        echo "  ✗ IPv6验证失败"
        return 1
    fi
    
    # 测试端口验证
    if validate_port "8080"; then
        echo "  ✓ 端口验证通过"
    else
        echo "  ✗ 端口验证失败"
        return 1
    fi
    
    # 测试随机字符串生成
    local random_str=$(generate_random_string 10)
    if [[ ${#random_str} -eq 10 ]]; then
        echo "  ✓ 随机字符串生成通过"
    else
        echo "  ✗ 随机字符串生成失败"
        return 1
    fi
    
    # 测试输入清理
    local sanitized=$(sanitize_input "test<script>alert('xss')</script>")
    if [[ "$sanitized" == "test_script_alert('xss')_script_" ]]; then
        echo "  ✓ 输入清理通过"
    else
        echo "  ✗ 输入清理失败"
        return 1
    fi
    
    return 0
}

# 测试配置管理
test_config_management() {
    echo "测试配置管理..."
    
    # 创建临时配置文件
    local temp_config="/tmp/test_config.conf"
    cat > "$temp_config" << EOF
# 测试配置
TEST_KEY=test_value
TEST_NUMBER=123
TEST_BOOLEAN=true
EOF
    
    # 测试配置读取
    local value=$(get_config_value "TEST_KEY" "$temp_config")
    if [[ "$value" == "test_value" ]]; then
        echo "  ✓ 配置读取通过"
    else
        echo "  ✗ 配置读取失败"
        rm -f "$temp_config"
        return 1
    fi
    
    # 测试配置设置
    set_config_value "TEST_NEW_KEY" "new_value" "$temp_config"
    local new_value=$(get_config_value "TEST_NEW_KEY" "$temp_config")
    if [[ "$new_value" == "new_value" ]]; then
        echo "  ✓ 配置设置通过"
    else
        echo "  ✗ 配置设置失败"
        rm -f "$temp_config"
        return 1
    fi
    
    rm -f "$temp_config"
    return 0
}

# 测试模块加载
test_module_loading() {
    echo "测试模块加载..."
    
    # 测试模块加载器
    if [[ -f "$MODULES_DIR/module_loader.sh" ]]; then
        echo "  ✓ 模块加载器存在"
    else
        echo "  ✗ 模块加载器不存在"
        return 1
    fi
    
    # 测试关键模块存在
    local critical_modules=(
        "common_functions"
        "error_handling"
        "system_detection"
        "wireguard_config"
        "client_management"
    )
    
    for module in "${critical_modules[@]}"; do
        if [[ -f "$MODULES_DIR/${module}.sh" ]]; then
            echo "  ✓ 模块 $module 存在"
        else
            echo "  ✗ 模块 $module 不存在"
            return 1
        fi
    done
    
    return 0
}

# 测试WireGuard配置
test_wireguard_config() {
    echo "测试WireGuard配置..."
    
    # 测试WireGuard配置模块
    if [[ -f "$MODULES_DIR/wireguard_config.sh" ]]; then
        echo "  ✓ WireGuard配置模块存在"
    else
        echo "  ✗ WireGuard配置模块不存在"
        return 1
    fi
    
    # 测试密钥生成函数
    source "$MODULES_DIR/wireguard_config.sh"
    
    # 测试私钥生成
    local private_key=$(generate_wireguard_private_key)
    if [[ ${#private_key} -eq 44 ]]; then
        echo "  ✓ 私钥生成通过"
    else
        echo "  ✗ 私钥生成失败"
        return 1
    fi
    
    # 测试公钥生成
    local public_key=$(generate_wireguard_public_key "$private_key")
    if [[ ${#public_key} -eq 44 ]]; then
        echo "  ✓ 公钥生成通过"
    else
        echo "  ✗ 公钥生成失败"
        return 1
    fi
    
    return 0
}

# 测试客户端管理
test_client_management() {
    echo "测试客户端管理..."
    
    # 测试客户端管理模块
    if [[ -f "$MODULES_DIR/client_management.sh" ]]; then
        echo "  ✓ 客户端管理模块存在"
    else
        echo "  ✗ 客户端管理模块不存在"
        return 1
    fi
    
    # 测试客户端数据库
    local temp_db="/tmp/test_clients.db"
    sqlite3 "$temp_db" << EOF
CREATE TABLE clients (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    public_key TEXT,
    allowed_ips TEXT,
    endpoint TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF
    
    # 测试数据库操作
    sqlite3 "$temp_db" "INSERT INTO clients (name, public_key) VALUES ('test_client', 'test_key');"
    local count=$(sqlite3 "$temp_db" "SELECT COUNT(*) FROM clients;")
    
    if [[ "$count" -eq 1 ]]; then
        echo "  ✓ 客户端数据库操作通过"
    else
        echo "  ✗ 客户端数据库操作失败"
        rm -f "$temp_db"
        return 1
    fi
    
    rm -f "$temp_db"
    return 0
}

# 测试网络管理
test_network_management() {
    echo "测试网络管理..."
    
    # 测试网络管理模块
    if [[ -f "$MODULES_DIR/network_management.sh" ]]; then
        echo "  ✓ 网络管理模块存在"
    else
        echo "  ✗ 网络管理模块不存在"
        return 1
    fi
    
    # 测试IP地址验证
    source "$MODULES_DIR/common_functions.sh"
    
    if validate_ipv4 "192.168.1.1" && validate_ipv6 "2001:db8::1"; then
        echo "  ✓ IP地址验证通过"
    else
        echo "  ✗ IP地址验证失败"
        return 1
    fi
    
    return 0
}

# 测试防火墙管理
test_firewall_management() {
    echo "测试防火墙管理..."
    
    # 测试防火墙管理模块
    if [[ -f "$MODULES_DIR/firewall_management.sh" ]]; then
        echo "  ✓ 防火墙管理模块存在"
    else
        echo "  ✗ 防火墙管理模块不存在"
        return 1
    fi
    
    # 测试防火墙检测
    source "$MODULES_DIR/firewall_management.sh"
    
    # 检查防火墙状态（不实际修改）
    if check_firewall_status; then
        echo "  ✓ 防火墙状态检查通过"
    else
        echo "  ⚠️  防火墙状态检查失败（可能是权限问题）"
    fi
    
    return 0
}

# 测试Web管理界面
test_web_management() {
    echo "测试Web管理界面..."
    
    # 测试Web管理模块
    if [[ -f "$MODULES_DIR/web_management.sh" ]]; then
        echo "  ✓ Web管理模块存在"
    else
        echo "  ✗ Web管理模块不存在"
        return 1
    fi
    
    # 测试Python依赖
    if command -v python3 &> /dev/null; then
        echo "  ✓ Python3可用"
    else
        echo "  ⚠️  Python3不可用，Web功能可能受限"
    fi
    
    return 0
}

# 测试安全功能
test_security_features() {
    echo "测试安全功能..."
    
    # 测试安全审计模块
    if [[ -f "$MODULES_DIR/security_audit_monitoring.sh" ]]; then
        echo "  ✓ 安全审计模块存在"
    else
        echo "  ✗ 安全审计模块不存在"
        return 1
    fi
    
    # 测试OAuth认证模块
    if [[ -f "$MODULES_DIR/oauth_authentication.sh" ]]; then
        echo "  ✓ OAuth认证模块存在"
    else
        echo "  ✗ OAuth认证模块不存在"
        return 1
    fi
    
    return 0
}

# 测试性能优化
test_performance_optimization() {
    echo "测试性能优化..."
    
    # 测试性能优化模块
    if [[ -f "$MODULES_DIR/performance_optimization.sh" ]]; then
        echo "  ✓ 性能优化模块存在"
    else
        echo "  ✗ 性能优化模块不存在"
        return 1
    fi
    
    # 测试懒加载模块
    if [[ -f "$MODULES_DIR/lazy_loading.sh" ]]; then
        echo "  ✓ 懒加载模块存在"
    else
        echo "  ✗ 懒加载模块不存在"
        return 1
    fi
    
    return 0
}

# 测试多租户功能
test_multi_tenant() {
    echo "测试多租户功能..."
    
    # 测试多租户模块
    if [[ -f "$MODULES_DIR/multi_tenant.sh" ]]; then
        echo "  ✓ 多租户模块存在"
    else
        echo "  ✗ 多租户模块不存在"
        return 1
    fi
    
    # 测试资源配额模块
    if [[ -f "$MODULES_DIR/resource_quota.sh" ]]; then
        echo "  ✓ 资源配额模块存在"
    else
        echo "  ✗ 资源配额模块不存在"
        return 1
    fi
    
    return 0
}

# 显示测试结果
show_test_results() {
    echo
    echo -e "${BLUE}=========================================="
    echo "  测试结果汇总"
    echo "==========================================${NC}"
    echo
    echo -e "总测试数: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"
    echo -e "跳过测试: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有测试通过！${NC}"
        return 0
    else
        echo -e "${RED}❌ 有 $FAILED_TESTS 个测试失败${NC}"
        return 1
    fi
}

# 显示详细测试结果
show_detailed_results() {
    echo
    echo -e "${BLUE}详细测试结果:${NC}"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
}

# 主函数
main() {
    local test_type="all"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --basic)
                test_type="basic"
                shift
                ;;
            --advanced)
                test_type="advanced"
                shift
                ;;
            --help)
                echo "用法: $0 [--basic|--advanced|--help]"
                echo "  --basic     运行基础测试"
                echo "  --advanced  运行高级测试"
                echo "  --help      显示帮助信息"
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    show_banner
    
    echo "开始运行测试..."
    echo "测试类型: $test_type"
    echo
    
    # 运行测试
    run_test "公共函数库" test_common_functions "$test_type"
    run_test "配置管理" test_config_management "$test_type"
    run_test "模块加载" test_module_loading "$test_type"
    run_test "WireGuard配置" test_wireguard_config "$test_type"
    run_test "客户端管理" test_client_management "$test_type"
    run_test "网络管理" test_network_management "$test_type"
    run_test "防火墙管理" test_firewall_management "$test_type"
    run_test "Web管理界面" test_web_management "$test_type"
    run_test "安全功能" test_security_features "$test_type"
    run_test "性能优化" test_performance_optimization "$test_type"
    run_test "多租户功能" test_multi_tenant "$test_type"
    
    # 显示结果
    show_test_results
    show_detailed_results
    
    # 返回退出码
    if [[ $FAILED_TESTS -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# 运行主函数
main "$@"
