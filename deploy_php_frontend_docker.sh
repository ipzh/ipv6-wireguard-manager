#!/bin/bash

# Docker环境下的PHP前端部署脚本
# 用于Docker安装模式下的PHP前端部署

set -euo pipefail

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

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 默认配置
WEB_PORT=${WEB_PORT:-80}
NGINX_CONFIG_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
PHP_VERSION=${PHP_VERSION:-8.1}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 安装PHP和Nginx
install_php_nginx() {
    log_info "安装PHP和Nginx..."
    
    # 更新包索引
    apt-get update
    
    # 安装PHP和扩展
    apt-get install -y nginx \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl
    
    # 启动PHP-FPM
    systemctl enable php${PHP_VERSION}-fpm
    systemctl start php${PHP_VERSION}-fpm
    
    # 启动Nginx
    systemctl enable nginx
    systemctl start nginx
    
    log_success "PHP和Nginx安装完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置文件
    cat > "${NGINX_CONFIG_DIR}/ipv6-wireguard-manager" << EOF
server {
    listen ${WEB_PORT};
    listen [::]:${WEB_PORT};
    server_name _;
    
    root ${PROJECT_DIR}/frontend;
    index index.php index.html;
    
    # 日志
    access_log /var/log/nginx/ipv6wgm_access.log;
    error_log /var/log/nginx/ipv6wgm_error.log;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # PHP处理
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    # API代理到Docker容器
    location /api/ {
        proxy_pass http://localhost:${API_PORT:-8000}/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 拒绝访问隐藏文件
    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    # 启用站点
    ln -sf "${NGINX_CONFIG_DIR}/ipv6-wireguard-manager" "${NGINX_ENABLED_DIR}/"
    
    # 删除默认站点
    rm -f "${NGINX_ENABLED_DIR}/default"
    
    # 测试Nginx配置
    nginx -t
    
    # 重启Nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 部署PHP前端
deploy_frontend() {
    log_info "部署PHP前端..."
    
    # 创建前端目录
    mkdir -p "${PROJECT_DIR}/frontend"
    
    # 复制前端文件
    if [[ -d "${PROJECT_DIR}/frontend_src" ]]; then
        cp -r "${PROJECT_DIR}/frontend_src/"* "${PROJECT_DIR}/frontend/"
    else
        # 创建基本的前端文件
        create_basic_frontend
    fi
    
    # 设置权限
    chown -R www-data:www-data "${PROJECT_DIR}/frontend"
    chmod -R 755 "${PROJECT_DIR}/frontend"
    
    log_success "PHP前端部署完成"
}

# 创建基本的前端文件
create_basic_frontend() {
    log_info "创建基本的前端文件..."
    
    # 创建index.php
    cat > "${PROJECT_DIR}/frontend/index.php" << 'EOF'
<?php
// IPv6 WireGuard Manager - 前端入口文件

// 配置
$apiUrl = 'http://localhost:' . ($_ENV['API_PORT'] ?? '8000') . '/api/v1';
$webPort = $_ENV['WEB_PORT'] ?? '80';

// 获取API状态
function getApiStatus($url) {
    $context = stream_context_create([
        'http' => [
            'timeout' => 5,
            'method' => 'GET'
        ]
    ]);
    
    $response = @file_get_contents($url . '/health', false, $context);
    return $response !== false;
}

$apiStatus = getApiStatus($apiUrl);
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            border-radius: 10px;
            margin-bottom: 2rem;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
        }
        
        .status {
            display: flex;
            justify-content: center;
            margin-bottom: 2rem;
        }
        
        .status-card {
            background: white;
            border-radius: 10px;
            padding: 1.5rem;
            margin: 0 1rem;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            text-align: center;
            min-width: 200px;
        }
        
        .status-card h3 {
            margin-bottom: 1rem;
            color: #333;
        }
        
        .status-indicator {
            display: inline-block;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            margin-right: 0.5rem;
        }
        
        .status-online {
            background-color: #28a745;
        }
        
        .status-offline {
            background-color: #dc3545;
        }
        
        .info-section {
            background: white;
            border-radius: 10px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .info-section h2 {
            margin-bottom: 1rem;
            color: #333;
        }
        
        .info-section p {
            margin-bottom: 1rem;
        }
        
        .btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 0.75rem 1.5rem;
            border-radius: 5px;
            text-decoration: none;
            margin-right: 1rem;
            margin-bottom: 1rem;
            transition: background 0.3s;
        }
        
        .btn:hover {
            background: #5a6fd8;
        }
        
        .footer {
            text-align: center;
            padding: 2rem;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>IPv6 WireGuard Manager</h1>
            <p>管理您的IPv6网络和WireGuard配置</p>
        </div>
        
        <div class="status">
            <div class="status-card">
                <h3>前端状态</h3>
                <p><span class="status-indicator status-online"></span>在线</p>
            </div>
            <div class="status-card">
                <h3>API状态</h3>
                <p>
                    <span class="status-indicator <?php echo $apiStatus ? 'status-online' : 'status-offline'; ?>"></span>
                    <?php echo $apiStatus ? '在线' : '离线'; ?>
                </p>
            </div>
        </div>
        
        <div class="info-section">
            <h2>欢迎使用IPv6 WireGuard Manager</h2>
            <p>这是一个用于管理IPv6网络和WireGuard配置的工具。</p>
            <p>您可以通过以下方式访问系统功能：</p>
            <div>
                <a href="<?php echo $apiUrl; ?>/docs" class="btn" target="_blank">API文档</a>
                <a href="<?php echo $apiUrl; ?>/admin" class="btn" target="_blank">管理面板</a>
            </div>
        </div>
        
        <div class="info-section">
            <h2>系统信息</h2>
            <p><strong>Web端口:</strong> <?php echo $webPort; ?></p>
            <p><strong>API端口:</strong> <?php echo $_ENV['API_PORT'] ?? '8000'; ?></p>
            <p><strong>安装类型:</strong> Docker</p>
        </div>
        
        <div class="footer">
            <p>&copy; <?php echo date('Y'); ?> IPv6 WireGuard Manager</p>
        </div>
    </div>
</body>
</html>
EOF
    
    log_success "基本前端文件创建完成"
}

# 主函数
main() {
    log_info "Docker环境下的PHP前端部署开始..."
    
    # 检查root权限
    check_root
    
    # 安装PHP和Nginx
    install_php_nginx
    
    # 配置Nginx
    configure_nginx
    
    # 部署前端
    deploy_frontend
    
    log_success "Docker环境下的PHP前端部署完成！"
    echo ""
    log_info "访问地址: http://localhost:${WEB_PORT}"
}

# 执行主函数
main "$@"