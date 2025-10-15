#!/bin/bash

# 快速修复Nginx前端配置问题

set -e

echo "🔧 快速修复Nginx前端配置问题..."

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 需要root权限"
    exit 1
fi

echo "1. 禁用默认站点..."
rm -f /etc/nginx/sites-enabled/default
echo "✅ 默认站点已禁用"

echo "2. 创建项目配置..."
cat > /etc/nginx/sites-enabled/ipv6-wireguard-manager << 'EOF'
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
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
echo "✅ 项目配置已创建"

echo "3. 测试配置..."
if nginx -t; then
    echo "✅ Nginx配置语法正确"
else
    echo "❌ Nginx配置语法错误"
    exit 1
fi

echo "4. 重新加载配置..."
systemctl reload nginx
echo "✅ Nginx配置已重新加载"

echo "5. 测试前端访问..."
if curl -s http://localhost:80 | grep -q "IPv6 WireGuard Manager"; then
    echo "✅ 前端页面正确显示"
else
    echo "❌ 前端页面显示不正确"
fi

echo "🎉 Nginx前端配置修复完成！"
echo "现在访问 http://localhost:80 应该显示正确的IPv6 WireGuard Manager页面"
