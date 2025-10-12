#!/bin/bash

echo "🌐 配置IPv6网络访问..."
echo "================================"

# 获取IPv6地址
echo "🔍 检测IPv6地址..."
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -z "$IPV6_ADDRESS" ]; then
    echo "❌ 未检测到IPv6地址"
    echo "📋 请检查IPv6配置:"
    echo "   ip -6 addr show"
    exit 1
fi

echo "✅ 检测到IPv6地址: $IPV6_ADDRESS"

# 检查服务状态
echo "🔍 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务未运行"
    sudo systemctl start ipv6-wireguard-manager
fi

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx服务运行正常"
else
    echo "❌ Nginx服务未运行"
    sudo systemctl start nginx
fi

# 更新Nginx配置支持IPv6
echo "🔧 更新Nginx配置..."
sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;  # IPv6监听
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

# 启用站点
echo "🔧 启用Nginx站点..."
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 测试Nginx配置
echo "🔍 测试Nginx配置..."
if sudo nginx -t; then
    echo "✅ Nginx配置正确"
else
    echo "❌ Nginx配置错误"
    exit 1
fi

# 重启Nginx
echo "🔄 重启Nginx..."
sudo systemctl restart nginx

# 检查端口监听
echo "🔍 检查端口监听..."
echo "   IPv4端口80:"
ss -tlnp | grep :80 | grep -v "::"
echo "   IPv6端口80:"
ss -tlnp | grep :80 | grep "::"

# 测试访问
echo "🔍 测试访问..."
echo "   测试IPv6 API访问:"
if curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status >/dev/null; then
    echo "✅ IPv6 API访问正常"
    curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status
else
    echo "❌ IPv6 API访问失败"
fi

echo ""
echo "   测试IPv6前端访问:"
if curl -6 -s http://[$IPV6_ADDRESS]/ >/dev/null; then
    echo "✅ IPv6前端访问正常"
else
    echo "❌ IPv6前端访问失败"
fi

echo ""
echo "🎯 IPv6访问配置完成！"
echo ""
echo "🌐 访问地址:"
echo "   IPv6前端: http://[$IPV6_ADDRESS]"
echo "   IPv6 API:  http://[$IPV6_ADDRESS]/api/v1/status"
echo "   IPv6健康检查: http://[$IPV6_ADDRESS]/health"
echo ""
echo "📋 访问说明:"
echo "   1. 确保您的网络支持IPv6"
echo "   2. 使用IPv6地址访问: http://[$IPV6_ADDRESS]"
echo "   3. 如果无法访问，请检查防火墙设置"
echo ""
echo "🔧 防火墙配置 (如果需要):"
echo "   sudo ufw allow 80/tcp"
echo "   sudo ufw allow 8000/tcp"
echo ""
echo "📊 服务状态:"
echo "   后端服务: $(systemctl is-active ipv6-wireguard-manager)"
echo "   Nginx服务: $(systemctl is-active nginx)"
echo "   IPv6地址: $IPV6_ADDRESS"
