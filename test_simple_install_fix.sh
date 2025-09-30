#!/bin/bash

# 简单测试现有安装检查修复

echo "=== 简单测试现有安装检查修复 ==="

# 创建测试目录
TEST_DIR="/tmp/simple-install-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "测试目录: $TEST_DIR"

# 创建模拟的安装脚本
cat > test_install.sh << 'EOF'
#!/bin/bash

# 简化的安装脚本测试
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 模拟变量
INSTALL_DIR="/tmp/test-install"
CONFIG_DIR="/tmp/test-config"
LOG_DIR="/tmp/test-log"
BIN_DIR="/tmp/test-bin"
SERVICE_DIR="/tmp/test-service"
FORCE_INSTALL="${FORCE_INSTALL:-false}"

# 检查现有安装函数
check_existing_installation() {
    log_info "检查现有安装..."
    
    local has_existing=false
    local has_real_installation=false
    
    # 检查关键文件是否存在（这些文件表明有真正的安装）
    local critical_files=(
        "$BIN_DIR/ipv6-wireguard-manager"
        "$SERVICE_DIR/ipv6-wireguard-manager.service"
        "$INSTALL_DIR/ipv6-wireguard-manager.sh"
        "$INSTALL_DIR/modules/common_functions.sh"
    )
    
    # 检查关键文件
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_warn "关键文件已存在: $file"
            has_existing=true
            has_real_installation=true
        fi
    done
    
    # 检查目录是否存在且非空
    local check_dirs=("$INSTALL_DIR" "$CONFIG_DIR")
    for dir in "${check_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            # 检查目录是否为空
            if [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
                log_warn "目录已存在且非空: $dir"
                has_existing=true
                has_real_installation=true
            else
                log_info "目录已存在但为空: $dir"
                has_existing=true
            fi
        fi
    done
    
    # 检查日志目录（日志目录存在是正常的）
    if [[ -d "$LOG_DIR" ]]; then
        log_info "日志目录已存在: $LOG_DIR"
        has_existing=true
    fi
    
    # 只有在检测到真正的安装时才要求强制安装
    if [[ "$has_real_installation" == "true" ]]; then
        if [[ "$FORCE_INSTALL" == "true" ]]; then
            log_info "强制安装模式，将覆盖现有安装"
        else
            log_error "检测到现有安装，请使用 --force 选项强制安装"
            return 1
        fi
    elif [[ "$has_existing" == "true" ]]; then
        log_info "检测到空目录，将使用现有目录进行安装"
    else
        log_info "未检测到现有安装"
    fi
    
    return 0
}

# 主函数
main() {
    log_info "开始安装..."
    
    # 检查现有安装
    if ! check_existing_installation; then
        log_error "现有安装检查失败"
        return 1
    fi
    
    log_info "安装检查通过"
    return 0
}

# 执行主函数
if main "$@"; then
    log_info "测试成功"
    exit 0
else
    log_error "测试失败"
    exit 1
fi
EOF

chmod +x test_install.sh

echo "1. 测试空目录情况..."
# 创建空目录
mkdir -p "/tmp/test-install" "/tmp/test-config" "/tmp/test-log"
echo "创建空目录: /tmp/test-install, /tmp/test-config, /tmp/test-log"

# 运行测试
if bash test_install.sh; then
    echo "✓ 空目录测试通过"
else
    echo "✗ 空目录测试失败"
fi

echo "2. 测试有文件的目录情况..."
# 在目录中创建文件
echo "test" > "/tmp/test-install/test.txt"
echo "创建文件: /tmp/test-install/test.txt"

# 运行测试
if bash test_install.sh; then
    echo "✓ 有文件目录测试通过"
else
    echo "✗ 有文件目录测试失败"
fi

echo "3. 测试关键文件存在情况..."
# 创建关键文件
mkdir -p "/tmp/test-bin" "/tmp/test-service"
echo "test" > "/tmp/test-bin/ipv6-wireguard-manager"
echo "创建关键文件: /tmp/test-bin/ipv6-wireguard-manager"

# 运行测试
if bash test_install.sh; then
    echo "✓ 关键文件存在测试通过"
else
    echo "✗ 关键文件存在测试失败"
fi

echo "4. 测试强制安装模式..."
# 设置强制安装
export FORCE_INSTALL="true"

# 运行测试
if bash test_install.sh; then
    echo "✓ 强制安装模式测试通过"
else
    echo "✗ 强制安装模式测试失败"
fi

# 清理
cd /
rm -rf "$TEST_DIR" "/tmp/test-install" "/tmp/test-config" "/tmp/test-log" "/tmp/test-bin" "/tmp/test-service"
echo "✓ 测试完成，临时目录已清理"
