#!/bin/bash

# 测试IPv6 WireGuard Manager启动方式

echo "=== IPv6 WireGuard Manager 启动方式测试 ==="
echo

# 测试1: 直接运行脚本
echo "1. 测试直接运行脚本:"
if [[ -f "./ipv6-wireguard-manager.sh" ]]; then
    echo "   ✓ 脚本文件存在"
    echo "   命令: sudo ./ipv6-wireguard-manager.sh"
    echo "   命令: sudo ./ipv6-wireguard-manager.sh --version"
    echo "   命令: sudo ./ipv6-wireguard-manager.sh --help"
else
    echo "   ✗ 脚本文件不存在"
fi
echo

# 测试2: 全局命令
echo "2. 测试全局命令:"
if command -v ipv6-wireguard-manager &> /dev/null; then
    echo "   ✓ 全局命令已安装"
    echo "   命令: sudo ipv6-wireguard-manager"
    echo "   命令: sudo ipv6-wireguard-manager --version"
    echo "   命令: sudo ipv6-wireguard-manager --help"
else
    echo "   ✗ 全局命令未安装"
    echo "   需要先运行安装脚本: sudo ./install.sh"
fi
echo

# 测试3: 安装目录中的脚本
echo "3. 测试安装目录中的脚本:"
if [[ -f "/opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh" ]]; then
    echo "   ✓ 安装目录脚本存在"
    echo "   命令: sudo /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh"
else
    echo "   ✗ 安装目录脚本不存在"
    echo "   需要先运行安装脚本: sudo ./install.sh"
fi
echo

# 测试4: 系统服务
echo "4. 测试系统服务:"
if systemctl is-enabled ipv6-wireguard-manager &> /dev/null; then
    echo "   ✓ 系统服务已安装"
    echo "   启动: sudo systemctl start ipv6-wireguard-manager"
    echo "   状态: sudo systemctl status ipv6-wireguard-manager"
    echo "   停止: sudo systemctl stop ipv6-wireguard-manager"
else
    echo "   ✗ 系统服务未安装"
    echo "   需要先运行安装脚本: sudo ./install.sh"
fi
echo

echo "=== 推荐启动方式 ==="
echo "1. 安装后使用全局命令: sudo ipv6-wireguard-manager"
echo "2. 或者直接运行脚本: sudo ./ipv6-wireguard-manager.sh"
echo "3. 或者使用安装目录: sudo /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh"
echo
