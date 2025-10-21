#!/bin/bash

# IPv6 WireGuard Manager 原生安装脚本
# 支持Linux/Unix系统直接安装，无需Docker

set -e
set -u
set -o pipefail

# 脚本信息
SCRIPT_NAME="IPv6 WireGuard Manager Native Installer"
SCRIPT_VERSION="3.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

# 显示帮助信息
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

用法: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -v, --version           显示版本信息
    -d, --debug             启用调试模式
    -f, --force             强制安装（覆盖现有配置）
    --skip-deps             跳过依赖检查
    --skip-config           跳过配置步骤
    --skip-db               跳过数据库初始化

示例:
    $0                      # 完整安装
    $0 --skip-deps          # 跳过依赖检查
    $0 --skip-config        # 跳过配置步骤

EOF
}

# 显示版本信息
show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "IPv6 WireGuard Manager 原生安装脚本"
    echo "支持Linux/Unix系统直接安装"
}

# 错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "脚本在第 $line_number 行执行失败，退出码: $exit_code"
    log_info "请检查上述错误信息并重试"
    exit $exit_code
}

# 设置错误陷阱
trap 'handle_error $LINENO' ERR

# 解析命令行参数
parse_arguments() {
    DEBUG=false
    FORCE=false
    SKIP_DEPS=false
    SKIP_CONFIG=false
    SKIP_DB=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-config)
                SKIP_CONFIG=true
                shift
                ;;
            --skip-db)
                SKIP_DB=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查操作系统
check_os() {
    log_info "检查操作系统..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_success "检测到Linux系统"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_success "检测到macOS系统"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 检查系统架构
check_architecture() {
    log_info "检查系统架构..."
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            log_success "检测到x86_64架构"
            ;;
        arm64|aarch64)
            log_success "检测到ARM64架构"
            ;;
        *)
            log_warning "未测试的架构: $ARCH"
            ;;
    esac
}

# 检查权限
check_permissions() {
    log_info "检查权限..."
    
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到root权限，建议使用普通用户运行"
    fi
    
    # 检查sudo权限
    if ! sudo -n true 2>/dev/null; then
        log_error "需要sudo权限来安装系统依赖"
        exit 1
    fi
    
    log_success "权限检查通过"
}

# 检测包管理器
detect_package_manager() {
    log_info "检测包管理器..."
    
    if command -v apt-get >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt"
        log_success "检测到APT包管理器"
    elif command -v yum >/dev/null 2>&1; then
        PACKAGE_MANAGER="yum"
        log_success "检测到YUM包管理器"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
        log_success "检测到DNF包管理器"
    elif command -v brew >/dev/null 2>&1; then
        PACKAGE_MANAGER="brew"
        log_success "检测到Homebrew包管理器"
    else
        log_error "未检测到支持的包管理器"
        exit 1
    fi
}

# 安装系统依赖
install_system_dependencies() {
    if [[ "$SKIP_DEPS" == "true" ]]; then
        log_info "跳过依赖安装"
        return 0
    fi
    
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update
            sudo apt install -y \
                python3 python3-pip python3-venv \
                php8.1 php8.1-fpm php8.1-mysql php8.1-curl php8.1-json \
                mysql-server redis-server nginx \
                git curl wget unzip \
                build-essential libssl-dev libffi-dev
            ;;
        yum|dnf)
            sudo $PACKAGE_MANAGER update -y
            sudo $PACKAGE_MANAGER install -y \
                python3 python3-pip \
                php php-fpm php-mysql php-curl php-json \
                mysql-server redis nginx \
                git curl wget unzip \
                gcc gcc-c++ make openssl-devel libffi-devel
            ;;
        brew)
            brew install python@3.9 php mysql redis nginx git
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 启动系统服务
start_system_services() {
    log_info "启动系统服务..."
    
    case $PACKAGE_MANAGER in
        apt|yum|dnf)
            sudo systemctl start mysql redis nginx
            sudo systemctl enable mysql redis nginx
            
            # 启动PHP-FPM
            if command -v php8.1-fpm >/dev/null 2>&1; then
                sudo systemctl start php8.1-fpm
                sudo systemctl enable php8.1-fpm
            elif command -v php-fpm >/dev/null 2>&1; then
                sudo systemctl start php-fpm
                sudo systemctl enable php-fpm
            fi
            ;;
        brew)
            brew services start mysql
            brew services start redis
            brew services start nginx
            ;;
    esac
    
    log_success "系统服务启动完成"
}

# 配置数据库
configure_database() {
    if [[ "$SKIP_DB" == "true" ]]; then
        log_info "跳过数据库配置"
        return 0
    fi
    
    log_info "配置数据库..."
    
    # 检查MySQL是否运行
    if ! sudo systemctl is-active --quiet mysql; then
        log_error "MySQL服务未运行"
        exit 1
    fi
    
    # 创建数据库和用户
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    sudo mysql -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    log_success "数据库配置完成"
}

# 安装Python依赖
install_python_dependencies() {
    log_info "安装Python依赖..."
    
    cd "$PROJECT_ROOT/backend"
    
    # 创建虚拟环境
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    
    # 激活虚拟环境
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    pip install -r requirements.txt
    
    log_success "Python依赖安装完成"
}

# 配置应用
configure_application() {
    if [[ "$SKIP_CONFIG" == "true" ]]; then
        log_info "跳过应用配置"
        return 0
    fi
    
    log_info "配置应用..."
    
    cd "$PROJECT_ROOT"
    
    # 创建环境文件
    if [[ ! -f ".env" ]]; then
        cp env.template .env
        log_info "已创建.env文件，请根据需要修改配置"
    fi
    
    # 设置文件权限
    sudo chown -R www-data:www-data "$PROJECT_ROOT" 2>/dev/null || true
    chmod -R 755 "$PROJECT_ROOT"
    
    log_success "应用配置完成"
}

# 初始化数据库
init_database() {
    if [[ "$SKIP_DB" == "true" ]]; then
        log_info "跳过数据库初始化"
        return 0
    fi
    
    log_info "初始化数据库..."
    
    cd "$PROJECT_ROOT/backend"
    source venv/bin/activate
    
    # 运行数据库迁移
    if command -v alembic >/dev/null 2>&1; then
        alembic upgrade head
    else
        python init_database.py
    fi
    
    log_success "数据库初始化完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置
    sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    server_name localhost;
    root $PROJECT_ROOT/php-frontend;
    index index.php;

    # 前端文件
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # PHP处理
    location ~ \.php\$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # 静态文件
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # 启用站点
    sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    sudo nginx -t
    
    # 重载Nginx
    sudo systemctl reload nginx
    
    log_success "Nginx配置完成"
}

# 创建systemd服务
create_systemd_service() {
    log_info "创建systemd服务..."
    
    sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager API
After=network.target mysql.service redis.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$PROJECT_ROOT/backend
Environment=PATH=$PROJECT_ROOT/backend/venv/bin
ExecStart=$PROJECT_ROOT/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # 重载systemd
    sudo systemctl daemon-reload
    sudo systemctl enable ipv6-wireguard-manager
    
    log_success "systemd服务创建完成"
}

# 启动应用服务
start_application_services() {
    log_info "启动应用服务..."
    
    # 启动应用服务
    sudo systemctl start ipv6-wireguard-manager
    
    # 检查服务状态
    if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "应用服务启动成功"
    else
        log_error "应用服务启动失败"
        sudo systemctl status ipv6-wireguard-manager
        exit 1
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 等待服务启动
    sleep 5
    
    # 检查API健康状态
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        log_success "API服务运行正常"
    else
        log_warning "API服务可能未正常启动"
    fi
    
    # 检查前端访问
    if curl -f http://localhost/ >/dev/null 2>&1; then
        log_success "前端服务运行正常"
    else
        log_warning "前端服务可能未正常启动"
    fi
    
    # 检查数据库连接
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" >/dev/null 2>&1; then
        log_success "数据库连接正常"
    else
        log_warning "数据库连接可能有问题"
    fi
    
    log_success "安装验证完成"
}

# 显示安装信息
show_installation_info() {
    log_info "安装完成！"
    echo ""
    echo "🌐 访问信息:"
    echo "  前端界面: http://localhost"
    echo "  API接口: http://localhost:8000"
    echo "  健康检查: http://localhost:8000/health"
    echo ""
    echo "🔧 服务管理:"
    echo "  启动服务: sudo systemctl start ipv6-wireguard-manager"
    echo "  停止服务: sudo systemctl stop ipv6-wireguard-manager"
    echo "  重启服务: sudo systemctl restart ipv6-wireguard-manager"
    echo "  查看状态: sudo systemctl status ipv6-wireguard-manager"
    echo ""
    echo "📊 日志查看:"
    echo "  应用日志: sudo journalctl -u ipv6-wireguard-manager -f"
    echo "  Nginx日志: sudo tail -f /var/log/nginx/access.log"
    echo "  错误日志: sudo tail -f /var/log/nginx/error.log"
    echo ""
    echo "📚 文档:"
    echo "  安装指南: docs/NATIVE_INSTALLATION_GUIDE.md"
    echo "  部署指南: docs/DEPLOYMENT_GUIDE.md"
    echo "  故障排除: docs/TROUBLESHOOTING_GUIDE.md"
    echo ""
    echo "🎉 安装完成！请访问 http://localhost 开始使用"
}

# 主函数
main() {
    log_info "开始IPv6 WireGuard Manager原生安装..."
    
    # 解析参数
    parse_arguments "$@"
    
    # 检查环境
    check_os
    check_architecture
    check_permissions
    detect_package_manager
    
    # 安装依赖
    install_system_dependencies
    start_system_services
    configure_database
    install_python_dependencies
    
    # 配置应用
    configure_application
    init_database
    configure_nginx
    create_systemd_service
    
    # 启动服务
    start_application_services
    
    # 验证安装
    verify_installation
    
    # 显示信息
    show_installation_info
}

# 运行主函数
main "$@"
