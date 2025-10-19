#!/bin/bash

# 修复Nginx API代理配置脚本
# 用于解决API路径重复问题导致的HTTP 500错误

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

# 获取安装目录
INSTALL_DIR=${INSTALL_DIR:-/opt/ipv6-wireguard-manager}
NGINX_CONF_PATH="/etc/nginx/sites-available/ipv6-wireguard-manager"

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   log_error "此脚本需要root权限运行"
   exit 1
fi

# 检查Nginx是否安装
if ! command -v nginx &> /dev/null; then
    log_error "Nginx未安装"
    exit 1
fi

log_info "开始修复Nginx API代理配置..."

# 备份当前配置
if [[ -f "$NGINX_CONF_PATH" ]]; then
    cp "$NGINX_CONF_PATH" "$NGINX_CONF_PATH.backup.$(date +%Y%m%d%H%M%S)"
    log_success "已备份当前Nginx配置"
fi

# 获取API端口和Web端口
API_PORT=${API_PORT:-8000}
WEB_PORT=${WEB_PORT:-80}

# 创建修复后的Nginx配置
cat > "$NGINX_CONF_PATH" << EOF
# 上游服务器组，支持IPv4和IPv6双栈
upstream backend_api {
    # IPv6优先，IPv4作为备选
    server [::1]:$API_PORT max_fails=3 fail_timeout=30s;
    server 127.0.0.1:$API_PORT backup max_fails=3 fail_timeout=30s;
    
    # 健康检查
    keepalive 32;
    keepalive_requests 100;
    keepalive_timeout 60s;
}

server {
    listen $WEB_PORT;
    listen [::]:$WEB_PORT;
    server_name _;
    root $INSTALL_DIR/frontend;
    index index.php index.html;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }
    
    # API代理配置 - 将 /api/* 请求代理到后端，支持IPv4和IPv6双栈
    location /api/ {
        # 定义上游服务器组，支持IPv4和IPv6双栈
        proxy_pass http://backend_api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # 错误处理
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_next_upstream_tries 3;
        proxy_next_upstream_timeout 10s;
        
        # CORS头 - 支持环境变量配置
        add_header Access-Control-Allow-Origin "${BACKEND_ALLOWED_ORIGINS:-http://localhost:$WEB_PORT}" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        # 处理预检请求
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "${BACKEND_ALLOWED_ORIGINS:-http://localhost:$WEB_PORT}" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # PHP文件处理
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # 超时设置
        fastcgi_connect_timeout 60s;
        fastcgi_send_timeout 60s;
        fastcgi_read_timeout 60s;
        
        # 缓冲设置
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }
    
    # 前端路由处理 - 支持单页应用路由
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # 禁止访问敏感文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ /(config|logs|backup)/ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 禁止访问PHP配置文件
    location ~ \.(ini|conf|log)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # 文件上传大小限制
    client_max_body_size 10M;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
}
EOF

# 启用站点
if [[ -d "/etc/nginx/sites-enabled" ]]; then
    ln -sf "$NGINX_CONF_PATH" "/etc/nginx/sites-enabled/ipv6-wireguard-manager"
    rm -f "/etc/nginx/sites-enabled/default" 2>/dev/null || true
fi

# 测试配置
log_info "测试Nginx配置..."
if nginx -t; then
    log_success "Nginx配置测试通过"
    
    # 重启Nginx
    log_info "重启Nginx服务..."
    systemctl restart nginx
    systemctl enable nginx
    
    log_success "Nginx配置修复完成"
    log_info "修复内容：移除了API代理路径中重复的/api/v1/前缀"
    log_info "现在前端到API的请求应该可以正常工作了"
else
    log_error "Nginx配置测试失败，请检查配置文件"
    exit 1
fi

# 检查API服务状态
log_info "检查API服务状态..."
if systemctl is-active --quiet ipv6-wireguard-api; then
    log_success "API服务正在运行"
else
    log_warning "API服务未运行，请启动API服务："
    log_info "systemctl start ipv6-wireguard-api"
fi

# 检查PHP-FPM服务状态
log_info "检查PHP-FPM服务状态..."
if systemctl is-active --quiet php8.1-fpm; then
    log_success "PHP-FPM服务正在运行"
else
    log_warning "PHP-FPM服务未运行，请启动PHP-FPM服务："
    log_info "systemctl start php8.1-fpm"
fi

echo ""
log_info "修复完成后，您可以运行以下命令验证修复效果："
log_info "curl -I http://localhost/api/v1/health"
log_info "或者访问前端页面检查是否还有错误"
echo ""