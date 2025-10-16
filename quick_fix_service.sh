#!/bin/bash

# IPv6 WireGuard Manager - 快速修复脚本
# 快速修复服务启动问题

set -e

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

# 默认配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"

log_info "开始快速修复IPv6 WireGuard Manager服务..."

# 停止服务
stop_service() {
    log_info "停止服务..."
    systemctl stop $SERVICE_NAME 2>/dev/null || true
    sleep 2
    log_success "✓ 服务已停止"
}

# 重新安装Python依赖
reinstall_dependencies() {
    log_info "重新安装Python依赖..."
    
    cd "$INSTALL_DIR"
    
    if [[ -f "backend/requirements.txt" ]]; then
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r backend/requirements.txt
        log_success "✓ Python依赖安装完成"
    else
        log_error "✗ requirements.txt文件不存在"
        return 1
    fi
}

# 重新创建环境配置
recreate_env_config() {
    log_info "重新创建环境配置..."
    
    if [[ -f "$INSTALL_DIR/.env.example" ]]; then
        cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
        log_success "✓ 环境配置文件已创建"
    else
        log_warning "⚠ .env.example文件不存在，创建默认配置..."
        create_default_env_config
    fi
}

# 创建默认环境配置
create_default_env_config() {
    cat > "$INSTALL_DIR/.env" << EOF
# IPv6 WireGuard Manager - 环境配置
APP_NAME="IPv6 WireGuard Manager"
APP_VERSION="3.1.0"
DEBUG=false
APP_ENV=production

# 数据库配置
DATABASE_URL="mysql+pymysql://ipv6wgm:ipv6wgm_password@localhost:3306/ipv6wgm"
DB_HOST="localhost"
DB_PORT=3306
DB_NAME="ipv6wgm"
DB_USER="ipv6wgm"
DB_PASS="ipv6wgm_password"

# 安全配置
SECRET_KEY="$(openssl rand -hex 32)"
JWT_SECRET_KEY="$(openssl rand -hex 32)"

# 服务器配置
HOST="::"
PORT=8000
EOF
    log_success "✓ 默认环境配置文件已创建"
}

# 重新创建服务配置
recreate_service_config() {
    log_info "重新创建服务配置..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=exec
User=ipv6wgm
Group=ipv6wgm
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host :: --port 8000
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ipv6-wireguard-manager

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "✓ 服务配置文件已重新创建"
}

# 重新加载systemd配置
reload_systemd() {
    log_info "重新加载systemd配置..."
    systemctl daemon-reload
    log_success "✓ systemd配置已重新加载"
}

# 设置权限
set_permissions() {
    log_info "设置文件权限..."
    
    chown -R ipv6wgm:ipv6wgm "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/venv/bin/uvicorn"
    
    log_success "✓ 文件权限已设置"
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME
    
    sleep 5
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        log_success "✓ 服务启动成功"
        return 0
    else
        log_error "✗ 服务启动失败"
        return 1
    fi
}

# 验证服务
verify_service() {
    log_info "验证服务状态..."
    
    # 等待服务完全启动
    sleep 10
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        log_success "✓ 服务正在运行"
    else
        log_error "✗ 服务未运行"
        return 1
    fi
    
    # 测试API连接
    if curl -f http://localhost:8000/api/v1/health &>/dev/null; then
        log_success "✓ API连接正常"
    else
        log_warning "⚠ API连接失败，但服务正在运行"
    fi
}

# 显示服务状态
show_service_status() {
    log_info "服务状态:"
    systemctl status $SERVICE_NAME --no-pager -l
    echo ""
    
    log_info "最近的服务日志:"
    journalctl -u $SERVICE_NAME --no-pager -n 10
    echo ""
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 快速修复脚本"
    echo ""
    
    # 停止服务
    stop_service
    echo ""
    
    # 重新安装依赖
    if ! reinstall_dependencies; then
        log_error "依赖安装失败"
        exit 1
    fi
    echo ""
    
    # 重新创建环境配置
    recreate_env_config
    echo ""
    
    # 重新创建服务配置
    recreate_service_config
    echo ""
    
    # 重新加载systemd配置
    reload_systemd
    echo ""
    
    # 设置权限
    set_permissions
    echo ""
    
    # 启动服务
    if ! start_service; then
        log_error "服务启动失败"
        echo ""
        show_service_status
        exit 1
    fi
    echo ""
    
    # 验证服务
    verify_service
    echo ""
    
    # 显示服务状态
    show_service_status
    
    log_success "🎉 服务修复完成！"
    echo ""
    log_info "访问信息:"
    log_info "  API健康检查: http://localhost:8000/api/v1/health"
    log_info "  API文档: http://localhost:8000/docs"
    log_info "  前端页面: http://localhost/"
    echo ""
    log_info "服务管理:"
    log_info "  查看状态: sudo systemctl status $SERVICE_NAME"
    log_info "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
    log_info "  重启服务: sudo systemctl restart $SERVICE_NAME"
}

# 运行主函数
main "$@"
