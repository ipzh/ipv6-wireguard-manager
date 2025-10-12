#!/bin/bash

echo "🔍 诊断前端JavaScript加载和执行问题..."
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

# 1. 检查HTML文件内容
log_step "检查HTML文件内容..."
HTML_FILE="$FRONTEND_DIR/dist/index.html"

if [ -f "$HTML_FILE" ]; then
    log_success "HTML文件存在"
    echo "文件大小: $(wc -c < "$HTML_FILE") 字节"
    echo "文件权限: $(ls -la "$HTML_FILE")"
    
    echo ""
    echo "📄 HTML文件内容预览:"
    echo "前10行:"
    head -10 "$HTML_FILE"
    echo ""
    echo "后10行:"
    tail -10 "$HTML_FILE"
    
    # 检查关键元素
    echo ""
    echo "🔍 检查关键元素:"
    if grep -q "id=\"root\"" "$HTML_FILE"; then
        log_success "找到 root 元素"
    else
        log_error "未找到 root 元素"
    fi
    
    if grep -q "ReactDOM.render" "$HTML_FILE"; then
        log_success "找到 ReactDOM.render"
    else
        log_error "未找到 ReactDOM.render"
    fi
    
    if grep -q "unpkg.com/react" "$HTML_FILE"; then
        log_success "找到 React CDN 链接"
    else
        log_error "未找到 React CDN 链接"
    fi
    
    if grep -q "unpkg.com/antd" "$HTML_FILE"; then
        log_success "找到 Ant Design CDN 链接"
    else
        log_error "未找到 Ant Design CDN 链接"
    fi
else
    log_error "HTML文件不存在: $HTML_FILE"
fi

# 2. 测试CDN资源访问
log_step "测试CDN资源访问..."
echo "测试React CDN:"
if curl -s -I "https://unpkg.com/react@18/umd/react.production.min.js" | head -1; then
    log_success "React CDN 可访问"
else
    log_warning "React CDN 可能无法访问"
fi

echo "测试Ant Design CDN:"
if curl -s -I "https://unpkg.com/antd@5/dist/antd.min.js" | head -1; then
    log_success "Ant Design CDN 可访问"
else
    log_warning "Ant Design CDN 可能无法访问"
fi

# 3. 创建简化的测试页面
log_step "创建简化的测试页面..."
sudo tee "$FRONTEND_DIR/dist/test.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager - 测试页面</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f0f2f5;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            padding: 20px; 
            border-radius: 8px; 
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .status { 
            padding: 10px; 
            margin: 10px 0; 
            border-radius: 4px; 
        }
        .success { background-color: #f6ffed; border: 1px solid #b7eb8f; color: #52c41a; }
        .error { background-color: #fff2f0; border: 1px solid #ffccc7; color: #ff4d4f; }
        .info { background-color: #e6f7ff; border: 1px solid #91d5ff; color: #1890ff; }
        .loading { background-color: #fffbe6; border: 1px solid #ffe58f; color: #faad14; }
        button { 
            background: #1890ff; 
            color: white; 
            border: none; 
            padding: 8px 16px; 
            border-radius: 4px; 
            cursor: pointer; 
            margin: 5px;
        }
        button:hover { background: #40a9ff; }
        #log { 
            background: #f5f5f5; 
            padding: 10px; 
            border-radius: 4px; 
            font-family: monospace; 
            white-space: pre-wrap; 
            max-height: 300px; 
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 IPv6 WireGuard Manager - 测试页面</h1>
        
        <div id="status" class="status loading">
            🔄 正在初始化测试...
        </div>
        
        <div>
            <button onclick="testBasicJS()">测试基础JavaScript</button>
            <button onclick="testReact()">测试React加载</button>
            <button onclick="testAPI()">测试API连接</button>
            <button onclick="clearLog()">清空日志</button>
        </div>
        
        <h3>📋 测试日志:</h3>
        <div id="log"></div>
        
        <h3>🔗 快速链接:</h3>
        <p>
            <a href="/" target="_blank">主页面</a> | 
            <a href="/api/v1/status" target="_blank">API状态</a> | 
            <a href="/health" target="_blank">健康检查</a>
        </p>
    </div>

    <script>
        const log = document.getElementById('log');
        const status = document.getElementById('status');
        
        function addLog(message, type = 'info') {
            const timestamp = new Date().toLocaleTimeString();
            const logEntry = `[${timestamp}] ${message}\n`;
            log.textContent += logEntry;
            log.scrollTop = log.scrollHeight;
            console.log(message);
        }
        
        function updateStatus(message, type = 'info') {
            status.textContent = message;
            status.className = `status ${type}`;
        }
        
        function testBasicJS() {
            addLog('开始测试基础JavaScript...');
            try {
                // 测试基础JavaScript功能
                const testArray = [1, 2, 3];
                const result = testArray.map(x => x * 2);
                addLog(`✅ 基础JavaScript测试通过: ${result.join(', ')}`);
                
                // 测试DOM操作
                const testDiv = document.createElement('div');
                testDiv.textContent = 'DOM操作测试';
                addLog('✅ DOM操作测试通过');
                
                updateStatus('✅ 基础JavaScript功能正常', 'success');
            } catch (error) {
                addLog(`❌ 基础JavaScript测试失败: ${error.message}`);
                updateStatus('❌ 基础JavaScript功能异常', 'error');
            }
        }
        
        function testReact() {
            addLog('开始测试React加载...');
            try {
                if (typeof React === 'undefined') {
                    addLog('❌ React未加载，尝试从CDN加载...');
                    
                    // 动态加载React
                    const script1 = document.createElement('script');
                    script1.src = 'https://unpkg.com/react@18/umd/react.production.min.js';
                    script1.onload = () => {
                        addLog('✅ React CDN加载成功');
                        testReactDOM();
                    };
                    script1.onerror = () => {
                        addLog('❌ React CDN加载失败');
                        updateStatus('❌ React加载失败', 'error');
                    };
                    document.head.appendChild(script1);
                } else {
                    addLog('✅ React已加载');
                    testReactDOM();
                }
            } catch (error) {
                addLog(`❌ React测试失败: ${error.message}`);
                updateStatus('❌ React加载异常', 'error');
            }
        }
        
        function testReactDOM() {
            try {
                if (typeof ReactDOM === 'undefined') {
                    addLog('❌ ReactDOM未加载，尝试从CDN加载...');
                    
                    const script2 = document.createElement('script');
                    script2.src = 'https://unpkg.com/react-dom@18/umd/react-dom.production.min.js';
                    script2.onload = () => {
                        addLog('✅ ReactDOM CDN加载成功');
                        testAntd();
                    };
                    script2.onerror = () => {
                        addLog('❌ ReactDOM CDN加载失败');
                        updateStatus('❌ ReactDOM加载失败', 'error');
                    };
                    document.head.appendChild(script2);
                } else {
                    addLog('✅ ReactDOM已加载');
                    testAntd();
                }
            } catch (error) {
                addLog(`❌ ReactDOM测试失败: ${error.message}`);
                updateStatus('❌ ReactDOM加载异常', 'error');
            }
        }
        
        function testAntd() {
            try {
                if (typeof antd === 'undefined') {
                    addLog('❌ Ant Design未加载，尝试从CDN加载...');
                    
                    const link = document.createElement('link');
                    link.rel = 'stylesheet';
                    link.href = 'https://unpkg.com/antd@5/dist/reset.css';
                    document.head.appendChild(link);
                    
                    const script3 = document.createElement('script');
                    script3.src = 'https://unpkg.com/antd@5/dist/antd.min.js';
                    script3.onload = () => {
                        addLog('✅ Ant Design CDN加载成功');
                        updateStatus('✅ 所有依赖加载成功', 'success');
                    };
                    script3.onerror = () => {
                        addLog('❌ Ant Design CDN加载失败');
                        updateStatus('❌ Ant Design加载失败', 'error');
                    };
                    document.head.appendChild(script3);
                } else {
                    addLog('✅ Ant Design已加载');
                    updateStatus('✅ 所有依赖加载成功', 'success');
                }
            } catch (error) {
                addLog(`❌ Ant Design测试失败: ${error.message}`);
                updateStatus('❌ Ant Design加载异常', 'error');
            }
        }
        
        function testAPI() {
            addLog('开始测试API连接...');
            updateStatus('🔄 正在测试API连接...', 'loading');
            
            fetch('/api/v1/status')
                .then(response => {
                    addLog(`API响应状态: ${response.status} ${response.statusText}`);
                    if (response.ok) {
                        return response.json();
                    } else {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }
                })
                .then(data => {
                    addLog(`✅ API连接成功: ${JSON.stringify(data)}`);
                    updateStatus('✅ API连接正常', 'success');
                })
                .catch(error => {
                    addLog(`❌ API连接失败: ${error.message}`);
                    updateStatus('❌ API连接失败', 'error');
                });
        }
        
        function clearLog() {
            log.textContent = '';
            addLog('日志已清空');
        }
        
        // 页面加载完成后自动运行基础测试
        window.addEventListener('load', () => {
            addLog('页面加载完成，开始自动测试...');
            testBasicJS();
            
            // 延迟测试API
            setTimeout(() => {
                testAPI();
            }, 1000);
        });
        
        // 错误处理
        window.addEventListener('error', (e) => {
            addLog(`❌ JavaScript错误: ${e.message} at ${e.filename}:${e.lineno}`);
            updateStatus('❌ 发现JavaScript错误', 'error');
        });
        
        // 网络错误处理
        window.addEventListener('unhandledrejection', (e) => {
            addLog(`❌ 未处理的Promise拒绝: ${e.reason}`);
            updateStatus('❌ 发现Promise错误', 'error');
        });
    </script>
</body>
</html>
EOF

log_success "测试页面创建完成"

# 4. 创建本地CDN备用方案
log_step "创建本地CDN备用方案..."
sudo mkdir -p "$FRONTEND_DIR/dist/libs"

# 下载React库到本地
echo "下载React库到本地..."
if curl -s -o "$FRONTEND_DIR/dist/libs/react.min.js" "https://unpkg.com/react@18/umd/react.production.min.js"; then
    log_success "React库下载成功"
else
    log_warning "React库下载失败"
fi

if curl -s -o "$FRONTEND_DIR/dist/libs/react-dom.min.js" "https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"; then
    log_success "ReactDOM库下载成功"
else
    log_warning "ReactDOM库下载失败"
fi

# 5. 创建使用本地库的HTML文件
log_step "创建使用本地库的HTML文件..."
sudo tee "$FRONTEND_DIR/dist/index-local.html" > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <script src="/libs/react.min.js"></script>
    <script src="/libs/react-dom.min.js"></script>
    <style>
        body { 
            margin: 0; 
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: #f0f2f5;
        }
        .loading {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-size: 18px;
            color: #1890ff;
        }
        .error {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-size: 18px;
            color: #ff4d4f;
            flex-direction: column;
        }
    </style>
</head>
<body>
    <div id="root">
        <div class="loading">🌐 正在加载 IPv6 WireGuard Manager...</div>
    </div>
    <script>
        try {
            const { useState, useEffect } = React;

            function Dashboard() {
                const [loading, setLoading] = useState(true);
                const [apiStatus, setApiStatus] = useState(null);
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
                    } catch (error) {
                        console.error('API连接失败:', error);
                        setError(error.message);
                    } finally {
                        setLoading(false);
                    }
                };

                useEffect(() => {
                    checkApiStatus();
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
                            style: { 
                                width: '40px', 
                                height: '40px', 
                                border: '4px solid #f3f3f3',
                                borderTop: '4px solid #1890ff',
                                borderRadius: '50%',
                                animation: 'spin 1s linear infinite'
                            }
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

                return React.createElement('div', { 
                    style: { 
                        padding: '20px',
                        maxWidth: '1200px',
                        margin: '0 auto'
                    }
                }, [
                    React.createElement('header', { 
                        key: 'header',
                        style: { 
                            background: '#fff', 
                            padding: '20px', 
                            borderRadius: '8px',
                            marginBottom: '20px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
                        }
                    }, [
                        React.createElement('h1', { 
                            key: 'title',
                            style: { margin: 0, color: '#1890ff' } 
                        }, '🌐 IPv6 WireGuard Manager'),
                        React.createElement('p', { 
                            key: 'status',
                            style: { margin: '8px 0 0 0', color: '#666' } 
                        }, `API状态: ${apiStatus ? apiStatus.status : '未知'}`)
                    ]),
                    React.createElement('div', { 
                        key: 'content',
                        style: { 
                            background: '#fff', 
                            padding: '20px', 
                            borderRadius: '8px',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
                        }
                    }, [
                        React.createElement('h2', { 
                            key: 'subtitle',
                            style: { marginTop: 0 } 
                        }, '系统状态'),
                        React.createElement('p', { 
                            key: 'info',
                            style: { color: '#666' } 
                        }, 'IPv6 WireGuard Manager 正在运行中...'),
                        React.createElement('button', { 
                            key: 'refresh',
                            onClick: checkApiStatus,
                            style: { 
                                marginTop: '16px',
                                padding: '8px 16px',
                                background: '#52c41a',
                                color: 'white',
                                border: 'none',
                                borderRadius: '4px',
                                cursor: 'pointer'
                            }
                        }, '刷新状态')
                    ])
                ]);
            }

            // 添加CSS动画
            const style = document.createElement('style');
            style.textContent = `
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
            `;
            document.head.appendChild(style);

            ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
        } catch (error) {
            console.error('应用启动失败:', error);
            document.getElementById('root').innerHTML = `
                <div class="error">
                    <h2>❌ 应用启动失败</h2>
                    <p>错误信息: ${error.message}</p>
                    <p>请检查浏览器控制台获取详细信息</p>
                </div>
            `;
        }
    </script>
</body>
</html>
EOF

log_success "本地库版本创建完成"

# 6. 更新Nginx配置以支持本地库
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

# 7. 设置文件权限
log_step "设置文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$FRONTEND_DIR"
sudo chmod -R 755 "$FRONTEND_DIR"

# 8. 显示诊断结果
log_step "显示诊断结果..."
echo "========================================"
echo -e "${GREEN}🎉 前端JavaScript诊断完成！${NC}"
echo ""
echo "📋 创建的文件："
echo "   ✅ 测试页面: http://localhost/test.html"
echo "   ✅ 本地库版本: http://localhost/index-local.html"
echo "   ✅ 本地React库: /libs/react.min.js"
echo "   ✅ 本地ReactDOM库: /libs/react-dom.min.js"
echo ""
echo "🔍 测试步骤："
echo "   1. 访问 http://localhost/test.html 进行完整诊断"
echo "   2. 访问 http://localhost/index-local.html 测试本地库版本"
echo "   3. 检查浏览器控制台的错误信息"
echo "   4. 查看网络面板的请求状态"
echo ""
echo "🌐 访问地址："
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)

if [ -n "$PUBLIC_IPV4" ]; then
    echo "   测试页面: http://$PUBLIC_IPV4/test.html"
    echo "   本地库版本: http://$PUBLIC_IPV4/index-local.html"
fi
echo "   测试页面 (本地): http://$LOCAL_IPV4/test.html"
echo "   本地库版本 (本地): http://$LOCAL_IPV4/index-local.html"
if [ -n "$IPV6_ADDRESS" ]; then
    echo "   测试页面 (IPv6): http://[$IPV6_ADDRESS]/test.html"
    echo "   本地库版本 (IPv6): http://[$IPV6_ADDRESS]/index-local.html"
fi
echo ""
echo "🔧 如果问题仍然存在："
echo "   1. 检查浏览器控制台的JavaScript错误"
echo "   2. 检查网络面板的CDN请求状态"
echo "   3. 尝试使用本地库版本 (index-local.html)"
echo "   4. 检查防火墙是否阻止了CDN访问"
echo ""
echo "========================================"
