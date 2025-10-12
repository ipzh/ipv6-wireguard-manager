#!/bin/bash

echo "🔍 诊断前端500错误..."
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

# 1. 检查服务状态
log_step "检查服务状态..."
echo "后端服务状态:"
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务未运行"
    echo "尝试启动后端服务..."
    sudo systemctl start $SERVICE_NAME
    sleep 3
    if systemctl is-active --quiet $SERVICE_NAME; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
    fi
fi

echo ""
echo "Nginx服务状态:"
if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务未运行"
    echo "尝试启动Nginx服务..."
    sudo systemctl start nginx
    sleep 2
    if systemctl is-active --quiet nginx; then
        log_success "Nginx服务启动成功"
    else
        log_error "Nginx服务启动失败"
    fi
fi

# 2. 检查端口监听
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

# 3. 检查前端文件
log_step "检查前端文件..."
if [ -d "$FRONTEND_DIR" ]; then
    log_success "前端目录存在: $FRONTEND_DIR"
    
    if [ -d "$FRONTEND_DIR/dist" ]; then
        log_success "前端dist目录存在"
        echo "前端文件列表:"
        ls -la "$FRONTEND_DIR/dist" | head -10
        
        # 检查index.html
        if [ -f "$FRONTEND_DIR/dist/index.html" ]; then
            log_success "index.html存在"
        else
            log_error "index.html不存在"
        fi
        
        # 检查静态资源
        if [ -d "$FRONTEND_DIR/dist/assets" ]; then
            log_success "assets目录存在"
            echo "静态资源文件:"
            ls -la "$FRONTEND_DIR/dist/assets" | head -5
        else
            log_warning "assets目录不存在"
        fi
    else
        log_error "前端dist目录不存在"
        echo "尝试重新构建前端..."
        
        if [ -f "$FRONTEND_DIR/package.json" ]; then
            log_info "发现package.json，尝试构建前端..."
            cd "$FRONTEND_DIR"
            
            # 检查Node.js
            if command -v node >/dev/null 2>&1; then
                log_info "Node.js版本: $(node --version)"
                
                # 检查npm
                if command -v npm >/dev/null 2>&1; then
                    log_info "npm版本: $(npm --version)"
                    
                    # 安装依赖
                    log_info "安装前端依赖..."
                    npm install --silent
                    
                    # 构建前端
                    log_info "构建前端..."
                    npm run build
                    
                    if [ -d "dist" ]; then
                        log_success "前端构建成功"
                    else
                        log_error "前端构建失败"
                    fi
                else
                    log_error "npm未安装"
                fi
            else
                log_error "Node.js未安装"
            fi
        else
            log_error "package.json不存在"
        fi
    fi
else
    log_error "前端目录不存在: $FRONTEND_DIR"
fi

# 4. 检查Nginx配置
log_step "检查Nginx配置..."
if [ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]; then
    log_success "Nginx站点配置文件存在"
    
    echo "Nginx配置内容:"
    cat /etc/nginx/sites-available/ipv6-wireguard-manager
    
    # 检查配置语法
    echo ""
    echo "检查Nginx配置语法:"
    if sudo nginx -t; then
        log_success "Nginx配置语法正确"
    else
        log_error "Nginx配置语法错误"
    fi
    
    # 检查站点是否启用
    if [ -L "/etc/nginx/sites-enabled/ipv6-wireguard-manager" ]; then
        log_success "Nginx站点已启用"
    else
        log_warning "Nginx站点未启用，尝试启用..."
        sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
        sudo systemctl reload nginx
    fi
else
    log_error "Nginx站点配置文件不存在"
    echo "创建Nginx配置..."
    
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
}
EOF
    
    # 启用站点
    sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    
    # 测试配置
    if sudo nginx -t; then
        log_success "Nginx配置创建成功"
        sudo systemctl reload nginx
    else
        log_error "Nginx配置创建失败"
    fi
fi

# 5. 检查文件权限
log_step "检查文件权限..."
echo "应用目录权限:"
ls -la "$APP_HOME"

echo ""
echo "前端目录权限:"
ls -la "$FRONTEND_DIR"

if [ -d "$FRONTEND_DIR/dist" ]; then
    echo ""
    echo "前端dist目录权限:"
    ls -la "$FRONTEND_DIR/dist"
fi

# 修复权限
log_info "修复文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 6. 测试后端API
log_step "测试后端API..."
echo "测试本地API访问:"
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    log_success "后端API访问正常"
    echo "API响应:"
    curl -s http://127.0.0.1:8000/health
else
    log_error "后端API访问失败"
    echo "尝试手动测试..."
    curl -v http://127.0.0.1:8000/health 2>&1 | head -20
fi

echo ""
echo "测试API状态:"
if curl -s http://127.0.0.1:8000/api/v1/status >/dev/null 2>&1; then
    log_success "API状态正常"
    curl -s http://127.0.0.1:8000/api/v1/status
else
    log_error "API状态异常"
    echo "尝试手动测试..."
    curl -v http://127.0.0.1:8000/api/v1/status 2>&1 | head -20
fi

# 7. 测试Nginx代理
log_step "测试Nginx代理..."
echo "测试本地Nginx访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "本地Nginx访问正常"
else
    log_error "本地Nginx访问失败"
    echo "尝试手动测试..."
    curl -v http://localhost 2>&1 | head -20
fi

echo ""
echo "测试Nginx API代理:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "Nginx API代理正常"
    curl -s http://localhost/api/v1/status
else
    log_error "Nginx API代理失败"
    echo "尝试手动测试..."
    curl -v http://localhost/api/v1/status 2>&1 | head -20
fi

# 8. 检查日志
log_step "检查错误日志..."
echo "后端服务日志 (最近10条):"
sudo journalctl -u $SERVICE_NAME --no-pager -n 10

echo ""
echo "Nginx错误日志 (最近10条):"
sudo tail -10 /var/log/nginx/error.log 2>/dev/null || echo "Nginx错误日志不可用"

echo ""
echo "Nginx访问日志 (最近5条):"
sudo tail -5 /var/log/nginx/access.log 2>/dev/null || echo "Nginx访问日志不可用"

# 9. 重启服务
log_step "重启服务..."
echo "重启后端服务..."
sudo systemctl restart $SERVICE_NAME
sleep 3

echo "重启Nginx服务..."
sudo systemctl restart nginx
sleep 2

# 10. 最终测试
log_step "最终测试..."
echo "测试前端访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "前端访问正常"
    echo "响应状态码:"
    curl -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_error "前端访问仍然失败"
    echo "详细错误信息:"
    curl -v http://localhost 2>&1 | head -30
fi

echo ""
echo "测试API访问:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "API访问正常"
    curl -s http://localhost/api/v1/status
else
    log_error "API访问仍然失败"
    echo "详细错误信息:"
    curl -v http://localhost/api/v1/status 2>&1 | head -30
fi

# 11. 显示访问信息
log_step "显示访问信息..."
echo "========================================"
echo "🌐 访问地址:"
echo "   本地访问: http://localhost"
echo "   API状态: http://localhost/api/v1/status"
echo "   健康检查: http://localhost/health"
echo ""

# 获取IP地址
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
LOCAL_IPV6=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -n "$LOCAL_IPV4" ] && [ "$LOCAL_IPV4" != "localhost" ]; then
    echo "   IPv4访问: http://$LOCAL_IPV4"
fi

if [ -n "$LOCAL_IPV6" ]; then
    echo "   IPv6访问: http://[$LOCAL_IPV6]"
fi

if [ -n "$PUBLIC_IPV4" ]; then
    echo "   公网访问: http://$PUBLIC_IPV4"
fi

echo ""
echo "📊 服务状态:"
echo "   后端服务: $(systemctl is-active $SERVICE_NAME)"
echo "   Nginx服务: $(systemctl is-active nginx)"
echo ""

echo "========================================"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "🎉 前端500错误已修复！"
else
    log_error "❌ 前端500错误仍然存在"
    echo ""
    echo "🔧 手动修复建议:"
    echo "1. 检查前端文件是否存在: ls -la $FRONTEND_DIR/dist"
    echo "2. 重新构建前端: cd $FRONTEND_DIR && npm run build"
    echo "3. 检查Nginx配置: sudo nginx -t"
    echo "4. 查看详细日志: sudo journalctl -u $SERVICE_NAME -f"
    echo "5. 运行完整修复: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick-fix-500.sh | bash"
fi
