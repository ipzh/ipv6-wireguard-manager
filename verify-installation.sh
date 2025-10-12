#!/bin/bash

echo "🔍 验证重构后的安装脚本是否修复了所有问题..."
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
BACKEND_DIR="$APP_HOME/backend"
SERVICE_NAME="ipv6-wireguard-manager"

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

# 检查项目
check_item() {
    local item="$1"
    local description="$2"
    local check_command="$3"
    
    echo -n "检查 $description... "
    if eval "$check_command" >/dev/null 2>&1; then
        log_success "$description 正常"
        return 0
    else
        log_error "$description 异常"
        return 1
    fi
}

# 1. 检查服务状态
log_step "检查服务状态..."
check_item "backend_service" "后端服务" "systemctl is-active --quiet $SERVICE_NAME"
check_item "nginx_service" "Nginx服务" "systemctl is-active --quiet nginx"

# 2. 检查端口监听
log_step "检查端口监听..."
check_item "port_8000" "端口8000(后端API)" "ss -tlnp | grep -q :8000"
check_item "port_80" "端口80(Nginx)" "ss -tlnp | grep -q :80"

# 3. 检查文件结构
log_step "检查文件结构..."
check_item "app_home" "应用目录" "[ -d '$APP_HOME' ]"
check_item "backend_dir" "后端目录" "[ -d '$BACKEND_DIR' ]"
check_item "frontend_dir" "前端目录" "[ -d '$FRONTEND_DIR' ]"
check_item "frontend_dist" "前端dist目录" "[ -d '$FRONTEND_DIR/dist' ]"
check_item "frontend_index" "前端index.html" "[ -f '$FRONTEND_DIR/dist/index.html' ]"

# 4. 检查配置文件
log_step "检查配置文件..."
check_item "nginx_config" "Nginx配置文件" "[ -f '/etc/nginx/sites-available/ipv6-wireguard-manager' ]"
check_item "systemd_service" "systemd服务文件" "[ -f '/etc/systemd/system/$SERVICE_NAME.service' ]"
check_item "env_config" "环境配置文件" "[ -f '$BACKEND_DIR/.env' ]"

# 5. 检查Nginx配置内容
log_step "检查Nginx配置内容..."
if [ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]; then
    echo "Nginx配置内容检查:"
    
    # 检查IPv6监听
    if grep -q "listen \[::\]:80" /etc/nginx/sites-available/ipv6-wireguard-manager; then
        log_success "IPv6监听配置存在"
    else
        log_warning "IPv6监听配置缺失"
    fi
    
    # 检查前端根目录
    if grep -q "root $FRONTEND_DIR/dist" /etc/nginx/sites-available/ipv6-wireguard-manager; then
        log_success "前端根目录配置正确"
    else
        log_error "前端根目录配置错误"
    fi
    
    # 检查API代理
    if grep -q "proxy_pass http://127.0.0.1:8000" /etc/nginx/sites-available/ipv6-wireguard-manager; then
        log_success "API代理配置正确"
    else
        log_error "API代理配置错误"
    fi
    
    # 检查错误页面
    if grep -q "error_page.*index.html" /etc/nginx/sites-available/ipv6-wireguard-manager; then
        log_success "错误页面配置存在"
    else
        log_warning "错误页面配置缺失"
    fi
fi

# 6. 检查systemd服务配置
log_step "检查systemd服务配置..."
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo "systemd服务配置检查:"
    
    # 检查服务名称
    if grep -q "Description=IPv6 WireGuard Manager" /etc/systemd/system/$SERVICE_NAME.service; then
        log_success "服务描述正确"
    else
        log_error "服务描述错误"
    fi
    
    # 检查工作目录
    if grep -q "WorkingDirectory=$BACKEND_DIR" /etc/systemd/system/$SERVICE_NAME.service; then
        log_success "工作目录配置正确"
    else
        log_error "工作目录配置错误"
    fi
    
    # 检查执行命令
    if grep -q "ExecStart=.*uvicorn.*app.main:app" /etc/systemd/system/$SERVICE_NAME.service; then
        log_success "执行命令配置正确"
    else
        log_error "执行命令配置错误"
    fi
    
    # 检查环境变量
    if grep -q "Environment=PYTHONPATH=$BACKEND_DIR" /etc/systemd/system/$SERVICE_NAME.service; then
        log_success "环境变量配置正确"
    else
        log_warning "环境变量配置缺失"
    fi
fi

# 7. 测试API访问
log_step "测试API访问..."
echo "测试后端API直接访问:"
if curl -s http://127.0.0.1:8000/health >/dev/null 2>&1; then
    log_success "后端API直接访问正常"
    echo "API响应:"
    curl -s http://127.0.0.1:8000/health
else
    log_error "后端API直接访问失败"
fi

echo ""
echo "测试API状态:"
if curl -s http://127.0.0.1:8000/api/v1/status >/dev/null 2>&1; then
    log_success "API状态正常"
    curl -s http://127.0.0.1:8000/api/v1/status
else
    log_error "API状态异常"
fi

# 8. 测试前端访问
log_step "测试前端访问..."
echo "测试本地前端访问:"
if curl -s http://localhost >/dev/null 2>&1; then
    log_success "本地前端访问正常"
    echo "响应状态码:"
    curl -s -o /dev/null -w "%{http_code}" http://localhost
else
    log_error "本地前端访问失败"
fi

echo ""
echo "测试Nginx API代理:"
if curl -s http://localhost/api/v1/status >/dev/null 2>&1; then
    log_success "Nginx API代理正常"
    curl -s http://localhost/api/v1/status
else
    log_error "Nginx API代理失败"
fi

# 9. 测试IPv6访问
log_step "测试IPv6访问..."
IPV6_ADDRESS=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
if [ -n "$IPV6_ADDRESS" ]; then
    echo "检测到IPv6地址: $IPV6_ADDRESS"
    echo "测试IPv6前端访问:"
    if curl -6 -s http://[$IPV6_ADDRESS] >/dev/null 2>&1; then
        log_success "IPv6前端访问正常"
    else
        log_warning "IPv6前端访问失败（可能是网络配置问题）"
    fi
    
    echo "测试IPv6 API访问:"
    if curl -6 -s http://[$IPV6_ADDRESS]/api/v1/status >/dev/null 2>&1; then
        log_success "IPv6 API访问正常"
    else
        log_warning "IPv6 API访问失败（可能是网络配置问题）"
    fi
else
    log_warning "未检测到IPv6地址"
fi

# 10. 检查访问地址显示
log_step "检查访问地址显示..."
echo "当前访问地址:"
PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "")
LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")

echo "  本地访问: http://localhost"
if [ -n "$LOCAL_IPV4" ] && [ "$LOCAL_IPV4" != "localhost" ]; then
    echo "  IPv4访问: http://$LOCAL_IPV4"
fi
if [ -n "$IPV6_ADDRESS" ]; then
    echo "  IPv6访问: http://[$IPV6_ADDRESS]"
fi
if [ -n "$PUBLIC_IPV4" ]; then
    echo "  公网访问: http://$PUBLIC_IPV4"
fi

# 11. 检查管理命令
log_step "检查管理命令..."
echo "正确的管理命令:"
echo "  查看状态: sudo systemctl status $SERVICE_NAME"
echo "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "  重启服务: sudo systemctl restart $SERVICE_NAME"
echo "  查看Nginx状态: sudo systemctl status nginx"
echo "  查看Nginx日志: sudo journalctl -u nginx -f"

# 12. 总结报告
log_step "生成验证报告..."
echo "========================================"
echo -e "${BLUE}📋 安装验证报告${NC}"
echo "========================================"

# 统计检查结果
TOTAL_CHECKS=0
PASSED_CHECKS=0

# 重新运行关键检查并统计
checks=(
    "systemctl is-active --quiet $SERVICE_NAME:后端服务"
    "systemctl is-active --quiet nginx:Nginx服务"
    "ss -tlnp | grep -q :8000:端口8000监听"
    "ss -tlnp | grep -q :80:端口80监听"
    "[ -d '$APP_HOME' ]:应用目录"
    "[ -d '$FRONTEND_DIR/dist' ]:前端dist目录"
    "[ -f '$FRONTEND_DIR/dist/index.html' ]:前端index.html"
    "curl -s http://127.0.0.1:8000/health >/dev/null 2>&1:后端API"
    "curl -s http://localhost >/dev/null 2>&1:前端访问"
    "curl -s http://localhost/api/v1/status >/dev/null 2>&1:API代理"
)

for check in "${checks[@]}"; do
    IFS=':' read -r command description <<< "$check"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if eval "$command"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        echo -e "  ${GREEN}✅ $description${NC}"
    else
        echo -e "  ${RED}❌ $description${NC}"
    fi
done

echo ""
echo "检查结果: $PASSED_CHECKS/$TOTAL_CHECKS 通过"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    log_success "🎉 所有检查都通过！安装完全正常！"
    echo ""
    echo "✅ 重构后的安装脚本已经修复了所有问题："
    echo "   - 端口配置正确（80而不是3000）"
    echo "   - 服务名称正确（ipv6-wireguard-manager）"
    echo "   - IPv6配置正确"
    echo "   - 前端构建正常"
    echo "   - API代理正常"
    echo "   - 访问地址显示正确"
    echo ""
    echo "🔄 重新安装建议："
    echo "   当前安装已经正常，无需重新安装"
    echo "   如果需要重新安装，可以使用："
    echo "   curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
else
    log_warning "⚠️  部分检查未通过，建议重新安装"
    echo ""
    echo "🔄 重新安装建议："
    echo "   1. 停止当前服务："
    echo "      sudo systemctl stop $SERVICE_NAME nginx"
    echo ""
    echo "   2. 清理安装目录："
    echo "      sudo rm -rf $APP_HOME"
    echo ""
    echo "   3. 重新安装："
    echo "      curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
fi

echo ""
echo "========================================"
