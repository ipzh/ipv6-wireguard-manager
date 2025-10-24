#!/bin/bash

# IPv6 WireGuard Manager 一键检查工具 (Linux/macOS版本)
# 一键检查所有问题并生成综合诊断报告

echo "🔍 IPv6 WireGuard Manager 一键检查工具"
echo "========================================"
echo

# 检查Python是否可用
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python3未安装或不在PATH中"
    echo "请先安装Python3"
    exit 1
fi

# 检查必要的Python包
echo "[INFO] 检查Python依赖包..."
python3 -c "import psutil, requests" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "[WARNING] 缺少必要的Python包，正在安装..."
    pip3 install psutil requests
    if [ $? -ne 0 ]; then
        echo "[ERROR] 包安装失败"
        exit 1
    fi
fi

# 运行一键检查
echo "[INFO] 开始运行一键检查..."
python3 scripts/one_click_check.py

# 检查退出码
case $? in
    0)
        echo
        echo "[SUCCESS] ✅ 所有检查通过，系统运行正常！"
        ;;
    1)
        echo
        echo "[ERROR] ❌ 发现严重问题，需要修复！"
        ;;
    2)
        echo
        echo "[WARNING] ⚠️ 发现警告，建议检查！"
        ;;
esac

echo
echo "检查完成！详细报告已保存到当前目录"
