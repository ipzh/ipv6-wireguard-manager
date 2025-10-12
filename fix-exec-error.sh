#!/bin/bash

echo "🔧 修复203/EXEC错误..."
echo "================================"

# 停止服务
echo "🛑 停止服务..."
sudo systemctl stop ipv6-wireguard-manager

# 进入后端目录
cd /opt/ipv6-wireguard-manager/backend

echo "🔍 检查当前状态..."
echo "   当前目录: $(pwd)"
echo "   用户: $(whoami)"

# 检查虚拟环境
echo "🔍 检查虚拟环境..."
if [ -d "venv" ]; then
    echo "✅ 虚拟环境存在"
    ls -la venv/bin/ | head -10
else
    echo "❌ 虚拟环境不存在，重新创建..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "🔍 激活虚拟环境..."
source venv/bin/activate

# 检查Python和pip
echo "🔍 检查Python环境..."
echo "   Python版本: $(python --version)"
echo "   Python路径: $(which python)"
echo "   pip版本: $(pip --version)"

# 重新安装依赖
echo "📦 重新安装依赖..."
pip install --upgrade pip
pip install -r requirements.txt

# 检查uvicorn
echo "🔍 检查uvicorn..."
UVICORN_PATH="venv/bin/uvicorn"
if [ -f "$UVICORN_PATH" ]; then
    echo "✅ uvicorn存在: $UVICORN_PATH"
    ls -la "$UVICORN_PATH"
    echo "   文件权限: $(stat -c '%A %n' "$UVICORN_PATH")"
else
    echo "❌ uvicorn不存在，重新安装..."
    pip install uvicorn[standard]
fi

# 检查uvicorn可执行性
echo "🔍 测试uvicorn可执行性..."
if [ -x "$UVICORN_PATH" ]; then
    echo "✅ uvicorn可执行"
else
    echo "❌ uvicorn不可执行，修复权限..."
    chmod +x "$UVICORN_PATH"
fi

# 测试uvicorn导入
echo "🔍 测试uvicorn导入..."
python -c "import uvicorn; print('✅ uvicorn导入成功')" || {
    echo "❌ uvicorn导入失败，重新安装..."
    pip uninstall uvicorn -y
    pip install uvicorn[standard]
}

# 检查app.main
echo "🔍 检查app.main..."
if [ -f "app/main.py" ]; then
    echo "✅ app/main.py存在"
    ls -la app/main.py
else
    echo "❌ app/main.py不存在，创建..."
    mkdir -p app
    cat > app/main.py << 'EOF'
"""
FastAPI应用主文件
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 创建FastAPI应用
app = FastAPI(
    title="IPv6 WireGuard Manager",
    version="3.0.0",
    debug=False
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API", "version": "3.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
EOF
fi

# 测试app导入
echo "🔍 测试app导入..."
python -c "from app.main import app; print('✅ app导入成功')" || {
    echo "❌ app导入失败，检查依赖..."
    pip install fastapi
    python -c "from app.main import app; print('✅ app导入成功')"
}

# 设置权限
echo "🔐 设置权限..."
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
sudo chmod +x /opt/ipv6-wireguard-manager/backend/venv/bin/*

# 测试手动启动
echo "🧪 测试手动启动..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate

echo "   测试uvicorn启动..."
timeout 5 python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1 &
UVICORN_PID=$!
sleep 3
if kill -0 $UVICORN_PID 2>/dev/null; then
    echo "✅ uvicorn手动启动成功"
    kill $UVICORN_PID
else
    echo "❌ uvicorn手动启动失败"
fi

# 更新systemd服务文件
echo "🔧 更新systemd服务文件..."
sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=redis-server.service redis.service

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=/opt/ipv6-wireguard-manager/backend
Environment=PATH=/opt/ipv6-wireguard-manager/backend/venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/opt/ipv6-wireguard-manager/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
echo "🔄 重新加载systemd..."
sudo systemctl daemon-reload

# 启动服务
echo "🚀 启动服务..."
sudo systemctl start ipv6-wireguard-manager

# 等待服务启动
sleep 5

# 检查服务状态
echo "🔍 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager

# 检查端口
echo "🔍 检查端口..."
if command -v ss >/dev/null 2>&1; then
    ss -tlnp | grep :8000 || echo "⚠️  端口8000未监听"
elif command -v netstat >/dev/null 2>&1; then
    netstat -tlnp | grep :8000 || echo "⚠️  端口8000未监听"
else
    echo "⚠️  无法检查端口（ss和netstat都不可用）"
fi

# 测试API
echo "🔍 测试API..."
if curl -s http://localhost:8000/health >/dev/null; then
    echo "✅ API响应正常"
    curl -s http://localhost:8000/health
else
    echo "❌ API无响应"
fi

echo ""
echo "🎯 修复完成！"
echo ""
echo "📋 如果服务仍有问题，请检查日志:"
echo "   sudo journalctl -u ipv6-wireguard-manager -f"
