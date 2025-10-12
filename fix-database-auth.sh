#!/bin/bash

echo "🔍 修复PostgreSQL密码认证失败问题..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$APP_HOME/backend"
SERVICE_NAME="ipv6-wireguard-manager"
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASSWORD="ipv6wgm"

# 日志函数
log_step() {
    echo -e "${BLUE}🚀 [STEP] $1${NC}"
}

log_info() {
    echo -e "${BLUE}💡 [INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}❌ [ERROR] $1${NC}"
}

# 1. 检查PostgreSQL服务状态
log_step "检查PostgreSQL服务状态..."
if systemctl is-active --quiet postgresql; then
    log_success "PostgreSQL服务正在运行"
else
    log_warning "PostgreSQL服务未运行，启动..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sleep 3
fi

# 2. 检查PostgreSQL版本和配置
log_step "检查PostgreSQL配置..."
echo "PostgreSQL版本:"
sudo -u postgres psql -c "SELECT version();" 2>/dev/null || echo "无法连接到PostgreSQL"

echo ""
echo "PostgreSQL配置目录:"
sudo -u postgres psql -c "SHOW config_file;" 2>/dev/null || echo "无法获取配置文件路径"

# 3. 检查数据库和用户是否存在
log_step "检查数据库和用户..."
echo "检查数据库是否存在:"
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    log_success "数据库 $DB_NAME 存在"
else
    log_warning "数据库 $DB_NAME 不存在，创建..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || true
fi

echo "检查用户是否存在:"
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER';" | grep -q 1; then
    log_success "用户 $DB_USER 存在"
else
    log_warning "用户 $DB_USER 不存在，创建..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
fi

# 4. 重置用户密码和权限
log_step "重置用户密码和权限..."
echo "重置用户密码..."
sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true

echo "授予数据库权限..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || true

echo "授予连接权限..."
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || true

echo "授予模式权限..."
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;" 2>/dev/null || true

echo "授予表权限..."
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;" 2>/dev/null || true

echo "授予序列权限..."
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;" 2>/dev/null || true

# 5. 检查PostgreSQL认证配置
log_step "检查PostgreSQL认证配置..."
PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"

if [ -d "$PG_CONFIG_DIR" ]; then
    echo "PostgreSQL配置目录: $PG_CONFIG_DIR"
    
    # 检查pg_hba.conf
    echo ""
    echo "检查pg_hba.conf配置:"
    if [ -f "$PG_CONFIG_DIR/pg_hba.conf" ]; then
        echo "当前认证配置:"
        grep -v "^#" "$PG_CONFIG_DIR/pg_hba.conf" | grep -v "^$" | head -10
        
        # 检查是否有正确的本地连接配置
        if ! grep -q "local.*$DB_NAME.*$DB_USER.*md5" "$PG_CONFIG_DIR/pg_hba.conf"; then
            log_warning "添加本地连接认证配置..."
            sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null << EOF

# IPv6 WireGuard Manager local connections
local   $DB_NAME             $DB_USER                                     md5
host    $DB_NAME             $DB_USER             127.0.0.1/32            md5
host    $DB_NAME             $DB_USER             ::1/128                 md5
EOF
        fi
        
        # 检查是否有正确的host连接配置
        if ! grep -q "host.*$DB_NAME.*$DB_USER.*127.0.0.1.*md5" "$PG_CONFIG_DIR/pg_hba.conf"; then
            log_warning "添加host连接认证配置..."
            sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null << EOF

# IPv6 WireGuard Manager host connections
host    $DB_NAME             $DB_USER             127.0.0.1/32            md5
host    $DB_NAME             $DB_USER             ::1/128                 md5
EOF
        fi
    else
        log_error "pg_hba.conf文件不存在"
    fi
else
    log_warning "PostgreSQL配置目录不存在，尝试其他位置..."
    # 尝试其他可能的配置目录
    for dir in /etc/postgresql/*/main /var/lib/pgsql/data; do
        if [ -d "$dir" ]; then
            echo "找到配置目录: $dir"
            PG_CONFIG_DIR="$dir"
            break
        fi
    done
fi

# 6. 重新加载PostgreSQL配置
log_step "重新加载PostgreSQL配置..."
sudo systemctl reload postgresql
sleep 2

# 7. 测试数据库连接
log_step "测试数据库连接..."
echo "测试本地连接..."
if sudo -u postgres psql -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
    log_success "PostgreSQL本地连接正常"
else
    log_error "PostgreSQL本地连接失败"
fi

echo "测试用户连接..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
    log_success "用户数据库连接正常"
else
    log_error "用户数据库连接失败"
    echo "尝试修复连接..."
    
    # 尝试不同的连接方式
    echo "测试IPv4连接..."
    if PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "IPv4连接正常"
    else
        log_error "IPv4连接失败"
    fi
    
    echo "测试IPv6连接..."
    if PGPASSWORD="$DB_PASSWORD" psql -h ::1 -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "IPv6连接正常"
    else
        log_error "IPv6连接失败"
    fi
fi

# 8. 更新应用配置
log_step "更新应用配置..."
cd "$BACKEND_DIR"

# 更新.env文件
if [ -f ".env" ]; then
    log_info "更新.env文件..."
    # 备份原文件
    cp .env .env.backup
    
    # 更新数据库URL
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME|" .env
else
    log_info "创建.env文件..."
    cat > .env << EOF
# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=1.0.0
DEBUG=false

# 数据库配置
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME

# Redis配置
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 超级用户配置
FIRST_SUPERUSER=admin
FIRST_SUPERUSER_EMAIL=admin@example.com
FIRST_SUPERUSER_PASSWORD=admin123

# CORS配置
BACKEND_CORS_ORIGINS=["http://localhost:3000","http://localhost","http://localhost:8080"]

# 服务器配置
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
EOF
fi

# 更新config.py文件
if [ -f "app/core/config.py" ]; then
    log_info "更新config.py文件..."
    sed -i "s|DATABASE_URL: str = \".*\"|DATABASE_URL: str = \"postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME\"|" app/core/config.py
fi

# 9. 测试应用数据库连接
log_step "测试应用数据库连接..."
if [ -d "venv" ]; then
    source venv/bin/activate
    
    echo "测试SQLAlchemy连接..."
    if python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.core.database import engine
    with engine.connect() as conn:
        result = conn.execute('SELECT 1')
        print('SQLAlchemy连接成功')
except Exception as e:
    print(f'SQLAlchemy连接失败: {e}')
    exit(1)
"; then
        log_success "应用数据库连接正常"
    else
        log_error "应用数据库连接失败"
    fi
else
    log_error "虚拟环境不存在"
fi

# 10. 重启后端服务
log_step "重启后端服务..."
sudo systemctl stop $SERVICE_NAME
sleep 2
sudo systemctl start $SERVICE_NAME
sleep 5

# 11. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务启动成功"
else
    log_error "后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
    echo ""
    echo "服务日志:"
    sudo journalctl -u $SERVICE_NAME --no-pager -l -n 10
fi

# 12. 测试API访问
log_step "测试API访问..."
echo "等待服务完全启动..."
sleep 3

echo "测试健康检查端点:"
if curl -s http://127.0.0.1:8000/health; then
    log_success "健康检查端点正常"
else
    log_error "健康检查端点失败"
fi

echo ""
echo "测试API状态端点:"
if curl -s http://127.0.0.1:8000/api/v1/status; then
    log_success "API状态端点正常"
else
    log_error "API状态端点失败"
fi

echo ""
echo "测试通过Nginx代理:"
if curl -s http://localhost/api/v1/status; then
    log_success "Nginx代理正常"
else
    log_error "Nginx代理失败"
fi

# 13. 显示修复结果
log_step "显示修复结果..."
echo "========================================"
echo -e "${GREEN}🎉 PostgreSQL认证问题修复完成！${NC}"
echo ""
echo "📋 修复内容："
echo "   ✅ 检查PostgreSQL服务状态"
echo "   ✅ 重置数据库用户密码和权限"
echo "   ✅ 配置PostgreSQL认证规则"
echo "   ✅ 更新应用配置文件"
echo "   ✅ 测试数据库连接"
echo "   ✅ 重启后端服务"
echo "   ✅ 验证API访问"
echo ""
echo "🔧 数据库信息："
echo "   数据库名: $DB_NAME"
echo "   用户名: $DB_USER"
echo "   密码: $DB_PASSWORD"
echo "   连接字符串: postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
echo ""
echo "🌐 测试访问："
echo "   直接访问: http://127.0.0.1:8000/api/v1/status"
echo "   通过Nginx: http://localhost/api/v1/status"
echo "   健康检查: http://localhost/health"
echo ""
echo "🔧 管理命令："
echo "   查看状态: sudo systemctl status $SERVICE_NAME"
echo "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   重启服务: sudo systemctl restart $SERVICE_NAME"
echo "   测试数据库: PGPASSWORD='$DB_PASSWORD' psql -h localhost -U $DB_USER -d $DB_NAME"
echo ""
echo "📊 服务状态："
echo "   后端服务: $(systemctl is-active $SERVICE_NAME)"
echo "   PostgreSQL: $(systemctl is-active postgresql)"
echo "   Nginx: $(systemctl is-active nginx)"
echo ""
echo "========================================"

# 14. 最终测试
echo "🔍 最终测试..."
if curl -s http://localhost/api/v1/status | grep -q "ok"; then
    log_success "🎉 后端服务完全正常！"
    echo "现在可以正常访问前端页面了"
    echo ""
    echo "请访问测试页面验证: http://localhost/test.html"
else
    log_error "❌ 后端服务仍有问题"
    echo "请检查服务日志: sudo journalctl -u $SERVICE_NAME -f"
fi
