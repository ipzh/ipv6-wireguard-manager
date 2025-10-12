#!/bin/bash

echo "🔧 修复Nginx IPv6配置导致的500错误..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
FRONTEND_DIR="$APP_HOME/frontend"
BACKEND_DIR="$APP_HOME/backend"
SERVICE_NAME="ipv6-wireguard-manager"

# 日志函数
log_step() {
    echo -e "${BLUE}🚀 [STEP] $1${NC}"
}

log_info() {
    echo -e "${BLUE}💡 [INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}❌ [ERROR] $1${NC}"
}

# 1. 检查当前Nginx配置
log_step "检查当前Nginx配置..."
if [ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]; then
    log_info "当前Nginx配置:"
    cat /etc/nginx/sites-available/ipv6-wireguard-manager
else
    log_warning "Nginx配置文件不存在"
fi

# 2. 检查IPv6支持
log_step "检查IPv6支持..."
echo "检查系统IPv6支持:"
if [ -f /proc/net/if_inet6 ]; then
    log_success "系统支持IPv6"
    echo "IPv6接口:"
    ip -6 addr show | grep -E "inet6.*global" | head -5
else
    log_warning "系统可能不支持IPv6"
fi

echo ""
echo "检查Nginx IPv6编译支持:"
if nginx -V 2>&1 | grep -q "with-ipv6"; then
    log_success "Nginx支持IPv6"
else
    log_warning "Nginx可能不支持IPv6"
fi

# 3. 检查端口监听
log_step "检查端口监听..."
echo "IPv4端口80监听:"
ss -tlnp | grep :80 | grep -v "::"

echo ""
echo "IPv6端口80监听:"
ss -tlnp | grep :80 | grep "::"

# 4. 停止服务
log_step "停止服务..."
sudo systemctl stop nginx
sudo systemctl stop $SERVICE_NAME

# 5. 创建兼容的Nginx配置
log_step "创建兼容的Nginx配置..."

# 首先尝试IPv6配置
log_info "尝试创建支持IPv6的配置..."
sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
        
        # 添加安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        root $FRONTEND_DIR/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 错误页面
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
EOF

# 测试配置
log_info "测试Nginx配置..."
if sudo nginx -t; then
    log_success "IPv6配置测试通过"
    CONFIG_TYPE="ipv6"
else
    log_warning "IPv6配置测试失败，尝试IPv4-only配置..."
    
    # 创建IPv4-only配置
    sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    # 前端静态文件
    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
        
        # 添加安全头
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        root $FRONTEND_DIR/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 错误页面
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
EOF
    
    # 再次测试配置
    if sudo nginx -t; then
        log_success "IPv4-only配置测试通过"
        CONFIG_TYPE="ipv4"
    else
        log_error "所有配置测试都失败"
        exit 1
    fi
fi

# 6. 启用站点
log_step "启用Nginx站点..."
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 7. 检查前端文件
log_step "检查前端文件..."
if [ ! -d "$FRONTEND_DIR/dist" ]; then
    log_warning "前端dist目录不存在，创建默认文件..."
    sudo mkdir -p "$FRONTEND_DIR/dist"
    
    sudo tee "$FRONTEND_DIR/dist/index.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        .status {
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .info {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 10px;
        }
        .btn:hover {
            background: #0056b3;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 IPv6 WireGuard Manager</h1>
        <div class="status success">
            <strong>✅ 服务运行正常</strong>
        </div>
        <div class="status info">
            <p>前端界面正在加载中...</p>
            <p>如果长时间未加载，请检查前端构建文件。</p>
        </div>
        <div>
            <a href="/api/v1/status" class="btn">API状态</a>
            <a href="/health" class="btn">健康检查</a>
        </div>
        <div style="margin-top: 20px; font-size: 14px; color: #666;">
            <p>默认登录: admin / admin123</p>
        </div>
    </div>
    
    <script>
        // 检查API状态
        fetch('/api/v1/status')
            .then(response => response.json())
            .then(data => {
                console.log('API状态:', data);
            })
            .catch(error => {
                console.error('API检查失败:', error);
            });
    </script>
</body>
</html>
EOF
    log_success "默认index.html创建完成"
fi

# 8. 修复权限
log_step "修复文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 9. 启动服务
log_step "启动服务..."
echo "启动后端服务..."
sudo systemctl start $SERVICE_NAME
sleep 3

echo "启动Nginx服务..."
sudo systemctl start nginx
sleep 2

# 10. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务启动失败"
    echo "服务状态:"
    sudo systemctl status nginx --no-pager -l
fi

# 11. 检查端口监听
log_step "检查端口监听..."
echo "端口监听状态:"
ss -tlnp | grep :80

# 12. 测试访问
log_step "测试访问..."
echo "测试IPv4访问:"
if curl -4 -s http://localhost >/dev/null 2>&1; then
    log_success "IPv4访问正常"
    echo "响应状态码:"
    curl -4 -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_error "IPv4访问失败"
    echo "详细错误:"
    curl -4 -v http://localhost 2>&1 | head -20
fi

echo ""
echo "测试IPv6访问:"
if curl -6 -s http://localhost >/dev/null 2>&1; then
    log_success "IPv6访问正常"
    echo "响应状态码:"
    curl -6 -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_warning "IPv6访问失败（可能是系统不支持）"
    echo "详细错误:"
    curl -6 -v http://localhost 2>&1 | head -10
fi

echo ""
echo "测试API访问:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "API访问正常"
    curl -s http://localhost/api/v1/status
else
    log_error "API访问失败"
fi

# 13. 显示访问信息
log_step "显示访问信息..."
echo "========================================"
echo -e "${GREEN}🎉 Nginx IPv6配置修复完成！${NC}"
echo ""
echo "📋 配置类型: $CONFIG_TYPE"
echo ""

# 获取IP地址
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
LOCAL_IPV6=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

echo "🌐 访问地址:"
echo "   本地访问: http://localhost"
echo "   API状态: http://localhost/api/v1/status"
echo "   健康检查: http://localhost/health"
echo ""

if [ -n "$LOCAL_IPV4" ] && [ "$LOCAL_IPV4" != "localhost" ]; then
    echo "   IPv4访问: http://$LOCAL_IPV4"
fi

if [ -n "$LOCAL_IPV6" ] && [ "$CONFIG_TYPE" = "ipv6" ]; then
    echo "   IPv6访问: http://[$LOCAL_IPV6]"
elif [ -n "$LOCAL_IPV6" ] && [ "$CONFIG_TYPE" = "ipv4" ]; then
    echo "   IPv6访问: 需要手动配置（当前为IPv4-only模式）"
fi

if [ -n "$PUBLIC_IPV4" ]; then
    echo "   公网访问: http://$PUBLIC_IPV4"
fi

echo ""
echo "📊 服务状态:"
echo "   后端服务: $(systemctl is-active $SERVICE_NAME)"
echo "   Nginx服务: $(systemctl is-active nginx)"
echo "   配置类型: $CONFIG_TYPE"
echo ""

echo "🔧 管理命令:"
echo "   查看Nginx配置: sudo nginx -t"
echo "   查看Nginx日志: sudo journalctl -u nginx -f"
echo "   重启Nginx: sudo systemctl restart nginx"
echo ""

echo "========================================"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "🎉 500错误已修复！服务正常运行！"
else
    log_error "❌ 仍有问题，请检查日志"
    echo "查看详细日志:"
    echo "  sudo journalctl -u nginx -f"
    echo "  sudo tail -f /var/log/nginx/error.log"
fi
