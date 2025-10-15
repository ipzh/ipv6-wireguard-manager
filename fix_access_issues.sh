#!/bin/bash

# 修复访问问题脚本
# 修复IPv6访问和API连接问题

set -e

echo "=========================================="
echo "🔧 修复访问问题脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

echo "1. 检查服务状态..."
if ! systemctl is-active --quiet nginx; then
    echo "   ❌ Nginx服务未运行，正在启动..."
    systemctl start nginx
    if systemctl is-active --quiet nginx; then
        echo "   ✅ Nginx服务启动成功"
    else
        echo "   ❌ Nginx服务启动失败"
        exit 1
    fi
else
    echo "   ✅ Nginx服务运行正常"
fi

if ! systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "   ❌ IPv6 WireGuard Manager服务未运行，正在启动..."
    systemctl start ipv6-wireguard-manager
    sleep 3
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        echo "   ✅ IPv6 WireGuard Manager服务启动成功"
    else
        echo "   ❌ IPv6 WireGuard Manager服务启动失败"
        echo "   查看服务日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -n 10
        exit 1
    fi
else
    echo "   ✅ IPv6 WireGuard Manager服务运行正常"
fi

echo ""

echo "2. 检查并修复Nginx配置..."
nginx_config="/etc/nginx/sites-enabled/ipv6-wireguard-manager"
nginx_config_dir="/etc/nginx/sites-available"

# 创建Nginx配置目录
mkdir -p "$nginx_config_dir"

# 创建正确的Nginx配置
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
}
EOF

echo "   ✅ Nginx配置文件已创建"

# 测试Nginx配置
if nginx -t; then
    echo "   ✅ Nginx配置语法正确"
else
    echo "   ❌ Nginx配置语法错误"
    exit 1
fi

# 重新加载Nginx配置
if systemctl reload nginx; then
    echo "   ✅ Nginx配置重新加载成功"
else
    echo "   ❌ Nginx配置重新加载失败"
    exit 1
fi

echo ""

echo "3. 检查并修复前端文件..."
frontend_dir="/opt/ipv6-wireguard-manager/frontend"
dist_dir="/opt/ipv6-wireguard-manager/frontend/dist"

if [ ! -d "$frontend_dir" ]; then
    echo "   ❌ 前端目录不存在: $frontend_dir"
    exit 1
fi

if [ ! -d "$dist_dir" ]; then
    echo "   ❌ 前端构建目录不存在: $dist_dir"
    echo "   正在构建前端..."
    
    cd "$frontend_dir" || {
        echo "   ❌ 无法进入前端目录"
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
    echo "   ✅ 前端构建目录存在"
fi

# 检查index.html
if [ -f "$dist_dir/index.html" ]; then
    echo "   ✅ index.html文件存在"
else
    echo "   ❌ index.html文件不存在"
    exit 1
fi

echo ""

echo "4. 检查并修复防火墙..."
# 检查UFW
if command -v ufw &> /dev/null; then
    echo "   配置UFW防火墙..."
    ufw allow 80/tcp
    ufw allow 8000/tcp
    echo "   ✅ UFW防火墙规则已添加"
fi

# 检查iptables
if command -v iptables &> /dev/null; then
    echo "   配置iptables防火墙..."
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
    echo "   ✅ iptables防火墙规则已添加"
fi

echo ""

echo "5. 测试连接..."
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

echo ""

echo "6. 测试IPv6连接..."
# 获取IPv6地址
ipv6_ips=()
while IFS= read -r line; do
    if [[ $line =~ ^[0-9a-fA-F:]+$ ]] && [[ $line != "::1" ]] && [[ ! $line =~ ^fe80: ]]; then
        ipv6_ips+=("$line")
    fi
done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-fA-F:]+' 2>/dev/null | grep -v '::1' | grep -v '^fe80:')

if [ ${#ipv6_ips[@]} -gt 0 ]; then
    echo "   发现IPv6地址:"
    for ip in "${ipv6_ips[@]}"; do
        echo "     IPv6: $ip"
        
        echo "     测试IPv6前端连接:"
        if curl -s -o /dev/null -w "%{http_code}" "http://[$ip]:80" --connect-timeout 5; then
            echo "       ✅ IPv6前端连接正常"
        else
            echo "       ❌ IPv6前端连接失败"
        fi
        
        echo "     测试IPv6 API连接:"
        if curl -s -o /dev/null -w "%{http_code}" "http://[$ip]:8000/health" --connect-timeout 5; then
            echo "       ✅ IPv6 API连接正常"
        else
            echo "       ❌ IPv6 API连接失败"
        fi
    done
else
    echo "   ⚠️  未发现IPv6地址"
fi

echo ""

echo "7. 显示访问地址..."
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
echo "🎉 访问问题修复完成！"
echo "=========================================="
echo ""
echo "如果问题仍然存在，请运行诊断脚本："
echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/diagnose_access_issues.sh | bash"
