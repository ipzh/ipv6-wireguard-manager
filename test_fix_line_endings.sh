#!/bin/bash

# 测试fix_line_endings函数

echo "=== 测试fix_line_endings函数 ==="

# 创建测试文件（Windows行尾符）
echo -e "line1\r\nline2\r\nline3\r\n" > test_file.txt

echo "原始文件内容（十六进制）:"
hexdump -C test_file.txt

# 测试fix_line_endings函数
if declare -f fix_line_endings >/dev/null 2>&1; then
    echo "fix_line_endings函数已定义"
    fix_line_endings test_file.txt
    echo "修复后文件内容（十六进制）:"
    hexdump -C test_file.txt
else
    echo "fix_line_endings函数未定义"
fi

# 清理
rm -f test_file.txt

echo "测试完成"
