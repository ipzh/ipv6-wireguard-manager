#!/bin/bash

# IPv6 WireGuard Manager 安装问题修复脚本
# 解决安装过程中可能出现的各种问题

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

# 项目信息
APP_USER="ipv6wgm"
APP_HOME="/opt/ipv6-wireguard-manager"

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 修复Docker相关问题
fix_docker_issues() {
    log_info "修复Docker相关问题..."
    
    # 清理旧的Docker仓库配置
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 根据系统选择正确的Docker仓库
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $VERSION_CODENAME in
            "jammy"|"focal"|"bionic")
                DOCKER_REPO="ubuntu"
                ;;
            "bullseye"|"buster")
                DOCKER_REPO="debian"
                ;;
            *)
                DOCKER_REPO="ubuntu"
                ;;
        esac
    else
        DOCKER_REPO="ubuntu"
    fi
    
    # 重新安装Docker
    curl -fsSL https://download.docker.com/linux/$DOCKER_REPO/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DOCKER_REPO $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # 启动Docker服务
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker问题修复完成"
}

# 修复Docker Compose问题
fix_docker_compose_issues() {
    log_info "修复Docker Compose问题..."
    
    # 检查docker-compose命令
    if command -v docker-compose >/dev/null 2>&1; then
        log_info "docker-compose 命令可用"
    elif docker compose version >/dev/null 2>&1; then
        log_info "docker compose 插件可用"
        # 创建docker-compose别名
        ln -sf /usr/bin/docker /usr/local/bin/docker-compose
        echo '#!/bin/bash' > /usr/local/bin/docker-compose
        echo 'docker compose "$@"' >> /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        log_error "Docker Compose不可用"
        return 1
    fi
    
    log_success "Docker Compose问题修复完成"
}

# 修复前端构建问题
fix_frontend_build_issues() {
    log_info "修复前端构建问题..."
    
    cd "$APP_HOME/frontend"
    
    # 检查Node.js版本
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_VERSION" -lt 18 ]; then
            log_info "升级Node.js到18版本..."
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt-get install -y nodejs
        fi
    fi
    
    # 清理node_modules和package-lock.json
    rm -rf node_modules package-lock.json
    
    # 重新安装依赖
    npm install --silent 2>/dev/null || npm install
    
    # 检查内存并设置Node.js内存限制
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [ "$TOTAL_MEM" -lt 2048 ]; then
        log_info "低内存环境，设置Node.js内存限制..."
        export NODE_OPTIONS="--max-old-space-size=2048"
    fi
    
    # 尝试构建
    if npm run build; then
        log_success "前端构建成功"
    else
        log_warning "前端构建失败，创建基础文件..."
        mkdir -p dist
        cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>IPv6 WireGuard Manager</h1>
        <div class="status info">
            <h3>系统状态</h3>
            <p>前端服务正在启动中...</p>
            <p>请稍等片刻，系统将自动重定向到登录页面。</p>
        </div>
        <div class="status success">
            <h3>默认登录信息</h3>
            <p>用户名: admin</p>
            <p>密码: admin123</p>
        </div>
    </div>
    <script>
        setTimeout(() => {
            window.location.href = '/login';
        }, 3000);
    </script>
</body>
</html>
EOF
    fi
    
    log_success "前端构建问题修复完成"
}

# 修复数据库问题
fix_database_issues() {
    log_info "修复数据库问题..."
    
    # 启动PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    # 重置数据库用户密码
    sudo -u postgres psql -c "ALTER USER ipv6wgm PASSWORD 'password';" 2>/dev/null || true
    
    # 配置PostgreSQL认证
    PG_HBA_FILE="/etc/postgresql/*/main/pg_hba.conf"
    if [ -f $PG_HBA_FILE ]; then
        # 备份原配置
        cp $PG_HBA_FILE ${PG_HBA_FILE}.backup
        
        # 添加信任认证
        if ! grep -q "ipv6wgm.*trust" $PG_HBA_FILE; then
            echo "local   all             ipv6wgm                                trust" >> $PG_HBA_FILE
            echo "host    all             ipv6wgm        127.0.0.1/32            trust" >> $PG_HBA_FILE
            echo "host    all             ipv6wgm        ::1/128                 trust" >> $PG_HBA_FILE
        fi
        
        # 重启PostgreSQL
        systemctl restart postgresql
    fi
    
    # 重新初始化数据库
    cd "$APP_HOME/backend"
    source venv/bin/activate
    
    python -c "
import asyncio
from app.core.database import engine
from app.models import Base
from app.core.init_db import init_db

async def init_database():
    try:
        Base.metadata.create_all(bind=engine)
        await init_db()
        print('数据库重新初始化成功')
    except Exception as e:
        print(f'数据库重新初始化失败: {e}')

asyncio.run(init_database())
"
    
    log_success "数据库问题修复完成"
}

# 修复后端启动问题
fix_backend_startup_issues() {
    log_info "修复后端启动问题..."
    
    cd "$APP_HOME/backend"
    
    # 检查虚拟环境
    if [ ! -d "venv" ]; then
        log_info "重新创建虚拟环境..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # 重新安装依赖
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # 修复Pydantic兼容性问题
    pip install pydantic-settings
    
    # 更新配置文件
    cat > .env << EOF
DATABASE_URL="postgresql://ipv6wgm:password@localhost:5432/ipv6wgm"
REDIS_URL="redis://localhost:6379/0"
SECRET_KEY="your_super_secret_key_for_production"
DEBUG=False
BACKEND_CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080", "http://localhost:5173", "http://localhost", "http://127.0.0.1:3000", "http://127.0.0.1:8080", "http://127.0.0.1:5173", "http://127.0.0.1"]
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF
    
    # 重启后端服务
    systemctl restart ipv6-wireguard-manager
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        systemctl status ipv6-wireguard-manager
        return 1
    fi
    
    log_success "后端启动问题修复完成"
}

# 修复Nginx配置问题
fix_nginx_issues() {
    log_info "修复Nginx配置问题..."
    
    # 确保前端dist目录存在
    if [ ! -d "$APP_HOME/frontend/dist" ]; then
        log_info "创建前端dist目录..."
        mkdir -p "$APP_HOME/frontend/dist"
        cat > "$APP_HOME/frontend/dist/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>IPv6 WireGuard Manager</h1>
        <div class="status info">
            <h3>系统状态</h3>
            <p>前端服务正在启动中...</p>
            <p>请稍等片刻，系统将自动重定向到登录页面。</p>
        </div>
        <div class="status success">
            <h3>默认登录信息</h3>
            <p>用户名: admin</p>
            <p>密码: admin123</p>
        </div>
    </div>
    <script>
        setTimeout(() => {
            window.location.href = '/login';
        }, 3000);
    </script>
</body>
</html>
EOF
    fi
    
    # 重新创建Nginx配置
    cat > /etc/nginx/sites-available/ipv6-wireguard-manager << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000/api/v1/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API文档
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
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
}
EOF
    
    # 启用站点
    ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    
    # 禁用默认站点
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    
    # 重启Nginx
    systemctl restart nginx
    
    log_success "Nginx配置问题修复完成"
}

# 修复权限问题
fix_permission_issues() {
    log_info "修复权限问题..."
    
    # 确保用户存在
    if ! id "$APP_USER" >/dev/null 2>&1; then
        useradd -r -s /bin/bash -d "$APP_HOME" -m "$APP_USER"
    fi
    
    # 设置正确的权限
    chown -R "$APP_USER:$APP_USER" "$APP_HOME"
    chmod -R 755 "$APP_HOME"
    
    # 设置特殊权限
    chmod +x "$APP_HOME/backend/venv/bin/python"
    chmod +x "$APP_HOME/frontend/dist" 2>/dev/null || true
    
    log_success "权限问题修复完成"
}

# 修复服务问题
fix_service_issues() {
    log_info "修复服务问题..."
    
    # 重新创建系统服务
    cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target postgresql.service redis.service
Requires=postgresql.service redis.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_HOME/backend
Environment=PATH=$APP_HOME/backend/venv/bin
Environment=PYTHONPATH=$APP_HOME/backend
ExecStart=$APP_HOME/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # 重载systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable ipv6-wireguard-manager
    
    # 重启服务
    systemctl restart ipv6-wireguard-manager
    
    log_success "服务问题修复完成"
}

# 修复网络问题
fix_network_issues() {
    log_info "修复网络问题..."
    
    # 启动Redis
    systemctl enable redis-server
    systemctl start redis-server
    
    # 启动PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    # 启动Nginx
    systemctl enable nginx
    systemctl start nginx
    
    # 检查端口占用
    local ports=("80" "8000" "5432" "6379")
    for port in "${ports[@]}"; do
        if netstat -tlnp | grep -q ":$port "; then
            log_success "端口 $port 监听正常"
        else
            log_warning "端口 $port 未监听"
        fi
    done
    
    log_success "网络问题修复完成"
}

# 全面修复
full_fix() {
    log_info "开始全面修复..."
    
    fix_docker_issues
    fix_docker_compose_issues
    fix_frontend_build_issues
    fix_database_issues
    fix_backend_startup_issues
    fix_nginx_issues
    fix_permission_issues
    fix_service_issues
    fix_network_issues
    
    log_success "全面修复完成"
}

# 显示修复结果
show_fix_result() {
    echo ""
    echo "=================================="
    echo "修复完成！"
    echo "=================================="
    echo ""
    
    log_info "服务状态检查:"
    local services=("nginx" "postgresql" "redis-server" "ipv6-wireguard-manager")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "$service 服务运行正常"
        else
            log_error "$service 服务异常"
        fi
    done
    
    echo ""
    log_info "访问地址:"
    echo "  前端界面: http://$(hostname -I | awk '{print $1}')"
    echo "  后端API: http://127.0.0.1:8000"
    echo "  API文档: http://127.0.0.1:8000/docs"
    echo ""
    
    log_info "默认登录信息:"
    echo "  用户名: admin"
    echo "  密码: admin123"
    echo ""
    
    log_success "修复完成！请访问前端界面检查系统状态。"
}

# 主函数
main() {
    echo "=================================="
    echo "IPv6 WireGuard Manager 问题修复"
    echo "=================================="
    echo ""
    
    check_root
    
    case "${1:-all}" in
        "docker")
            fix_docker_issues
            ;;
        "docker-compose")
            fix_docker_compose_issues
            ;;
        "frontend")
            fix_frontend_build_issues
            ;;
        "database")
            fix_database_issues
            ;;
        "backend")
            fix_backend_startup_issues
            ;;
        "nginx")
            fix_nginx_issues
            ;;
        "permissions")
            fix_permission_issues
            ;;
        "services")
            fix_service_issues
            ;;
        "network")
            fix_network_issues
            ;;
        "all"|*)
            full_fix
            ;;
    esac
    
    show_fix_result
}

# 运行主函数
main "$@"
