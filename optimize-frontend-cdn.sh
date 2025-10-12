#!/bin/bash

echo "🔍 优化前端CDN加载问题..."
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

# 1. 创建本地CDN库目录
log_step "创建本地CDN库目录..."
sudo mkdir -p "$FRONTEND_DIR/dist/libs"
sudo mkdir -p "$FRONTEND_DIR/dist/css"

# 2. 下载React库到本地
log_step "下载React库到本地..."
echo "下载React库..."
if curl -s -L -o "$FRONTEND_DIR/dist/libs/react.min.js" "https://unpkg.com/react@18/umd/react.production.min.js"; then
    log_success "React库下载成功"
    echo "文件大小: $(wc -c < "$FRONTEND_DIR/dist/libs/react.min.js") 字节"
else
    log_error "React库下载失败"
fi

echo "下载ReactDOM库..."
if curl -s -L -o "$FRONTEND_DIR/dist/libs/react-dom.min.js" "https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"; then
    log_success "ReactDOM库下载成功"
    echo "文件大小: $(wc -c < "$FRONTEND_DIR/dist/libs/react-dom.min.js") 字节"
else
    log_error "ReactDOM库下载失败"
fi

echo "下载Ant Design库..."
if curl -s -L -o "$FRONTEND_DIR/dist/libs/antd.min.js" "https://unpkg.com/antd@5/dist/antd.min.js"; then
    log_success "Ant Design库下载成功"
    echo "文件大小: $(wc -c < "$FRONTEND_DIR/dist/libs/antd.min.js") 字节"
else
    log_error "Ant Design库下载失败"
fi

echo "下载Ant Design CSS..."
if curl -s -L -o "$FRONTEND_DIR/dist/css/antd.min.css" "https://unpkg.com/antd@5/dist/reset.css"; then
    log_success "Ant Design CSS下载成功"
    echo "文件大小: $(wc -c < "$FRONTEND_DIR/dist/css/antd.min.css") 字节"
else
    log_error "Ant Design CSS下载失败"
fi

# 3. 创建优化的前端HTML文件
log_step "创建优化的前端HTML文件..."
sudo tee "$FRONTEND_DIR/dist/index.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    
    <!-- 本地CSS库 -->
    <link rel="stylesheet" href="/css/antd.min.css">
    
    <!-- 备用CDN CSS -->
    <link rel="stylesheet" href="https://unpkg.com/antd@5/dist/reset.css" onerror="console.log('CDN CSS加载失败，使用本地版本')">
    
    <style>
        body { 
            margin: 0; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif;
            background-color: #f0f2f5;
        }
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-size: 18px;
            color: #1890ff;
            flex-direction: column;
        }
        .error {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-size: 18px;
            color: #ff4d4f;
            flex-direction: column;
            padding: 20px;
            text-align: center;
        }
        .spinner {
            width: 40px;
            height: 40px;
            border: 4px solid #f3f3f3;
            border-top: 4px solid #1890ff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-bottom: 16px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div id="root">
        <div class="loading">
            <div class="spinner"></div>
            <div>🌐 正在加载 IPv6 WireGuard Manager...</div>
        </div>
    </div>

    <!-- 本地JavaScript库 -->
    <script src="/libs/react.min.js"></script>
    <script src="/libs/react-dom.min.js"></script>
    <script src="/libs/antd.min.js"></script>
    
    <!-- 备用CDN JavaScript库 -->
    <script src="https://unpkg.com/react@18/umd/react.production.min.js" onerror="console.log('React CDN加载失败，使用本地版本')"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js" onerror="console.log('ReactDOM CDN加载失败，使用本地版本')"></script>
    <script src="https://unpkg.com/antd@5/dist/antd.min.js" onerror="console.log('Ant Design CDN加载失败，使用本地版本')"></script>

    <script>
        // 错误处理
        window.addEventListener('error', function(e) {
            console.error('JavaScript错误:', e.error);
            const root = document.getElementById('root');
            if (root) {
                root.innerHTML = '<div class="error"><h2>❌ 页面加载错误</h2><p>请检查浏览器控制台或联系管理员</p><p>错误: ' + e.message + '</p></div>';
            }
        });

        // 等待所有库加载完成
        function waitForLibraries() {
            return new Promise((resolve, reject) => {
                let attempts = 0;
                const maxAttempts = 50; // 5秒超时
                
                const checkLibraries = () => {
                    attempts++;
                    
                    if (typeof React !== 'undefined' && typeof ReactDOM !== 'undefined' && typeof antd !== 'undefined') {
                        console.log('所有库加载完成');
                        resolve();
                    } else if (attempts >= maxAttempts) {
                        console.error('库加载超时');
                        reject(new Error('库加载超时'));
                    } else {
                        setTimeout(checkLibraries, 100);
                    }
                };
                
                checkLibraries();
            });
        }

        // 主应用
        async function initApp() {
            try {
                await waitForLibraries();
                
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
                            React.createElement('div', { 
                                key: 'spinner',
                                className: 'spinner'
                            }),
                            React.createElement('div', { 
                                key: 'text',
                                style: { marginTop: '16px', fontSize: '16px', color: '#666' } 
                            }, '正在加载 IPv6 WireGuard Manager...')
                        ]);
                    }

                    if (error) {
                        return React.createElement('div', { 
                            style: { 
                                display: 'flex', 
                                justifyContent: 'center', 
                                alignItems: 'center', 
                                height: '100vh',
                                flexDirection: 'column',
                                padding: '20px'
                            } 
                        }, [
                            React.createElement('h2', { 
                                key: 'title',
                                style: { color: '#ff4d4f', marginBottom: '16px' } 
                            }, '❌ 连接错误'),
                            React.createElement('p', { 
                                key: 'message',
                                style: { color: '#666', textAlign: 'center', maxWidth: '400px' } 
                            }, `API连接失败: ${error}`),
                            React.createElement('button', { 
                                key: 'retry',
                                onClick: checkApiStatus,
                                style: { 
                                    marginTop: '16px',
                                    padding: '8px 16px',
                                    background: '#1890ff',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '4px',
                                    cursor: 'pointer'
                                }
                            }, '重试')
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

                ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
                
            } catch (error) {
                console.error('应用启动失败:', error);
                document.getElementById('root').innerHTML = `
                    <div class="error">
                        <h2>❌ 应用启动失败</h2>
                        <p>错误信息: ${error.message}</p>
                        <p>请检查浏览器控制台获取详细信息</p>
                        <button onclick="location.reload()" style="margin-top: 16px; padding: 8px 16px; background: #1890ff; color: white; border: none; border-radius: 4px; cursor: pointer;">重新加载</button>
                    </div>
                `;
            }
        }

        // 启动应用
        initApp();
    </script>
</body>
</html>
EOF

log_success "优化的前端HTML文件创建完成"

# 4. 更新Nginx配置以支持本地库
log_step "更新Nginx配置..."
sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << 'EOF'
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
    
    # 本地库文件
    location /libs/ {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 本地CSS文件
    location /css/ {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
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

# 测试Nginx配置
if sudo nginx -t; then
    log_success "Nginx配置正确"
    sudo systemctl reload nginx
else
    log_error "Nginx配置错误"
fi

# 5. 设置文件权限
log_step "设置文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$FRONTEND_DIR"
sudo chmod -R 755 "$FRONTEND_DIR"

# 6. 测试访问
log_step "测试访问..."
echo "测试本地库文件访问:"
if curl -s -I http://localhost/libs/react.min.js | head -1; then
    log_success "本地React库访问正常"
else
    log_error "本地React库访问失败"
fi

if curl -s -I http://localhost/css/antd.min.css | head -1; then
    log_success "本地CSS文件访问正常"
else
    log_error "本地CSS文件访问失败"
fi

echo ""
echo "测试前端页面访问:"
if curl -s -I http://localhost | head -1; then
    log_success "前端页面访问正常"
else
    log_error "前端页面访问失败"
fi

# 7. 显示优化结果
log_step "显示优化结果..."
echo "========================================"
echo -e "${GREEN}🎉 前端CDN优化完成！${NC}"
echo ""
echo "📋 优化内容："
echo "   ✅ 下载React库到本地"
echo "   ✅ 下载ReactDOM库到本地"
echo "   ✅ 下载Ant Design库到本地"
echo "   ✅ 下载Ant Design CSS到本地"
echo "   ✅ 创建优化的HTML文件"
echo "   ✅ 配置Nginx支持本地库"
echo "   ✅ 设置文件权限"
echo "   ✅ 测试访问功能"
echo ""
echo "🌐 访问地址："
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -n "$PUBLIC_IPV4" ]; then
    echo "   主页面: http://$PUBLIC_IPV4"
fi
echo "   主页面 (本地): http://$LOCAL_IPV4"
if [ -n "$IPV6_ADDRESS" ]; then
    echo "   主页面 (IPv6): http://[$IPV6_ADDRESS]"
fi
echo ""
echo "📁 本地库文件："
echo "   React: http://localhost/libs/react.min.js"
echo "   ReactDOM: http://localhost/libs/react-dom.min.js"
echo "   Ant Design: http://localhost/libs/antd.min.js"
echo "   Ant Design CSS: http://localhost/css/antd.min.css"
echo ""
echo "🔧 优化特性："
echo "   ✅ 本地库优先加载"
echo "   ✅ CDN作为备用方案"
echo "   ✅ 自动错误处理和重试"
echo "   ✅ 优化的加载动画"
echo "   ✅ 详细的错误信息"
echo ""
echo "========================================"

# 8. 最终测试
echo "🔍 最终测试..."
if curl -s http://localhost | grep -q "IPv6 WireGuard Manager"; then
    log_success "🎉 前端页面完全正常！"
    echo "现在可以正常访问管理界面了"
    echo ""
    echo "请访问主页面验证: http://localhost"
else
    log_error "❌ 前端页面仍有问题"
    echo "请检查Nginx配置和文件权限"
fi
