#!/bin/bash

# 测试路径修复脚本
# 验证主脚本在不同运行方式下的路径设置

echo "=== 测试路径修复 ==="

# 测试1: 直接运行脚本
echo "测试1: 直接运行脚本"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
MODULES_DIR="${SCRIPT_DIR}/modules"

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "MODULES_DIR: $MODULES_DIR"

if [[ -f "${MODULES_DIR}/common_functions.sh" ]]; then
    echo "✓ 直接运行: 找到 common_functions.sh"
else
    echo "✗ 直接运行: 未找到 common_functions.sh"
fi

# 测试2: 模拟符号链接运行
echo -e "\n测试2: 模拟符号链接运行"
if [[ -L "/usr/local/bin/ipv6-wireguard-manager" ]]; then
    SCRIPT_DIR="/opt/ipv6-wireguard-manager"
    MODULES_DIR="/opt/ipv6-wireguard-manager/modules"
    echo "通过符号链接运行"
else
    echo "未通过符号链接运行，使用实际安装目录测试"
    SCRIPT_DIR="/opt/ipv6-wireguard-manager"
    MODULES_DIR="/opt/ipv6-wireguard-manager/modules"
fi

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "MODULES_DIR: $MODULES_DIR"

if [[ -f "${MODULES_DIR}/common_functions.sh" ]]; then
    echo "✓ 符号链接运行: 找到 common_functions.sh"
else
    echo "✗ 符号链接运行: 未找到 common_functions.sh"
    
    # 检查实际安装目录
    echo "检查实际安装目录:"
    if [[ -d "/opt/ipv6-wireguard-manager" ]]; then
        echo "✓ /opt/ipv6-wireguard-manager 目录存在"
        find /opt/ipv6-wireguard-manager/ -maxdepth 1 -type f -o -type d | head -5
    else
        echo "✗ /opt/ipv6-wireguard-manager 目录不存在"
    fi
    
    if [[ -d "/opt/ipv6-wireguard-manager/modules" ]]; then
        echo "✓ /opt/ipv6-wireguard-manager/modules 目录存在"
        find /opt/ipv6-wireguard-manager/modules/ -maxdepth 1 -type f -o -type d | head -5
    else
        echo "✗ /opt/ipv6-wireguard-manager/modules 目录不存在"
    fi
fi

# 测试3: 检查所有可能的路径
echo -e "\n测试3: 检查所有可能的路径"
alt_paths=(
    "/opt/ipv6-wireguard-manager/modules/common_functions.sh"
    "/usr/local/share/ipv6-wireguard-manager/modules/common_functions.sh"
    "$(pwd)/modules/common_functions.sh"
    "${SCRIPT_DIR}/modules/common_functions.sh"
)

for path in "${alt_paths[@]}"; do
    if [[ -f "$path" ]]; then
        echo "✓ 找到: $path"
    else
        echo "✗ 未找到: $path"
    fi
done

echo -e "\n=== 测试完成 ==="
