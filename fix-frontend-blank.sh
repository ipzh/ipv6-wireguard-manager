#!/bin/bash

# IPv6 WireGuard Manager 前端空白页面快速修复脚本
# 用于修复VPS上安装后前端显示空白的问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "IPv6 WireGuard Manager 前端修复工具"
echo "=========================================="
echo ""

# 1. 检查并启动必要服务
log_info "1. 启动必要服务..."

# 启动PostgreSQL
if ! systemctl is-active --quiet postgresql; then
    log_info "启动PostgreSQL服务..."
    systemctl start postgresql
    systemctl enable postgresql
    log_success "PostgreSQL服务已启动"
fi

# 启动Redis
if ! systemctl is-active --quiet redis-server; then
    log_info "启动Redis服务..."
    systemctl start redis-server
    systemctl enable redis-server
    log_success "Redis服务已启动"
fi

# 启动后端服务
if ! systemctl is-active --quiet ipv6-wireguard-manager; then
    log_info "启动后端服务..."
    systemctl start ipv6-wireguard-manager
    systemctl enable ipv6-wireguard-manager
    log_success "后端服务已启动"
fi

# 启动Nginx
if ! systemctl is-active --quiet nginx; then
    log_info "启动Nginx服务..."
    systemctl start nginx
    systemctl enable nginx
    log_success "Nginx服务已启动"
fi

echo ""

# 2. 检查并修复前端构建
log_info "2. 检查并修复前端构建..."

FRONTEND_DIR="/opt/ipv6-wireguard-manager/frontend"

if [ -d "$FRONTEND_DIR" ]; then
    cd "$FRONTEND_DIR"
    
    # 检查是否需要重新构建
    if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
        log_info "前端未构建或构建不完整，开始重新构建..."
        
        # 检查Node.js和npm
        if ! command -v node &> /dev/null; then
            log_error "Node.js未安装，无法构建前端"
            echo "请先安装Node.js: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
            exit 1
        fi
        
        if ! command -v npm &> /dev/null; then
            log_error "npm未安装，无法构建前端"
            exit 1
        fi
        
        # 安装依赖
        log_info "安装前端依赖..."
        npm install
        
        # 构建前端
        log_info "构建前端..."
        npm run build
        
        if [ -d "dist" ] && [ -f "dist/index.html" ]; then
            log_success "前端构建成功"
        else
            log_error "前端构建失败"
            exit 1
        fi
    else
        log_success "前端已构建"
    fi
else
    log_error "前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

echo ""

# 3. 检查并修复Nginx配置
log_info "3. 检查并修复Nginx配置..."

NGINX_CONFIG="/etc/nginx/sites-available/ipv6-wireguard-manager"

# 创建Nginx配置
if [ ! -f "$NGINX_CONFIG" ]; then
    log_info "创建Nginx配置文件..."
    cat > "$NGINX_CONFIG" << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
        
        # 添加缓存控制
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
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
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF
    log_success "Nginx配置文件已创建"
fi

# 启用站点
if [ ! -L "/etc/nginx/sites-enabled/ipv6-wireguard-manager" ]; then
    log_info "启用Nginx站点..."
    ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/ipv6-wireguard-manager
    log_success "Nginx站点已启用"
fi

# 测试Nginx配置
if nginx -t; then
    log_success "Nginx配置语法正确"
else
    log_error "Nginx配置语法错误"
    nginx -t
    exit 1
fi

# 重载Nginx
systemctl reload nginx
log_success "Nginx配置已重载"

echo ""

# 4. 检查并修复防火墙
log_info "4. 检查并修复防火墙..."

# 检查UFW
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log_info "配置UFW防火墙规则..."
        
        # 允许HTTP
        ufw allow 80/tcp
        ufw allow 443/tcp
        
        # 允许SSH
        ufw allow ssh
        
        # 允许WireGuard
        ufw allow 51820/udp
        
        log_success "UFW防火墙规则已配置"
    else
        log_info "UFW防火墙未启用"
    fi
fi

echo ""

# 5. 检查API连接
log_info "5. 检查API连接..."

# 等待服务启动
sleep 5

# 检查本地API
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    log_success "本地API连接正常"
else
    log_warning "本地API连接失败，尝试重启后端服务..."
    systemctl restart ipv6-wireguard-manager
    sleep 10
    
    if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
        log_success "重启后API连接正常"
    else
        log_error "API连接仍然失败"
        echo "后端服务日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -l | tail -20
    fi
fi

echo ""

# 6. 检查前端访问
log_info "6. 检查前端访问..."

SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")

# 检查HTTP访问
if curl -f -s http://$SERVER_IP/ > /dev/null 2>&1; then
    log_success "前端HTTP访问正常"
else
    log_warning "前端HTTP访问失败"
    echo "尝试详细诊断..."
    curl -v http://$SERVER_IP/ 2>&1 | head -10
fi

echo ""

# 7. 生成访问信息
log_info "7. 生成访问信息..."

echo "=========================================="
echo "修复完成！访问信息："
echo "=========================================="
echo ""
echo "前端访问地址:"
echo "  HTTP: http://$SERVER_IP"
echo "  IPv6: http://[$SERVER_IP] (如果支持IPv6)"
echo ""
echo "API文档地址:"
echo "  http://$SERVER_IP/api/v1/docs"
echo ""
echo "默认登录信息:"
echo "  用户名: admin"
echo "  密码: admin123"
echo ""
echo "服务状态:"
echo "  Nginx: $(systemctl is-active nginx)"
echo "  后端: $(systemctl is-active ipv6-wireguard-manager)"
echo "  PostgreSQL: $(systemctl is-active postgresql)"
echo "  Redis: $(systemctl is-active redis-server)"
echo ""
echo "如果仍有问题，请运行诊断脚本:"
echo "  bash diagnose-frontend-issue.sh"
echo ""
