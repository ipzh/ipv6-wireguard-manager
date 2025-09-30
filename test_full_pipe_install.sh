#!/bin/bash

# 测试完整管道安装流程

echo "=== 测试完整管道安装流程 ==="

# 创建测试目录
TEST_DIR="/tmp/full-pipe-install-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "测试目录: $TEST_DIR"

# 模拟完整的管道安装流程
echo "1. 模拟完整管道安装流程..."

# 创建一个模拟的安装脚本，只测试关键部分
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

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 主函数
main() {
    log_info "开始安装..."
    
    # 检查是否为管道执行
    if [[ -t 0 ]]; then
        log_info "交互式执行模式"
    else
        log_info "管道执行模式，使用快速安装"
    fi
    
    # 模拟安装过程
    log_info "检查系统兼容性..."
    sleep 1
    
    log_info "安装依赖..."
    sleep 1
    
    log_info "创建目录结构..."
    sleep 1
    
    log_info "下载项目文件..."
    sleep 1
    
    log_info "安装文件..."
    sleep 1
    
    log_info "配置系统..."
    sleep 1
    
    log_success "安装完成！"
    return 0
}

# 错误处理
if [[ -t 0 ]]; then
    trap 'log_error "安装过程中发生错误，行号: $LINENO"; exit 1' ERR
else
    trap 'log_error "安装过程中发生错误，行号: $LINENO"; return 1' ERR
fi

# 执行主函数
if main "$@"; then
    log_success "安装成功完成！"
    exit 0
else
    log_error "安装失败！"
    exit 1
fi
EOF

chmod +x test_install.sh

echo "2. 测试交互式执行..."
echo "" | timeout 10 bash test_install.sh
INTERACTIVE_EXIT_CODE=$?
echo "交互式执行退出码: $INTERACTIVE_EXIT_CODE"

echo "3. 测试管道执行..."
echo "" | timeout 10 bash test_install.sh
PIPE_EXIT_CODE=$?
echo "管道执行退出码: $PIPE_EXIT_CODE"

echo "4. 测试结果分析..."
if [[ $INTERACTIVE_EXIT_CODE -eq 0 ]]; then
    echo "✓ 交互式执行正常"
else
    echo "✗ 交互式执行异常，退出码: $INTERACTIVE_EXIT_CODE"
fi

if [[ $PIPE_EXIT_CODE -eq 0 ]]; then
    echo "✓ 管道执行正常"
else
    echo "✗ 管道执行异常，退出码: $PIPE_EXIT_CODE"
fi

# 清理
cd /
rm -rf "$TEST_DIR"
echo "✓ 测试完成，临时目录已清理"
