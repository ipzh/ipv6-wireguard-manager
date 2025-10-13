#!/bin/bash

echo "🔧 修复后端服务启动问题..."

# 1. 停止服务
echo "1. 停止服务..."
systemctl stop ipv6-wireguard-manager.service

# 2. 检查并修复权限
echo "2. 检查并修复权限..."
chown -R www-data:www-data /opt/ipv6-wireguard-manager/
chmod -R 755 /opt/ipv6-wireguard-manager/

# 3. 检查虚拟环境
echo "3. 检查虚拟环境..."
cd /opt/ipv6-wireguard-manager/backend

if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    
    # 检查并安装python3-venv包
    if ! python3 -m venv --help &> /dev/null; then
        echo "检测到缺少python3-venv包，正在安装..."
        apt-get update -y
        apt-get install -y python3-venv
        echo "python3-venv包安装完成"
    fi
    
    python3 -m venv venv
fi

# 4. 激活虚拟环境并安装依赖
echo "4. 安装依赖..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. 检查环境变量
echo "5. 检查环境变量..."
if [ ! -f "/opt/ipv6-wireguard-manager/.env" ]; then
    echo "创建环境变量文件..."
    cat > /opt/ipv6-wireguard-manager/.env << 'EOF'
# 数据库配置
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-change-this-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 应用配置
DEBUG=false
LOG_LEVEL=INFO
SERVER_HOST=127.0.0.1
SERVER_PORT=8000

# WireGuard配置
WIREGUARD_CONFIG_DIR=/etc/wireguard
WIREGUARD_INTERFACE=wg0
EOF
fi

# 6. 检查数据库
echo "6. 检查数据库..."
sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "启动PostgreSQL..."
    systemctl start postgresql
    systemctl enable postgresql
fi

# 7. 检查Redis
echo "7. 检查Redis..."
redis-cli ping > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "启动Redis..."
    systemctl start redis-server
    systemctl enable redis-server
fi

# 8. 运行数据库迁移
echo "8. 运行数据库迁移..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager"
alembic upgrade head

# 9. 测试应用启动
echo "9. 测试应用启动..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager"
export REDIS_URL="redis://localhost:6379/0"
export SECRET_KEY="test-secret-key"

# 测试导入
python -c "
try:
    from app.main import app
    print('✅ 应用导入成功')
except Exception as e:
    print(f'❌ 应用导入失败: {e}')
    exit(1)
"

# 10. 修复systemd服务文件
echo "10. 修复systemd服务文件..."
cat > /etc/systemd/system/ipv6-wireguard-manager.service << 'EOF'
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin
Environment=DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager
Environment=REDIS_URL=redis://localhost:6379/0
Environment=SECRET_KEY=your-secret-key-change-this-in-production
Environment=DEBUG=false
Environment=LOG_LEVEL=INFO
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

[Install]
WantedBy=multi-user.target
EOF

# 11. 重新加载systemd配置
echo "11. 重新加载systemd配置..."
systemctl daemon-reload

# 12. 启动服务
echo "12. 启动服务..."
systemctl start ipv6-wireguard-manager.service
systemctl enable ipv6-wireguard-manager.service

# 13. 检查服务状态
echo "13. 检查服务状态..."
sleep 5
systemctl status ipv6-wireguard-manager.service --no-pager

# 14. 测试API
echo "14. 测试API..."
sleep 3
curl -f http://localhost:8000/health > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ API测试成功"
else
    echo "❌ API测试失败"
    echo "查看详细日志:"
    journalctl -u ipv6-wireguard-manager.service -n 10 --no-pager
fi

echo ""
echo "修复完成！"
echo "如果问题仍然存在，请运行诊断脚本:"
echo "bash diagnose-backend-startup.sh"
