#!/bin/bash

echo "🔧 修复500 Internal Server Error..."
echo "========================================"

# 定义路径
APP_HOME="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$APP_HOME/backend"
VENV_DIR="$BACKEND_DIR/venv"
SERVICE_NAME="ipv6-wireguard-manager"

# 日志函数
log_step() {
    echo "🚀 [STEP] $1"
}

log_info() {
    echo "💡 [INFO] $1"
}

log_success() {
    echo "✅ [SUCCESS] $1"
}

log_warning() {
    echo "⚠️  [WARNING] $1"
}

log_error() {
    echo "❌ [ERROR] $1"
}

# 1. 检查服务状态
log_step "检查服务状态..."
echo "后端服务状态:"
sudo systemctl status $SERVICE_NAME --no-pager -l

echo ""
echo "Nginx服务状态:"
sudo systemctl status nginx --no-pager -l

# 2. 检查端口监听
log_step "检查端口监听..."
echo "端口8000监听状态:"
ss -tlnp | grep :8000

echo ""
echo "端口80监听状态:"
ss -tlnp | grep :80

# 3. 检查后端日志
log_step "检查后端服务日志..."
echo "最近的后端服务日志:"
sudo journalctl -u $SERVICE_NAME --no-pager -l -n 20

# 4. 检查Nginx日志
log_step "检查Nginx错误日志..."
echo "Nginx错误日志:"
sudo tail -20 /var/log/nginx/error.log

echo ""
echo "Nginx访问日志:"
sudo tail -10 /var/log/nginx/access.log

# 5. 测试后端API直接访问
log_step "测试后端API直接访问..."
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    log_success "后端API直接访问正常"
    curl -s http://127.0.0.1:8000/health
else
    log_error "后端API直接访问失败"
    echo "尝试手动启动后端服务..."
    
    # 检查虚拟环境
    if [ -f "$VENV_DIR/bin/activate" ]; then
        log_info "激活虚拟环境并测试..."
        source "$VENV_DIR/bin/activate"
        
        # 测试Python导入
        if python -c "from app.main import app; print('✅ app导入成功')" 2>/dev/null; then
            log_success "app模块导入正常"
        else
            log_error "app模块导入失败"
            echo "错误详情:"
            python -c "from app.main import app" 2>&1
        fi
        
        # 测试uvicorn
        if python -c "import uvicorn; print('✅ uvicorn导入成功')" 2>/dev/null; then
            log_success "uvicorn模块导入正常"
        else
            log_error "uvicorn模块导入失败"
        fi
    else
        log_error "虚拟环境不存在: $VENV_DIR"
    fi
fi

# 6. 检查文件权限
log_step "检查文件权限..."
echo "应用目录权限:"
ls -la "$APP_HOME"

echo ""
echo "后端目录权限:"
ls -la "$BACKEND_DIR"

echo ""
echo "虚拟环境权限:"
ls -la "$VENV_DIR/bin/" | head -10

# 7. 检查Nginx配置
log_step "检查Nginx配置..."
echo "Nginx配置语法:"
sudo nginx -t

echo ""
echo "当前Nginx站点配置:"
if [ -f /etc/nginx/sites-available/ipv6-wireguard-manager ]; then
    cat /etc/nginx/sites-available/ipv6-wireguard-manager
else
    log_warning "Nginx站点配置文件不存在"
fi

# 8. 检查前端文件
log_step "检查前端文件..."
if [ -d "$APP_HOME/frontend/dist" ]; then
    log_success "前端dist目录存在"
    echo "前端文件列表:"
    ls -la "$APP_HOME/frontend/dist" | head -10
else
    log_error "前端dist目录不存在: $APP_HOME/frontend/dist"
fi

# 9. 尝试修复
log_step "尝试修复问题..."

# 重启服务
echo "重启后端服务..."
sudo systemctl restart $SERVICE_NAME
sleep 3

echo "重启Nginx服务..."
sudo systemctl restart nginx
sleep 2

# 检查服务状态
log_step "检查修复后的服务状态..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log_success "后端服务运行正常"
else
    log_error "后端服务仍然异常"
    echo "服务状态:"
    sudo systemctl status $SERVICE_NAME --no-pager -l
fi

if sudo systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务仍然异常"
    echo "服务状态:"
    sudo systemctl status nginx --no-pager -l
fi

# 10. 最终测试
log_step "最终测试..."
echo "测试本地访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "本地访问正常"
else
    log_error "本地访问仍然失败"
    echo "响应内容:"
    curl -v http://localhost 2>&1 | head -20
fi

echo ""
echo "测试API访问:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "API访问正常"
    curl -s http://localhost/api/v1/status
else
    log_error "API访问仍然失败"
    echo "响应内容:"
    curl -v http://localhost/api/v1/status 2>&1 | head -20
fi

echo ""
echo "========================================"
echo "🔍 诊断完成！"
echo ""
echo "📋 常见解决方案:"
echo "1. 如果后端服务未运行:"
echo "   sudo systemctl start $SERVICE_NAME"
echo "   sudo systemctl enable $SERVICE_NAME"
echo ""
echo "2. 如果虚拟环境有问题:"
echo "   cd $BACKEND_DIR"
echo "   source venv/bin/activate"
echo "   pip install -r requirements.txt"
echo ""
echo "3. 如果Nginx配置有问题:"
echo "   sudo nginx -t"
echo "   sudo systemctl restart nginx"
echo ""
echo "4. 如果权限有问题:"
echo "   sudo chown -R ipv6wgm:ipv6wgm $APP_HOME"
echo "   sudo chmod -R 755 $APP_HOME"
echo ""
echo "5. 查看详细日志:"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo "   sudo tail -f /var/log/nginx/error.log"
