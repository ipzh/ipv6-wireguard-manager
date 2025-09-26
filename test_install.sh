#!/bin/bash

# 测试安装脚本的诊断脚本

set -euo pipefail

echo "🔍 诊断安装脚本问题..."

# 检查脚本语法
echo "1. 检查脚本语法..."
if bash -n install.sh; then
    echo "✅ 脚本语法正确"
else
    echo "❌ 脚本语法错误"
    exit 1
fi

# 检查关键函数是否存在
echo "2. 检查关键函数..."
functions=("main" "show_install_methods" "quick_install" "perform_installation")

for func in "${functions[@]}"; do
    if grep -q "^${func}()" install.sh; then
        echo "✅ 函数 $func 存在"
    else
        echo "❌ 函数 $func 不存在"
    fi
done

# 检查脚本末尾
echo "3. 检查脚本末尾..."
if grep -q "main \"\$@\"" install.sh; then
    echo "✅ main函数调用存在"
else
    echo "❌ main函数调用不存在"
fi

# 测试脚本执行
echo "4. 测试脚本执行..."
echo "运行: bash install.sh --help"
bash install.sh --help

echo "5. 测试交互式模式..."
echo "运行: echo '1' | bash install.sh"
echo "1" | timeout 10s bash install.sh || echo "脚本执行超时或出错"

echo "诊断完成！"
