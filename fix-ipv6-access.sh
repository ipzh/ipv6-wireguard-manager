#!/bin/bash

echo "🔧 修复IPv6访问问题..."

# 检查IPv6配置
echo "📊 检查IPv6配置..."

# 1. 检查IPv6地址
echo "1. 检查IPv6地址:"
ip -6 addr show | grep inet6

# 2. 检查Nginx IPv6配置
echo "2. 检查Nginx IPv6配置:"
if grep -q "listen \[::\]:80" /etc/nginx/sites-available/ipv6-wireguard-manager; then
    echo "✅ Nginx已配置IPv6监听"
else
    echo "❌ Nginx未配置IPv6监听"
fi

# 3. 检查防火墙IPv6规则
echo "3. 检查防火墙IPv6规则:"
ufw status | grep -E "(80|443).*v6"

# 4. 检查IPv6路由
echo "4. 检查IPv6路由:"
ip -6 route show

# 修复IPv6访问问题
echo "🔧 修复IPv6访问问题..."

# 1. 修复Nginx配置
echo "1. 修复Nginx IPv6配置..."
cat > /etc/nginx/sites-available/ipv6-wireguard-manager << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # 添加IPv6支持头
        add_header X-IPv6-Support "enabled";
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # IPv6支持
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # WebSocket代理
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

# 2. 测试Nginx配置
echo "2. 测试Nginx配置..."
nginx -t

# 3. 重启Nginx
echo "3. 重启Nginx..."
systemctl restart nginx

# 4. 配置防火墙IPv6规则
echo "4. 配置防火墙IPv6规则..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force reload

# 5. 检查IPv6监听
echo "5. 检查IPv6监听..."
netstat -tlnp | grep -E ':(80|443)'

# 6. 测试IPv6连接
echo "6. 测试IPv6连接..."
# 获取IPv6地址
IPV6_ADDR=$(ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -n "$IPV6_ADDR" ]; then
    echo "检测到IPv6地址: $IPV6_ADDR"
    echo "测试IPv6连接..."
    
    # 测试本地IPv6连接
    if curl -6 -s --connect-timeout 5 http://[::1] > /dev/null; then
        echo "✅ 本地IPv6连接正常"
    else
        echo "❌ 本地IPv6连接失败"
    fi
    
    # 测试外部IPv6连接
    if curl -6 -s --connect-timeout 5 http://[$IPV6_ADDR] > /dev/null; then
        echo "✅ 外部IPv6连接正常"
    else
        echo "❌ 外部IPv6连接失败"
    fi
    
    echo ""
    echo "IPv6访问地址:"
    echo "  http://[$IPV6_ADDR]"
    echo "  http://[$IPV6_ADDR]/docs"
else
    echo "❌ 未检测到IPv6地址"
    echo "请检查IPv6配置"
fi

# 7. 检查系统IPv6支持
echo "7. 检查系统IPv6支持..."
if [ -f /proc/net/if_inet6 ]; then
    echo "✅ 系统支持IPv6"
else
    echo "❌ 系统不支持IPv6"
fi

# 8. 检查IPv6转发
echo "8. 检查IPv6转发..."
if [ "$(cat /proc/sys/net/ipv6/conf/all/forwarding)" = "1" ]; then
    echo "✅ IPv6转发已启用"
else
    echo "⚠️ IPv6转发未启用"
    echo "启用IPv6转发..."
    echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p
fi

echo "✅ IPv6访问修复完成"
echo ""
echo "如果IPv6访问仍有问题，请检查："
echo "1. 服务器是否分配了IPv6地址"
echo "2. 网络提供商是否支持IPv6"
echo "3. 防火墙是否允许IPv6流量"
echo "4. DNS是否支持IPv6解析"
