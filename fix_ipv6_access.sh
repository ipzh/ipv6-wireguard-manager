#!/bin/bash

# 修复IPv6访问问题脚本
# 修复IPv6无法访问前端的问题

set -e

echo "=========================================="
echo "🔧 修复IPv6访问问题脚本"
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

echo ""

# 1. 检查IPv6支持
echo "1. 检查IPv6支持..."
if lsmod | grep ipv6 > /dev/null; then
    echo "✅ IPv6模块已加载"
else
    echo "❌ IPv6模块未加载"
    echo "   加载IPv6模块..."
    modprobe ipv6
    echo "✅ IPv6模块已加载"
fi

echo ""

# 2. 检查IPv6地址
echo "2. 检查IPv6地址..."
ipv6_addr=$(ip -6 addr show | grep -E "inet6.*global" | head -1 | awk '{print $2}' | cut -d'/' -f1)
if [ -n "$ipv6_addr" ]; then
    echo "✅ 找到IPv6地址: $ipv6_addr"
else
    echo "❌ 未找到IPv6地址"
    echo "   请检查网络配置"
    exit 1
fi

echo ""

# 3. 修复Nginx配置
echo "3. 修复Nginx配置..."
nginx_config="/etc/nginx/sites-enabled/ipv6-wireguard-manager"

if [ -f "$nginx_config" ]; then
    echo "   Nginx配置文件存在"
    
    # 检查是否已配置IPv6监听
    if grep -q "listen \[::\]:80" "$nginx_config"; then
        echo "✅ Nginx已配置IPv6监听"
    else
        echo "❌ Nginx未配置IPv6监听"
        echo "   修复Nginx配置..."
        
        # 备份原配置
        cp "$nginx_config" "$nginx_config.backup"
        
        # 修复配置
        sed -i 's/listen 80;/listen 80;\n    listen [::]:80;/' "$nginx_config"
        
        echo "✅ Nginx配置已修复"
    fi
else
    echo "❌ Nginx配置文件不存在"
    echo "   创建Nginx配置..."
    
    # 创建Nginx配置
    cat > "$nginx_config" << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    
    echo "✅ Nginx配置已创建"
fi

echo ""

# 4. 检查Nginx配置语法
echo "4. 检查Nginx配置语法..."
if nginx -t; then
    echo "✅ Nginx配置语法正确"
else
    echo "❌ Nginx配置语法错误"
    echo "   恢复备份配置..."
    if [ -f "$nginx_config.backup" ]; then
        cp "$nginx_config.backup" "$nginx_config"
        echo "✅ 已恢复备份配置"
    fi
    exit 1
fi

echo ""

# 5. 配置防火墙
echo "5. 配置防火墙..."
if command -v ufw &> /dev/null; then
    echo "   配置UFW防火墙..."
    ufw allow 80/tcp
    ufw allow 8000/tcp
    echo "✅ UFW防火墙已配置"
elif command -v iptables &> /dev/null; then
    echo "   配置iptables防火墙..."
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
    echo "✅ iptables防火墙已配置"
else
    echo "⚠️  未检测到防火墙，跳过配置"
fi

echo ""

# 6. 重启服务
echo "6. 重启服务..."
echo "   重启Nginx..."
if systemctl restart nginx; then
    echo "✅ Nginx重启成功"
else
    echo "❌ Nginx重启失败"
    exit 1
fi

echo "   重启IPv6 WireGuard Manager..."
if systemctl restart ipv6-wireguard-manager; then
    echo "✅ IPv6 WireGuard Manager重启成功"
else
    echo "❌ IPv6 WireGuard Manager重启失败"
fi

echo ""

# 7. 等待服务启动
echo "7. 等待服务启动..."
sleep 3

# 8. 测试连接
echo "8. 测试连接..."
echo "   测试IPv4连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80; then
    echo "     ✅ IPv4前端连接正常"
else
    echo "     ❌ IPv4前端连接失败"
fi

echo "   测试IPv6连接:"
if curl -s -o /dev/null -w "%{http_code}" http://[::1]:80; then
    echo "     ✅ IPv6前端连接正常"
else
    echo "     ❌ IPv6前端连接失败"
fi

echo "   测试外部IPv6连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_addr]:80" --connect-timeout 5; then
    echo "     ✅ 外部IPv6前端连接正常"
else
    echo "     ❌ 外部IPv6前端连接失败"
fi

echo ""

# 9. 显示访问地址
echo "9. 显示访问地址..."
echo "  📱 本地访问:"
echo "    前端界面: http://localhost:80"
echo "    API文档: http://localhost:80/api/v1/docs"
echo "    健康检查: http://localhost:8000/health"

echo "  🌐 IPv4访问:"
ipv4_addr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
if [ -n "$ipv4_addr" ]; then
    echo "    前端界面: http://$ipv4_addr:80"
    echo "    API文档: http://$ipv4_addr:80/api/v1/docs"
    echo "    健康检查: http://$ipv4_addr:8000/health"
fi

echo "  🔗 IPv6访问:"
echo "    前端界面: http://[$ipv6_addr]:80"
echo "    API文档: http://[$ipv6_addr]:80/api/v1/docs"
echo "    健康检查: http://[$ipv6_addr]:8000/health"

echo ""

echo "=========================================="
echo "🎉 IPv6访问修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "✅ 检查IPv6支持"
echo "✅ 修复Nginx配置"
echo "✅ 配置防火墙"
echo "✅ 重启服务"
echo "✅ 测试连接"
echo "✅ 显示访问地址"
echo ""
echo "现在可以通过IPv6地址访问前端了！"
echo "如果仍有问题，请检查网络路由和ISP配置。"
