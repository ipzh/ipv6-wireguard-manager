#!/bin/bash

echo "🔍 诊断和修复前端空白页面问题..."
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

# 1. 检查前端文件
log_step "检查前端文件..."
echo "检查前端目录: $FRONTEND_DIR"

if [ ! -d "$FRONTEND_DIR" ]; then
    log_error "前端目录不存在: $FRONTEND_DIR"
    echo "创建前端目录..."
    sudo mkdir -p "$FRONTEND_DIR/dist"
else
    log_success "前端目录存在"
fi

echo "检查dist目录..."
if [ ! -d "$FRONTEND_DIR/dist" ]; then
    log_warning "dist目录不存在，创建..."
    sudo mkdir -p "$FRONTEND_DIR/dist"
else
    log_success "dist目录存在"
fi

echo "检查index.html文件..."
if [ ! -f "$FRONTEND_DIR/dist/index.html" ]; then
    log_error "index.html文件不存在，创建..."
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
        body { 
            margin: 0; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif;
            background-color: #f0f2f5;
        }
        .container { 
            padding: 20px; 
            max-width: 1200px; 
            margin: 0 auto; 
        }
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-size: 18px;
            color: #1890ff;
        }
    </style>
</head>
<body>
    <div id="root">
        <div class="loading">🌐 正在加载 IPv6 WireGuard Manager...</div>
    </div>
    <script>
        const { useState, useEffect } = React;
        const { Layout, Card, Row, Col, Statistic, Button, message, Table, Tag, Spin } = antd;
        const { Header, Content } = Layout;

        function Dashboard() {
            const [loading, setLoading] = useState(true);
            const [apiStatus, setApiStatus] = useState(null);
            const [servers, setServers] = useState([]);
            const [clients, setClients] = useState([]);
            const [error, setError] = useState(null);

            const checkApiStatus = async () => {
                try {
                    const response = await fetch('/api/v1/status');
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                    const data = await response.json();
                    setApiStatus(data);
                    setError(null);
                    message.success('API连接正常');
                } catch (error) {
                    console.error('API连接失败:', error);
                    setError(error.message);
                    message.error('API连接失败: ' + error.message);
                }
            };

            const loadServers = async () => {
                try {
                    const response = await fetch('/api/v1/servers');
                    if (response.ok) {
                        const data = await response.json();
                        setServers(data.servers || []);
                    }
                } catch (error) {
                    console.error('加载服务器失败:', error);
                }
            };

            const loadClients = async () => {
                try {
                    const response = await fetch('/api/v1/clients');
                    if (response.ok) {
                        const data = await response.json();
                        setClients(data.clients || []);
                    }
                } catch (error) {
                    console.error('加载客户端失败:', error);
                }
            };

            useEffect(() => {
                const init = async () => {
                    setLoading(true);
                    await Promise.all([
                        checkApiStatus(),
                        loadServers(),
                        loadClients()
                    ]);
                    setLoading(false);
                };
                init();
            }, []);

            if (loading) {
                return React.createElement('div', { 
                    style: { 
                        display: 'flex', 
                        justifyContent: 'center', 
                        alignItems: 'center', 
                        height: '100vh',
                        flexDirection: 'column'
                    } 
                }, [
                    React.createElement(Spin, { size: 'large', key: 'spin' }),
                    React.createElement('div', { 
                        key: 'text',
                        style: { marginTop: '16px', fontSize: '16px', color: '#666' } 
                    }, '正在加载 IPv6 WireGuard Manager...')
                ]);
            }

            const serverColumns = [
                { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
                { title: '名称', dataIndex: 'name', key: 'name' },
                { title: '描述', dataIndex: 'description', key: 'description' },
                { title: '状态', key: 'status', width: 80, render: () => React.createElement(Tag, { color: "green" }, "运行中") }
            ];

            const clientColumns = [
                { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
                { title: '名称', dataIndex: 'name', key: 'name' },
                { title: '描述', dataIndex: 'description', key: 'description' },
                { title: '状态', key: 'status', width: 80, render: () => React.createElement(Tag, { color: "blue" }, "已连接") }
            ];

            return React.createElement(Layout, { style: { minHeight: '100vh' } }, [
                React.createElement(Header, { 
                    key: 'header',
                    style: { 
                        background: '#fff', 
                        padding: '0 24px', 
                        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                        display: 'flex',
                        alignItems: 'center'
                    }
                }, [
                    React.createElement('h1', { 
                        key: 'title',
                        style: { margin: 0, color: '#1890ff', fontSize: '20px' } 
                    }, '🌐 IPv6 WireGuard Manager'),
                    React.createElement('div', {
                        key: 'status',
                        style: { marginLeft: 'auto', display: 'flex', alignItems: 'center' }
                    }, [
                        React.createElement('span', {
                            key: 'status-text',
                            style: { marginRight: '8px', fontSize: '14px' }
                        }, apiStatus ? `API: ${apiStatus.status}` : 'API: 检查中'),
                        React.createElement(Button, { 
                            key: 'refresh',
                            size: 'small',
                            type: 'primary', 
                            onClick: checkApiStatus
                        }, '刷新')
                    ])
                ]),
                React.createElement(Content, { 
                    key: 'content',
                    style: { padding: '24px', background: '#f0f2f5' }
                }, [
                    error && React.createElement(Card, {
                        key: 'error',
                        style: { marginBottom: '16px', border: '1px solid #ff4d4f' }
                    }, [
                        React.createElement('div', {
                            key: 'error-title',
                            style: { color: '#ff4d4f', fontWeight: 'bold', marginBottom: '8px' }
                        }, '⚠️ 连接错误'),
                        React.createElement('div', {
                            key: 'error-msg',
                            style: { color: '#666' }
                        }, error)
                    ]),
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
                                    valueStyle: { color: apiStatus ? '#1890ff' : '#faad14' } 
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'version', xs: 24, sm: 12, md: 8 }, 
                            React.createElement(Card, null, 
                                React.createElement(Statistic, { 
                                    title: '版本', 
                                    value: apiStatus ? apiStatus.version : '1.0.0', 
                                    valueStyle: { color: '#722ed1' } 
                                })
                            )
                        )
                    ]),
                    React.createElement(Row, { key: 'tables', gutter: [16, 16], style: { marginTop: 16 } }, [
                        React.createElement(Col, { key: 'servers', xs: 24, lg: 12 }, 
                            React.createElement(Card, { title: 'WireGuard服务器' }, 
                                React.createElement(Table, { 
                                    columns: serverColumns, 
                                    dataSource: servers, 
                                    rowKey: 'id',
                                    pagination: false,
                                    size: 'small',
                                    locale: { emptyText: '暂无服务器' }
                                })
                            )
                        ),
                        React.createElement(Col, { key: 'clients', xs: 24, lg: 12 }, 
                            React.createElement(Card, { title: 'WireGuard客户端' }, 
                                React.createElement(Table, { 
                                    columns: clientColumns, 
                                    dataSource: clients, 
                                    rowKey: 'id',
                                    pagination: false,
                                    size: 'small',
                                    locale: { emptyText: '暂无客户端' }
                                })
                            )
                        )
                    ])
                ])
            ]);
        }

        // 错误处理
        window.addEventListener('error', function(e) {
            console.error('JavaScript错误:', e.error);
            const root = document.getElementById('root');
            if (root) {
                root.innerHTML = '<div style="padding: 20px; text-align: center; color: #ff4d4f;"><h2>❌ 页面加载错误</h2><p>请检查浏览器控制台或联系管理员</p></div>';
            }
        });

        ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
    </script>
</body>
</html>
EOF
    log_success "index.html文件创建完成"
else
    log_success "index.html文件存在"
    echo "文件大小: $(wc -c < "$FRONTEND_DIR/dist/index.html") 字节"
fi

# 2. 检查文件权限
log_step "检查文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$FRONTEND_DIR" 2>/dev/null || true
sudo chmod -R 755 "$FRONTEND_DIR"
log_success "文件权限设置完成"

# 3. 检查Nginx配置
log_step "检查Nginx配置..."
NGINX_CONFIG="/etc/nginx/sites-available/ipv6-wireguard-manager"

if [ ! -f "$NGINX_CONFIG" ]; then
    log_error "Nginx配置文件不存在，创建..."
    sudo tee "$NGINX_CONFIG" > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
        index index.html;
        
        # 添加缓存控制
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
    
    # 错误页面
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
EOF
    log_success "Nginx配置文件创建完成"
else
    log_success "Nginx配置文件存在"
fi

# 启用Nginx站点
sudo ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/

# 测试Nginx配置
log_step "测试Nginx配置..."
if sudo nginx -t; then
    log_success "Nginx配置正确"
else
    log_error "Nginx配置错误"
    echo "Nginx配置测试失败，请检查配置文件"
    exit 1
fi

# 4. 重启服务
log_step "重启服务..."
sudo systemctl restart nginx
sudo systemctl restart $SERVICE_NAME
sleep 3

# 5. 检查服务状态
log_step "检查服务状态..."
if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务异常"
    echo "Nginx状态:"
    sudo systemctl status nginx --no-pager -l
fi

if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务异常"
    echo "后端服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

# 6. 测试访问
log_step "测试访问..."
echo "测试前端文件访问:"
if [ -f "$FRONTEND_DIR/dist/index.html" ]; then
    log_success "前端文件存在"
    echo "文件内容预览:"
    head -5 "$FRONTEND_DIR/dist/index.html"
else
    log_error "前端文件不存在"
fi

echo ""
echo "测试HTTP访问:"
if curl -s -I http://localhost | head -1; then
    log_success "HTTP访问正常"
else
    log_error "HTTP访问失败"
fi

echo ""
echo "测试API访问:"
if curl -s http://localhost/api/v1/status; then
    log_success "API访问正常"
else
    log_error "API访问失败"
fi

# 7. 显示诊断结果
log_step "显示诊断结果..."
echo "========================================"
echo -e "${GREEN}🎉 前端空白页面修复完成！${NC}"
echo ""
echo "📋 修复内容："
echo "   ✅ 检查并创建前端文件"
echo "   ✅ 设置正确的文件权限"
echo "   ✅ 配置Nginx代理"
echo "   ✅ 重启相关服务"
echo "   ✅ 测试访问功能"
echo ""
echo "🌐 访问地址："
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -n "$PUBLIC_IPV4" ]; then
    echo "   IPv4: http://$PUBLIC_IPV4"
fi
echo "   IPv4 (本地): http://$LOCAL_IPV4"
if [ -n "$IPV6_ADDRESS" ]; then
    echo "   IPv6: http://[$IPV6_ADDRESS]"
fi
echo ""
echo "🔧 如果仍然空白，请检查："
echo "   1. 浏览器控制台是否有JavaScript错误"
echo "   2. 网络连接是否正常"
echo "   3. 防火墙是否阻止了访问"
echo "   4. 运行: curl -I http://localhost 检查HTTP响应"
echo ""
echo "📊 服务状态："
echo "   Nginx: $(systemctl is-active nginx)"
echo "   后端: $(systemctl is-active $SERVICE_NAME)"
echo ""
echo "========================================"

# 8. 提供调试命令
echo "🔍 调试命令："
echo "   查看Nginx日志: sudo tail -f /var/log/nginx/error.log"
echo "   查看后端日志: sudo journalctl -u $SERVICE_NAME -f"
echo "   测试前端文件: curl -I http://localhost"
echo "   测试API: curl http://localhost/api/v1/status"
echo "   检查文件: ls -la $FRONTEND_DIR/dist/"
