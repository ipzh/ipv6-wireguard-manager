#!/bin/bash

# 修复IPv6绑定问题脚本
# 解决后端服务只监听IPv6但Nginx代理IPv4的问题

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

echo "=========================================="
echo "修复IPv6绑定问题"
echo "=========================================="
echo ""

# 1. 检查当前后端服务配置
log_info "1. 检查当前后端服务配置..."

SERVICE_FILE="/etc/systemd/system/ipv6-wireguard-manager.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "当前服务配置:"
    cat "$SERVICE_FILE"
    echo ""
    
    # 检查是否只监听IPv6
    if grep -q "::" "$SERVICE_FILE" && ! grep -q "0.0.0.0" "$SERVICE_FILE"; then
        log_warning "发现后端服务只监听IPv6地址"
        NEED_FIX=true
    else
        log_info "后端服务配置看起来正常"
        NEED_FIX=false
    fi
else
    log_error "服务配置文件不存在: $SERVICE_FILE"
    exit 1
fi

echo ""

# 2. 修复后端服务配置
if [ "$NEED_FIX" = true ]; then
    log_info "2. 修复后端服务配置..."
    
    # 备份原配置
    cp "$SERVICE_FILE" "$SERVICE_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    log_success "原配置已备份"
    
    # 修改服务配置，让后端同时监听IPv4和IPv6
    sed -i 's/--host ::/--host 0.0.0.0/g' "$SERVICE_FILE"
    
    log_success "服务配置已修改为监听所有接口"
    echo "修改后的配置:"
    cat "$SERVICE_FILE"
    echo ""
    
    # 重载systemd配置
    systemctl daemon-reload
    log_success "systemd配置已重载"
    
    # 重启后端服务
    log_info "重启后端服务..."
    systemctl restart ipv6-wireguard-manager
    
    # 等待服务启动
    sleep 5
    
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务重启成功"
    else
        log_error "后端服务重启失败"
        echo "服务状态:"
        systemctl status ipv6-wireguard-manager --no-pager -l
        exit 1
    fi
else
    log_info "2. 跳过服务配置修复（配置正常）"
fi

echo ""

# 3. 检查端口监听状态
log_info "3. 检查端口监听状态..."

echo "端口8000监听详情:"
ss -tlnp | grep ":8000 " || echo "端口8000未监听"

echo ""

# 4. 测试API连接
log_info "4. 测试API连接..."

# 测试IPv4连接
if curl -f -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
    log_success "IPv4 API连接正常"
else
    log_error "IPv4 API连接失败"
fi

# 测试IPv6连接
if curl -f -s http://[::1]:8000/health > /dev/null 2>&1; then
    log_success "IPv6 API连接正常"
else
    log_warning "IPv6 API连接失败"
fi

# 测试外部连接
SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
if curl -f -s http://$SERVER_IP:8000/health > /dev/null 2>&1; then
    log_success "外部API连接正常 (IP: $SERVER_IP)"
else
    log_warning "外部API连接失败 (IP: $SERVER_IP)"
fi

echo ""

# 5. 检查Nginx配置
log_info "5. 检查Nginx配置..."

NGINX_CONFIG="/etc/nginx/sites-available/ipv6-wireguard-manager"
if [ -f "$NGINX_CONFIG" ]; then
    # 检查是否需要修改代理地址
    if grep -q "proxy_pass http://127.0.0.1:8000" "$NGINX_CONFIG"; then
        log_info "Nginx配置使用IPv4代理地址，这是正确的"
    else
        log_warning "Nginx配置可能有问题"
        echo "当前Nginx配置:"
        cat "$NGINX_CONFIG"
    fi
else
    log_error "Nginx配置文件不存在"
fi

echo ""

# 6. 测试前端访问
log_info "6. 测试前端访问..."

# 测试HTTP访问
if curl -f -s http://$SERVER_IP/ > /dev/null 2>&1; then
    log_success "前端HTTP访问正常"
    echo "前端页面内容预览:"
    curl -s http://$SERVER_IP/ | head -5
else
    log_warning "前端HTTP访问失败"
    echo "详细错误信息:"
    curl -v http://$SERVER_IP/ 2>&1 | head -10
fi

echo ""

# 7. 检查前端JavaScript错误
log_info "7. 检查前端JavaScript错误..."

# 检查前端文件完整性
FRONTEND_DIR="/opt/ipv6-wireguard-manager/frontend/dist"
if [ -d "$FRONTEND_DIR" ]; then
    echo "前端文件检查:"
    echo "  index.html: $([ -f "$FRONTEND_DIR/index.html" ] && echo "存在" || echo "缺失")"
    echo "  assets目录: $([ -d "$FRONTEND_DIR/assets" ] && echo "存在" || echo "缺失")"
    
    if [ -d "$FRONTEND_DIR/assets" ]; then
        echo "  JS文件数量: $(find "$FRONTEND_DIR/assets" -name "*.js" | wc -l)"
        echo "  CSS文件数量: $(find "$FRONTEND_DIR/assets" -name "*.css" | wc -l)"
    fi
    
    # 检查index.html内容
    if [ -f "$FRONTEND_DIR/index.html" ]; then
        echo ""
        echo "index.html内容预览:"
        head -10 "$FRONTEND_DIR/index.html"
    fi
else
    log_error "前端构建目录不存在"
fi

echo ""

# 8. 生成修复报告
log_info "8. 生成修复报告..."

REPORT_FILE="/tmp/ipv6-binding-fix-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "IPv6绑定问题修复报告"
    echo "修复时间: $(date)"
    echo "=========================================="
    echo ""
    echo "修复前问题:"
    echo "- 后端服务只监听IPv6地址 [::]:8000"
    echo "- Nginx代理到IPv4地址 127.0.0.1:8000"
    echo "- 导致外部API连接失败"
    echo ""
    echo "修复措施:"
    echo "- 修改后端服务配置为监听 0.0.0.0:8000"
    echo "- 重启后端服务"
    echo "- 验证API连接"
    echo ""
    echo "修复后状态:"
    echo "服务状态:"
    systemctl status ipv6-wireguard-manager --no-pager -l
    echo ""
    echo "端口监听:"
    ss -tlnp | grep ":8000 "
    echo ""
    echo "API测试:"
    curl -s http://127.0.0.1:8000/health
    echo ""
    echo "前端访问:"
    curl -s http://$SERVER_IP/ | head -5
    echo ""
} > "$REPORT_FILE"

log_success "修复报告已生成: $REPORT_FILE"

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "访问信息:"
echo "  前端: http://$SERVER_IP"
echo "  API文档: http://$SERVER_IP/api/v1/docs"
echo "  健康检查: http://$SERVER_IP/api/v1/health"
echo ""
echo "默认登录:"
echo "  用户名: admin"
echo "  密码: admin123"
echo ""
echo "如果问题仍然存在，请检查:"
echo "1. 浏览器控制台是否有JavaScript错误"
echo "2. 网络请求是否正常"
echo "3. 防火墙是否阻止了连接"
echo ""
