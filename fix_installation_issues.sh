#!/bin/bash

# 修复安装问题脚本
# 解决前端构建和IP地址显示问题

set -e

echo "=========================================="
echo "🔧 修复安装问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 检查安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 安装目录不存在: $INSTALL_DIR"
    exit 1
fi

echo "📁 安装目录: $INSTALL_DIR"
cd "$INSTALL_DIR" || {
    echo "❌ 无法进入安装目录"
    exit 1
}

echo ""

# 检查前端是否存在
echo "1. 检查前端目录..."
if [ ! -d "frontend" ]; then
    echo "❌ 前端目录不存在"
    echo "   重新下载项目..."
    if git clone https://github.com/ipzh/ipv6-wireguard-manager.git /tmp/ipv6-wireguard-temp; then
        cp -r /tmp/ipv6-wireguard-temp/frontend .
        rm -rf /tmp/ipv6-wireguard-temp
        echo "✅ 前端目录已恢复"
    else
        echo "❌ 无法下载前端代码"
        exit 1
    fi
else
    echo "✅ 前端目录存在"
fi

echo ""

# 检查前端是否已构建
echo "2. 检查前端构建..."
if [ ! -d "frontend/dist" ]; then
    echo "❌ 前端未构建"
    echo "   开始构建前端..."
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        echo "   安装Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # 进入前端目录
    cd frontend || {
        echo "❌ 无法进入前端目录"
        exit 1
    }
    
    # 安装依赖
    echo "   安装前端依赖..."
    if npm install; then
        echo "✅ 前端依赖安装成功"
    else
        echo "❌ 前端依赖安装失败"
        exit 1
    fi
    
    # 构建前端
    echo "   构建前端项目..."
    if npm run build; then
        echo "✅ 前端构建成功"
    else
        echo "❌ 前端构建失败"
        exit 1
    fi
    
    # 返回根目录
    cd ..
else
    echo "✅ 前端已构建"
fi

echo ""

# 检查后端是否存在
echo "3. 检查后端目录..."
if [ ! -d "backend" ]; then
    echo "❌ 后端目录不存在"
    echo "   重新下载项目..."
    if git clone https://github.com/ipzh/ipv6-wireguard-manager.git /tmp/ipv6-wireguard-temp; then
        cp -r /tmp/ipv6-wireguard-temp/backend .
        rm -rf /tmp/ipv6-wireguard-temp
        echo "✅ 后端目录已恢复"
    else
        echo "❌ 无法下载后端代码"
        exit 1
    fi
else
    echo "✅ 后端目录存在"
fi

echo ""

# 检查服务状态
echo "4. 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 服务正在运行"
    echo "   重启服务以应用修复..."
    if systemctl restart ipv6-wireguard-manager; then
        echo "✅ 服务重启成功"
    else
        echo "❌ 服务重启失败"
    fi
else
    echo "⚠️  服务未运行"
    echo "   启动服务..."
    if systemctl start ipv6-wireguard-manager; then
        echo "✅ 服务启动成功"
    else
        echo "❌ 服务启动失败"
    fi
fi

echo ""

# 显示访问地址
echo "5. 显示访问地址..."
get_local_ips() {
    local ipv4_ips=()
    local ipv6_ips=()
    
    # 获取IPv4地址
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
            ipv4_ips+=("$line")
        fi
    done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null || ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' || hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '127.0.0.1')
    
    # 获取IPv6地址
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
            ipv6_ips+=("$line")
        fi
    done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:' || ifconfig 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' | grep -v '::1' | grep -v '^fe80:')
    
    # 显示访问地址
    echo "  📱 本地访问:"
    echo "    前端界面: http://localhost:80"
    echo "    API文档: http://localhost:80/api/v1/docs"
    echo "    健康检查: http://localhost:8000/health"
    
    if [ ${#ipv4_ips[@]} -gt 0 ]; then
        echo "  🌐 IPv4访问:"
        for ip in "${ipv4_ips[@]}"; do
            echo "    前端界面: http://$ip:80"
            echo "    API文档: http://$ip:80/api/v1/docs"
            echo "    健康检查: http://$ip:8000/health"
        done
    fi
    
    if [ ${#ipv6_ips[@]} -gt 0 ]; then
        echo "  🔗 IPv6访问:"
        for ip in "${ipv6_ips[@]}"; do
            echo "    前端界面: http://[$ip]:80"
            echo "    API文档: http://[$ip]:80/api/v1/docs"
            echo "    健康检查: http://[$ip]:8000/health"
        done
    fi
}

get_local_ips

echo ""

# 测试连接
echo "6. 测试连接..."
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ 后端API连接正常"
else
    echo "❌ 后端API连接失败"
fi

if curl -s http://localhost:80 > /dev/null; then
    echo "✅ 前端界面连接正常"
else
    echo "❌ 前端界面连接失败"
fi

echo ""

echo "=========================================="
echo "🎉 修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "✅ 检查并恢复前端目录"
echo "✅ 构建前端项目"
echo "✅ 检查并恢复后端目录"
echo "✅ 重启服务"
echo "✅ 显示所有访问地址"
echo "✅ 测试连接"
echo ""
echo "现在可以通过上述地址访问IPv6 WireGuard Manager了！"
