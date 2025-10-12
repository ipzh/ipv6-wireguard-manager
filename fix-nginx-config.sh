#!/bin/bash

# 修复Nginx配置问题
echo "🔧 开始修复Nginx配置问题..."

APP_HOME="/opt/ipv6-wireguard-manager"

echo "🔧 检查Nginx状态..."
if ! sudo systemctl is-active --quiet nginx; then
    echo "❌ Nginx服务未运行，正在启动..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

echo "✅ Nginx服务运行正常"

echo "🔧 检查前端文件..."
if [ ! -d "$APP_HOME/frontend/dist" ]; then
    echo "❌ 前端dist目录不存在，正在创建..."
    mkdir -p "$APP_HOME/frontend/dist"
    
    # 创建简单的前端页面
    cat > "$APP_HOME/frontend/dist/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
            width: 90%;
        }
        .logo {
            font-size: 2rem;
            font-weight: bold;
            color: #333;
            margin-bottom: 1rem;
        }
        .status {
            padding: 1rem;
            border-radius: 5px;
            margin: 1rem 0;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .btn {
            display: inline-block;
            padding: 0.75rem 1.5rem;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 0.5rem;
            transition: background 0.3s;
        }
        .btn:hover {
            background: #0056b3;
        }
        .info {
            margin-top: 1rem;
            font-size: 0.9rem;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌐 IPv6 WireGuard Manager</div>
        
        <div id="status" class="status">
            <div>正在检查系统状态...</div>
        </div>
        
        <div id="actions" style="display: none;">
            <a href="/api/docs" class="btn">API文档</a>
            <a href="/health" class="btn">健康检查</a>
        </div>
        
        <div class="info">
            <p>系统版本: v1.0.0</p>
            <p>默认登录: admin / admin123</p>
        </div>
    </div>

    <script>
        async function checkStatus() {
            const statusDiv = document.getElementById('status');
            const actionsDiv = document.getElementById('actions');
            
            try {
                // 检查API状态
                const response = await fetch('/api/v1/status/status');
                if (response.ok) {
                    const data = await response.json();
                    statusDiv.className = 'status success';
                    statusDiv.innerHTML = `
                        <div>✅ 系统运行正常</div>
                        <div>服务: ${data.service}</div>
                        <div>版本: ${data.version}</div>
                        <div>状态: ${data.status}</div>
                    `;
                    actionsDiv.style.display = 'block';
                } else {
                    throw new Error('API响应异常');
                }
            } catch (error) {
                statusDiv.className = 'status error';
                statusDiv.innerHTML = `
                    <div>❌ 系统连接异常</div>
                    <div>错误: ${error.message}</div>
                    <div>请检查后端服务状态</div>
                `;
            }
        }
        
        // 页面加载时检查状态
        checkStatus();
        
        // 每30秒检查一次状态
        setInterval(checkStatus, 30000);
    </script>
</body>
</html>
HTML_EOF
    
    echo "✅ 已创建前端页面"
fi

echo "🔧 配置Nginx..."
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

echo "✅ 已创建Nginx站点配置"

echo "🔧 启用站点配置..."
sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/

echo "🔧 禁用默认站点..."
sudo rm -f /etc/nginx/sites-enabled/default

echo "🔧 测试Nginx配置..."
if sudo nginx -t; then
    echo "✅ Nginx配置测试通过"
else
    echo "❌ Nginx配置测试失败"
    exit 1
fi

echo "🔧 重启Nginx服务..."
sudo systemctl restart nginx

echo "⏳ 等待服务启动..."
sleep 5

echo "🔍 检查Nginx状态..."
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx服务运行正常"
else
    echo "❌ Nginx服务异常"
    sudo systemctl status nginx --no-pager -l
fi

echo "🔍 检查后端服务状态..."
if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务异常"
    sudo systemctl status ipv6-wireguard-manager --no-pager -l
fi

echo "🔍 测试Web访问..."
if curl -s "http://localhost" | grep -q "IPv6 WireGuard Manager"; then
    echo "✅ Web访问正常"
else
    echo "❌ Web访问异常"
    echo "📋 响应内容:"
    curl -s "http://localhost" | head -10
fi

echo "🔍 测试API访问..."
if curl -s "http://localhost/api/v1/status/status" >/dev/null 2>&1; then
    echo "✅ API访问正常"
else
    echo "❌ API访问异常"
fi

echo "🔍 测试健康检查..."
if curl -s "http://localhost/health" >/dev/null 2>&1; then
    echo "✅ 健康检查正常"
else
    echo "❌ 健康检查异常"
fi

echo ""
echo "🎉 Nginx配置修复完成！"
echo ""
echo "📋 访问信息:"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')
echo "   Web界面: http://$SERVER_IP"
echo "   API文档: http://$SERVER_IP/docs"
echo "   健康检查: http://$SERVER_IP/health"
echo ""
echo "🔧 管理命令:"
echo "   查看Nginx状态: sudo systemctl status nginx"
echo "   查看Nginx日志: sudo journalctl -u nginx -f"
echo "   重启Nginx: sudo systemctl restart nginx"
echo "   测试配置: sudo nginx -t"
echo ""
echo "🔧 如果仍有问题，请检查:"
echo "   1. 后端服务: sudo systemctl status ipv6-wireguard-manager"
echo "   2. 端口占用: sudo netstat -tlnp | grep -E ':(80|8000)'"
echo "   3. Nginx配置: sudo nginx -t"
echo "   4. 前端文件: ls -la $APP_HOME/frontend/dist/"
