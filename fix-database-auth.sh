#!/bin/bash

# 修复PostgreSQL数据库认证问题
echo "🔧 开始修复PostgreSQL数据库认证问题..."

# 数据库配置
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASSWORD="ipv6wgm123"

echo "🔧 检查PostgreSQL服务状态..."
if ! sudo systemctl is-active --quiet postgresql; then
    echo "❌ PostgreSQL服务未运行，正在启动..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    sleep 5
fi

echo "✅ PostgreSQL服务运行正常"

echo "🔧 重置数据库用户密码..."
sudo -u postgres psql << EOF
-- 删除现有用户（如果存在）
DROP USER IF EXISTS $DB_USER;

-- 创建新用户
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- 创建数据库
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME OWNER $DB_USER;

-- 授予权限
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;

-- 设置默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;

-- 退出
\q
EOF

if [ $? -eq 0 ]; then
    echo "✅ 数据库用户和权限设置成功"
else
    echo "❌ 数据库用户设置失败"
    exit 1
fi

echo "🔧 配置PostgreSQL认证..."
# 查找PostgreSQL配置目录
PG_CONFIG_DIR=""
for dir in /etc/postgresql/*/main /var/lib/pgsql/data; do
    if [ -d "$dir" ]; then
        PG_CONFIG_DIR="$dir"
        break
    fi
done

if [ -z "$PG_CONFIG_DIR" ]; then
    echo "❌ 找不到PostgreSQL配置目录"
    exit 1
fi

echo "📁 PostgreSQL配置目录: $PG_CONFIG_DIR"

# 备份原始配置
sudo cp "$PG_CONFIG_DIR/pg_hba.conf" "$PG_CONFIG_DIR/pg_hba.conf.backup.$(date +%Y%m%d_%H%M%S)"

# 配置认证方式
sudo tee "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null << EOF
# PostgreSQL Client Authentication Configuration File
# ===================================================

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5
EOF

echo "✅ PostgreSQL认证配置已更新"

echo "🔧 重启PostgreSQL服务..."
sudo systemctl restart postgresql
sleep 5

echo "🔧 测试数据库连接..."
if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ 数据库连接测试成功"
else
    echo "❌ 数据库连接测试失败"
    echo "🔧 尝试其他认证方式..."
    
    # 尝试trust认证
    sudo tee "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null << EOF
# PostgreSQL Client Authentication Configuration File
# ===================================================

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
EOF
    
    sudo systemctl restart postgresql
    sleep 5
    
    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ 数据库连接测试成功（使用trust认证）"
    else
        echo "❌ 数据库连接仍然失败"
        exit 1
    fi
fi

echo "🔧 更新应用配置文件..."
APP_HOME="/opt/ipv6-wireguard-manager"
if [ -d "$APP_HOME/backend" ]; then
    # 更新.env文件
    cat > "$APP_HOME/backend/.env" << EOF
# 数据库配置
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME

# 应用配置
APP_NAME=IPv6 WireGuard Manager
APP_VERSION=1.0.0
DEBUG=False

# 服务器配置
SERVER_HOST=127.0.0.1
SERVER_PORT=8000

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# Redis配置
REDIS_URL=redis://localhost:6379/0

# 日志配置
LOG_LEVEL=INFO
EOF
    
    echo "✅ 应用配置文件已更新"
fi

echo "🔧 重新创建数据库表..."
if [ -d "$APP_HOME/backend" ]; then
    cd "$APP_HOME/backend"
    
    if [ -d "venv" ]; then
        source venv/bin/activate
        
        # 修复models/__init__.py
        cat > app/models/__init__.py << 'EOF'
"""
数据库模型
"""
from ..core.database import Base
from .user import User, Role, UserRole
from .wireguard import WireGuardServer, WireGuardClient, ClientServerRelation
from .network import NetworkInterface, FirewallRule
from .monitoring import SystemMetric, AuditLog, OperationLog
from .config import ConfigVersion, BackupRecord

__all__ = [
    "Base",
    "User",
    "Role", 
    "UserRole",
    "WireGuardServer",
    "WireGuardClient",
    "ClientServerRelation",
    "NetworkInterface",
    "FirewallRule",
    "SystemMetric",
    "AuditLog",
    "OperationLog",
    "ConfigVersion",
    "BackupRecord",
]
EOF
        
        echo "🔧 创建数据库表..."
        python -c "
import sys
import os
sys.path.insert(0, '.')
os.environ['DATABASE_URL'] = 'postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME'
try:
    from app.core.database import sync_engine
    from app.models import Base
    print('正在创建数据库表...')
    Base.metadata.create_all(bind=sync_engine)
    print('✅ 数据库表创建成功')
except Exception as e:
    print(f'❌ 数据库表创建失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"
        
        if [ $? -eq 0 ]; then
            echo "✅ 数据库表创建成功"
            
            echo "🔧 初始化默认数据..."
            python -c "
import sys
import os
import asyncio
sys.path.insert(0, '.')
os.environ['DATABASE_URL'] = 'postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME'
try:
    from app.core.init_db import init_db
    print('正在初始化默认数据...')
    asyncio.run(init_db())
    print('✅ 默认数据初始化成功')
except Exception as e:
    print(f'❌ 默认数据初始化失败: {e}')
    import traceback
    traceback.print_exc()
"
        else
            echo "❌ 数据库表创建失败"
            exit 1
        fi
    fi
fi

echo "🔧 重启后端服务..."
sudo systemctl restart ipv6-wireguard-manager

echo "⏳ 等待服务启动..."
sleep 10

echo "🔍 检查服务状态..."
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务异常"
    echo "📋 服务状态:"
    sudo systemctl status ipv6-wireguard-manager --no-pager -l
    echo ""
    echo "📋 服务日志:"
    sudo journalctl -u ipv6-wireguard-manager --no-pager -l -n 20
fi

echo "🔍 测试API访问..."
if curl -s "http://localhost:8000/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API访问正常"
else
    echo "❌ API访问异常"
fi

echo "🔍 测试Web访问..."
if curl -s "http://localhost" >/dev/null 2>&1; then
    echo "✅ Web访问正常"
else
    echo "❌ Web访问异常"
fi

echo ""
echo "🎉 数据库认证问题修复完成！"
echo ""
echo "📋 数据库信息:"
echo "   数据库名: $DB_NAME"
echo "   用户名: $DB_USER"
echo "   密码: $DB_PASSWORD"
echo ""
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')
echo "📋 访问信息:"
echo "   Web界面: http://$SERVER_IP"
echo "   API文档: http://$SERVER_IP:8000/docs"
echo ""
echo "🔧 如果仍有问题，请检查:"
echo "   1. PostgreSQL状态: sudo systemctl status postgresql"
echo "   2. 后端服务日志: sudo journalctl -u ipv6-wireguard-manager -f"
echo "   3. 数据库连接: PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USER -d $DB_NAME"