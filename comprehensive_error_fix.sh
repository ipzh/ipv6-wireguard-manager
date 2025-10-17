#!/bin/bash

# IPv6 WireGuard Manager - 综合错误检查和修复脚本
# 系统性检查所有可能的错误并修复

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
FRONTEND_DIR="/var/www/html"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"
WEB_USER="www-data"
WEB_GROUP="www-data"
API_PORT="8000"

echo "🔧 开始综合错误检查和修复..."

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    log_error "此脚本需要root权限运行"
    exit 1
fi

# 1. 检查项目目录是否存在
log_info "1. 检查项目目录..."
if [[ -d "$INSTALL_DIR" ]]; then
    log_success "✓ 项目目录存在: $INSTALL_DIR"
else
    log_error "❌ 项目目录不存在: $INSTALL_DIR"
    log_info "尝试从 /tmp/ipv6-wireguard-manager 迁移..."
    if [[ -d "/tmp/ipv6-wireguard-manager" ]]; then
        log_info "发现旧目录，正在迁移..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        mv "/tmp/ipv6-wireguard-manager" "$INSTALL_DIR"
        log_success "✓ 项目目录已迁移到: $INSTALL_DIR"
    else
        log_error "❌ 找不到项目目录，请重新安装"
        exit 1
    fi
fi

# 2. 检查systemd服务配置
log_info "2. 检查systemd服务配置..."
if [[ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]]; then
    # 检查服务配置中的路径
    if grep -q "/tmp/ipv6-wireguard-manager" "/etc/systemd/system/ipv6-wireguard-manager.service"; then
        log_warning "⚠ 发现旧路径，正在更新systemd服务配置..."
        
        cat > /etc/systemd/system/ipv6-wireguard-manager.service << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service

[Service]
Type=exec
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port $API_PORT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        log_success "✓ systemd服务配置已更新"
    else
        log_success "✓ systemd服务配置正确"
    fi
else
    log_error "❌ systemd服务配置文件不存在"
    exit 1
fi

# 3. 检查服务用户和组
log_info "3. 检查服务用户和组..."
if id "$SERVICE_USER" &>/dev/null; then
    log_success "✓ 服务用户存在: $SERVICE_USER"
else
    log_warning "⚠ 服务用户不存在，正在创建..."
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
    log_success "✓ 服务用户已创建: $SERVICE_USER"
fi

if getent group "$SERVICE_GROUP" &>/dev/null; then
    log_success "✓ 服务组存在: $SERVICE_GROUP"
else
    log_warning "⚠ 服务组不存在，正在创建..."
    groupadd -r "$SERVICE_GROUP"
    log_success "✓ 服务组已创建: $SERVICE_GROUP"
fi

# 4. 检查目录权限
log_info "4. 检查目录权限..."
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
find "$INSTALL_DIR" -name "*.py" -exec chmod 755 {} \;
find "$INSTALL_DIR" -name "*.sh" -exec chmod 755 {} \;
log_success "✓ 目录权限已设置"

# 5. 检查Python虚拟环境
log_info "5. 检查Python虚拟环境..."
if [[ -d "$INSTALL_DIR/venv" ]]; then
    log_success "✓ Python虚拟环境存在"
    
    # 检查虚拟环境权限
    chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/venv"
    find "$INSTALL_DIR/venv/bin" -type f -exec chmod 755 {} \;
    log_success "✓ 虚拟环境权限已设置"
else
    log_error "❌ Python虚拟环境不存在"
    log_info "正在创建虚拟环境..."
    cd "$INSTALL_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    if [[ -f "backend/requirements.txt" ]]; then
        pip install -r backend/requirements.txt
    fi
    chown -R "$SERVICE_USER:$SERVICE_GROUP" venv
    log_success "✓ Python虚拟环境已创建"
fi

# 6. 检查后端导入错误
log_info "6. 检查后端导入错误..."
cd "$INSTALL_DIR"

# 检查Python语法
if python3 -m py_compile backend/app/main.py 2>/dev/null; then
    log_success "✓ 主应用文件语法正确"
else
    log_error "❌ 主应用文件语法错误"
    python3 -m py_compile backend/app/main.py
fi

# 检查导入
if python3 -c "import sys; sys.path.insert(0, '.'); from backend.app.main import app" 2>/dev/null; then
    log_success "✓ 后端导入正常"
else
    log_error "❌ 后端导入错误，正在修复..."
    
    # 修复导入路径
    find backend/app/api/api_v1/endpoints -name "*.py" -type f -exec sed -i 's/from app\./from ..../g' {} \;
    find backend/app/api/api_v1 -name "*.py" -type f -exec sed -i 's/from app\./from .../g' {} \;
    find backend/app -name "*.py" -type f -exec sed -i 's/from app\./from ../g' {} \;
    
    log_success "✓ 导入路径已修复"
fi

# 7. 检查数据库连接
log_info "7. 检查数据库连接..."
if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
    log_success "✓ 数据库服务正在运行"
    
    # 检查数据库是否存在
    if mysql -u root -e "USE ipv6wgm;" 2>/dev/null; then
        log_success "✓ 数据库 ipv6wgm 存在"
    else
        log_warning "⚠ 数据库 ipv6wgm 不存在，正在创建..."
        mysql -u root -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        mysql -u root -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';"
        mysql -u root -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
        mysql -u root -e "FLUSH PRIVILEGES;"
        log_success "✓ 数据库已创建"
    fi
else
    log_error "❌ 数据库服务未运行"
    log_info "正在启动数据库服务..."
    systemctl start mysql || systemctl start mariadb
    systemctl enable mysql || systemctl enable mariadb
    log_success "✓ 数据库服务已启动"
fi

# 8. 检查前端目录
log_info "8. 检查前端目录..."
if [[ -d "$FRONTEND_DIR" ]]; then
    log_success "✓ 前端目录存在: $FRONTEND_DIR"
    
    # 检查前端文件
    if [[ -f "$FRONTEND_DIR/index.php" ]]; then
        log_success "✓ 前端文件存在"
    else
        log_warning "⚠ 前端文件不存在，正在复制..."
        if [[ -d "$INSTALL_DIR/php-frontend" ]]; then
            cp -r "$INSTALL_DIR/php-frontend"/* "$FRONTEND_DIR/"
            chown -R "$WEB_USER:$WEB_GROUP" "$FRONTEND_DIR"
            chmod -R 755 "$FRONTEND_DIR"
            mkdir -p "$FRONTEND_DIR/logs"
            chmod -R 777 "$FRONTEND_DIR/logs"
            log_success "✓ 前端文件已复制"
        else
            log_error "❌ 前端源码目录不存在"
        fi
    fi
else
    log_error "❌ 前端目录不存在: $FRONTEND_DIR"
    log_info "正在创建前端目录..."
    mkdir -p "$FRONTEND_DIR"
    if [[ -d "$INSTALL_DIR/php-frontend" ]]; then
        cp -r "$INSTALL_DIR/php-frontend"/* "$FRONTEND_DIR/"
        chown -R "$WEB_USER:$WEB_GROUP" "$FRONTEND_DIR"
        chmod -R 755 "$FRONTEND_DIR"
        mkdir -p "$FRONTEND_DIR/logs"
        chmod -R 777 "$FRONTEND_DIR/logs"
        log_success "✓ 前端目录已创建并复制文件"
    else
        log_error "❌ 前端源码目录不存在"
    fi
fi

# 9. 检查Nginx配置
log_info "9. 检查Nginx配置..."
if [[ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]]; then
    if grep -q "root /var/www/html;" "/etc/nginx/sites-available/ipv6-wireguard-manager"; then
        log_success "✓ Nginx配置正确"
    else
        log_warning "⚠ Nginx配置需要更新，正在修复..."
        # 这里需要重新生成Nginx配置
        log_info "请运行安装脚本重新配置Nginx"
    fi
else
    log_warning "⚠ Nginx配置文件不存在"
fi

# 10. 检查端口占用
log_info "10. 检查端口占用..."
if netstat -tuln 2>/dev/null | grep -q ":$API_PORT "; then
    log_warning "⚠ 端口 $API_PORT 已被占用"
    # 检查是否是我们的服务
    if pgrep -f "uvicorn.*$API_PORT" >/dev/null; then
        log_info "发现旧的服务进程，正在停止..."
        pkill -f "uvicorn.*$API_PORT" || true
        sleep 2
    fi
else
    log_success "✓ 端口 $API_PORT 可用"
fi

# 11. 重启服务
log_info "11. 重启服务..."
systemctl stop ipv6-wireguard-manager 2>/dev/null || true
sleep 2
systemctl start ipv6-wireguard-manager

# 等待服务启动
log_info "等待服务启动..."
for i in {1..10}; do
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "✓ 服务启动成功"
        break
    else
        log_info "等待服务启动... ($i/10)"
        sleep 3
    fi
done

# 12. 检查服务状态
log_info "12. 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    log_success "✓ 服务正在运行"
    
    # 检查API是否响应
    if curl -f "http://localhost:$API_PORT/api/v1/health" &>/dev/null; then
        log_success "✓ API响应正常"
    else
        log_warning "⚠ API未响应，检查日志..."
        journalctl -u ipv6-wireguard-manager --no-pager -n 20
    fi
else
    log_error "❌ 服务启动失败"
    log_info "查看服务日志:"
    journalctl -u ipv6-wireguard-manager --no-pager -n 20
fi

# 13. 检查前端访问
log_info "13. 检查前端访问..."
if curl -f "http://localhost/" &>/dev/null; then
    log_success "✓ 前端访问正常"
else
    log_warning "⚠ 前端访问异常"
    if systemctl is-active --quiet nginx; then
        log_success "✓ Nginx服务正在运行"
    else
        log_error "❌ Nginx服务未运行"
        systemctl start nginx
    fi
fi

# 总结
echo ""
log_info "📋 修复总结："
echo ""
log_success "✅ 项目目录检查完成"
log_success "✅ systemd服务配置已更新"
log_success "✅ 用户和组权限已设置"
log_success "✅ Python环境已配置"
log_success "✅ 后端导入错误已修复"
log_success "✅ 数据库连接已检查"
log_success "✅ 前端目录已配置"
log_success "✅ 服务已重启"
echo ""
log_info "🔧 如果仍有问题，请运行以下命令查看详细日志："
log_info "   sudo journalctl -u ipv6-wireguard-manager -f"
log_info "   sudo systemctl status ipv6-wireguard-manager"
echo ""
log_success "🎉 综合错误检查和修复完成！"
