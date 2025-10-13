#!/bin/bash

echo "🚀 快速修复后端启动问题..."

# 停止服务
systemctl stop ipv6-wireguard-manager.service

# 检查并修复常见问题
cd /opt/ipv6-wireguard-manager/backend

# 1. 修复虚拟环境路径问题
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
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# 2. 修复权限问题
chown -R www-data:www-data /opt/ipv6-wireguard-manager/
chmod +x /opt/ipv6-wireguard-manager/backend/venv/bin/*

# 3. 修复环境变量
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager"
export REDIS_URL="redis://localhost:6379/0"
export SECRET_KEY="your-secret-key-change-this-in-production"

# 4. 确保数据库和Redis运行
systemctl start postgresql redis-server

# 5. 运行数据库迁移
source venv/bin/activate
alembic upgrade head

# 6. 修复systemd服务文件
cat > /etc/systemd/system/ipv6-wireguard-manager.service << 'EOF'
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target postgresql.service redis.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin
Environment=DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ipv6_wireguard_manager
Environment=REDIS_URL=redis://localhost:6379/0
Environment=SECRET_KEY=your-secret-key-change-this-in-production
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 7. 重新加载并启动
systemctl daemon-reload
systemctl start ipv6-wireguard-manager.service

# 8. 检查状态
sleep 3
systemctl status ipv6-wireguard-manager.service --no-pager

echo "修复完成！"
