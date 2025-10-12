#!/bin/bash

# 修复前端空白页面问题
echo "🔧 开始修复前端空白页面问题..."

APP_HOME="/opt/ipv6-wireguard-manager"

echo "🔧 检查前端目录..."
if [ ! -d "$APP_HOME/frontend" ]; then
    echo "❌ 前端目录不存在，正在创建..."
    sudo mkdir -p "$APP_HOME/frontend/dist"
fi

echo "🔧 检查后端服务状态..."
if ! sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "❌ 后端服务未运行，正在启动..."
    sudo systemctl start ipv6-wireguard-manager
    sleep 5
fi

echo "🔧 测试API连接..."
if curl -s "http://localhost:8000/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API连接正常"
    API_STATUS="ok"
else
    echo "❌ API连接异常"
    API_STATUS="error"
fi

echo "🔧 创建完整的前端页面..."
sudo tee "$APP_HOME/frontend/dist/index.html" > /dev/null << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        
        .container {
            background: white;
            padding: 2rem;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
            width: 90%;
            margin: 20px;
        }
        
        .logo {
            font-size: 2.5rem;
            font-weight: bold;
            color: #333;
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .status {
            padding: 1.5rem;
            border-radius: 10px;
            margin: 1.5rem 0;
            font-size: 1.1rem;
            line-height: 1.6;
        }
        
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 2px solid #c3e6cb;
        }
        
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 2px solid #f5c6cb;
        }
        
        .status.loading {
            background: #d1ecf1;
            color: #0c5460;
            border: 2px solid #bee5eb;
        }
        
        .btn {
            display: inline-block;
            padding: 0.75rem 1.5rem;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            margin: 0.5rem;
            transition: all 0.3s ease;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }
        
        .btn:hover {
            background: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,123,255,0.3);
        }
        
        .btn.secondary {
            background: #6c757d;
        }
        
        .btn.secondary:hover {
            background: #545b62;
        }
        
        .info {
            margin-top: 2rem;
            font-size: 0.95rem;
            color: #666;
            line-height: 1.6;
        }
        
        .info h3 {
            color: #333;
            margin-bottom: 1rem;
        }
        
        .info p {
            margin-bottom: 0.5rem;
        }
        
        .loading-spinner {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid #f3f3f3;
            border-top: 3px solid #007bff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-right: 10px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .actions {
            margin: 1.5rem 0;
        }
        
        .system-info {
            background: #f8f9fa;
            padding: 1rem;
            border-radius: 8px;
            margin-top: 1rem;
            text-align: left;
        }
        
        .system-info h4 {
            color: #495057;
            margin-bottom: 0.5rem;
        }
        
        .system-info ul {
            list-style: none;
            padding: 0;
        }
        
        .system-info li {
            padding: 0.25rem 0;
            color: #6c757d;
        }
        
        .system-info li:before {
            content: "• ";
            color: #007bff;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            🌐 IPv6 WireGuard Manager
        </div>
        
        <div id="status" class="status loading">
            <div class="loading-spinner"></div>
            正在检查系统状态...
        </div>
        
        <div id="actions" class="actions" style="display: none;">
            <a href="/docs" class="btn">📚 API文档</a>
            <a href="/health" class="btn secondary">❤️ 健康检查</a>
            <button onclick="refreshStatus()" class="btn secondary">🔄 刷新状态</button>
        </div>
        
        <div class="info">
            <h3>系统信息</h3>
            <p><strong>版本:</strong> v1.0.0</p>
            <p><strong>默认登录:</strong> admin / admin123</p>
            <p><strong>系统类型:</strong> IPv6 WireGuard VPN 管理系统</p>
        </div>
        
        <div class="system-info">
            <h4>系统功能</h4>
            <ul>
                <li>WireGuard 服务器管理</li>
                <li>客户端配置管理</li>
                <li>BGP 宣告管理</li>
                <li>用户权限管理</li>
                <li>系统监控统计</li>
                <li>域名与SSL配置</li>
            </ul>
        </div>
    </div>

    <script>
        let checkCount = 0;
        const maxChecks = 10;
        
        async function checkStatus() {
            const statusDiv = document.getElementById('status');
            const actionsDiv = document.getElementById('actions');
            
            checkCount++;
            
            try {
                console.log(`检查API状态 (${checkCount}/${maxChecks})...`);
                
                const response = await fetch('/api/v1/status/status', {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                        'Content-Type': 'application/json'
                    },
                    timeout: 5000
                });
                
                if (response.ok) {
                    const data = await response.json();
                    console.log('API响应:', data);
                    
                    statusDiv.className = 'status success';
                    statusDiv.innerHTML = `
                        <div>✅ 系统运行正常</div>
                        <div><strong>服务:</strong> ${data.service || 'IPv6 WireGuard Manager'}</div>
                        <div><strong>版本:</strong> ${data.version || '1.0.0'}</div>
                        <div><strong>状态:</strong> ${data.status || 'ok'}</div>
                        <div><strong>消息:</strong> ${data.message || '系统正常运行'}</div>
                    `;
                    actionsDiv.style.display = 'block';
                    
                    // 成功后就停止检查
                    return;
                } else {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
            } catch (error) {
                console.error('API检查失败:', error);
                
                if (checkCount < maxChecks) {
                    // 继续尝试
                    statusDiv.className = 'status loading';
                    statusDiv.innerHTML = `
                        <div class="loading-spinner"></div>
                        正在检查系统状态... (${checkCount}/${maxChecks})
                        <div style="font-size: 0.9rem; margin-top: 0.5rem; color: #666;">
                            错误: ${error.message}
                        </div>
                    `;
                    
                    // 3秒后重试
                    setTimeout(checkStatus, 3000);
                } else {
                    // 达到最大重试次数
                    statusDiv.className = 'status error';
                    statusDiv.innerHTML = `
                        <div>❌ 系统连接异常</div>
                        <div><strong>错误:</strong> ${error.message}</div>
                        <div><strong>尝试次数:</strong> ${checkCount}</div>
                        <div style="margin-top: 1rem; font-size: 0.9rem;">
                            请检查后端服务状态或联系管理员
                        </div>
                    `;
                    actionsDiv.style.display = 'block';
                }
            }
        }
        
        function refreshStatus() {
            checkCount = 0;
            checkStatus();
        }
        
        // 页面加载时开始检查
        document.addEventListener('DOMContentLoaded', function() {
            console.log('页面加载完成，开始检查系统状态...');
            checkStatus();
        });
        
        // 每30秒自动检查一次（仅在成功连接后）
        setInterval(() => {
            if (checkCount === 0 || checkCount >= maxChecks) {
                checkStatus();
            }
        }, 30000);
    </script>
</body>
</html>
HTML_EOF

echo "✅ 已创建完整的前端页面"

echo "🔧 设置正确的文件权限..."
sudo chown -R ipv6wgm:ipv6wgm "$APP_HOME/frontend"
sudo chmod -R 755 "$APP_HOME/frontend"

echo "🔧 检查Nginx配置..."
if [ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]; then
    echo "✅ Nginx配置存在"
else
    echo "❌ Nginx配置不存在，正在创建..."
    
    sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << 'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # 添加缓存控制
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API代理到后端
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API文档
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # ReDoc文档
    location /redoc {
        proxy_pass http://127.0.0.1:8000/redoc;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
NGINX_EOF
    
    # 启用站点
    sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    if sudo nginx -t; then
        echo "✅ Nginx配置测试通过"
        sudo systemctl restart nginx
    else
        echo "❌ Nginx配置测试失败"
    fi
fi

echo "🔧 重启Nginx服务..."
sudo systemctl restart nginx

echo "⏳ 等待服务启动..."
sleep 5

echo "🔍 检查服务状态..."
echo "📋 Nginx状态:"
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx服务运行正常"
else
    echo "❌ Nginx服务异常"
    sudo systemctl status nginx --no-pager -l
fi

echo "📋 后端服务状态:"
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务异常"
    sudo systemctl status ipv6-wireguard-manager --no-pager -l
fi

echo "🔍 测试Web访问..."
if curl -s "http://localhost" | grep -q "IPv6 WireGuard Manager"; then
    echo "✅ Web访问正常"
    echo "📋 页面内容预览:"
    curl -s "http://localhost" | grep -E "(IPv6 WireGuard Manager|系统运行正常|系统连接异常)" | head -3
else
    echo "❌ Web访问异常"
    echo "📋 响应内容:"
    curl -s "http://localhost" | head -10
fi

echo "🔍 测试API访问..."
if curl -s "http://localhost/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API访问正常"
    echo "📋 API响应:"
    curl -s "http://localhost/api/v1/status/status" | head -c 200
    echo ""
else
    echo "❌ API访问异常"
    echo "📋 尝试直接测试后端:"
    curl -s "http://localhost:8000/api/v1/status/status" | head -c 100
    echo ""
fi

echo ""
echo "🎉 前端空白页面修复完成！"
echo ""
echo "📋 访问信息:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')
echo "   Web界面: http://$SERVER_IP"
echo "   API文档: http://$SERVER_IP/docs"
echo "   健康检查: http://$SERVER_IP/health"
echo ""
echo "🔧 如果仍有问题，请检查:"
echo "   1. 后端服务: sudo systemctl status ipv6-wireguard-manager"
echo "   2. Nginx状态: sudo systemctl status nginx"
echo "   3. 服务日志: sudo journalctl -u ipv6-wireguard-manager -f"
echo "   4. 前端文件: ls -la $APP_HOME/frontend/dist/"
echo "   5. 端口占用: sudo netstat -tlnp | grep -E ':(80|8000)'"