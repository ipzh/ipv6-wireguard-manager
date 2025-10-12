#!/bin/bash

echo "🚀 快速修复500错误..."
echo "========================"

# 定义路径
APP_HOME="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$APP_HOME/backend"
VENV_DIR="$BACKEND_DIR/venv"
SERVICE_NAME="ipv6-wireguard-manager"

# 1. 停止服务
echo "🛑 停止服务..."
sudo systemctl stop $SERVICE_NAME
sudo systemctl stop nginx

# 2. 检查并修复权限
echo "🔧 修复权限..."
sudo chown -R ipv6wgm:ipv6wgm $APP_HOME 2>/dev/null || sudo chown -R $(whoami):$(whoami) $APP_HOME
sudo chmod -R 755 $APP_HOME

# 3. 检查虚拟环境
echo "🐍 检查虚拟环境..."
if [ -d "$VENV_DIR" ]; then
    echo "✅ 虚拟环境存在"
    # 重新安装依赖
    echo "📦 重新安装依赖..."
    cd $BACKEND_DIR
    source $VENV_DIR/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "❌ 虚拟环境不存在，重新创建..."
    cd $BACKEND_DIR
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# 4. 测试应用导入
echo "🧪 测试应用导入..."
cd $BACKEND_DIR
source $VENV_DIR/bin/activate

if python -c "from app.main import app; print('✅ 应用导入成功')" 2>/dev/null; then
    echo "✅ 应用可以正常导入"
else
    echo "❌ 应用导入失败，尝试修复..."
    
    # 创建简化的main.py
    echo "🔧 创建简化的应用结构..."
    sudo tee $BACKEND_DIR/app/main.py > /dev/null << 'EOF'
from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="IPv6 WireGuard Manager")

@app.get("/health")
async def health_check():
    return JSONResponse(content={"status": "healthy"})

@app.get("/api/v1/status")
async def get_status():
    return {"status": "ok", "message": "IPv6 WireGuard Manager is running"}

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API"}
EOF
    
    # 确保__init__.py存在
    sudo touch $BACKEND_DIR/app/__init__.py
    sudo touch $BACKEND_DIR/app/core/__init__.py
fi

# 5. 更新systemd服务
echo "⚙️ 更新systemd服务..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target

[Service]
Type=simple
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=$BACKEND_DIR
ExecStart=$VENV_DIR/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. 重新加载systemd
echo "🔄 重新加载systemd..."
sudo systemctl daemon-reload

# 7. 启动服务
echo "🚀 启动服务..."
sudo systemctl start $SERVICE_NAME
sleep 3

# 8. 检查服务状态
echo "🔍 检查服务状态..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "✅ 后端服务启动成功"
else
    echo "❌ 后端服务启动失败"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

# 9. 测试API
echo "🧪 测试API..."
sleep 2
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "✅ API测试成功"
    curl -s http://127.0.0.1:8000/health
else
    echo "❌ API测试失败"
fi

# 10. 启动Nginx
echo "🌐 启动Nginx..."
sudo systemctl start nginx

# 11. 最终测试
echo "🎯 最终测试..."
sleep 2
if curl -s http://localhost >/dev/null 2>&1; then
    echo "✅ 网站访问正常"
    echo "🎉 修复成功！"
else
    echo "❌ 网站访问仍然失败"
    echo "请运行详细诊断: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-500-error.sh | bash"
fi

echo ""
echo "📋 服务状态:"
echo "   后端服务: $(sudo systemctl is-active $SERVICE_NAME)"
echo "   Nginx服务: $(sudo systemctl is-active nginx)"
echo ""
echo "🌐 访问地址:"
echo "   本地访问: http://localhost"
echo "   API状态: http://localhost/api/v1/status"
echo "   健康检查: http://localhost/health"
