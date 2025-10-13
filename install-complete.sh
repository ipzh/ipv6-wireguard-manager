#!/bin/bash

# IPv6 WireGuard Manager - 完整安装脚本
# 支持 Docker、原生和低内存安装方式

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 解析命令行参数
parse_arguments() {
    local install_type="native"
    local install_dir="/opt/ipv6-wireguard-manager"
    local port="80"
    local silent=false
    local performance=false
    local production=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker|native|low-memory)
                install_type="$1"
                shift
                ;;
            --dir)
                install_dir="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --silent)
                silent=true
                shift
                ;;
            --performance)
                performance=true
                shift
                ;;
            --production)
                production=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    echo "$install_type|$install_dir|$port|$silent|$performance|$production"
}

# 解析参数
args=$(parse_arguments "$@")
IFS='|' read -r INSTALL_TYPE INSTALL_DIR PORT SILENT PERFORMANCE PRODUCTION <<< "$args"

log_info "IPv6 WireGuard Manager 完整安装脚本"
log_info "安装类型: $INSTALL_TYPE"
log_info "安装目录: $INSTALL_DIR"
log_info "端口: $PORT"
log_info "静默模式: $SILENT"
log_info "性能优化: $PERFORMANCE"
log_info "生产模式: $PRODUCTION"

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "不支持的操作系统"
        exit 1
    fi
    
    source /etc/os-release
    log_info "检测到操作系统: $NAME $VERSION"
    
    # 检查内存
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    log_info "系统内存: ${memory_mb}MB"
    
    if [ "$memory_mb" -lt 512 ]; then
        log_error "系统内存不足，至少需要512MB"
        exit 1
    fi
    
    # 检查磁盘空间
    local disk_space=$(df / | awk 'NR==2{print $4}')
    local disk_space_mb=$((disk_space / 1024))
    log_info "可用磁盘空间: ${disk_space_mb}MB"
    
    if [ "$disk_space_mb" -lt 1024 ]; then
        log_error "磁盘空间不足，至少需要1GB"
        exit 1
    fi
    
    log_success "系统要求检查通过"
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    # 更新包列表
    apt-get update -y
    
    # 安装基础依赖
    apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    # 根据安装类型安装额外依赖
    case $INSTALL_TYPE in
        "docker")
            install_docker_dependencies
            ;;
        "native")
            install_native_dependencies
            ;;
        "low-memory")
            install_low_memory_dependencies
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 安装Docker依赖
install_docker_dependencies() {
    log_info "安装Docker依赖..."
    
    # 安装Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
        rm get-docker.sh
    fi
    
    # 安装Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    log_success "Docker依赖安装完成"
}

# 安装原生依赖
install_native_dependencies() {
    log_info "安装原生依赖..."
    
    # 安装Python 3.11
    if ! command -v python3.11 &> /dev/null; then
        add-apt-repository ppa:deadsnakes/ppa -y
        apt-get update
        apt-get install -y python3.11 python3.11-venv python3.11-dev
    fi
    
    # 安装Node.js 18
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # 安装PostgreSQL
    if ! command -v psql &> /dev/null; then
        apt-get install -y postgresql postgresql-contrib
        systemctl enable postgresql
        systemctl start postgresql
    fi
    
    # 安装Redis
    if ! command -v redis-server &> /dev/null; then
        apt-get install -y redis-server
        systemctl enable redis-server
        systemctl start redis-server
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
        systemctl enable nginx
        systemctl start nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        apt-get install -y wireguard
    fi
    
    log_success "原生依赖安装完成"
}

# 安装低内存依赖
install_low_memory_dependencies() {
    log_info "安装低内存依赖..."
    
    # 安装Python 3.11
    if ! command -v python3.11 &> /dev/null; then
        add-apt-repository ppa:deadsnakes/ppa -y
        apt-get update
        apt-get install -y python3.11 python3.11-venv python3.11-dev
    fi
    
    # 安装Node.js 18
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # 安装PostgreSQL（低内存优化配置）
    if ! command -v psql &> /dev/null; then
        apt-get install -y postgresql postgresql-contrib
        systemctl enable postgresql
        systemctl start postgresql
    fi
    
    # 安装Nginx
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
        systemctl enable nginx
        systemctl start nginx
    fi
    
    # 安装WireGuard
    if ! command -v wg &> /dev/null; then
        apt-get install -y wireguard
    fi
    
    log_success "低内存依赖安装完成"
}

# 下载项目代码
download_project() {
    log_info "下载项目代码..."
    
    local project_dir="$INSTALL_DIR"
    
    # 创建项目目录
    mkdir -p $project_dir
    cd $project_dir
    
    # 下载项目代码
    if [ -d ".git" ]; then
        log_info "更新现有代码..."
        git pull origin main
    else
        log_info "克隆项目代码..."
        git clone https://github.com/ipzh/ipv6-wireguard-manager.git .
    fi
    
    log_success "项目代码下载完成"
}

# 配置数据库
setup_database() {
    log_info "配置数据库..."
    
    case $INSTALL_TYPE in
        "docker")
            # Docker模式需要确保PostgreSQL容器正确启动
            setup_docker_postgresql
            ;;
        "native")
            setup_postgresql
            ;;
        "low-memory")
            setup_postgresql_low_memory
            ;;
    esac
    
    log_success "数据库配置完成"
}

# 配置Docker模式下的PostgreSQL
setup_docker_postgresql() {
    log_info "配置Docker模式下的PostgreSQL..."
    
    cd $INSTALL_DIR
    
    # 检查Docker Compose文件是否存在
    if [ ! -f "docker-compose.production.yml" ]; then
        log_error "Docker Compose文件不存在"
        exit 1
    fi
    
    # 启动PostgreSQL容器
    log_info "启动PostgreSQL容器..."
    docker-compose -f docker-compose.production.yml up -d postgres
    
    # 等待PostgreSQL服务启动
    log_info "等待PostgreSQL服务启动..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U ipv6wgm -d ipv6wgm; then
            log_success "PostgreSQL服务已启动"
            break
        fi
        
        log_info "等待PostgreSQL启动... (尝试 $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "PostgreSQL服务启动超时"
        exit 1
    fi
    
    # 初始化数据库
    log_info "初始化PostgreSQL数据库..."
    
    # 等待数据库完全就绪
    sleep 5
    
    # 检查数据库是否已存在
    if docker-compose -f docker-compose.production.yml exec -T postgres psql -U ipv6wgm -d ipv6wgm -c "SELECT 1;" &> /dev/null; then
        log_warning "数据库 ipv6wgm 已存在，跳过创建"
    else
        # 创建数据库（如果不存在）
        docker-compose -f docker-compose.production.yml exec -T postgres createdb -U ipv6wgm ipv6wgm || true
    fi
    
    log_success "Docker模式下的PostgreSQL配置完成"
}

# 配置PostgreSQL
setup_postgresql() {
    log_info "配置PostgreSQL..."
    
    # 检查数据库是否已存在
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ipv6wgm; then
        log_warning "数据库 ipv6wgm 已存在，跳过创建"
    else
        # 创建数据库
        sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;"
    fi
    
    # 检查用户是否已存在
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='ipv6wgm';" | grep -q 1; then
        log_warning "用户 ipv6wgm 已存在，跳过创建"
    else
        # 创建用户
        sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'ipv6wgm123';"
    fi
    
    # 授予权限
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;"
    
    log_success "PostgreSQL配置完成"
}

# 配置低内存模式的PostgreSQL
setup_postgresql_low_memory() {
    log_info "配置低内存模式的PostgreSQL..."
    
    # 检查数据库是否已存在
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ipv6wgm; then
        log_warning "数据库 ipv6wgm 已存在，跳过创建"
    else
        # 创建数据库
        sudo -u postgres psql -c "CREATE DATABASE ipv6wgm;"
    fi
    
    # 检查用户是否已存在
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='ipv6wgm';" | grep -q 1; then
        log_warning "用户 ipv6wgm 已存在，跳过创建"
    else
        # 创建用户
        sudo -u postgres psql -c "CREATE USER ipv6wgm WITH PASSWORD 'ipv6wgm123';"
    fi
    
    # 授予权限
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;"
    
    # 优化PostgreSQL配置以适应低内存环境
    optimize_postgresql_low_memory
    
    log_success "低内存模式PostgreSQL配置完成"
}

# 优化PostgreSQL低内存配置
optimize_postgresql_low_memory() {
    log_info "优化PostgreSQL低内存配置..."
    
    # 查找PostgreSQL配置目录
    local postgresql_conf_dir=$(find /etc/postgresql -name "postgresql.conf" -type f | head -1 | xargs dirname 2>/dev/null || echo "")
    
    if [ -z "$postgresql_conf_dir" ]; then
        log_warning "未找到PostgreSQL配置文件，跳过优化配置"
        return 0
    fi
    
    # 备份原始配置
    cp "$postgresql_conf_dir/postgresql.conf" "$postgresql_conf_dir/postgresql.conf.backup"
    
    # 应用低内存优化配置
    cat >> "$postgresql_conf_dir/postgresql.conf" << 'EOF'

# IPv6 WireGuard Manager 低内存优化配置
shared_buffers = 64MB
work_mem = 4MB
maintenance_work_mem = 32MB
effective_cache_size = 128MB
max_connections = 50
random_page_cost = 1.1
effective_io_concurrency = 2
max_wal_size = 1GB
min_wal_size = 80MB
checkpoint_completion_target = 0.5
wal_buffers = 4MB
default_statistics_target = 100
EOF
    
    # 重启PostgreSQL以应用配置
    systemctl restart postgresql
    
    log_success "PostgreSQL低内存优化配置完成"
}

# 安装后端
install_backend() {
    log_info "安装后端..."
    
    cd /opt/ipv6-wireguard-manager/backend
    
    # 强制安装python3-venv包（确保虚拟环境创建成功）
    log_info "确保python3-venv包已安装..."
    apt-get update -y
    apt-get install -y python3.11-venv
    log_success "python3-venv包安装完成"
    
    # 创建虚拟环境
    python3.11 -m venv venv
    source venv/bin/activate
    
    # 安装Python依赖
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # 设置环境变量
    case $INSTALL_TYPE in
        "docker")
            export DATABASE_URL="postgresql://ipv6wgm:ipv6wgm123@postgres:5432/ipv6wgm"
            export REDIS_URL="redis://redis:6379/0"
            ;;
        *)
            # 原生模式和低内存模式都使用本地PostgreSQL
            export DATABASE_URL="postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6_wireguard_manager"
            export REDIS_URL="redis://localhost:6379/0"
            ;;
    esac
    
    export SECRET_KEY="your-secret-key-change-this-in-production"
    export DEBUG=false
    export LOG_LEVEL=INFO
    
    # 初始化数据库
    python -c "
from app.core.database import init_db
import asyncio
asyncio.run(init_db())
print('数据库初始化完成')
"
    
    log_success "后端安装完成"
}

# 安装前端
install_frontend() {
    log_info "安装前端..."
    
    cd /opt/ipv6-wireguard-manager/frontend
    
    # 安装Node.js依赖
    npm install
    
    # 构建前端
    npm run build
    
    log_success "前端安装完成"
}

# 配置Nginx
setup_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置
    cat > /etc/nginx/sites-available/ipv6-wireguard-manager << 'EOF'
server {
    listen 80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket支持
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
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    
    # 重启Nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 创建系统服务
create_systemd_service() {
    log_info "创建系统服务..."
    
    # 创建服务文件
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/backend/venv/bin
Environment=DATABASE_URL=postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6wgm
Environment=REDIS_URL=redis://localhost:6379/0
Environment=SECRET_KEY=your-secret-key-change-this-in-production
Environment=DEBUG=false
Environment=LOG_LEVEL=INFO
ExecStart=$INSTALL_DIR/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # 重载systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable ipv6-wireguard-manager
    
    # 启动服务
    systemctl start ipv6-wireguard-manager
    
    log_success "系统服务创建完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    # 检查ufw是否安装
    if command -v ufw &> /dev/null; then
        # 允许HTTP和HTTPS
        ufw allow $PORT/tcp
        ufw allow 443/tcp
        
        # 允许WireGuard端口
        ufw allow 51820/udp
        
        # 允许SSH（如果ufw是活跃的）
        if ufw status | grep -q "Status: active"; then
            ufw allow ssh
        fi
        
        log_success "防火墙配置完成"
    else
        log_warning "ufw未安装，跳过防火墙配置"
    fi
}

# 性能优化配置
setup_performance_optimizations() {
    if [ "$PERFORMANCE" = true ]; then
        log_info "配置性能优化..."
        
        # 优化内核参数
        cat >> /etc/sysctl.conf << 'EOF'
# IPv6 WireGuard Manager 性能优化
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
EOF
        
        # 应用内核参数
        sysctl -p
        
        # 优化Nginx配置
        cat >> /etc/nginx/nginx.conf << 'EOF'
# 性能优化配置
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
EOF
        
        log_success "性能优化配置完成"
    fi
}

# 生产环境配置
setup_production_config() {
    if [ "$PRODUCTION" = true ]; then
        log_info "配置生产环境..."
        
        # 安装监控工具
        apt-get install -y htop iotop nethogs
        
        # 配置日志轮转
        cat > /etc/logrotate.d/ipv6-wireguard-manager << EOF
$INSTALL_DIR/backend/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload ipv6-wireguard-manager
    endscript
}
EOF
        
        # 配置自动备份
        cat > /etc/cron.daily/ipv6-wireguard-backup << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/ipv6-wireguard-manager"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)

# 备份数据库
pg_dump ipv6_wireguard_manager > $BACKUP_DIR/db_$DATE.sql

# 备份配置文件
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/ipv6-wireguard-manager/backend/app/core /etc/nginx/sites-available/ipv6-wireguard-manager

# 清理旧备份（保留30天）
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF
        
        chmod +x /etc/cron.daily/ipv6-wireguard-backup
        
        log_success "生产环境配置完成"
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 等待服务启动
    sleep 10
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务运行正常"
    else
        log_error "后端服务启动失败"
        systemctl status ipv6-wireguard-manager --no-pager
        return 1
    fi
    
    # 检查Nginx状态
    if systemctl is-active --quiet nginx; then
        log_success "Nginx服务运行正常"
    else
        log_error "Nginx服务启动失败"
        return 1
    fi
    
    # 检查端口监听
    if netstat -tlnp | grep -q ":$PORT "; then
        log_success "端口$PORT监听正常"
    else
        log_error "端口$PORT未监听"
        return 1
    fi
    
    if netstat -tlnp | grep -q ":8000 "; then
        log_success "端口8000监听正常"
    else
        log_error "端口8000未监听"
        return 1
    fi
    
    # 测试API
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log_success "后端API响应正常"
    else
        log_error "后端API响应失败"
        return 1
    fi
    
    log_success "安装验证通过"
}

# 显示安装结果
show_installation_result() {
    log_success "🎉 IPv6 WireGuard Manager 安装完成！"
    
    # 获取服务器IP
    local server_ip=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    local ipv6_ip=$(ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1)
    
    echo ""
    log_info "访问信息:"
    if [ "$PORT" = "80" ]; then
        echo "  前端界面: http://$server_ip"
        if [ -n "$ipv6_ip" ]; then
            echo "  IPv6访问: http://[$ipv6_ip]"
        fi
        echo "  API文档: http://$server_ip/docs"
    else
        echo "  前端界面: http://$server_ip:$PORT"
        if [ -n "$ipv6_ip" ]; then
            echo "  IPv6访问: http://[$ipv6_ip]:$PORT"
        fi
        echo "  API文档: http://$server_ip:$PORT/docs"
    fi
    
    echo ""
    log_info "默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    
    echo ""
    log_info "配置文件位置:"
    echo "  应用目录: $INSTALL_DIR"
    echo "  Nginx配置: /etc/nginx/sites-available/ipv6-wireguard-manager"
    echo "  服务配置: /etc/systemd/system/ipv6-wireguard-manager.service"
    
    echo ""
    log_success "安装完成！请访问前端界面开始使用。"
}

# Docker安装
install_docker() {
    log_info "开始Docker安装..."
    
    check_system_requirements
    install_system_dependencies
    download_project
    setup_database  # 配置数据库（包括PostgreSQL容器启动）
    setup_firewall
    
    # 启动完整的Docker服务栈
    cd /opt/ipv6-wireguard-manager
    log_info "启动完整的Docker服务栈..."
    docker-compose -f docker-compose.production.yml up -d
    
    # 等待服务启动
    log_info "等待Docker服务启动..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
            log_success "Docker服务启动成功"
            break
        fi
        
        log_info "等待Docker服务启动... (尝试 $attempt/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "Docker服务启动超时"
        docker-compose -f docker-compose.production.yml logs
        exit 1
    fi
    
    # 验证安装
    log_info "验证Docker安装..."
    
    # 检查后端服务
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log_success "后端API响应正常"
    else
        log_error "后端API响应失败"
        docker-compose -f docker-compose.production.yml logs backend
        exit 1
    fi
    
    # 检查前端服务
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log_success "前端服务响应正常"
    else
        log_error "前端服务响应失败"
        docker-compose -f docker-compose.production.yml logs frontend
        exit 1
    fi
    
    show_installation_result
}

# 原生安装
install_native() {
    log_info "开始原生安装..."
    
    check_system_requirements
    install_system_dependencies
    download_project
    setup_database
    install_backend
    install_frontend
    setup_nginx
    create_systemd_service
    setup_firewall
    setup_performance_optimizations
    setup_production_config
    verify_installation
    show_installation_result
}

# 低内存安装
install_low_memory() {
    log_info "开始低内存安装..."
    
    check_system_requirements
    install_system_dependencies
    download_project
    setup_database  # 配置数据库（SQLite）
    install_backend
    install_frontend
    setup_nginx
    create_systemd_service
    setup_firewall
    setup_performance_optimizations
    setup_production_config
    verify_installation
    show_installation_result
}

# 主安装函数
main() {
    case $INSTALL_TYPE in
        "docker")
            install_docker
            ;;
        "native")
            install_native
            ;;
        "low-memory")
            install_low_memory
            ;;
        *)
            log_error "不支持的安装类型: $INSTALL_TYPE"
            exit 1
            ;;
    esac
}

# 运行主函数
main
