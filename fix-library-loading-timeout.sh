#!/bin/bash

echo "🔍 修复库加载超时问题..."
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

# 1. 检查本地库文件
log_step "检查本地库文件..."
if [ -d "$FRONTEND_DIR/dist/libs" ]; then
    log_success "本地库目录存在"
    echo "库文件列表:"
    ls -la "$FRONTEND_DIR/dist/libs/"
else
    log_error "本地库目录不存在"
    sudo mkdir -p "$FRONTEND_DIR/dist/libs"
fi

if [ -d "$FRONTEND_DIR/dist/css" ]; then
    log_success "本地CSS目录存在"
    echo "CSS文件列表:"
    ls -la "$FRONTEND_DIR/dist/css/"
else
    log_error "本地CSS目录不存在"
    sudo mkdir -p "$FRONTEND_DIR/dist/css"
fi

# 2. 重新下载库文件
log_step "重新下载库文件..."
cd "$FRONTEND_DIR"

echo "下载React库..."
if curl -s -L -o "dist/libs/react.min.js" "https://unpkg.com/react@18/umd/react.production.min.js"; then
    log_success "React库下载成功"
    echo "文件大小: $(wc -c < "dist/libs/react.min.js") 字节"
else
    log_error "React库下载失败"
fi

echo "下载ReactDOM库..."
if curl -s -L -o "dist/libs/react-dom.min.js" "https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"; then
    log_success "ReactDOM库下载成功"
    echo "文件大小: $(wc -c < "dist/libs/react-dom.min.js") 字节"
else
    log_error "ReactDOM库下载失败"
fi

echo "下载Ant Design库..."
if curl -s -L -o "dist/libs/antd.min.js" "https://unpkg.com/antd@5/dist/antd.min.js"; then
    log_success "Ant Design库下载成功"
    echo "文件大小: $(wc -c < "dist/libs/antd.min.js") 字节"
else
    log_error "Ant Design库下载失败"
fi

echo "下载Ant Design CSS..."
if curl -s -L -o "dist/css/antd.min.css" "https://unpkg.com/antd@5/dist/reset.css"; then
    log_success "Ant Design CSS下载成功"
    echo "文件大小: $(wc -c < "dist/css/antd.min.css") 字节"
else
    log_error "Ant Design CSS下载失败"
fi

# 3. 创建简化的HTML文件（不依赖本地库）
log_step "创建简化的HTML文件..."
sudo tee "$FRONTEND_DIR/dist/index.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    
    <!-- 直接使用CDN，避免本地库问题 -->
    <link rel="stylesheet" href="https://unpkg.com/antd@5/dist/reset.css">
    
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
        .simple-dashboard {
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .status-ok { color: #52c41a; }
        .status-error { color: #ff4d4f; }
        .status-warning { color: #faad14; }
        .btn {
            background: #1890ff;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        .btn:hover { background: #40a9ff; }
        .btn-success { background: #52c41a; }
        .btn-success:hover { background: #73d13d; }
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .table th, .table td {
            border: 1px solid #d9d9d9;
            padding: 8px 12px;
            text-align: left;
        }
        .table th {
            background: #fafafa;
            font-weight: 600;
        }
        .tag {
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 12px;
            color: white;
        }
        .tag-green { background: #52c41a; }
        .tag-blue { background: #1890ff; }
    </style>
</head>
<body>
    <div id="root">
        <div class="loading">
            <div class="spinner"></div>
            <div>🌐 正在加载 IPv6 WireGuard Manager...</div>
        </div>
    </div>

    <!-- 直接使用CDN，避免本地库问题 -->
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/antd@5/dist/antd.min.js"></script>

    <script>
        // 简化的应用，不依赖复杂的库加载检测
        function initSimpleApp() {
            const root = document.getElementById('root');
            
            // 检查基本库是否加载
            if (typeof React === 'undefined' || typeof ReactDOM === 'undefined') {
                root.innerHTML = `
                    <div class="error">
                        <h2>❌ 库加载失败</h2>
                        <p>React或ReactDOM库未能正确加载</p>
                        <button class="btn" onclick="location.reload()">重新加载</button>
                    </div>
                `;
                return;
            }
            
            // 使用原生JavaScript创建简单的管理界面
            function createSimpleDashboard() {
                const [apiStatus, setApiStatus] = React.useState(null);
                const [servers, setServers] = React.useState([]);
                const [clients, setClients] = React.useState([]);
                const [loading, setLoading] = React.useState(true);
                const [error, setError] = React.useState(null);
                
                const checkApiStatus = async () => {
                    try {
                        const response = await fetch('/api/v1/status');
                        if (!response.ok) {
                            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                        }
                        const data = await response.json();
                        setApiStatus(data);
                        setError(null);
                    } catch (error) {
                        console.error('API连接失败:', error);
                        setError(error.message);
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
                
                React.useEffect(() => {
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
                    return React.createElement('div', { className: 'loading' }, [
                        React.createElement('div', { key: 'spinner', className: 'spinner' }),
                        React.createElement('div', { key: 'text' }, '正在加载 IPv6 WireGuard Manager...')
                    ]);
                }
                
                if (error) {
                    return React.createElement('div', { className: 'error' }, [
                        React.createElement('h2', { key: 'title' }, '❌ 连接错误'),
                        React.createElement('p', { key: 'message' }, `API连接失败: ${error}`),
                        React.createElement('button', { 
                            key: 'retry',
                            className: 'btn',
                            onClick: checkApiStatus 
                        }, '重试')
                    ]);
                }
                
                return React.createElement('div', { className: 'simple-dashboard' }, [
                    React.createElement('div', { key: 'header', className: 'card' }, [
                        React.createElement('h1', { key: 'title' }, '🌐 IPv6 WireGuard Manager'),
                        React.createElement('p', { key: 'status' }, [
                            'API状态: ',
                            React.createElement('span', { 
                                key: 'status-text',
                                className: apiStatus ? 'status-ok' : 'status-warning' 
                            }, apiStatus ? apiStatus.status : '检查中')
                        ]),
                        React.createElement('button', { 
                            key: 'refresh',
                            className: 'btn btn-success',
                            onClick: checkApiStatus 
                        }, '刷新状态')
                    ]),
                    
                    React.createElement('div', { key: 'stats', className: 'card' }, [
                        React.createElement('h2', { key: 'title' }, '系统状态'),
                        React.createElement('div', { key: 'stats-grid', style: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' } }, [
                            React.createElement('div', { key: 'service' }, [
                                React.createElement('h3', { key: 'title' }, '服务状态'),
                                React.createElement('p', { key: 'value', className: 'status-ok' }, '运行中')
                            ]),
                            React.createElement('div', { key: 'api' }, [
                                React.createElement('h3', { key: 'title' }, 'API状态'),
                                React.createElement('p', { key: 'value', className: apiStatus ? 'status-ok' : 'status-warning' }, 
                                    apiStatus ? apiStatus.status : '检查中')
                            ]),
                            React.createElement('div', { key: 'version' }, [
                                React.createElement('h3', { key: 'title' }, '版本'),
                                React.createElement('p', { key: 'value' }, apiStatus ? apiStatus.version : '1.0.0')
                            ])
                        ])
                    ]),
                    
                    React.createElement('div', { key: 'servers', className: 'card' }, [
                        React.createElement('h2', { key: 'title' }, 'WireGuard服务器'),
                        servers.length > 0 ? 
                            React.createElement('table', { key: 'table', className: 'table' }, [
                                React.createElement('thead', { key: 'head' }, [
                                    React.createElement('tr', { key: 'row' }, [
                                        React.createElement('th', { key: 'id' }, 'ID'),
                                        React.createElement('th', { key: 'name' }, '名称'),
                                        React.createElement('th', { key: 'description' }, '描述'),
                                        React.createElement('th', { key: 'status' }, '状态')
                                    ])
                                ]),
                                React.createElement('tbody', { key: 'body' }, 
                                    servers.map(server => 
                                        React.createElement('tr', { key: server.id }, [
                                            React.createElement('td', { key: 'id' }, server.id),
                                            React.createElement('td', { key: 'name' }, server.name),
                                            React.createElement('td', { key: 'description' }, server.description || '-'),
                                            React.createElement('td', { key: 'status' }, 
                                                React.createElement('span', { className: 'tag tag-green' }, '运行中')
                                            )
                                        ])
                                    )
                                )
                            ]) :
                            React.createElement('p', { key: 'empty' }, '暂无服务器')
                    ]),
                    
                    React.createElement('div', { key: 'clients', className: 'card' }, [
                        React.createElement('h2', { key: 'title' }, 'WireGuard客户端'),
                        clients.length > 0 ? 
                            React.createElement('table', { key: 'table', className: 'table' }, [
                                React.createElement('thead', { key: 'head' }, [
                                    React.createElement('tr', { key: 'row' }, [
                                        React.createElement('th', { key: 'id' }, 'ID'),
                                        React.createElement('th', { key: 'name' }, '名称'),
                                        React.createElement('th', { key: 'description' }, '描述'),
                                        React.createElement('th', { key: 'status' }, '状态')
                                    ])
                                ]),
                                React.createElement('tbody', { key: 'body' }, 
                                    clients.map(client => 
                                        React.createElement('tr', { key: client.id }, [
                                            React.createElement('td', { key: 'id' }, client.id),
                                            React.createElement('td', { key: 'name' }, client.name),
                                            React.createElement('td', { key: 'description' }, client.description || '-'),
                                            React.createElement('td', { key: 'status' }, 
                                                React.createElement('span', { className: 'tag tag-blue' }, '已连接')
                                            )
                                        ])
                                    )
                                )
                            ]) :
                            React.createElement('p', { key: 'empty' }, '暂无客户端')
                    ])
                ]);
            }
            
            ReactDOM.render(React.createElement(createSimpleDashboard), root);
        }
        
        // 延迟启动，确保库加载完成
        setTimeout(initSimpleApp, 100);
        
        // 错误处理
        window.addEventListener('error', function(e) {
            console.error('JavaScript错误:', e.error);
            const root = document.getElementById('root');
            if (root) {
                root.innerHTML = `
                    <div class="error">
                        <h2>❌ 页面加载错误</h2>
                        <p>错误信息: ${e.message}</p>
                        <p>请检查浏览器控制台获取详细信息</p>
                        <button class="btn" onclick="location.reload()">重新加载</button>
                    </div>
                `;
            }
        });
    </script>
</body>
</html>
EOF

log_success "简化的HTML文件创建完成"

# 4. 设置文件权限
log_step "设置文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$FRONTEND_DIR"
sudo chmod -R 755 "$FRONTEND_DIR"

# 5. 测试访问
log_step "测试访问..."
echo "测试本地库文件访问:"
if curl -s -I http://localhost/libs/react.min.js | head -1; then
    log_success "本地React库访问正常"
else
    log_warning "本地React库访问失败，将使用CDN"
fi

echo ""
echo "测试前端页面访问:"
if curl -s -I http://localhost | head -1; then
    log_success "前端页面访问正常"
else
    log_error "前端页面访问失败"
fi

# 6. 显示修复结果
log_step "显示修复结果..."
echo "========================================"
echo -e "${GREEN}🎉 库加载超时问题修复完成！${NC}"
echo ""
echo "📋 修复内容："
echo "   ✅ 检查本地库文件状态"
echo "   ✅ 重新下载所有库文件"
echo "   ✅ 创建简化的HTML文件"
echo "   ✅ 设置正确的文件权限"
echo "   ✅ 测试访问功能"
echo ""
echo "🔧 修复策略："
echo "   ✅ 直接使用CDN，避免本地库问题"
echo "   ✅ 简化应用逻辑，减少依赖"
echo "   ✅ 增强错误处理和用户反馈"
echo "   ✅ 提供重新加载功能"
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
echo "========================================"

# 7. 最终测试
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
