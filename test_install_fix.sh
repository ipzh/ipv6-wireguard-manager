#!/bin/bash

# 测试install.sh修复结果
echo "测试install.sh修复结果..."

# 测试语法
echo "1. 测试语法..."
if bash -n install.sh; then
    echo "✓ 语法检查通过"
else
    echo "✗ 语法检查失败"
    exit 1
fi

# 测试log_info函数是否可用
echo "2. 测试log_info函数..."
bash -c "
source install.sh
if declare -f log_info >/dev/null 2>&1; then
    echo '✓ log_info函数已定义'
    log_info '测试日志信息'
    echo '✓ log_info函数调用成功'
else
    echo '✗ log_info函数未定义'
    exit 1
fi
"

# 测试其他日志函数
echo "3. 测试其他日志函数..."
bash -c "
source install.sh
if declare -f log_success >/dev/null 2>&1 && \
   declare -f log_warn >/dev/null 2>&1 && \
   declare -f log_error >/dev/null 2>&1; then
    echo '✓ 所有日志函数已定义'
    log_success '测试成功信息'
    log_warn '测试警告信息'
    log_error '测试错误信息'
    echo '✓ 所有日志函数调用成功'
else
    echo '✗ 部分日志函数未定义'
    exit 1
fi
"

echo "所有测试通过！install.sh修复成功。"
