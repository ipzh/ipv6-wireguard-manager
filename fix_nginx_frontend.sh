#!/bin/bash

# 修复Nginx前端配置问题脚本
# 解决前端访问返回Nginx默认页面的问题

set -e

echo "=========================================="
echo "🔧 修复Nginx前端配置问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查当前Nginx配置..."
echo "   检查默认站点配置:"
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    echo "     ✅ 默认站点配置存在"
    echo "     配置内容:"
    cat /etc/nginx/sites-enabled/default | sed 's/^/       /'
else
    echo "     ❌ 默认站点配置不存在"
fi

echo ""
echo "   检查我们的项目配置:"
project_config="/etc/nginx/sites-enabled/ipv6-wireguard-manager"
if [ -f "$project_config" ]; then
    echo "     ✅ 项目配置文件存在"
    echo "     配置内容:"
    cat "$project_config" | sed 's/^/       /'
else
    echo "     ❌ 项目配置文件不存在"
fi

echo ""

echo "2. 检查前端文件..."
frontend_dir="/opt/ipv6-wireguard-manager/frontend/dist"
if [ -d "$frontend_dir" ]; then
    echo "   ✅ 前端目录存在: $frontend_dir"
    echo "   目录内容:"
    ls -la "$frontend_dir" | sed 's/^/     /'
    
    if [ -f "$frontend_dir/index.html" ]; then
        echo "   ✅ index.html文件存在"
        echo "   文件大小: $(du -h "$frontend_dir/index.html" | cut -f1)"
        echo "   文件内容预览:"
        head -10 "$frontend_dir/index.html" | sed 's/^/     /'
    else
        echo "   ❌ index.html文件不存在"
    fi
else
    echo "   ❌ 前端目录不存在: $frontend_dir"
    echo "   正在构建前端..."
    
    frontend_source="/opt/ipv6-wireguard-manager/frontend"
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
        
        # 安装依赖
        if [ -f "package.json" ]; then
            echo "   安装前端依赖..."
            npm install
        fi
        
        # 构建前端
        echo "   构建前端..."
        npm run build
        
        if [ -d "dist" ]; then
            echo "   ✅ 前端构建成功"
        else
            echo "   ❌ 前端构建失败"
            exit 1
        fi
    else
        echo "   ❌ 前端源码目录不存在: $frontend_source"
        exit 1
    fi
fi

echo ""

echo "3. 禁用默认站点..."
echo "   禁用Nginx默认站点:"
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm -f /etc/nginx/sites-enabled/default
    echo "     ✅ 默认站点已禁用"
else
    echo "     ⚠️  默认站点配置不存在"
fi

echo ""

echo "4. 创建正确的项目配置..."
echo "   创建项目Nginx配置:"
cat > "$project_config" << 'EOF'
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

echo "     ✅ 项目配置文件已创建"

echo ""

echo "5. 测试Nginx配置..."
echo "   测试Nginx配置语法:"
if nginx -t; then
    echo "     ✅ Nginx配置语法正确"
else
    echo "     ❌ Nginx配置语法错误"
    exit 1
fi

echo ""

echo "6. 重新加载Nginx配置..."
echo "   重新加载Nginx配置:"
if systemctl reload nginx; then
    echo "     ✅ Nginx配置重新加载成功"
else
    echo "     ❌ Nginx配置重新加载失败"
    exit 1
fi

echo ""

echo "7. 检查Nginx服务状态..."
echo "   Nginx服务状态:"
if systemctl is-active --quiet nginx; then
    echo "     ✅ Nginx服务运行正常"
else
    echo "     ❌ Nginx服务未运行"
    echo "     启动Nginx服务..."
    systemctl start nginx
    if systemctl is-active --quiet nginx; then
        echo "     ✅ Nginx服务启动成功"
    else
        echo "     ❌ Nginx服务启动失败"
        exit 1
    fi
fi

echo ""

echo "8. 测试前端访问..."
echo "   测试本地前端访问:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 --connect-timeout 5; then
    echo "     ✅ 本地前端访问正常"
else
    echo "     ❌ 本地前端访问失败"
fi

echo "   测试前端页面内容:"
response=$(curl -s http://localhost:80 --connect-timeout 5)
if echo "$response" | grep -q "IPv6 WireGuard Manager"; then
    echo "     ✅ 前端页面内容正确"
else
    echo "     ❌ 前端页面内容不正确"
    echo "     响应内容预览:"
    echo "$response" | head -5 | sed 's/^/       /'
fi

echo ""

echo "9. 检查端口监听..."
echo "   端口80监听状态:"
netstat -tlnp | grep :80 | sed 's/^/     /' || echo "     端口80未监听"

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
echo "🎉 Nginx前端配置问题修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "  ✅ 禁用了Nginx默认站点"
echo "  ✅ 创建了正确的项目配置"
echo "  ✅ 配置了前端静态文件服务"
echo "  ✅ 配置了后端API代理"
echo "  ✅ 配置了WebSocket支持"
echo "  ✅ 配置了健康检查"
echo "  ✅ 配置了静态资源缓存"
echo "  ✅ 重新加载了Nginx配置"
echo ""
echo "现在前端应该能正确显示IPv6 WireGuard Manager页面了！"
echo ""
echo "如果问题仍然存在，请检查："
echo "1. 前端文件是否正确构建"
echo "2. 文件权限是否正确"
echo "3. Nginx日志是否有错误信息"
echo ""
echo "查看Nginx日志:"
echo "  tail -f /var/log/nginx/error.log"
echo "  tail -f /var/log/nginx/access.log"
