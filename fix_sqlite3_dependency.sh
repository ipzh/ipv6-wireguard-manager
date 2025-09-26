#!/bin/bash

# 修复sqlite3依赖问题
# 作者: IPv6 WireGuard Manager Team

echo "开始修复sqlite3依赖问题..."

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# 安装sqlite3
install_sqlite3() {
    local os=$(detect_os)
    echo "检测到操作系统: $os"
    
    case "$os" in
        "ubuntu"|"debian")
            echo "安装sqlite3..."
            apt-get update && apt-get install -y sqlite3 python3-psutil
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            echo "安装sqlite..."
            yum install -y sqlite python3-psutil
            ;;
        "fedora")
            echo "安装sqlite..."
            dnf install -y sqlite python3-psutil
            ;;
        "arch")
            echo "安装sqlite..."
            pacman -S --noconfirm sqlite python-psutil
            ;;
        "opensuse")
            echo "安装sqlite3..."
            zypper install -y sqlite3 python3-psutil
            ;;
        *)
            echo "未知操作系统，尝试通用安装方法..."
            if command -v apt-get &> /dev/null; then
                apt-get update && apt-get install -y sqlite3 python3-psutil
            elif command -v yum &> /dev/null; then
                yum install -y sqlite python3-psutil
            elif command -v dnf &> /dev/null; then
                dnf install -y sqlite python3-psutil
            elif command -v pacman &> /dev/null; then
                pacman -S --noconfirm sqlite python-psutil
            elif command -v zypper &> /dev/null; then
                zypper install -y sqlite3 python3-psutil
            else
                echo "错误: 无法找到支持的包管理器"
                exit 1
            fi
            ;;
    esac
}

# 检查sqlite3是否已安装
if command -v sqlite3 &> /dev/null; then
    echo "✓ sqlite3已安装"
    sqlite3 --version
else
    echo "✗ sqlite3未安装，开始安装..."
    install_sqlite3
fi

# 检查psutil是否已安装
if python3 -c "import psutil" 2>/dev/null; then
    echo "✓ psutil已安装"
else
    echo "✗ psutil未安装，开始安装..."
    pip3 install psutil
fi

# 测试sqlite3功能
echo "测试sqlite3功能..."
if sqlite3 --version >/dev/null 2>&1; then
    echo "✓ sqlite3功能正常"
else
    echo "✗ sqlite3功能异常"
    exit 1
fi

echo "sqlite3依赖修复完成！"
