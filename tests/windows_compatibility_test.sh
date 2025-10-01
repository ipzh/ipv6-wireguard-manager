#!/bin/bash

# Windows 兼容性测试脚本
# 专门用于测试 IPv6-WireGuard Manager 在 Windows 环境下的兼容性

# =============================================================================
# 测试配置
# =============================================================================

# 测试结果统计
declare -g TOTAL_TESTS=0
declare -g PASSED_TESTS=0
declare -g FAILED_TESTS=0
declare -g SKIPPED_TESTS=0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# 测试框架函数
# =============================================================================

# 运行测试
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${BLUE}运行测试: $test_name${NC}"
    ((TOTAL_TESTS++))
    
    if $test_function; then
        echo -e "${GREEN}✓ 通过${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ 失败${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# 跳过测试
skip_test() {
    local test_name="$1"
    local reason="$2"
    
    echo -e "${YELLOW}跳过测试: $test_name - $reason${NC}"
    ((SKIPPED_TESTS++))
}

# 显示测试结果
show_test_results() {
    echo
    echo -e "${BLUE}=== 测试结果汇总 ===${NC}"
    echo "总测试数: $TOTAL_TESTS"
    echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败: ${RED}$FAILED_TESTS${NC}"
    echo -e "跳过: ${YELLOW}$SKIPPED_TESTS${NC}"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} 所有测试通过！"
        return 0
    else
        echo -e "${RED}[FAILURE]${NC} 有 $FAILED_TESTS 个测试失败"
        return 1
    fi
}

# =============================================================================
# Windows 环境检测
# =============================================================================

# 检测 Windows 环境
detect_windows_environment() {
    local env_type="unknown"
    
    # 检测 WSL
    if [[ -f "/proc/version" ]] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        env_type="wsl"
    # 检测 MSYS2
    elif [[ -n "$MSYSTEM" ]] || [[ "$OSTYPE" == "msys" ]]; then
        env_type="msys2"
    # 检测 Cygwin
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        env_type="cygwin"
    # 检测 PowerShell
    elif command -v pwsh >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
        env_type="powershell"
    # 检测 Git Bash
    elif [[ -n "$GIT_BASH" ]] || [[ "$SHELL" == *"git-bash"* ]]; then
        env_type="git_bash"
    fi
    
    echo "$env_type"
}

# 获取环境信息
get_environment_info() {
    echo -e "${BLUE}=== 环境信息 ===${NC}"
    echo "操作系统: $(uname -a)"
    echo "Shell: $SHELL"
    echo "PATH: $PATH"
    echo "OSTYPE: $OSTYPE"
    
    if [[ -n "$MSYSTEM" ]]; then
        echo "MSYSTEM: $MSYSTEM"
    fi
    
    if [[ -n "$GIT_BASH" ]]; then
        echo "GIT_BASH: $GIT_BASH"
    fi
    
    echo
}

# =============================================================================
# WSL 兼容性测试
# =============================================================================

# 测试 WSL 兼容性
test_wsl_compatibility() {
    echo "测试 WSL 兼容性..."
    
    local wsl_version=""
    local wsl_distro=""
    
    # 检测 WSL 版本
    if command -v wsl.exe >/dev/null 2>&1; then
        wsl_version=$(wsl.exe --version 2>/dev/null | head -1 || echo "WSL 2")
    fi
    
    # 检测发行版
    if [[ -f "/etc/os-release" ]]; then
        wsl_distro=$(grep "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    
    echo "  WSL 版本: $wsl_version"
    echo "  发行版: $wsl_distro"
    
    # 测试关键功能
    local tests_passed=0
    local total_tests=5
    
    # 测试网络功能
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✓ 网络连接正常"
        ((tests_passed++))
    else
        echo "  ✗ 网络连接失败"
    fi
    
    # 测试文件系统
    if [[ -w "/tmp" ]]; then
        echo "  ✓ 文件系统可写"
        ((tests_passed++))
    else
        echo "  ✗ 文件系统不可写"
    fi
    
    # 测试系统命令
    if command -v systemctl >/dev/null 2>&1; then
        echo "  ✓ systemctl 可用"
        ((tests_passed++))
    else
        echo "  ✗ systemctl 不可用"
    fi
    
    # 测试 IPv6 支持
    if [[ -f "/proc/net/if_inet6" ]]; then
        echo "  ✓ IPv6 支持"
        ((tests_passed++))
    else
        echo "  ✗ IPv6 不支持"
    fi
    
    # 测试 WireGuard 支持
    if command -v wg >/dev/null 2>&1; then
        echo "  ✓ WireGuard 可用"
        ((tests_passed++))
    else
        echo "  ✗ WireGuard 不可用"
    fi
    
    echo "  WSL 兼容性测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# =============================================================================
# MSYS2 兼容性测试
# =============================================================================

# 测试 MSYS2 兼容性
test_msys2_compatibility() {
    echo "测试 MSYS2 兼容性..."
    
    local msys2_version=""
    local package_manager=""
    
    # 检测 MSYS2 版本
    if command -v pacman >/dev/null 2>&1; then
        msys2_version=$(pacman --version | head -1)
        package_manager="pacman"
    fi
    
    echo "  MSYS2 版本: $msys2_version"
    echo "  包管理器: $package_manager"
    
    # 测试关键功能
    local tests_passed=0
    local total_tests=4
    
    # 测试包管理器
    if command -v pacman >/dev/null 2>&1; then
        echo "  ✓ pacman 可用"
        ((tests_passed++))
    else
        echo "  ✗ pacman 不可用"
    fi
    
    # 测试网络功能
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✓ 网络连接正常"
        ((tests_passed++))
    else
        echo "  ✗ 网络连接失败"
    fi
    
    # 测试文件系统
    if [[ -w "/tmp" ]]; then
        echo "  ✓ 文件系统可写"
        ((tests_passed++))
    else
        echo "  ✗ 文件系统不可写"
    fi
    
    # 测试 IPv6 支持
    if [[ -f "/proc/net/if_inet6" ]]; then
        echo "  ✓ IPv6 支持"
        ((tests_passed++))
    else
        echo "  ✗ IPv6 不支持"
    fi
    
    echo "  MSYS2 兼容性测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# =============================================================================
# PowerShell 兼容性测试
# =============================================================================

# 测试 PowerShell 兼容性
test_powershell_compatibility() {
    echo "测试 PowerShell 兼容性..."
    
    local pwsh_version=""
    local ps_version=""
    
    # 检测 PowerShell Core
    if command -v pwsh >/dev/null 2>&1; then
        pwsh_version=$(pwsh --version 2>/dev/null || echo "PowerShell Core")
    fi
    
    # 检测 Windows PowerShell
    if command -v powershell >/dev/null 2>&1; then
        ps_version=$(powershell --version 2>/dev/null || echo "Windows PowerShell")
    fi
    
    echo "  PowerShell Core: $pwsh_version"
    echo "  Windows PowerShell: $ps_version"
    
    # 测试关键功能
    local tests_passed=0
    local total_tests=3
    
    # 测试 PowerShell 可用性
    if command -v pwsh >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
        echo "  ✓ PowerShell 可用"
        ((tests_passed++))
    else
        echo "  ✗ PowerShell 不可用"
    fi
    
    # 测试网络功能
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✓ 网络连接正常"
        ((tests_passed++))
    else
        echo "  ✗ 网络连接失败"
    fi
    
    # 测试文件系统
    if [[ -w "/tmp" ]] || [[ -w "C:\\" ]]; then
        echo "  ✓ 文件系统可写"
        ((tests_passed++))
    else
        echo "  ✗ 文件系统不可写"
    fi
    
    echo "  PowerShell 兼容性测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# =============================================================================
# Git Bash 兼容性测试
# =============================================================================

# 测试 Git Bash 兼容性
test_git_bash_compatibility() {
    echo "测试 Git Bash 兼容性..."
    
    local git_version=""
    local bash_version=""
    
    # 检测 Git 版本
    if command -v git >/dev/null 2>&1; then
        git_version=$(git --version)
    fi
    
    # 检测 Bash 版本
    if command -v bash >/dev/null 2>&1; then
        bash_version=$(bash --version | head -1)
    fi
    
    echo "  Git 版本: $git_version"
    echo "  Bash 版本: $bash_version"
    
    # 测试关键功能
    local tests_passed=0
    local total_tests=4
    
    # 测试 Git
    if command -v git >/dev/null 2>&1; then
        echo "  ✓ Git 可用"
        ((tests_passed++))
    else
        echo "  ✗ Git 不可用"
    fi
    
    # 测试 Bash
    if command -v bash >/dev/null 2>&1; then
        echo "  ✓ Bash 可用"
        ((tests_passed++))
    else
        echo "  ✗ Bash 不可用"
    fi
    
    # 测试网络功能
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✓ 网络连接正常"
        ((tests_passed++))
    else
        echo "  ✗ 网络连接失败"
    fi
    
    # 测试文件系统
    if [[ -w "/tmp" ]] || [[ -w "C:\\" ]]; then
        echo "  ✓ 文件系统可写"
        ((tests_passed++))
    else
        echo "  ✗ 文件系统不可写"
    fi
    
    echo "  Git Bash 兼容性测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# =============================================================================
# 通用 Windows 兼容性测试
# =============================================================================

# 测试 Windows 路径处理
test_windows_path_handling() {
    echo "测试 Windows 路径处理..."
    
    local tests_passed=0
    local total_tests=3
    
    # 测试路径转换
    local test_path="/c/Users/test"
    local windows_path="C:\\Users\\test"
    
    if [[ "$test_path" == "/c/Users/test" ]]; then
        echo "  ✓ Unix 路径格式"
        ((tests_passed++))
    else
        echo "  ✗ Unix 路径格式失败"
    fi
    
    # 测试路径分隔符
    if [[ "$PATH" == *":"* ]]; then
        echo "  ✓ Unix 路径分隔符"
        ((tests_passed++))
    else
        echo "  ✗ Unix 路径分隔符失败"
    fi
    
    # 测试文件权限
    if [[ -r "/etc/passwd" ]] || [[ -r "C:\\Windows\\System32\\drivers\\etc\\hosts" ]]; then
        echo "  ✓ 文件读取权限"
        ((tests_passed++))
    else
        echo "  ✗ 文件读取权限失败"
    fi
    
    echo "  Windows 路径处理测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# 测试 Windows 网络功能
test_windows_network() {
    echo "测试 Windows 网络功能..."
    
    local tests_passed=0
    local total_tests=4
    
    # 测试 IPv4 连接
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✓ IPv4 连接正常"
        ((tests_passed++))
    else
        echo "  ✗ IPv4 连接失败"
    fi
    
    # 测试 IPv6 连接
    if ping -c 1 2001:4860:4860::8888 >/dev/null 2>&1; then
        echo "  ✓ IPv6 连接正常"
        ((tests_passed++))
    else
        echo "  ✗ IPv6 连接失败"
    fi
    
    # 测试 DNS 解析
    if nslookup google.com >/dev/null 2>&1; then
        echo "  ✓ DNS 解析正常"
        ((tests_passed++))
    else
        echo "  ✗ DNS 解析失败"
    fi
    
    # 测试网络接口
    if ip addr show >/dev/null 2>&1 || ifconfig >/dev/null 2>&1; then
        echo "  ✓ 网络接口检测正常"
        ((tests_passed++))
    else
        echo "  ✗ 网络接口检测失败"
    fi
    
    echo "  Windows 网络功能测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# 测试 Windows 命令兼容性
test_windows_commands() {
    echo "测试 Windows 命令兼容性..."
    
    local tests_passed=0
    local total_tests=5
    
    # 测试基本命令
    if command -v ls >/dev/null 2>&1; then
        echo "  ✓ ls 命令可用"
        ((tests_passed++))
    else
        echo "  ✗ ls 命令不可用"
    fi
    
    if command -v grep >/dev/null 2>&1; then
        echo "  ✓ grep 命令可用"
        ((tests_passed++))
    else
        echo "  ✗ grep 命令不可用"
    fi
    
    if command -v sed >/dev/null 2>&1; then
        echo "  ✓ sed 命令可用"
        ((tests_passed++))
    else
        echo "  ✗ sed 命令不可用"
    fi
    
    if command -v awk >/dev/null 2>&1; then
        echo "  ✓ awk 命令可用"
        ((tests_passed++))
    else
        echo "  ✗ awk 命令不可用"
    fi
    
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        echo "  ✓ 网络工具可用"
        ((tests_passed++))
    else
        echo "  ✗ 网络工具不可用"
    fi
    
    echo "  Windows 命令兼容性测试: $tests_passed/$total_tests 通过"
    return $((tests_passed == total_tests ? 0 : 1))
}

# =============================================================================
# 主测试函数
# =============================================================================

# 运行 Windows 兼容性测试
run_windows_compatibility_tests() {
    echo -e "${BLUE}=== Windows 兼容性测试 ===${NC}"
    
    local env_type=$(detect_windows_environment)
    echo "检测到的环境类型: $env_type"
    echo
    
    # 显示环境信息
    get_environment_info
    
    # 根据环境类型运行相应测试
    case "$env_type" in
        "wsl")
            run_test "WSL 兼容性测试" test_wsl_compatibility
            ;;
        "msys2")
            run_test "MSYS2 兼容性测试" test_msys2_compatibility
            ;;
        "powershell")
            run_test "PowerShell 兼容性测试" test_powershell_compatibility
            ;;
        "git_bash")
            run_test "Git Bash 兼容性测试" test_git_bash_compatibility
            ;;
        *)
            echo "未知的 Windows 环境类型，跳过特定环境测试"
            ;;
    esac
    
    # 通用 Windows 兼容性测试
    run_test "Windows 路径处理测试" test_windows_path_handling
    run_test "Windows 网络功能测试" test_windows_network
    run_test "Windows 命令兼容性测试" test_windows_commands
    
    echo
    echo "Windows 兼容性测试结果: $PASSED_TESTS/$TOTAL_TESTS 通过"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}✓ 所有 Windows 兼容性测试通过${NC}"
        return 0
    else
        echo -e "${RED}✗ 部分 Windows 兼容性测试失败${NC}"
        return 1
    fi
}

# 主函数
main() {
    echo -e "${BLUE}=== IPv6-WireGuard Manager Windows 兼容性测试 ===${NC}"
    echo "开始时间: $(date)"
    echo
    
    # 运行 Windows 兼容性测试
    run_windows_compatibility_tests
    
    # 显示测试结果
    show_test_results
    
    local test_result=$?
    
    echo
    echo "结束时间: $(date)"
    
    exit $test_result
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
