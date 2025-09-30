#!/bin/bash
# fix_line_endings.sh

# 修复Windows行尾符问题

echo "修复Shell脚本的行尾符问题..."

# 查找所有.sh文件并修复行尾符
find modules -name "*.sh" -type f | while read -r file; do
    if [[ -f "$file" ]]; then
        echo "处理文件: $file"
        # 使用sed替换Windows行尾符为Unix行尾符
        sed -i 's/\r$//' "$file" 2>/dev/null || true
    fi
done

echo "行尾符修复完成"
