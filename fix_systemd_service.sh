#!/bin/bash
# 彻底修复 systemd 服务文件

echo "正在修复 systemd 服务文件..."

# 备份
cp /etc/systemd/system/ipv6-wireguard-manager.service /etc/systemd/system/ipv6-wireguard-manager.service.backup.$(date +%Y%m%d_%H%M%S)

# 读取当前配置
API_PORT=$(grep "^API_PORT=" /opt/ipv6-wireguard-manager/.env | cut -d= -f2 | tr -d '"' | tr -d "'" || echo "8000")
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"

# 重新生成服务文件（不包含健康检查）
cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service mariadb.service
Wants=network.target

[Service]
Type=notify
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
Environment=PYTHONPATH=$INSTALL_DIR
EnvironmentFile=$INSTALL_DIR/.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host :: --port $API_PORT --workers 2 --access-log --log-level info
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

# 资源限制
LimitNOFILE=65536
LimitNPROC=4096
MemoryLimit=1G

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

echo "✓ 服务文件已更新（已移除健康检查）"

# 重新加载
systemctl daemon-reload
echo "✓ systemd 已重新加载"

# 重启服务
echo ""
echo "重启服务..."
systemctl restart ipv6-wireguard-manager.service

sleep 3

echo ""
echo "检查服务状态..."
systemctl status ipv6-wireguard-manager.service --no-pager -l

echo ""
if systemctl is-active --quiet ipv6-wireguard-manager.service; then
    echo "=========================================="
    echo "✅ 服务启动成功！"
    echo "=========================================="
    echo ""
    
    # 获取 IP 地址
    ipv4_addr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    ipv6_addr=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^::1' | grep -v '^fe80' | head -1)
    
    echo "📡 访问地址:"
    echo ""
    if [[ -n "$ipv4_addr" ]]; then
        echo "  🌐 IPv4 访问:"
        echo "     前端:        http://$ipv4_addr"
        echo "     API文档:     http://$ipv4_addr:$API_PORT/docs"
        echo "     API健康检查: http://$ipv4_addr:$API_PORT/api/v1/health"
        echo ""
    fi
    
    if [[ -n "$ipv6_addr" ]]; then
        echo "  🌐 IPv6 访问:"
        echo "     前端:        http://[$ipv6_addr]"
        echo "     API文档:     http://[$ipv6_addr]:$API_PORT/docs"
        echo "     API健康检查: http://[$ipv6_addr]:$API_PORT/api/v1/health"
        echo ""
    fi
    
    echo "  🏠 本地访问:"
    echo "     前端:        http://localhost"
    echo "     API文档:     http://localhost:$API_PORT/docs"
    echo ""
    
    # 获取管理员密码
    admin_pass=$(grep "^FIRST_SUPERUSER_PASSWORD=" /opt/ipv6-wireguard-manager/.env | cut -d= -f2 | tr -d '"' | tr -d "'")
    
    echo "🔑 登录信息:"
    echo "     用户名: admin"
    echo "     密码:   $admin_pass"
    echo "     邮箱:   admin@example.com"
    echo ""
    echo "=========================================="
    
else
    echo "❌ 服务仍然失败"
    echo ""
    echo "查看最新日志:"
    journalctl -u ipv6-wireguard-manager.service -n 50 --no-pager
fi

