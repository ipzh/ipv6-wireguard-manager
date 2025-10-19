#!/bin/bash
# IPv6 WireGuard Manager - 路径配置化改进
# 解决硬编码路径问题，实现动态路径配置

# 路径配置管理
PATH_CONFIG_FILE=".path_config"
ENV_CONFIG_FILE=".env"

# 默认路径配置
declare -A DEFAULT_PATHS=(
    ["INSTALL_DIR"]="/opt/ipv6-wireguard-manager"
    ["FRONTEND_DIR"]="/var/www/html"
    ["WIREGUARD_CONFIG_DIR"]="/etc/wireguard"
    ["NGINX_LOG_DIR"]="/var/log/nginx"
    ["NGINX_CONFIG_DIR"]="/etc/nginx/sites-available"
    ["BIN_DIR"]="/usr/local/bin"
    ["LOG_DIR"]="/var/log/ipv6-wireguard-manager"
    ["TEMP_DIR"]="/tmp/ipv6-wireguard-manager"
    ["BACKUP_DIR"]="/opt/ipv6-wireguard-manager/backups"
    ["CACHE_DIR"]="/opt/ipv6-wireguard-manager/cache"
)

# API端点配置
declare -A DEFAULT_API_CONFIG=(
    ["API_BASE_URL"]="http://localhost:8000/api/v1"
    ["WEBSOCKET_URL"]="ws://localhost:8000/ws/"
    ["BACKEND_HOST"]="localhost"
    ["BACKEND_PORT"]="8000"
    ["FRONTEND_PORT"]="80"
    ["NGINX_PORT"]="80"
)

# 数据库配置
declare -A DEFAULT_DB_CONFIG=(
    ["DATABASE_URL"]="mysql://ipv6wgm:ipv6wgm_password@localhost:3306/ipv6wgm"
    ["DATABASE_HOST"]="localhost"
    ["DATABASE_PORT"]="3306"
    ["DATABASE_USER"]="ipv6wgm"
    ["DATABASE_PASSWORD"]="ipv6wgm_password"
    ["DATABASE_NAME"]="ipv6wgm"
)

# 安全配置
declare -A DEFAULT_SECURITY_CONFIG=(
    ["DEFAULT_USERNAME"]="admin"
    ["DEFAULT_PASSWORD"]="admin123"
    ["SECRET_KEY"]=""
    ["SESSION_TIMEOUT"]="1440"
    ["MAX_LOGIN_ATTEMPTS"]="5"
    ["LOCKOUT_DURATION"]="15"
)

# 初始化路径配置
init_path_config() {
    log_info "初始化路径配置系统..."
    
    # 检测系统环境
    detect_system_paths
    
    # 创建路径配置文件
    create_path_config_file
    
    # 创建环境配置文件
    create_env_config_file
    
    log_success "路径配置系统初始化完成"
}

# 检测系统路径
detect_system_paths() {
    log_info "检测系统路径..."
    
    # 检测安装目录
    if [[ -d "/opt" ]]; then
        DEFAULT_PATHS["INSTALL_DIR"]="/opt/ipv6-wireguard-manager"
    elif [[ -d "/usr/local" ]]; then
        DEFAULT_PATHS["INSTALL_DIR"]="/usr/local/ipv6-wireguard-manager"
    else
        DEFAULT_PATHS["INSTALL_DIR"]="$HOME/ipv6-wireguard-manager"
    fi
    
    # 检测Web目录
    if [[ -d "/var/www/html" ]]; then
        DEFAULT_PATHS["FRONTEND_DIR"]="/var/www/html"
    elif [[ -d "/usr/share/nginx/html" ]]; then
        DEFAULT_PATHS["FRONTEND_DIR"]="/usr/share/nginx/html"
    else
        DEFAULT_PATHS["FRONTEND_DIR"]="${DEFAULT_PATHS[INSTALL_DIR]}/web"
    fi
    
    # 检测WireGuard配置目录
    if [[ -d "/etc/wireguard" ]]; then
        DEFAULT_PATHS["WIREGUARD_CONFIG_DIR"]="/etc/wireguard"
    else
        DEFAULT_PATHS["WIREGUARD_CONFIG_DIR"]="${DEFAULT_PATHS[INSTALL_DIR]}/config/wireguard"
    fi
    
    # 检测Nginx配置目录
    if [[ -d "/etc/nginx/sites-available" ]]; then
        DEFAULT_PATHS["NGINX_CONFIG_DIR"]="/etc/nginx/sites-available"
    else
        DEFAULT_PATHS["NGINX_CONFIG_DIR"]="${DEFAULT_PATHS[INSTALL_DIR]}/config/nginx"
    fi
    
    # 检测日志目录
    if [[ -d "/var/log" ]]; then
        DEFAULT_PATHS["LOG_DIR"]="/var/log/ipv6-wireguard-manager"
    else
        DEFAULT_PATHS["LOG_DIR"]="${DEFAULT_PATHS[INSTALL_DIR]}/logs"
    fi
    
    log_success "系统路径检测完成"
}

# 创建路径配置文件
create_path_config_file() {
    log_info "创建路径配置文件..."
    
    cat > "$PATH_CONFIG_FILE" << EOF
# IPv6 WireGuard Manager 路径配置
# 支持环境变量覆盖，格式: export PATH_NAME="custom_path"

# 系统目录路径
export INSTALL_DIR="\${INSTALL_DIR:-${DEFAULT_PATHS[INSTALL_DIR]}}"
export FRONTEND_DIR="\${FRONTEND_DIR:-${DEFAULT_PATHS[FRONTEND_DIR]}}"
export WIREGUARD_CONFIG_DIR="\${WIREGUARD_CONFIG_DIR:-${DEFAULT_PATHS[WIREGUARD_CONFIG_DIR]}}"
export NGINX_LOG_DIR="\${NGINX_LOG_DIR:-${DEFAULT_PATHS[NGINX_LOG_DIR]}}"
export NGINX_CONFIG_DIR="\${NGINX_CONFIG_DIR:-${DEFAULT_PATHS[NGINX_CONFIG_DIR]}}"
export BIN_DIR="\${BIN_DIR:-${DEFAULT_PATHS[BIN_DIR]}}"
export LOG_DIR="\${LOG_DIR:-${DEFAULT_PATHS[LOG_DIR]}}"
export TEMP_DIR="\${TEMP_DIR:-${DEFAULT_PATHS[TEMP_DIR]}}"
export BACKUP_DIR="\${BACKUP_DIR:-${DEFAULT_PATHS[BACKUP_DIR]}}"
export CACHE_DIR="\${CACHE_DIR:-${DEFAULT_PATHS[CACHE_DIR]}}"

# API端点配置
export API_BASE_URL="\${API_BASE_URL:-${DEFAULT_API_CONFIG[API_BASE_URL]}}"
export WEBSOCKET_URL="\${WEBSOCKET_URL:-${DEFAULT_API_CONFIG[WEBSOCKET_URL]}}"
export BACKEND_HOST="\${BACKEND_HOST:-${DEFAULT_API_CONFIG[BACKEND_HOST]}}"
export BACKEND_PORT="\${BACKEND_PORT:-${DEFAULT_API_CONFIG[BACKEND_PORT]}}"
export FRONTEND_PORT="\${FRONTEND_PORT:-${DEFAULT_API_CONFIG[FRONTEND_PORT]}}"
export NGINX_PORT="\${NGINX_PORT:-${DEFAULT_API_CONFIG[NGINX_PORT]}}"

# 数据库配置
export DATABASE_URL="\${DATABASE_URL:-${DEFAULT_DB_CONFIG[DATABASE_URL]}}"
export DATABASE_HOST="\${DATABASE_HOST:-${DEFAULT_DB_CONFIG[DATABASE_HOST]}}"
export DATABASE_PORT="\${DATABASE_PORT:-${DEFAULT_DB_CONFIG[DATABASE_PORT]}}"
export DATABASE_USER="\${DATABASE_USER:-${DEFAULT_DB_CONFIG[DATABASE_USER]}}"
export DATABASE_PASSWORD="\${DATABASE_PASSWORD:-${DEFAULT_DB_CONFIG[DATABASE_PASSWORD]}}"
export DATABASE_NAME="\${DATABASE_NAME:-${DEFAULT_DB_CONFIG[DATABASE_NAME]}}"

# 安全配置
export DEFAULT_USERNAME="\${DEFAULT_USERNAME:-${DEFAULT_SECURITY_CONFIG[DEFAULT_USERNAME]}}"
export DEFAULT_PASSWORD="\${DEFAULT_PASSWORD:-${DEFAULT_SECURITY_CONFIG[DEFAULT_PASSWORD]}}"
export SECRET_KEY="\${SECRET_KEY:-$(openssl rand -hex 32)}"
export SESSION_TIMEOUT="\${SESSION_TIMEOUT:-${DEFAULT_SECURITY_CONFIG[SESSION_TIMEOUT]}}"
export MAX_LOGIN_ATTEMPTS="\${MAX_LOGIN_ATTEMPTS:-${DEFAULT_SECURITY_CONFIG[MAX_LOGIN_ATTEMPTS]}}"
export LOCKOUT_DURATION="\${LOCKOUT_DURATION:-${DEFAULT_SECURITY_CONFIG[LOCKOUT_DURATION]}}"
EOF
    
    log_success "路径配置文件创建完成: $PATH_CONFIG_FILE"
}

# 创建环境配置文件
create_env_config_file() {
    log_info "创建环境配置文件..."
    
    # 加载路径配置
    source "$PATH_CONFIG_FILE"
    
    cat > "$ENV_CONFIG_FILE" << EOF
# IPv6 WireGuard Manager 环境配置
# 自动生成，请勿手动修改

# 应用设置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.1.0"
DEBUG=false
ENVIRONMENT="production"

# API设置
API_V1_STR="/api/v1"
SECRET_KEY="$SECRET_KEY"
ACCESS_TOKEN_EXPIRE_MINUTES=$SESSION_TIMEOUT

# 服务器设置
SERVER_HOST="0.0.0.0"
SERVER_PORT=$BACKEND_PORT

# 数据库设置
DATABASE_URL="$DATABASE_URL"
DATABASE_HOST="$DATABASE_HOST"
DATABASE_PORT=$DATABASE_PORT
DATABASE_USER="$DATABASE_USER"
DATABASE_PASSWORD="$DATABASE_PASSWORD"
DATABASE_NAME="$DATABASE_NAME"
AUTO_CREATE_DATABASE=True

# Redis设置（可选）
USE_REDIS=False
REDIS_URL="redis://:redis123@localhost:6379/0"

# CORS Origins
BACKEND_CORS_ORIGINS=["http://localhost:$FRONTEND_PORT", "http://127.0.0.1:$FRONTEND_PORT", "http://localhost", "http://127.0.0.1"]

# 日志设置
LOG_LEVEL="INFO"
LOG_FORMAT="json"

# 超级用户设置
FIRST_SUPERUSER="$DEFAULT_USERNAME"
FIRST_SUPERUSER_PASSWORD="$DEFAULT_PASSWORD"
FIRST_SUPERUSER_EMAIL="admin@example.com"

# 路径设置
INSTALL_DIR="$INSTALL_DIR"
FRONTEND_DIR="$FRONTEND_DIR"
WIREGUARD_CONFIG_DIR="$WIREGUARD_CONFIG_DIR"
NGINX_LOG_DIR="$NGINX_LOG_DIR"
NGINX_CONFIG_DIR="$NGINX_CONFIG_DIR"
BIN_DIR="$BIN_DIR"
LOG_DIR="$LOG_DIR"
TEMP_DIR="$TEMP_DIR"
BACKUP_DIR="$BACKUP_DIR"
CACHE_DIR="$CACHE_DIR"

# API端点设置
API_BASE_URL="$API_BASE_URL"
WEBSOCKET_URL="$WEBSOCKET_URL"
BACKEND_HOST="$BACKEND_HOST"
BACKEND_PORT=$BACKEND_PORT
FRONTEND_PORT=$FRONTEND_PORT
NGINX_PORT=$NGINX_PORT

# 安全设置
PASSWORD_MIN_LENGTH=12
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBERS=true
PASSWORD_REQUIRE_SPECIAL_CHARS=true
PASSWORD_HISTORY_COUNT=5
PASSWORD_EXPIRY_DAYS=90

# MFA设置
MFA_TOTP_ISSUER="IPv6 WireGuard Manager"
MFA_BACKUP_CODES_COUNT=10
MFA_SMS_ENABLED=false
MFA_EMAIL_ENABLED=true

# API安全设置
RATE_LIMIT_REQUESTS_PER_MINUTE=60
RATE_LIMIT_REQUESTS_PER_HOUR=1000
RATE_LIMIT_BURST_LIMIT=10
MAX_REQUEST_SIZE=10485760
MAX_HEADER_SIZE=8192

# 监控设置
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090
HEALTH_CHECK_INTERVAL=30
ALERT_CPU_THRESHOLD=80.0
ALERT_MEMORY_THRESHOLD=85.0
ALERT_DISK_THRESHOLD=90.0

# 日志设置
LOG_AGGREGATION_ENABLED=true
ELASTICSEARCH_ENABLED=false
ELASTICSEARCH_HOSTS=["localhost:9200"]
LOG_RETENTION_DAYS=30

# 缓存设置
CACHE_BACKEND="memory"
CACHE_MAX_SIZE=1000
CACHE_DEFAULT_TTL=3600
CACHE_COMPRESSION=false

# 压缩设置
RESPONSE_COMPRESSION_ENABLED=true
COMPRESSION_MIN_SIZE=1024
COMPRESSION_MAX_SIZE=10485760
COMPRESSION_LEVEL=6
EOF
    
    log_success "环境配置文件创建完成: $ENV_CONFIG_FILE"
}

# 验证路径配置
validate_path_config() {
    log_info "验证路径配置..."
    
    local errors=0
    
    # 检查必需路径
    local required_paths=("INSTALL_DIR" "FRONTEND_DIR" "WIREGUARD_CONFIG_DIR" "NGINX_CONFIG_DIR")
    
    for path_name in "${required_paths[@]}"; do
        local path_value="${!path_name}"
        
        if [[ -z "$path_value" ]]; then
            log_error "路径配置缺失: $path_name"
            errors=$((errors + 1))
        elif [[ ! -d "$(dirname "$path_value")" ]]; then
            log_warning "路径目录不存在: $path_name = $path_value"
        else
            log_success "路径配置有效: $path_name = $path_value"
        fi
    done
    
    # 检查端口配置
    local required_ports=("BACKEND_PORT" "FRONTEND_PORT" "NGINX_PORT")
    
    for port_name in "${required_ports[@]}"; do
        local port_value="${!port_name}"
        
        if [[ ! "$port_value" =~ ^[0-9]+$ ]] || [[ "$port_value" -lt 1 ]] || [[ "$port_value" -gt 65535 ]]; then
            log_error "端口配置无效: $port_name = $port_value"
            errors=$((errors + 1))
        else
            log_success "端口配置有效: $port_name = $port_value"
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "路径配置验证通过"
        return 0
    else
        log_error "路径配置验证失败，发现 $errors 个错误"
        return 1
    fi
}

# 应用路径配置
apply_path_config() {
    log_info "应用路径配置..."
    
    # 加载路径配置
    source "$PATH_CONFIG_FILE"
    
    # 创建目录
    create_directories
    
    # 设置权限
    set_directory_permissions
    
    # 更新配置文件
    update_config_files
    
    log_success "路径配置应用完成"
}

# 创建目录
create_directories() {
    log_info "创建目录结构..."
    
    local directories=(
        "$INSTALL_DIR"
        "$FRONTEND_DIR"
        "$WIREGUARD_CONFIG_DIR"
        "$NGINX_LOG_DIR"
        "$NGINX_CONFIG_DIR"
        "$BIN_DIR"
        "$LOG_DIR"
        "$TEMP_DIR"
        "$BACKUP_DIR"
        "$CACHE_DIR"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "创建目录: $dir"
        else
            log_info "目录已存在: $dir"
        fi
    done
}

# 设置目录权限
set_directory_permissions() {
    log_info "设置目录权限..."
    
    # 设置安装目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
    chmod 755 "$INSTALL_DIR"
    
    # 设置Web目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$FRONTEND_DIR"
    chmod 755 "$FRONTEND_DIR"
    
    # 设置WireGuard配置目录权限
    chown -R root:root "$WIREGUARD_CONFIG_DIR"
    chmod 700 "$WIREGUARD_CONFIG_DIR"
    
    # 设置日志目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    # 设置临时目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$TEMP_DIR"
    chmod 777 "$TEMP_DIR"
    
    # 设置备份目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$BACKUP_DIR"
    chmod 755 "$BACKUP_DIR"
    
    # 设置缓存目录权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$CACHE_DIR"
    chmod 755 "$CACHE_DIR"
    
    log_success "目录权限设置完成"
}

# 更新配置文件
update_config_files() {
    log_info "更新配置文件..."
    
    # 更新Nginx配置
    update_nginx_config
    
    # 更新systemd服务配置
    update_systemd_config
    
    # 更新前端配置
    update_frontend_config
    
    log_success "配置文件更新完成"
}

# 更新Nginx配置
update_nginx_config() {
    log_info "更新Nginx配置..."
    
    cat > "$NGINX_CONFIG_DIR/ipv6-wireguard-manager" << EOF
server {
    listen $NGINX_PORT;
    server_name localhost;
    
    # 前端文件
    root $FRONTEND_DIR;
    index index.php index.html;
    
    # 日志
    access_log $NGINX_LOG_DIR/access.log;
    error_log $NGINX_LOG_DIR/error.log;
    
    # API代理
    location /api/ {
        proxy_pass http://$BACKEND_HOST:$BACKEND_PORT/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://$BACKEND_HOST:$BACKEND_PORT/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # PHP处理
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    log_success "Nginx配置更新完成"
}

# 更新systemd服务配置
update_systemd_config() {
    log_info "更新systemd服务配置..."
    
    cat > "/etc/systemd/system/ipv6-wireguard-manager.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager API Service
After=network.target mysql.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port $BACKEND_PORT --workers 1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "systemd服务配置更新完成"
}

# 更新前端配置
update_frontend_config() {
    log_info "更新前端配置..."
    
    cat > "$FRONTEND_DIR/config/config.php" << EOF
<?php
/**
 * IPv6 WireGuard Manager 前端配置
 * 自动生成，请勿手动修改
 */

// 应用配置
define('APP_NAME', 'IPv6 WireGuard Manager');
define('APP_VERSION', '3.1.0');
define('APP_ENV', 'production');

// API配置
define('API_BASE_URL', getenv('API_BASE_URL') ?: 'http://' . (\$_SERVER['HTTP_HOST'] ?? 'localhost') . ':$BACKEND_PORT/api/v1');
define('API_TIMEOUT', getenv('API_TIMEOUT') ?: 30);

// WebSocket配置
define('WEBSOCKET_URL', getenv('WEBSOCKET_URL') ?: 'ws://' . (\$_SERVER['HTTP_HOST'] ?? 'localhost') . ':$BACKEND_PORT/ws/');

// 路径配置
define('INSTALL_DIR', '$INSTALL_DIR');
define('FRONTEND_DIR', '$FRONTEND_DIR');
define('WIREGUARD_CONFIG_DIR', '$WIREGUARD_CONFIG_DIR');
define('LOG_DIR', '$LOG_DIR');
define('TEMP_DIR', '$TEMP_DIR');
define('BACKUP_DIR', '$BACKUP_DIR');
define('CACHE_DIR', '$CACHE_DIR');

// 安全配置
define('SESSION_TIMEOUT', $SESSION_TIMEOUT);
define('MAX_LOGIN_ATTEMPTS', $MAX_LOGIN_ATTEMPTS);
define('LOCKOUT_DURATION', $LOCKOUT_DURATION);

// 调试配置
define('DEBUG', false);
define('LOG_LEVEL', 'INFO');
?>
EOF
    
    log_success "前端配置更新完成"
}

# 主函数
main() {
    log_info "开始实施硬编码路径问题改进..."
    
    # 初始化路径配置
    init_path_config
    
    # 验证路径配置
    if validate_path_config; then
        # 应用路径配置
        apply_path_config
        
        log_success "硬编码路径问题改进完成"
        log_info "配置文件位置:"
        log_info "  路径配置: $PATH_CONFIG_FILE"
        log_info "  环境配置: $ENV_CONFIG_FILE"
        log_info "  Nginx配置: $NGINX_CONFIG_DIR/ipv6-wireguard-manager"
        log_info "  前端配置: $FRONTEND_DIR/config/config.php"
    else
        log_error "路径配置验证失败，请检查配置"
        exit 1
    fi
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
