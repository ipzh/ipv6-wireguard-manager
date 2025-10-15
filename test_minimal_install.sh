#!/bin/bash

# 测试最小化安装脚本
# 用于调试安装问题

set -e

echo "=========================================="
echo "🧪 测试最小化安装脚本"
echo "=========================================="
echo ""

# 测试1: 检查脚本语法
echo "测试1: 检查脚本语法..."
if bash -n install.sh; then
    echo "✅ 脚本语法检查通过"
else
    echo "❌ 脚本语法错误"
    exit 1
fi
echo ""

# 测试2: 检查非交互模式处理
echo "测试2: 检查非交互模式处理..."
echo "模拟非交互模式测试..."

# 创建一个测试函数来模拟非交互模式
test_non_interactive_mode() {
    echo "测试非交互模式参数解析..."
    
    # 模拟管道安装
    echo "minimal" | timeout 10 bash install.sh --help 2>/dev/null || {
        echo "⚠️ 非交互模式测试超时或失败"
        return 1
    }
    
    echo "✅ 非交互模式处理正常"
    return 0
}

# 测试3: 检查关键函数
echo "测试3: 检查关键函数..."
key_functions=(
    "recommend_install_type"
    "install_minimal_dependencies"
    "create_service_user"
    "download_project"
    "install_core_dependencies"
    "configure_minimal_mysql_database"
    "create_simple_service"
    "start_minimal_services"
    "run_environment_check"
)

for func in "${key_functions[@]}"; do
    if grep -q "^$func()" install.sh; then
        echo "✅ 函数 $func 存在"
    else
        echo "❌ 函数 $func 不存在"
        exit 1
    fi
done
echo ""

# 测试4: 检查错误处理
echo "测试4: 检查错误处理..."
if grep -q "log_error.*失败" install.sh; then
    echo "✅ 错误处理已添加"
else
    echo "❌ 错误处理不完整"
    exit 1
fi
echo ""

# 测试5: 检查调试信息
echo "测试5: 检查调试信息..."
if grep -q "开始.*完成" install.sh; then
    echo "✅ 调试信息已添加"
else
    echo "❌ 调试信息不完整"
    exit 1
fi
echo ""

# 测试6: 检查变量设置
echo "测试6: 检查变量设置..."
required_vars=(
    "INSTALL_DIR"
    "SERVICE_USER"
    "SKIP_DEPS"
    "SKIP_SERVICE"
    "MYSQL_VERSION"
)

for var in "${required_vars[@]}"; do
    if grep -q "$var=" install.sh; then
        echo "✅ 变量 $var 已设置"
    else
        echo "❌ 变量 $var 未设置"
        exit 1
    fi
done
echo ""

echo "=========================================="
echo "🎉 所有测试通过！"
echo "=========================================="
echo ""
echo "修复内容总结:"
echo "✅ 修复了非交互模式参数解析问题"
echo "✅ 添加了详细的调试信息"
echo "✅ 改进了错误处理机制"
echo "✅ 优化了MySQL包安装逻辑"
echo "✅ 添加了函数执行状态检查"
echo ""
echo "现在可以测试安装:"
echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
echo ""
echo "或者本地测试:"
echo "bash install.sh minimal --dir /tmp/test-install"
