#!/bin/bash

# IPv6 WireGuard Manager - PHP前端部署脚本
# 用于部署PHP前端到Web服务器

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 默认配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
WEB_DIR="/var/www/html"
WEB_USER="www-data"
WEB_GROUP="www-data"
PHP_VERSION="8.1"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --dir DIR           安装目录 (默认: $INSTALL_DIR)"
    echo "  --web-dir DIR       Web目录 (默认: $WEB_DIR)"
    echo "  --web-user USER     Web用户 (默认: $WEB_USER)"
    echo "  --web-group GROUP   Web组 (默认: $WEB_GROUP)"
    echo "  --php-version VER   PHP版本 (默认: $PHP_VERSION)"
    echo "  --help|-h          显示此帮助信息"
    echo ""
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --web-dir)
                WEB_DIR="$2"
                shift 2
                ;;
            --web-user)
                WEB_USER="$2"
                shift 2
                ;;
            --web-group)
                WEB_GROUP="$2"
                shift 2
                ;;
            --php-version)
                PHP_VERSION="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查PHP安装
check_php_installation() {
    log_step "检查PHP安装..."
    
    if ! command -v php &> /dev/null; then
        log_error "PHP未安装"
        log_info "请先安装PHP和PHP-FPM:"
        log_info "  Ubuntu/Debian: sudo apt-get install php$PHP_VERSION php$PHP_VERSION-fpm"
        log_info "  CentOS/RHEL: sudo yum install php php-fpm"
        exit 1
    fi
    
    # 检测PHP-FPM服务名称
    php_fpm_service=""
    if systemctl list-units --type=service --state=running | grep -q "php$PHP_VERSION-fpm"; then
        php_fpm_service="php$PHP_VERSION-fpm"
    elif systemctl list-units --type=service --state=running | grep -q "php-fpm"; then
        php_fpm_service="php-fpm"
    elif systemctl list-units --type=service --state=running | grep -q "php${PHP_VERSION/./}-fpm"; then
        php_fpm_service="php${PHP_VERSION/./}-fpm"
    fi
    
    if [[ -n "$php_fpm_service" ]]; then
        log_success "PHP-FPM服务 ($php_fpm_service) 运行正常"
    else
        # 尝试启动PHP-FPM服务
        log_warning "PHP-FPM服务未运行"
        log_info "尝试启动PHP-FPM服务..."
        
        if systemctl start php$PHP_VERSION-fpm 2>/dev/null; then
            php_fpm_service="php$PHP_VERSION-fpm"
            log_success "PHP-FPM服务 ($php_fpm_service) 启动成功"
        elif systemctl start php-fpm 2>/dev/null; then
            php_fpm_service="php-fpm"
            log_success "PHP-FPM服务 ($php_fpm_service) 启动成功"
        elif systemctl start php${PHP_VERSION/./}-fpm 2>/dev/null; then
            php_fpm_service="php${PHP_VERSION/./}-fpm"
            log_success "PHP-FPM服务 ($php_fpm_service) 启动成功"
        else
            log_error "无法启动PHP-FPM服务"
            log_info "请手动安装和启动PHP-FPM"
            exit 1
        fi
    fi
    
    # 检查PHP版本
    local current_php_version=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+' | head -1)
    if [[ "$current_php_version" < "8.1" ]]; then
        log_warning "PHP版本较低 ($current_php_version)，推荐使用PHP 8.1+"
    fi
    
    log_success "PHP检查完成"
}

# 检查必需扩展
check_php_extensions() {
    log_step "检查PHP扩展..."
    
    local required_extensions=("session" "json" "mbstring" "filter" "pdo" "pdo_mysql" "curl" "openssl")
    local missing_extensions=()
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            missing_extensions+=("$ext")
        fi
    done
    
    if [[ ${#missing_extensions[@]} -gt 0 ]]; then
        log_error "缺少必需的PHP扩展: ${missing_extensions[*]}"
        log_info "请安装缺失的扩展:"
        log_info "  Ubuntu/Debian: sudo apt-get install php$PHP_VERSION-${missing_extensions[*]}"
        log_info "  CentOS/RHEL: sudo yum install php-${missing_extensions[*]}"
        exit 1
    fi
    
    log_success "PHP扩展检查完成"
}

# 创建Web目录
create_web_directory() {
    log_step "创建Web目录..."
    
    if [[ ! -d "$WEB_DIR" ]]; then
        log_info "创建Web目录: $WEB_DIR"
        mkdir -p "$WEB_DIR"
    fi
    
    # 设置权限
    chown -R "$WEB_USER:$WEB_GROUP" "$WEB_DIR"
    chmod -R 755 "$WEB_DIR"
    
    log_success "Web目录创建完成"
}

# 部署PHP前端文件
deploy_php_files() {
    log_step "部署PHP前端文件..."
    
    local php_frontend_dir="$INSTALL_DIR/php-frontend"
    
    if [[ ! -d "$php_frontend_dir" ]]; then
        log_error "PHP前端目录不存在: $php_frontend_dir"
        log_info "请确保项目已正确下载"
        exit 1
    fi
    
    # 复制PHP前端文件
    log_info "复制PHP前端文件到Web目录..."
    cp -r "$php_frontend_dir"/* "$WEB_DIR/"
    
    # 创建配置文件
    log_info "创建前端配置文件..."
    cat > "$WEB_DIR/config/config.php" << EOF
<?php
// 应用配置
define('APP_NAME', 'IPv6 WireGuard Manager');
define('APP_VERSION', '3.0.0');
define('APP_DEBUG', false);

// API配置
define('API_BASE_URL', 'http://localhost:8000/api/v1');
define('API_TIMEOUT', 30);

// 会话配置
define('SESSION_LIFETIME', 3600);

// 分页配置
define('DEFAULT_PAGE_SIZE', 20);
define('MAX_PAGE_SIZE', 100);

// 安全配置
define('CSRF_TOKEN_NAME', '_token');
define('PASSWORD_MIN_LENGTH', 8);

// 错误处理
error_reporting(0);
ini_set('display_errors', 0);

// 时区设置
date_default_timezone_set('Asia/Shanghai');

// 字符编码
mb_internal_encoding('UTF-8');
mb_http_output('UTF-8');
?>
EOF
    
    # 设置权限
    chown -R "$WEB_USER:$WEB_GROUP" "$WEB_DIR"
    chmod -R 755 "$WEB_DIR"
    
    log_success "PHP前端文件部署完成"
}

# 配置Nginx
configure_nginx() {
    log_step "配置Nginx..."
    
    # 检查Nginx是否安装
    if ! command -v nginx &> /dev/null; then
        log_error "Nginx未安装"
        log_info "请先安装Nginx"
        exit 1
    fi
    
    # 创建Nginx配置
    local nginx_config="/etc/nginx/sites-available/ipv6-wireguard-manager"
    
    cat > "$nginx_config" << EOF
# IPv6 WireGuard Manager - Nginx配置文件
server {
    listen 80;
    listen [::]:80;
    
    server_name _;
    root $WEB_DIR;
    index index.php index.html index.htm;
    
    # 字符集
    charset utf-8;
    
    # 日志配置
    access_log /var/log/nginx/ipv6-wireguard-manager_access.log;
    error_log /var/log/nginx/ipv6-wireguard-manager_error.log;
    
    # 安全头设置
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # 客户端最大上传大小
    client_max_body_size 10M;
    
    # 超时设置
    client_body_timeout 60s;
    client_header_timeout 60s;
    keepalive_timeout 65s;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
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
    
    # PHP文件处理
    location ~ \\.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\\.php)(/.+)\\$;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 添加CORS头
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization";
        
        # 处理OPTIONS请求
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";
            add_header Access-Control-Max-Age 86400;
            return 204;
        }
    }
    
    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
    
    # 静态资源缓存
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 默认路由处理
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
}
EOF
    
    # 启用站点
    log_info "启用项目站点..."
    ln -sf "$nginx_config" /etc/nginx/sites-enabled/
    
    # 禁用默认站点
    if [[ -f "/etc/nginx/sites-enabled/default" ]]; then
        rm -f "/etc/nginx/sites-enabled/default"
    fi
    
    # 测试配置
    log_info "测试Nginx配置..."
    if nginx -t; then
        log_success "Nginx配置语法正确"
    else
        log_error "Nginx配置语法错误"
        exit 1
    fi
    
    # 重启Nginx
    log_info "重启Nginx服务..."
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        log_success "Nginx服务重启成功"
    else
        log_error "Nginx服务重启失败"
        exit 1
    fi
    
    log_success "Nginx配置完成"
}

# 主函数
main() {
    echo "=========================================="
    echo "IPv6 WireGuard Manager - PHP前端部署脚本"
    echo "=========================================="
    echo ""
    
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0 $*"
        exit 1
    fi
    
    # 解析参数
    parse_arguments "$@"
    
    log_info "部署配置:"
    log_info "  安装目录: $INSTALL_DIR"
    log_info "  Web目录: $WEB_DIR"
    log_info "  Web用户: $WEB_USER"
    log_info "  Web组: $WEB_GROUP"
    log_info "  PHP版本: $PHP_VERSION"
    echo ""
    
    # 执行部署步骤
    check_php_installation
    check_php_extensions
    create_web_directory
    deploy_php_files
    configure_nginx
    
    echo ""
    log_success "PHP前端部署完成！"
    log_info "访问地址: http://你的服务器IP"
    log_info "默认登录: admin / admin123"
    echo ""
}

# 运行主函数
main "$@"