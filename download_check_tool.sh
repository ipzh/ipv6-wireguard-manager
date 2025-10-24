#!/bin/bash

# IPv6 WireGuard Manager 一键检查工具 - 远程下载版本 (Linux/macOS)
# 自动下载并运行一键检查工具

echo "🔍 IPv6 WireGuard Manager 一键检查工具 - 远程下载版本"
echo "====================================================="
echo

# 设置下载URL
DOWNLOAD_URL="https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/one_click_check.sh"
LOCAL_FILE="one_click_check.sh"

echo "[INFO] 正在下载一键检查工具..."
echo "[INFO] 下载地址: $DOWNLOAD_URL"
echo

# 检查是否有wget
if command -v wget &> /dev/null; then
    echo "[INFO] 使用wget下载..."
    wget -O "$LOCAL_FILE" "$DOWNLOAD_URL"
elif command -v curl &> /dev/null; then
    echo "[INFO] 使用curl下载..."
    curl -o "$LOCAL_FILE" "$DOWNLOAD_URL"
else
    echo "[ERROR] 未找到wget或curl，无法下载"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "[SUCCESS] 下载完成"
else
    echo "[ERROR] 下载失败"
    exit 1
fi

echo
echo "[INFO] 检查下载的文件..."
if [ -f "$LOCAL_FILE" ]; then
    echo "[SUCCESS] ✓ 文件下载成功: $LOCAL_FILE"
    
    # 添加执行权限
    chmod +x "$LOCAL_FILE"
    echo "[SUCCESS] ✓ 已添加执行权限"
    
    echo
    echo "[INFO] 是否立即运行检查工具? (y/n)"
    read -p "请输入选择: " choice
    
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo
        echo "[INFO] 正在运行一键检查工具..."
        ./"$LOCAL_FILE"
    else
        echo
        echo "[INFO] 文件已下载到当前目录: $LOCAL_FILE"
        echo "[INFO] 您可以稍后手动运行: ./$LOCAL_FILE"
    fi
else
    echo "[ERROR] ✗ 文件下载失败"
    exit 1
fi

echo
echo "[INFO] 下载完成！"
