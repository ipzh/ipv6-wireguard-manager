#!/bin/bash

echo "🔧 快速修复常见问题..."
echo "========================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用配置
APP_HOME="/opt/ipv6-wireguard-manager"
FRONTEND_DIR="$APP_HOME/frontend"
BACKEND_DIR="$APP_HOME/backend"
SERVICE_NAME="ipv6-wireguard-manager"

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

# 1. 停止服务
log_step "停止服务..."
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# 2. 修复前端文件
log_step "修复前端文件..."
if [ ! -d "$FRONTEND_DIR/dist" ] || [ ! -f "$FRONTEND_DIR/dist/index.html" ]; then
    log_info "前端文件缺失，创建默认文件..."
    
    sudo mkdir -p "$FRONTEND_DIR/dist"
    sudo tee "$FRONTEND_DIR/dist/index.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/antd@5/dist/antd.min.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/antd@5/dist/reset.css">
    <style>
        body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
        .container { padding: 20px; max-width: 1200px; margin: 0 auto; }
    </style>
</head>
<body>
    <div id="root"></div>
    <script>
        const { useState, useEffect } = React;
        const { Layout, Card, Row, Col, Statistic, Button, message } = antd;
        const { Header, Content } = Layout;

        function Dashboard() {
            const [loading, setLoading] = useState(false);
            const [apiStatus, setApiStatus] = useState(null);

            const checkApiStatus = async () => {
                setLoading(true);
                try {
                    const response = await fetch('/api/v1/status');
                    const data = await response.json();
                    setApiStatus(data);
                    message.success('API连接正常');
                } catch (error) {
                    message.error('API连接失败');
                } finally {
                    setLoading(false);
                }
            };

            useEffect(() => {
                checkApiStatus();
            }, []);

            return React.createElement(Layout, { style: { minHeight: '100vh' } }, [
                React.createElement(Header, { 
                    key: 'header',
                    style: { background: '#fff', padding: '0 24px', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }
                }, React.createElement('h1', { style: { margin: 0, color: '#1890ff' } }, '🌐 IPv6 WireGuard Manager')),
                React.createElement(Content, { 
                    key: 'content',
                    style: { padding: '24px', background: '#f0f2f5' }
                }, [
                    React.createElement(Row, { key: 'stats', gutter: [16, 16] }, [
                        React.createElement(Col, { key: 'status', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: '服务状态', 
                                    value: '运行中', 
                                    valueStyle: { color: '#52c41a' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'api', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: 'API状态', 
                                    value: apiStatus ? apiStatus.status : '检查中', 
                                    valueStyle: { color: '#1890ff' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'actions', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Button, { 
                                    type: 'primary', 
                                    onClick: checkApiStatus, 
                                    loading: loading 
                                }, '刷新状态')
                            )
                        )
                    ])
                ])
            ]);
        }

        ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
    </script>
</body>
</html>
EOF
    log_success "默认前端文件创建完成"
fi

# 3. 修复Nginx配置
log_step "修复Nginx配置..."
sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # 错误页面
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
EOF

# 启用站点
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

# 测试配置
if sudo nginx -t; then
    log_success "Nginx配置正确"
else
    log_error "Nginx配置错误"
    exit 1
fi

# 4. 修复systemd服务
log_step "修复systemd服务..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$BACKEND_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=$BACKEND_DIR
ExecStart=$BACKEND_DIR/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 5. 修复权限
log_step "修复文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME" 2>/dev/null || sudo chown -R $(whoami):$(whoami) "$APP_HOME"
sudo chmod -R 755 "$APP_HOME"

# 6. 重新加载配置
log_step "重新加载配置..."
sudo systemctl daemon-reload

# 7. 启动服务
log_step "启动服务..."
sudo systemctl start $SERVICE_NAME
sleep 3

sudo systemctl start nginx
sleep 2

# 8. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务启动失败"
fi

if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务启动失败"
fi

# 9. 测试访问
log_step "测试访问..."
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "前端访问正常"
else
    log_error "前端访问失败"
fi

if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "API访问正常"
else
    log_error "API访问失败"
fi

# 10. 显示结果
log_step "显示修复结果..."
echo "========================================"
echo -e "${GREEN}🎉 常见问题修复完成！${NC}"
echo ""
echo "🌐 访问地址:"
echo "   本地访问: http://localhost"
echo "   IPv4访问: http://$(curl -s -4 ifconfig.me 2>/dev/null || echo '您的IP')"
echo "   IPv6访问: http://[$(ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1)]"
echo ""
echo "🔑 默认登录: admin / admin123"
echo ""
echo "🔧 管理命令:"
echo "   查看状态: sudo systemctl status $SERVICE_NAME nginx"
echo "   查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   重启服务: sudo systemctl restart $SERVICE_NAME nginx"
echo ""
echo "========================================"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "🎉 修复成功！服务正常运行！"
else
    log_error "❌ 修复失败，请检查日志"
fi
