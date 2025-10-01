#!/bin/bash

# 优化硬编码sleep调用的脚本
# 将硬编码的sleep时间替换为可配置的智能等待函数

echo "开始优化硬编码sleep调用..."

# 需要处理的文件列表
files=(
    "ipv6-wireguard-manager.sh"
    "tests/comprehensive_test_suite.sh"
    "uninstall.sh"
    "install_with_download.sh"
    "modules/user_interface.sh"
)

# 替换规则
declare -A replacements=(
    ["sleep 0.1"]="smart_sleep \$IPV6WGM_SLEEP_SHORT"
    ["sleep 0.5"]="smart_sleep \$IPV6WGM_SLEEP_UI"
    ["sleep 1"]="smart_sleep \$IPV6WGM_SLEEP_MEDIUM"
    ["sleep 2"]="smart_sleep \$IPV6WGM_SLEEP_LONG"
)

# 处理每个文件
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "处理文件: $file"
        
        # 创建备份
        cp "$file" "${file}.backup"
        
        # 应用替换规则
        for old_pattern in "${!replacements[@]}"; do
            new_pattern="${replacements[$old_pattern]}"
            sed -i "s/${old_pattern}/${new_pattern}/g" "$file"
        done
        
        echo "✓ 已处理: $file"
    else
        echo "⚠ 文件不存在: $file"
    fi
done

echo "sleep调用优化完成！"

# 验证结果
echo "验证优化结果..."
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        hardcoded_sleeps=$(grep -c "sleep [0-9]" "$file" 2>/dev/null || echo "0")
        smart_sleeps=$(grep -c "smart_sleep" "$file" 2>/dev/null || echo "0")
        
        if [[ $hardcoded_sleeps -gt 0 ]]; then
            echo "⚠ $file 仍有 $hardcoded_sleeps 个硬编码sleep调用"
        else
            echo "✓ $file 已优化完成 (使用 $smart_sleeps 个smart_sleep调用)"
        fi
    fi
done

echo "优化验证完成！"
