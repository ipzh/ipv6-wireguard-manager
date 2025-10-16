#!/bin/bash

# IPv6 WireGuard Manager - 全面API服务修复脚本
# 深度诊断和修复API服务启动问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 配置
INSTALL_DIR="/opt/ipv6-wireguard-manager"
SERVICE_NAME="ipv6-wireguard-manager"
SERVICE_USER="ipv6wgm"
SERVICE_GROUP="ipv6wgm"

# 停止服务
stop_service() {
    log_info "停止服务..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    sleep 3
    log_success "✓ 服务已停止"
}

# 检查服务日志
check_service_logs() {
    log_info "检查服务日志..."
    
    echo "=== 最近的服务日志 ==="
    journalctl -u "$SERVICE_NAME" --no-pager -n 20
    echo ""
    
    echo "=== 错误日志 ==="
    journalctl -u "$SERVICE_NAME" --no-pager -n 50 | grep -i error || echo "未发现错误日志"
    echo ""
}

# 检查Python环境
check_python_environment() {
    log_info "检查Python环境..."
    
    # 检查Python版本
    if [[ -f "$INSTALL_DIR/venv/bin/python" ]]; then
        local python_version=$("$INSTALL_DIR/venv/bin/python" --version 2>&1)
        log_success "✓ Python版本: $python_version"
    else
        log_error "✗ Python可执行文件不存在"
        return 1
    fi
    
    # 检查关键模块
    local modules=("fastapi" "uvicorn" "sqlalchemy" "pymysql" "aiomysql")
    for module in "${modules[@]}"; do
        if "$INSTALL_DIR/venv/bin/python" -c "import $module" 2>/dev/null; then
            log_success "✓ 模块 $module 可用"
        else
            log_error "✗ 模块 $module 不可用"
            return 1
        fi
    done
    
    return 0
}

# 检查配置文件
check_configuration() {
    log_info "检查配置文件..."
    
    # 检查环境文件
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        log_success "✓ 环境配置文件存在"
        
        # 检查关键配置
        local configs=("DATABASE_URL" "SECRET_KEY" "HOST" "PORT")
        for config in "${configs[@]}"; do
            if grep -q "^$config=" "$INSTALL_DIR/.env"; then
                log_success "✓ 配置项 $config 存在"
            else
                log_warning "⚠ 配置项 $config 缺失"
            fi
        done
    else
        log_error "✗ 环境配置文件不存在"
        return 1
    fi
    
    # 检查主应用文件
    if [[ -f "$INSTALL_DIR/backend/app/main.py" ]]; then
        log_success "✓ 主应用文件存在"
    else
        log_error "✗ 主应用文件不存在"
        return 1
    fi
    
    # 检查配置文件
    if [[ -f "$INSTALL_DIR/backend/app/core/config_enhanced.py" ]]; then
        log_success "✓ 配置文件存在"
    else
        log_error "✗ 配置文件不存在"
        return 1
    fi
    
    return 0
}

# 检查目录权限
check_directory_permissions() {
    log_info "检查目录权限..."
    
    local directories=(
        "$INSTALL_DIR"
        "$INSTALL_DIR/uploads"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/wireguard"
        "$INSTALL_DIR/wireguard/clients"
    )
    
    for directory in "${directories[@]}"; do
        if [[ -d "$directory" ]]; then
            local owner=$(stat -c '%U:%G' "$directory" 2>/dev/null || echo "unknown")
            if [[ "$owner" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
                log_success "✓ 目录权限正确: $directory ($owner)"
            else
                log_warning "⚠ 目录权限不正确: $directory ($owner)"
                # 修复权限
                chown "$SERVICE_USER:$SERVICE_GROUP" "$directory"
                chmod 755 "$directory"
                log_info "✓ 已修复目录权限: $directory"
            fi
        else
            log_warning "⚠ 目录不存在: $directory"
            mkdir -p "$directory"
            chown "$SERVICE_USER:$SERVICE_GROUP" "$directory"
            chmod 755 "$directory"
            log_info "✓ 已创建目录: $directory"
        fi
    done
}

# 测试Python应用启动
test_python_application() {
    log_info "测试Python应用启动..."
    
    # 切换到安装目录
    cd "$INSTALL_DIR"
    
    # 设置环境变量
    export PYTHONPATH="$INSTALL_DIR"
    
    # 测试导入主应用
    log_info "测试导入主应用..."
    if "$INSTALL_DIR/venv/bin/python" -c "
import sys
sys.path.insert(0, '$INSTALL_DIR')
try:
    from backend.app.main import app
    print('✓ 主应用导入成功')
except Exception as e:
    print(f'✗ 主应用导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
" 2>&1; then
        log_success "✓ 主应用导入测试通过"
    else
        log_error "✗ 主应用导入测试失败"
        return 1
    fi
    
    # 测试配置文件
    log_info "测试配置文件..."
    if "$INSTALL_DIR/venv/bin/python" -c "
import sys
sys.path.insert(0, '$INSTALL_DIR')
try:
    from backend.app.core.config_enhanced import settings
    print('✓ 配置文件导入成功')
    print(f'数据库URL: {settings.DATABASE_URL}')
    print(f'主机: {settings.HOST}')
    print(f'端口: {settings.PORT}')
except Exception as e:
    print(f'✗ 配置文件导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
" 2>&1; then
        log_success "✓ 配置文件测试通过"
    else
        log_error "✗ 配置文件测试失败"
        return 1
    fi
    
    return 0
}

# 检查数据库连接
check_database_connection() {
    log_info "检查数据库连接..."
    
    # 检查MySQL/MariaDB服务
    if systemctl is-active --quiet mysql; then
        log_success "✓ MySQL服务运行中"
    elif systemctl is-active --quiet mariadb; then
        log_success "✓ MariaDB服务运行中"
    else
        log_error "✗ 数据库服务未运行"
        return 1
    fi
    
    # 测试数据库连接
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
        log_success "✓ 数据库连接正常"
    else
        log_error "✗ 数据库连接失败"
        return 1
    fi
    
    return 0
}

# 修复服务配置
fix_service_configuration() {
    log_info "修复服务配置..."
    
    # 检查服务文件
    local service_file="/etc/systemd/system/$SERVICE_NAME.service"
    if [[ -f "$service_file" ]]; then
        log_success "✓ 服务文件存在"
        
        # 显示服务文件内容
        echo "=== 服务文件内容 ==="
        cat "$service_file"
        echo ""
        
        # 重新加载systemd
        systemctl daemon-reload
        log_success "✓ systemd配置已重新加载"
    else
        log_error "✗ 服务文件不存在"
        return 1
    fi
}

# 手动启动测试
manual_startup_test() {
    log_info "手动启动测试..."
    
    # 切换到安装目录
    cd "$INSTALL_DIR"
    
    # 设置环境变量
    export PYTHONPATH="$INSTALL_DIR"
    
    log_info "尝试手动启动应用..."
    log_info "命令: $INSTALL_DIR/venv/bin/uvicorn backend.app.main:app --host :: --port 8000"
    
    # 后台启动测试
    timeout 10s "$INSTALL_DIR/venv/bin/uvicorn" backend.app.main:app --host :: --port 8000 &
    local pid=$!
    sleep 5
    
    # 检查进程是否还在运行
    if kill -0 "$pid" 2>/dev/null; then
        log_success "✓ 手动启动成功，进程ID: $pid"
        
        # 检查端口
        if netstat -tlnp 2>/dev/null | grep ":8000 " &>/dev/null; then
            log_success "✓ 端口8000正在监听"
        else
            log_warning "⚠ 端口8000未监听"
        fi
        
        # 停止测试进程
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    else
        log_error "✗ 手动启动失败"
        return 1
    fi
    
    return 0
}

# 重新安装依赖
reinstall_dependencies() {
    log_info "重新安装Python依赖..."
    
    # 切换到安装目录
    cd "$INSTALL_DIR"
    
    # 激活虚拟环境并安装依赖
    if [[ -f "backend/requirements.txt" ]]; then
        log_info "安装requirements.txt中的依赖..."
        "$INSTALL_DIR/venv/bin/pip" install -r backend/requirements.txt --upgrade
        log_success "✓ 依赖安装完成"
    else
        log_warning "⚠ requirements.txt文件不存在"
    fi
    
    # 安装关键依赖
    local critical_packages=("fastapi" "uvicorn" "sqlalchemy" "pymysql" "aiomysql" "python-dotenv")
    for package in "${critical_packages[@]}"; do
        log_info "安装关键包: $package"
        "$INSTALL_DIR/venv/bin/pip" install "$package" --upgrade
    done
    
    log_success "✓ 关键依赖安装完成"
}

# 启动服务
start_service() {
    log_info "启动服务..."
    
    systemctl start "$SERVICE_NAME"
    sleep 5
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务启动成功"
        return 0
    else
        log_error "✗ 服务启动失败"
        return 1
    fi
}

# 验证服务
verify_service() {
    log_info "验证服务..."
    
    # 检查服务状态
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "✓ 服务正在运行"
    else
        log_error "✗ 服务未运行"
        return 1
    fi
    
    # 检查端口
    if netstat -tlnp 2>/dev/null | grep ":8000 " &>/dev/null; then
        log_success "✓ 端口8000正在监听"
    else
        log_error "✗ 端口8000未监听"
        return 1
    fi
    
    # 测试API连接
    sleep 3
    if curl -f http://localhost:8000/api/v1/health &>/dev/null; then
        log_success "✓ API健康检查通过"
    else
        log_warning "⚠ API健康检查失败"
    fi
    
    return 0
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager - 全面API服务修复"
    echo ""
    
    # 停止服务
    stop_service
    echo ""
    
    # 检查服务日志
    check_service_logs
    echo ""
    
    # 检查Python环境
    if ! check_python_environment; then
        log_error "Python环境检查失败，重新安装依赖..."
        reinstall_dependencies
        echo ""
    fi
    echo ""
    
    # 检查配置文件
    if ! check_configuration; then
        log_error "配置文件检查失败"
        return 1
    fi
    echo ""
    
    # 检查目录权限
    check_directory_permissions
    echo ""
    
    # 检查数据库连接
    if ! check_database_connection; then
        log_error "数据库连接检查失败"
        return 1
    fi
    echo ""
    
    # 测试Python应用
    if ! test_python_application; then
        log_error "Python应用测试失败"
        return 1
    fi
    echo ""
    
    # 修复服务配置
    fix_service_configuration
    echo ""
    
    # 手动启动测试
    if ! manual_startup_test; then
        log_error "手动启动测试失败"
        return 1
    fi
    echo ""
    
    # 启动服务
    if ! start_service; then
        log_error "服务启动失败"
        return 1
    fi
    echo ""
    
    # 验证服务
    if verify_service; then
        log_success "🎉 API服务修复成功！"
        echo ""
        log_info "访问信息:"
        log_info "  API健康检查: http://localhost:8000/api/v1/health"
        log_info "  API文档: http://localhost:8000/docs"
        echo ""
        log_info "服务管理:"
        log_info "  查看状态: sudo systemctl status $SERVICE_NAME"
        log_info "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
    else
        log_error "❌ API服务修复失败"
        echo ""
        log_info "请检查以下信息:"
        log_info "  服务日志: sudo journalctl -u $SERVICE_NAME -f"
        log_info "  系统日志: sudo journalctl -f"
        return 1
    fi
}

# 运行主函数
main "$@"
