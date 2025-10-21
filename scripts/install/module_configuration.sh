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
API_PORT="8000"
MYSQL_PORT="3306"
REDIS_PORT="6379"

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
        "/var/www/html"
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
    sudo chmod 777 "$INSTALL_DIR/logs"
    sudo chmod 777 "$INSTALL_DIR/cache"
}

# 创建环境配置文件
create_env_config() {
    log_info "创建环境配置文件..."
    
    # 生成随机密钥
    SECRET_KEY=$(openssl rand -hex 32)
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    MYSQL_PASSWORD=$(openssl rand -base64 32)
    
    # 创建.env文件
    cat > "$INSTALL_DIR/.env" << EOF
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

# 数据库配置
DATABASE_URL=mysql://ipv6wgm:$MYSQL_PASSWORD@localhost:$MYSQL_PORT/ipv6wgm
DATABASE_HOST=localhost
DATABASE_PORT=$MYSQL_PORT
DATABASE_USER=ipv6wgm
DATABASE_PASSWORD=$MYSQL_PASSWORD
DATABASE_NAME=ipv6wgm

# 安全配置
SECRET_KEY=$SECRET_KEY
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# 超级用户配置
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_PASSWORD=admin123
FIRST_SUPERUSER_EMAIL=admin@example.com

# WireGuard配置
WIREGUARD_PORT=51820
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
FRONTEND_DIR=/var/www/html
NGINX_CONFIG_DIR=/etc/nginx/sites-available
NGINX_LOG_DIR=/var/log/nginx
SYSTEMD_CONFIG_DIR=/etc/systemd/system

# MySQL配置
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=ipv6wgm
MYSQL_USER=ipv6wgm
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF
    
    # 设置权限
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/.env"
    sudo chmod 600 "$INSTALL_DIR/.env"
    
    log_success "环境配置文件已创建: $INSTALL_DIR/.env"
}

# 配置数据库
configure_database() {
    log_info "配置数据库..."
    
    # 检查MySQL是否运行
    if ! systemctl is-active --quiet mysql; then
        log_info "启动MySQL服务..."
        sudo systemctl start mysql
        sudo systemctl enable mysql
    fi
    
    # 创建数据库和用户
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" << EOF
CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    log_success "数据库配置完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置
    cat > "/etc/nginx/sites-available/ipv6-wireguard-manager" << EOF
server {
    listen 80;
    server_name _;
    
    # 前端
    location / {
        root /var/www/html;
        index index.php index.html;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # PHP处理
    location ~ \.php$ {
        root /var/www/html;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    
    # 启用站点
    sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    
    # 测试配置
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log_success "Nginx配置完成"
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
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
            sudo ufw allow $API_PORT/tcp
            sudo ufw allow $WIREGUARD_PORT/udp
            log_success "UFW防火墙规则已配置"
        fi
    elif command -v firewall-cmd &> /dev/null; then
        if systemctl is-active --quiet firewalld; then
            log_info "配置firewalld防火墙规则..."
            sudo firewall-cmd --permanent --add-port=80/tcp
            sudo firewall-cmd --permanent --add-port=443/tcp
            sudo firewall-cmd --permanent --add-port=$API_PORT/tcp
            sudo firewall-cmd --permanent --add-port=$WIREGUARD_PORT/udp
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
