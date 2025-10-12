#!/bin/bash

echo "🔧 修复安装后的问题..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$APP_HOME/backend"
FRONTEND_DIR="$APP_HOME/frontend"
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

# 1. 检查当前服务状态
log_step "检查当前服务状态..."
echo "检查所有相关服务:"

# 检查可能存在的服务名称
SERVICES=("ipv6-wireguard-manager" "ipv6-wireguard-backend" "ipv6-wireguard-frontend" "ipv6-wireguard")

for service in "${SERVICES[@]}"; do
    if systemctl list-units --type=service | grep -q "$service"; then
        echo "发现服务: $service"
        systemctl status "$service" --no-pager -l
        echo ""
    fi
done

# 2. 停止所有相关服务
log_step "停止所有相关服务..."
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "停止服务: $service"
        sudo systemctl stop "$service"
    fi
done

# 停止Nginx
sudo systemctl stop nginx

# 3. 清理旧的服务文件
log_step "清理旧的服务文件..."
for service in "${SERVICES[@]}"; do
    if [ -f "/etc/systemd/system/$service.service" ]; then
        echo "删除旧服务文件: $service.service"
        sudo systemctl disable "$service" 2>/dev/null || true
        sudo rm -f "/etc/systemd/system/$service.service"
    fi
done

# 4. 检查应用文件
log_step "检查应用文件..."
if [ -d "$APP_HOME" ]; then
    log_success "应用目录存在: $APP_HOME"
    echo "应用目录内容:"
    ls -la "$APP_HOME"
else
    log_error "应用目录不存在: $APP_HOME"
    exit 1
fi

if [ -d "$BACKEND_DIR" ]; then
    log_success "后端目录存在: $BACKEND_DIR"
else
    log_error "后端目录不存在: $BACKEND_DIR"
    exit 1
fi

if [ -d "$FRONTEND_DIR" ]; then
    log_success "前端目录存在: $FRONTEND_DIR"
else
    log_error "前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

# 5. 检查前端文件
log_step "检查前端文件..."
if [ -d "$FRONTEND_DIR/dist" ]; then
    log_success "前端dist目录存在"
    echo "前端文件:"
    ls -la "$FRONTEND_DIR/dist" | head -10
else
    log_warning "前端dist目录不存在，尝试重新构建..."
    
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        cd "$FRONTEND_DIR"
        
        if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
            log_info "重新构建前端..."
            npm install --silent
            npm run build
            
            if [ -d "dist" ]; then
                log_success "前端构建成功"
            else
                log_error "前端构建失败"
            fi
        else
            log_error "Node.js环境不可用"
        fi
    else
        log_error "package.json不存在"
    fi
fi

# 6. 创建正确的systemd服务
log_step "创建正确的systemd服务..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=redis-server.service redis.service

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$BACKEND_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=$BACKEND_DIR
ExecStart=$BACKEND_DIR/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

log_success "systemd服务文件创建完成"

# 7. 创建正确的Nginx配置
log_step "创建正确的Nginx配置..."
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

# 启用Nginx站点
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 测试Nginx配置
if sudo nginx -t; then
    log_success "Nginx配置正确"
else
    log_error "Nginx配置错误"
    exit 1
fi

# 8. 修复权限
log_step "修复文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 9. 重新加载systemd
log_step "重新加载systemd..."
sudo systemctl daemon-reload

# 10. 启动服务
log_step "启动服务..."
echo "启动后端服务..."
sudo systemctl start $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME

sleep 3

echo "启动Nginx服务..."
sudo systemctl start nginx
sudo systemctl enable nginx

sleep 2

# 11. 检查服务状态
log_step "检查服务状态..."
echo "后端服务状态:"
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

echo ""
echo "Nginx服务状态:"
if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务启动失败"
    echo "服务状态:"
    sudo systemctl status nginx --no-pager -l
fi

# 12. 检查端口监听
log_step "检查端口监听..."
echo "端口8000 (后端API):"
if ss -tlnp | grep -q :8000; then
    log_success "端口8000正常监听"
    ss -tlnp | grep :8000
else
    log_error "端口8000未监听"
fi

echo ""
echo "端口80 (Nginx):"
if ss -tlnp | grep -q :80; then
    log_success "端口80正常监听"
    ss -tlnp | grep :80
else
    log_error "端口80未监听"
fi

# 13. 测试访问
log_step "测试访问..."
echo "测试后端API:"
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    log_success "后端API访问正常"
    curl -s http://127.0.0.1:8000/health
else
    log_error "后端API访问失败"
fi

echo ""
echo "测试前端访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "前端访问正常"
    echo "响应状态码:"
    curl -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_error "前端访问失败"
    echo "详细错误:"
    curl -v http://localhost 2>&1 | head -20
fi

echo ""
echo "测试API代理:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "API代理正常"
    curl -s http://localhost/api/v1/status
else
    log_error "API代理失败"
fi

# 14. 显示正确的访问信息
log_step "显示正确的访问信息..."
echo "========================================"
echo -e "${GREEN}🎉 修复完成！${NC}"
echo ""
echo "📋 正确的访问信息："
echo "   IPv4访问地址："
if [ -n "$(curl -s -4 ifconfig.me 2>/dev/null)" ]; then
    PUBLIC_IPV4=$(curl -s -4 ifconfig.me)
    echo "     - 前端界面: http://$PUBLIC_IPV4"
    echo "     - 后端API: http://$PUBLIC_IPV4/api"
    echo "     - API文档: http://$PUBLIC_IPV4/api/docs"
else
    LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    echo "     - 前端界面: http://$LOCAL_IPV4"
    echo "     - 后端API: http://$LOCAL_IPV4/api"
    echo "     - API文档: http://$LOCAL_IPV4/api/docs"
fi

echo "   IPv6访问地址："
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
if [ -n "$IPV6_ADDRESS" ]; then
    echo "     - 前端界面: http://[$IPV6_ADDRESS]"
    echo "     - 后端API: http://[$IPV6_ADDRESS]/api"
    echo "     - API文档: http://[$IPV6_ADDRESS]/api/docs"
else
    echo "     - 请运行 'ip -6 addr show' 查看IPv6地址"
fi

echo ""
echo "🔑 默认登录信息："
echo "   用户名: admin"
echo "   密码: admin123"
echo ""
echo "🛠️  正确的管理命令："
echo "   查看状态: sudo systemctl status $SERVICE_NAME"
echo "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   重启服务: sudo systemctl restart $SERVICE_NAME"
echo "   查看Nginx状态: sudo systemctl status nginx"
echo "   查看Nginx日志: sudo journalctl -u nginx -f"
echo ""
echo "📁 安装位置："
echo "   应用目录: $APP_HOME"
echo "   配置文件: $BACKEND_DIR/.env"
echo ""
echo "🌐 本地测试："
echo "   前端: http://localhost"
echo "   API: http://localhost/api/v1/status"
echo "   健康: http://localhost/health"
echo ""
echo "========================================"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "🎉 所有问题已修复！服务正常运行！"
else
    log_error "❌ 仍有问题，请检查日志"
    echo "查看详细日志:"
    echo "  sudo journalctl -u $SERVICE_NAME -f"
    echo "  sudo tail -f /var/log/nginx/error.log"
fi
