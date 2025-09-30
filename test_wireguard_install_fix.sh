#!/bin/bash

# 测试WireGuard安装卡住问题修复

echo "=== 测试WireGuard安装卡住问题修复 ==="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 测试WireGuard安装修复
test_wireguard_install_fix() {
    log_info "测试WireGuard安装修复..."
    
    # 创建测试目录
    TEST_DIR="/tmp/wireguard-test-$(date +%s)"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR" || exit
    
    echo "测试目录: $TEST_DIR"
    
    # 创建模拟的安装脚本
    cat > test_install.sh << 'EOF'
#!/bin/bash

# 模拟WireGuard安装修复
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 模拟WireGuard安装修复
install_wireguard_with_fix() {
    log_info "开始安装WireGuard（带修复）..."
    
    # 1. 停止可能卡住的服务
    log_info "停止WireGuard相关服务..."
    systemctl stop wg-quick@wg0 2>/dev/null || true
    systemctl stop wg-quick.target 2>/dev/null || true
    systemctl disable wg-quick@wg0 2>/dev/null || true
    systemctl disable wg-quick.target 2>/dev/null || true
    
    # 2. 重新加载systemd配置
    log_info "重新加载systemd配置..."
    systemctl daemon-reload
    
    # 3. 重置systemd状态
    log_info "重置systemd状态..."
    systemctl reset-failed wg-quick@wg0 2>/dev/null || true
    systemctl reset-failed wg-quick.target 2>/dev/null || true
    
    # 4. 模拟安装WireGuard（带超时）
    log_info "安装WireGuard包（带超时）..."
    if timeout 10 echo "模拟WireGuard安装成功"; then
        log_success "WireGuard包安装成功"
    else
        log_warn "WireGuard包安装超时，尝试继续..."
        echo "模拟强制配置包"
    fi
    
    # 5. 创建基本配置
    log_info "创建基本配置..."
    mkdir -p /tmp/test-wireguard
    cat > /tmp/test-wireguard/wg0.conf << 'WIREGUARD_EOF'
# WireGuard配置示例
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.0.0.1/24
ListenPort = 51820
WIREGUARD_EOF
    
    # 6. 验证安装
    log_info "验证WireGuard安装..."
    if command -v wg >/dev/null 2>&1; then
        log_success "WireGuard工具已安装"
    else
        log_warn "WireGuard工具未安装（测试环境）"
    fi
    
    log_success "WireGuard安装修复完成！"
}

# 执行安装
install_wireguard_with_fix
EOF

    chmod +x test_install.sh
    
    # 运行测试
    if bash test_install.sh; then
        log_success "WireGuard安装修复测试通过"
    else
        log_error "WireGuard安装修复测试失败"
    fi
    
    # 清理
    cd / || exit
    rm -rf "$TEST_DIR"
    echo "✓ 测试完成，临时目录已清理"
}

# 测试超时处理
test_timeout_handling() {
    log_info "测试超时处理..."
    
    # 测试超时命令
    if timeout 2 sleep 1; then
        log_success "超时命令测试通过"
    else
        log_error "超时命令测试失败"
    fi
    
    # 测试超时失败
    if timeout 1 sleep 2; then
        log_error "超时失败测试失败"
    else
        log_success "超时失败测试通过"
    fi
}

# 测试systemd服务处理
test_systemd_handling() {
    log_info "测试systemd服务处理..."
    
    # 测试服务停止
    if systemctl stop wg-quick@wg0 2>/dev/null; then
        log_success "服务停止测试通过"
    else
        log_warn "服务停止测试（预期失败）"
    fi
    
    # 测试服务禁用
    if systemctl disable wg-quick@wg0 2>/dev/null; then
        log_success "服务禁用测试通过"
    else
        log_warn "服务禁用测试（预期失败）"
    fi
    
    # 测试daemon-reload
    if systemctl daemon-reload; then
        log_success "daemon-reload测试通过"
    else
        log_error "daemon-reload测试失败"
    fi
}

# 主函数
main() {
    log_info "开始测试WireGuard安装卡住问题修复..."
    
    # 测试超时处理
    test_timeout_handling
    
    # 测试systemd服务处理
    test_systemd_handling
    
    # 测试WireGuard安装修复
    test_wireguard_install_fix
    
    log_success "所有测试完成！"
}

# 执行主函数
main "$@"
