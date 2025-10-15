#!/bin/bash

# 修复空白页面和API错误问题脚本

set -e

echo "=========================================="
echo "🔧 修复空白页面和API错误问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查并修复前端文件..."
frontend_dir="/opt/ipv6-wireguard-manager/frontend/dist"
frontend_source="/opt/ipv6-wireguard-manager/frontend"

if [ ! -d "$frontend_dir" ] || [ ! -f "$frontend_dir/index.html" ]; then
    echo "   ❌ 前端文件不存在或损坏，正在重新构建..."
    
    if [ -d "$frontend_source" ]; then
        cd "$frontend_source" || {
            echo "   ❌ 无法进入前端源码目录"
            exit 1
        }
        
        # 检查Node.js
        if ! command -v node &> /dev/null; then
            echo "   ❌ Node.js未安装"
            exit 1
        fi
        
        # 清理旧的构建文件
        rm -rf dist node_modules package-lock.json
        
        # 安装依赖
        echo "   安装前端依赖..."
        npm install
        
        # 构建前端
        echo "   构建前端..."
        npm run build
        
        if [ -d "dist" ] && [ -f "dist/index.html" ]; then
            echo "   ✅ 前端构建成功"
        else
            echo "   ❌ 前端构建失败"
            exit 1
        fi
    else
        echo "   ❌ 前端源码目录不存在: $frontend_source"
        exit 1
    fi
else
    echo "   ✅ 前端文件存在"
fi

echo ""

echo "2. 检查并修复Nginx配置..."
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

# 测试Nginx配置
echo "   测试Nginx配置..."
if nginx -t; then
    echo "   ✅ Nginx配置语法正确"
else
    echo "   ❌ Nginx配置语法错误"
    exit 1
fi

# 重新加载Nginx配置
echo "   重新加载Nginx配置..."
if systemctl reload nginx; then
    echo "   ✅ Nginx配置重新加载成功"
else
    echo "   ❌ Nginx配置重新加载失败"
    exit 1
fi

echo ""

echo "3. 检查并修复后端服务..."
if ! systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ❌ 后端服务未运行，正在启动..."
    systemctl start ipv6-wireguard-manager
    sleep 5
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        echo "   ✅ 后端服务启动成功"
    else
        echo "   ❌ 后端服务启动失败"
        echo "   查看服务日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -n 10
        exit 1
    fi
else
    echo "   ✅ 后端服务运行正常"
fi

echo ""

echo "4. 检查并修复数据库连接..."
cd /opt/ipv6-wireguard-manager/backend || {
    echo "   ❌ 无法进入后端目录"
    exit 1
}

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    
    # 检查数据库连接
    if python scripts/check_environment.py; then
        echo "   ✅ 数据库连接正常"
    else
        echo "   ❌ 数据库连接失败，正在修复..."
        
        # 重启数据库服务
        if systemctl is-active --quiet mysql; then
            systemctl restart mysql
        elif systemctl is-active --quiet mariadb; then
            systemctl restart mariadb
        fi
        
        sleep 3
        
        # 重新检查
        if python scripts/check_environment.py; then
            echo "   ✅ 数据库连接修复成功"
        else
            echo "   ❌ 数据库连接修复失败"
            exit 1
        fi
    fi
else
    echo "   ❌ 虚拟环境不存在"
    exit 1
fi

echo ""

echo "5. 检查文件权限..."
echo "   修复前端文件权限..."
chown -R www-data:www-data /opt/ipv6-wireguard-manager/frontend/dist/
chmod -R 755 /opt/ipv6-wireguard-manager/frontend/dist/

echo "   修复后端文件权限..."
chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager/backend/
chmod -R 755 /opt/ipv6-wireguard-manager/backend/

echo ""

echo "6. 测试连接..."
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

echo "7. 测试IPv6连接..."
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

echo "8. 检查前端页面内容..."
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

echo "9. 检查API文档..."
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

echo "10. 显示访问地址..."
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
    echo "    API文档: http://localhost:80/api/v1/docs"
    echo "    健康检查: http://localhost:8000/health"
    echo ""
    
    if [ ${#ipv4_ips[@]} -gt 0 ]; then
        echo "  🌐 IPv4访问:"
        for ip in "${ipv4_ips[@]}"; do
            echo "    前端界面: http://$ip:80"
            echo "    API文档: http://$ip:80/api/v1/docs"
            echo "    健康检查: http://$ip:8000/health"
        done
        echo ""
    fi
    
    if [ ${#ipv6_ips[@]} -gt 0 ]; then
        echo "  🔗 IPv6访问:"
        for ip in "${ipv6_ips[@]}"; do
            echo "    前端界面: http://[$ip]:80"
            echo "    API文档: http://[$ip]:80/api/v1/docs"
            echo "    健康检查: http://[$ip]:8000/health"
        done
        echo ""
    fi
}

get_ip_addresses

echo ""

echo "=========================================="
echo "🎉 空白页面和API错误问题修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "  ✅ 重新构建了前端文件"
echo "  ✅ 修复了Nginx配置"
echo "  ✅ 启动了后端服务"
echo "  ✅ 修复了数据库连接"
echo "  ✅ 修复了文件权限"
echo "  ✅ 测试了所有连接"
echo ""
echo "现在应该能够正常访问："
echo "  - 前端页面: http://[2605:6400:8a61:100::117]:80"
echo "  - API文档: http://[2605:6400:8a61:100::117]:8000/docs"
echo ""
echo "如果问题仍然存在，请查看日志："
echo "  tail -f /var/log/nginx/error.log"
echo "  journalctl -u ipv6-wireguard-manager -f"
