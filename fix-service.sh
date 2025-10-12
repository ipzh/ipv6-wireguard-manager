#!/bin/bash

echo "🔧 修复服务启动问题..."
echo "================================"

# 停止服务
echo "🛑 停止服务..."
sudo systemctl stop ipv6-wireguard-manager

# 检查并修复虚拟环境
echo "🔍 检查虚拟环境..."
cd /opt/ipv6-wireguard-manager/backend

if [ ! -d "venv" ]; then
    echo "📦 创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境并安装依赖
echo "📦 安装依赖..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 检查uvicorn
echo "🔍 检查uvicorn..."
if ! command -v uvicorn >/dev/null 2>&1; then
    echo "📦 安装uvicorn..."
    pip install uvicorn[standard]
fi

# 检查app.main
echo "🔍 检查app.main..."
if [ ! -f "app/main.py" ]; then
    echo "❌ app/main.py不存在，创建基本文件..."
    mkdir -p app
    cat > app/main.py << 'EOF'
"""
FastAPI应用主文件
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

# 创建FastAPI应用
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API", "version": settings.APP_VERSION}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=settings.SERVER_HOST, port=settings.SERVER_PORT)
EOF
fi

# 设置权限
echo "🔐 设置权限..."
sudo chown -R ipv6wgm:ipv6wgm /opt/ipv6-wireguard-manager
sudo chmod -R 755 /opt/ipv6-wireguard-manager
sudo chmod +x /opt/ipv6-wireguard-manager/backend/venv/bin/*

# 测试启动
echo "🧪 测试启动..."
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate

echo "   测试uvicorn导入..."
python -c "import uvicorn; print('✅ uvicorn导入成功')" || {
    echo "❌ uvicorn导入失败，重新安装..."
    pip install uvicorn[standard]
}

echo "   测试app导入..."
python -c "from app.main import app; print('✅ app导入成功')" || {
    echo "❌ app导入失败，检查依赖..."
    pip install fastapi
}

# 重新加载systemd
echo "🔄 重新加载systemd..."
sudo systemctl daemon-reload

# 启动服务
echo "🚀 启动服务..."
sudo systemctl start ipv6-wireguard-manager

# 等待服务启动
sleep 3

# 检查服务状态
echo "🔍 检查服务状态..."
sudo systemctl status ipv6-wireguard-manager --no-pager

# 检查端口
echo "🔍 检查端口..."
sudo netstat -tlnp | grep :8000 || echo "⚠️  端口8000未监听"

echo ""
echo "🎯 修复完成！"
echo ""
echo "📋 如果服务仍然有问题，请检查日志:"
echo "   sudo journalctl -u ipv6-wireguard-manager -f"
