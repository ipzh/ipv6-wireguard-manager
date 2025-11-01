#!/bin/bash

# 配置模块
# 创建配置文件、设置环境变量、配置服务

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

# 配置变量
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
WEB_PORT="80"
API_PORT="8000"
FRONTEND_ROOT="/var/www/html"
PHP_FPM_SOCKET="/var/run/php/php8.1-fpm.sock"
MYSQL_PORT="3306"
REDIS_PORT="6379"
WIREGUARD_PORT="51820"
NGINX_SITE_NAME="ipv6-wireguard-manager"
MYSQL_APP_USER="ipv6wgm"

SECRET_KEY=""
MYSQL_PASSWORD=""
SUPERUSER_PASSWORD=""

generate_password() {
    local length="${1:-32}"
    local password=""
    local attempts=0

    while [[ $attempts -lt 5 ]]; do
        if command -v openssl >/dev/null 2>&1; then
            password=$(openssl rand -base64 64 | LC_ALL=C tr -dc 'A-Za-z0-9@#%+=_' | head -c "$length")
        else
            password=$(LC_ALL=C tr -dc 'A-Za-z0-9@#%+=_' < /dev/urandom | head -c "$length")
        fi

        if [[ -n "$password" && ${#password} -ge $length ]]; then
            echo "$password"
            return 0
        fi

        attempts=$((attempts + 1))
    done

    log_warning "无法生成足够长度的随机字符串，使用回退方案"
    password=$(date +%s%N | sha256sum | head -c "$length")
    echo "$password"
}

# 创建用户和组
create_user() {
    log_info "创建服务用户..."
    
    if ! id "$SERVICE_USER" &>/dev/null; then
        sudo useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
        log_success "创建用户: $SERVICE_USER"
    else
        log_info "用户已存在: $SERVICE_USER"
    fi
    
    if ! getent group "$SERVICE_GROUP" &>/dev/null; then
        sudo groupadd "$SERVICE_GROUP"
        log_success "创建组: $SERVICE_GROUP"
    else
        log_info "组已存在: $SERVICE_GROUP"
    fi
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    DIRS=(
        "$INSTALL_DIR"
        "$INSTALL_DIR/backend"
        "$INSTALL_DIR/frontend"
        "$INSTALL_DIR/config"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/data"
        "$INSTALL_DIR/backups"
        "$INSTALL_DIR/cache"
        "/etc/wireguard"
        "/etc/wireguard/clients"
        "$FRONTEND_ROOT"
        "/etc/nginx/sites-available"
        "/etc/nginx/sites-enabled"
    )
    
    for dir in "${DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            sudo mkdir -p "$dir"
            log_success "创建目录: $dir"
        else
            log_info "目录已存在: $dir"
        fi
    done
    
    # 设置权限
    sudo chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    sudo chmod 755 "$INSTALL_DIR"
    
    # 日志和缓存目录使用更安全的权限
    sudo chmod 775 "$INSTALL_DIR/logs"
    sudo chmod 775 "$INSTALL_DIR/cache"
}

# 创建环境配置文件
create_env_config() {
    log_info "创建环境配置文件..."

    if [[ -f "$INSTALL_DIR/.env" && "${FORCE:-false}" != "true" ]]; then
        log_warning ".env 文件已存在，使用现有配置（使用 FORCE=true 可覆盖）"

        local value=""
        value=$( { grep -E '^MYSQL_PASSWORD=' "$INSTALL_DIR/.env" | tail -1 || true; } )
        if [[ -n "$value" ]]; then
            MYSQL_PASSWORD="${value#*=}"
        fi

        value=$( { grep -E '^FIRST_SUPERUSER_PASSWORD=' "$INSTALL_DIR/.env" | tail -1 || true; } )
        if [[ -n "$value" ]]; then
            SUPERUSER_PASSWORD="${value#*=}"
        fi

        value=$( { grep -E '^SECRET_KEY=' "$INSTALL_DIR/.env" | tail -1 || true; } )
        if [[ -n "$value" ]]; then
            SECRET_KEY="${value#*=}"
        fi

        return 0
    fi

    SECRET_KEY=$(generate_password 64)
    MYSQL_PASSWORD=$(generate_password 32)
    SUPERUSER_PASSWORD=$(generate_password 24)

    cat > "$INSTALL_DIR/.env" <<EOF
# IPv6 WireGuard Manager 环境配置
# 生成时间: $(date)

# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=3.1.0
DEBUG=false
ENVIRONMENT=production

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=$API_PORT
API_PORT=$API_PORT
WEB_PORT=$WEB_PORT

# 数据库配置
DATABASE_URL=mysql://$MYSQL_APP_USER:$MYSQL_PASSWORD@localhost:$MYSQL_PORT/ipv6wgm
DATABASE_HOST=localhost
DATABASE_PORT=$MYSQL_PORT
DATABASE_USER=$MYSQL_APP_USER
DATABASE_PASSWORD=$MYSQL_PASSWORD
DATABASE_NAME=ipv6wgm

# 安全配置
SECRET_KEY=$SECRET_KEY
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# 超级用户配置
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_PASSWORD=$SUPERUSER_PASSWORD
FIRST_SUPERUSER_EMAIL=admin@example.com

# WireGuard配置
WIREGUARD_PORT=$WIREGUARD_PORT
WIREGUARD_INTERFACE=wg0
WIREGUARD_NETWORK=10.0.0.0/24
WIREGUARD_IPV6_NETWORK=fd00::/64

# 日志配置
LOG_LEVEL=INFO
LOG_FORMAT=json

# 监控配置
ENABLE_METRICS=true
ENABLE_HEALTH_CHECK=true

# Redis配置
REDIS_URL=redis://localhost:$REDIS_PORT/0
USE_REDIS=false

# 路径配置
INSTALL_DIR=$INSTALL_DIR
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_CLIENTS_DIR=/etc/wireguard/clients
FRONTEND_DIR=$FRONTEND_ROOT
NGINX_CONFIG_DIR=/etc/nginx/sites-available
NGINX_LOG_DIR=/var/log/nginx
SYSTEMD_CONFIG_DIR=/etc/systemd/system

# MySQL配置
MYSQL_DATABASE=ipv6wgm
MYSQL_USER=$MYSQL_APP_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF

    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/.env"
    sudo chmod 600 "$INSTALL_DIR/.env"

    local credentials_file="$INSTALL_DIR/setup_credentials.txt"
    cat > "$credentials_file" <<EOF
# IPv6 WireGuard Manager 安装凭据
# 生成时间: $(date)
FIRST_SUPERUSER_PASSWORD=$SUPERUSER_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF

    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$credentials_file"
    sudo chmod 600 "$credentials_file"

    log_success "环境配置文件已创建: $INSTALL_DIR/.env"
    log_info "生成的凭据已保存至 $credentials_file"
}

# 配置数据库
configure_database() {
    log_info "配置数据库..."

    if ! command -v mysql >/dev/null 2>&1; then
        log_warning "未检测到 mysql 命令，跳过数据库配置"
        return 0
    fi

    if [[ -z "$MYSQL_PASSWORD" ]]; then
        log_warning "未获取到数据库密码，跳过自动配置"
        return 0
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if ! systemctl is-active --quiet mysql 2>/dev/null; then
            log_info "启动MySQL服务..."
            if command -v sudo >/dev/null 2>&1; then
                sudo systemctl start mysql 2>/dev/null || true
                sudo systemctl enable mysql 2>/dev/null || true
            else
                systemctl start mysql 2>/dev/null || true
                systemctl enable mysql 2>/dev/null || true
            fi
        fi
    fi

    local mysql_cmd=(mysql -u root)
    if command -v sudo >/dev/null 2>&1; then
        mysql_cmd=(sudo mysql -u root)
    fi

    if ! "${mysql_cmd[@]}" -e "SELECT 1" >/dev/null 2>&1; then
        log_warning "通过 socket 连接 MySQL 失败，尝试不使用 sudo"
        mysql_cmd=(mysql -u root)
    fi

    if ! "${mysql_cmd[@]}" -e "SELECT 1" >/dev/null 2>&1; then
        log_warning "无法连接到 MySQL，跳过自动创建数据库和用户"
        return 0
    fi

    "${mysql_cmd[@]}" <<EOF
CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$MYSQL_APP_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
ALTER USER '$MYSQL_APP_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO '$MYSQL_APP_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

    log_success "数据库配置完成 (用户: $MYSQL_APP_USER)"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."

    local site_available="/etc/nginx/sites-available/$NGINX_SITE_NAME"
    local site_enabled="/etc/nginx/sites-enabled/$NGINX_SITE_NAME"

    cat > "$site_available" <<EOF
server {
    listen $WEB_PORT;
    server_name _;
    root $FRONTEND_ROOT;
    index index.php index.html;

    # 安全头配置
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:$PHP_FPM_SOCKET;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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
}
EOF

    sudo ln -sf "$site_available" "$site_enabled"

    if sudo nginx -t; then
        sudo systemctl reload nginx
        log_success "Nginx配置完成 ($NGINX_SITE_NAME)"
    else
        log_error "Nginx配置测试失败"
        exit 1
    fi
}

# 配置systemd服务
configure_systemd() {
    log_info "配置systemd服务..."
    
    # 创建后端服务
    cat > "/etc/systemd/system/ipv6-wireguard-manager.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/backend/venv/bin
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port $API_PORT --workers 1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd
    sudo systemctl daemon-reload
    sudo systemctl enable ipv6-wireguard-manager
    
    log_success "systemd服务配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."
    
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            log_info "配置UFW防火墙规则..."
            sudo ufw allow $WEB_PORT/tcp
            sudo ufw allow 443/tcp
            sudo ufw allow $API_PORT/tcp
            sudo ufw allow $WIREGUARD_PORT/udp
            log_success "UFW防火墙规则已配置"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if systemctl is-active --quiet firewalld; then
            log_info "配置firewalld防火墙规则..."
            sudo firewall-cmd --permanent --add-port=${WEB_PORT}/tcp
            sudo firewall-cmd --permanent --add-port=443/tcp
            sudo firewall-cmd --permanent --add-port=${API_PORT}/tcp
            sudo firewall-cmd --permanent --add-port=${WIREGUARD_PORT}/udp
            sudo firewall-cmd --reload
            log_success "firewalld防火墙规则已配置"
        fi
    else
        log_warning "未检测到防火墙，请手动配置防火墙规则"
    fi
}

# 主配置函数
configure_system() {
    log_info "开始系统配置..."
    echo ""
    
    create_user
    create_directories
    create_env_config
    configure_database
    configure_nginx
    configure_systemd
    configure_firewall
    
    echo ""
    log_success "系统配置完成！"
    echo ""
    log_info "配置总结:"
    echo "  ✅ 用户和组: 已创建"
    echo "  ✅ 目录结构: 已创建"
    echo "  ✅ 环境配置: 已创建"
    echo "  ✅ 数据库: 已配置"
    echo "  ✅ Nginx: 已配置"
    echo "  ✅ systemd: 已配置"
    echo "  ✅ 防火墙: 已配置"
    echo ""
    log_info "下一步: 运行部署模块"
}
