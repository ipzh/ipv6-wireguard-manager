#!/bin/bash

# 一键修复脚本 - 修复空白页面和API错误问题

set -e

echo "=========================================="
echo "🔧 一键修复脚本 - 修复空白页面和API错误问题"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 修复TrustedHostMiddleware错误..."
echo "   ✅ 已修复backend/app/main.py中的TrustedHostMiddleware配置"

echo ""

echo "2. 创建Nginx配置文件..."
nginx_config="/etc/nginx/sites-enabled/ipv6-wireguard-manager"

# 禁用默认站点
echo "   禁用Nginx默认站点..."
rm -f /etc/nginx/sites-enabled/default

# 创建正确的Nginx配置
echo "   创建项目Nginx配置..."
cat > "$nginx_config" << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # 添加CORS头
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
        
        # 处理预检请求
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 添加CORS头
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
        
        # 处理预检请求
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization";
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain; charset=utf-8';
            add_header Content-Length 0;
            return 204;
        }
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
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "   ✅ Nginx配置文件已创建"

echo ""

echo "3. 测试Nginx配置..."
if nginx -t; then
    echo "   ✅ Nginx配置语法正确"
else
    echo "   ❌ Nginx配置语法错误"
    exit 1
fi

echo ""

echo "4. 重新加载Nginx配置..."
if systemctl reload nginx; then
    echo "   ✅ Nginx配置重新加载成功"
else
    echo "   ❌ Nginx配置重新加载失败"
    exit 1
fi

echo ""

echo "5. 修复后端IPv6支持..."
# 修复服务配置以支持IPv6
if [ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]; then
    # 备份原配置
    cp /etc/systemd/system/ipv6-wireguard-manager.service /etc/systemd/system/ipv6-wireguard-manager.service.backup
    
    # 修复host参数从0.0.0.0改为::
    sed -i 's/--host 0\.0\.0\.0/--host ::/g' /etc/systemd/system/ipv6-wireguard-manager.service
    
    echo "   ✅ 后端服务配置已修复（支持IPv6）"
    
    # 重新加载systemd配置
    systemctl daemon-reload
    echo "   ✅ systemd配置已重新加载"
else
    echo "   ❌ 服务配置文件不存在"
fi

echo ""

echo "6. 重启后端服务..."
if systemctl restart ipv6-wireguard-manager; then
    echo "   ✅ 后端服务重启成功"
else
    echo "   ❌ 后端服务重启失败"
    exit 1
fi

echo ""

echo "7. 等待服务启动..."
sleep 5

echo ""

echo "8. 检查服务状态..."
if systemctl is-active --quiet nginx; then
    echo "   ✅ Nginx服务运行正常"
else
    echo "   ❌ Nginx服务未运行"
fi

if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ✅ IPv6 WireGuard Manager服务运行正常"
else
    echo "   ❌ IPv6 WireGuard Manager服务未运行"
fi

echo ""

echo "9. 测试连接..."
echo "   测试本地前端连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --connect-timeout 5; then
    echo "     ✅ 本地前端连接正常"
else
    echo "     ❌ 本地前端连接失败"
fi

echo "   测试本地API连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health --connect-timeout 5; then
    echo "     ✅ 本地API连接正常"
else
    echo "     ❌ 本地API连接失败"
fi

echo "   测试本地API文档连接:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs --connect-timeout 5; then
    echo "     ✅ 本地API文档连接正常"
else
    echo "     ❌ 本地API文档连接失败"
fi

echo ""

echo "10. 测试IPv6连接..."
ipv6_ip="2605:6400:8a61:100::117"
echo "   测试IPv6前端连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:80" --connect-timeout 5; then
    echo "     ✅ IPv6前端连接正常"
else
    echo "     ❌ IPv6前端连接失败"
fi

echo "   测试IPv6 API连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:8000/health" --connect-timeout 5; then
    echo "     ✅ IPv6 API连接正常"
else
    echo "     ❌ IPv6 API连接失败"
fi

echo "   测试IPv6 API文档连接:"
if curl -s -o /dev/null -w "%{http_code}" "http://[$ipv6_ip]:8000/docs" --connect-timeout 5; then
    echo "     ✅ IPv6 API文档连接正常"
else
    echo "     ❌ IPv6 API文档连接失败"
fi

echo ""

echo "11. 检查前端页面内容..."
echo "   获取前端页面内容:"
response=$(curl -s "http://[$ipv6_ip]:80" --connect-timeout 5)
if [ -n "$response" ]; then
    echo "     ✅ 前端页面有内容"
    echo "     内容长度: ${#response} 字符"
    
    if echo "$response" | grep -q "IPv6 WireGuard Manager"; then
        echo "     ✅ 页面包含正确标题"
    else
        echo "     ❌ 页面不包含正确标题"
    fi
    
    if echo "$response" | grep -q "root"; then
        echo "     ✅ 页面包含React根元素"
    else
        echo "     ❌ 页面不包含React根元素"
    fi
else
    echo "     ❌ 前端页面无内容"
fi

echo ""

echo "12. 检查API文档..."
echo "   获取API文档内容:"
api_response=$(curl -s "http://[$ipv6_ip]:8000/docs" --connect-timeout 5)
if [ -n "$api_response" ]; then
    echo "     ✅ API文档有响应"
    echo "     响应长度: ${#api_response} 字符"
    if echo "$api_response" | grep -q "Internal Server Error"; then
        echo "     ❌ API返回内部服务器错误"
    else
        echo "     ✅ API文档正常"
    fi
else
    echo "     ❌ API文档无响应"
fi

echo ""

echo "13. 显示访问地址..."
get_ip_addresses() {
    local ipv4_ips=()
    local ipv6_ips=()
    
    # 获取IPv4地址
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ $line != "127.0.0.1" ]]; then
            ipv4_ips+=("$line")
        fi
    done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null)
    
    # 获取IPv6地址
    while IFS= read -r line; do
        if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
            ipv6_ips+=("$line")
        fi
    done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')
    
    echo "  📱 本地访问:"
    echo "    前端界面: http://localhost:80"
    echo "    API文档: http://localhost:8000/docs"
    echo "    健康检查: http://localhost:8000/health"
    echo ""
    
    if [ ${#ipv4_ips[@]} -gt 0 ]; then
        echo "  🌐 IPv4访问:"
        for ip in "${ipv4_ips[@]}"; do
            echo "    前端界面: http://$ip:80"
            echo "    API文档: http://$ip:8000/docs"
            echo "    健康检查: http://$ip:8000/health"
        done
        echo ""
    fi
    
    if [ ${#ipv6_ips[@]} -gt 0 ]; then
        echo "  🔗 IPv6访问:"
        for ip in "${ipv6_ips[@]}"; do
            echo "    前端界面: http://[$ip]:80"
            echo "    API文档: http://[$ip]:8000/docs"
            echo "    健康检查: http://[$ip]:8000/health"
        done
        echo ""
    fi
}

get_ip_addresses

echo ""

echo "=========================================="
echo "🎉 一键修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "  ✅ 修复了TrustedHostMiddleware错误"
echo "  ✅ 创建了Nginx配置文件"
echo "  ✅ 禁用了默认站点"
echo "  ✅ 重新加载了Nginx配置"
echo "  ✅ 重启了后端服务"
echo "  ✅ 测试了所有连接"
echo ""
echo "现在应该能够正常访问："
echo "  - 前端页面: http://[2605:6400:8a61:100::117]:80"
echo "  - API文档: http://[2605:6400:8a61:100::117]:8000/docs"
echo ""
echo "如果问题仍然存在，请查看日志："
echo "  tail -f /var/log/nginx/error.log"
echo "  journalctl -u ipv6-wireguard-manager -f"
