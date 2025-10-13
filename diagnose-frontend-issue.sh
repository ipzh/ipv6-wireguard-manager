#!/bin/bash

# IPv6 WireGuard Manager 前端空白页面诊断脚本
# 用于诊断VPS上安装后前端显示空白的问题

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
echo "IPv6 WireGuard Manager 前端诊断工具"
echo "=========================================="
echo ""

# 1. 检查系统服务状态
log_info "1. 检查系统服务状态..."

# 检查Nginx状态
if systemctl is-active --quiet nginx; then
    log_success "Nginx服务运行正常"
else
    log_error "Nginx服务未运行"
    echo "尝试启动Nginx..."
    systemctl start nginx
    if systemctl is-active --quiet nginx; then
        log_success "Nginx服务启动成功"
    else
        log_error "Nginx服务启动失败"
    fi
fi

# 检查后端服务状态
if systemctl is-active --quiet ipv6-wireguard-manager; then
    log_success "后端服务运行正常"
else
    log_error "后端服务未运行"
    echo "尝试启动后端服务..."
    systemctl start ipv6-wireguard-manager
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_success "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        echo "查看后端服务日志:"
        journalctl -u ipv6-wireguard-manager --no-pager -l | tail -20
    fi
fi

echo ""

# 2. 检查端口监听状态
log_info "2. 检查端口监听状态..."

# 检查端口80
if ss -tlnp | grep -q ":80 "; then
    log_success "端口80监听正常"
    echo "端口80监听详情:"
    ss -tlnp | grep ":80 "
else
    log_error "端口80未监听"
fi

# 检查端口8000
if ss -tlnp | grep -q ":8000 "; then
    log_success "端口8000监听正常"
    echo "端口8000监听详情:"
    ss -tlnp | grep ":8000 "
else
    log_error "端口8000未监听"
fi

echo ""

# 3. 检查防火墙状态
log_info "3. 检查防火墙状态..."

if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log_warning "UFW防火墙已启用"
        echo "防火墙规则:"
        ufw status numbered
    else
        log_info "UFW防火墙未启用"
    fi
else
    log_info "UFW未安装"
fi

# 检查iptables
if command -v iptables &> /dev/null; then
    if iptables -L | grep -q "ACCEPT"; then
        log_info "iptables规则存在"
    else
        log_info "iptables规则为空"
    fi
fi

echo ""

# 4. 检查API连接性
log_info "4. 检查API连接性..."

# 检查本地API连接
if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
    log_success "本地API连接正常"
    echo "API健康检查响应:"
    curl -s http://localhost:8000/health | head -3
else
    log_error "本地API连接失败"
    echo "尝试详细诊断..."
    curl -v http://localhost:8000/health 2>&1 | head -10
fi

# 检查外部API连接
SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
if curl -f -s http://$SERVER_IP:8000/health > /dev/null 2>&1; then
    log_success "外部API连接正常 (IP: $SERVER_IP)"
else
    log_error "外部API连接失败 (IP: $SERVER_IP)"
fi

echo ""

# 5. 检查前端文件
log_info "5. 检查前端文件..."

FRONTEND_DIR="/opt/ipv6-wireguard-manager/frontend"
if [ -d "$FRONTEND_DIR" ]; then
    log_success "前端目录存在: $FRONTEND_DIR"
    
    # 检查dist目录
    if [ -d "$FRONTEND_DIR/dist" ]; then
        log_success "前端构建目录存在"
        echo "构建文件列表:"
        ls -la "$FRONTEND_DIR/dist" | head -10
        
        # 检查index.html
        if [ -f "$FRONTEND_DIR/dist/index.html" ]; then
            log_success "index.html文件存在"
        else
            log_error "index.html文件不存在"
        fi
    else
        log_error "前端构建目录不存在，需要重新构建"
        echo "尝试重新构建前端..."
        cd "$FRONTEND_DIR"
        if command -v npm &> /dev/null; then
            npm run build
            if [ -d "dist" ]; then
                log_success "前端构建成功"
            else
                log_error "前端构建失败"
            fi
        else
            log_error "npm未安装，无法构建前端"
        fi
    fi
else
    log_error "前端目录不存在: $FRONTEND_DIR"
fi

echo ""

# 6. 检查Nginx配置
log_info "6. 检查Nginx配置..."

NGINX_CONFIG="/etc/nginx/sites-available/ipv6-wireguard-manager"
if [ -f "$NGINX_CONFIG" ]; then
    log_success "Nginx配置文件存在"
    echo "配置文件内容:"
    cat "$NGINX_CONFIG"
else
    log_error "Nginx配置文件不存在"
fi

# 检查Nginx配置语法
if nginx -t 2>/dev/null; then
    log_success "Nginx配置语法正确"
else
    log_error "Nginx配置语法错误"
    echo "配置错误详情:"
    nginx -t
fi

# 检查Nginx站点是否启用
if [ -L "/etc/nginx/sites-enabled/ipv6-wireguard-manager" ]; then
    log_success "Nginx站点已启用"
else
    log_warning "Nginx站点未启用，尝试启用..."
    ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/ipv6-wireguard-manager
    systemctl reload nginx
    log_success "Nginx站点已启用并重载"
fi

echo ""

# 7. 检查数据库连接
log_info "7. 检查数据库连接..."

# 检查PostgreSQL
if systemctl is-active --quiet postgresql; then
    log_success "PostgreSQL服务运行正常"
    
    # 检查数据库连接
    if sudo -u postgres psql -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "PostgreSQL连接正常"
    else
        log_error "PostgreSQL连接失败"
    fi
else
    log_error "PostgreSQL服务未运行"
fi

echo ""

# 8. 检查日志文件
log_info "8. 检查相关日志..."

echo "Nginx错误日志 (最近10行):"
if [ -f "/var/log/nginx/error.log" ]; then
    tail -10 /var/log/nginx/error.log
else
    echo "Nginx错误日志文件不存在"
fi

echo ""
echo "后端服务日志 (最近10行):"
journalctl -u ipv6-wireguard-manager --no-pager -l | tail -10

echo ""

# 9. 生成诊断报告
log_info "9. 生成诊断报告..."

REPORT_FILE="/tmp/frontend-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "IPv6 WireGuard Manager 前端诊断报告"
    echo "生成时间: $(date)"
    echo "=========================================="
    echo ""
    echo "系统信息:"
    uname -a
    echo ""
    echo "服务状态:"
    systemctl status nginx --no-pager -l
    echo ""
    systemctl status ipv6-wireguard-manager --no-pager -l
    echo ""
    echo "端口监听:"
    ss -tlnp
    echo ""
    echo "防火墙状态:"
    ufw status
    echo ""
    echo "Nginx配置:"
    cat /etc/nginx/sites-available/ipv6-wireguard-manager
    echo ""
    echo "前端文件:"
    ls -la /opt/ipv6-wireguard-manager/frontend/dist/
    echo ""
    echo "API测试:"
    curl -v http://localhost:8000/health
    echo ""
} > "$REPORT_FILE"

log_success "诊断报告已生成: $REPORT_FILE"

echo ""
echo "=========================================="
echo "诊断完成！"
echo "=========================================="
echo ""
echo "如果问题仍然存在，请："
echo "1. 查看诊断报告: cat $REPORT_FILE"
echo "2. 检查后端服务日志: journalctl -u ipv6-wireguard-manager -f"
echo "3. 检查Nginx日志: tail -f /var/log/nginx/error.log"
echo "4. 重新构建前端: cd /opt/ipv6-wireguard-manager/frontend && npm run build"
echo "5. 重启服务: systemctl restart nginx ipv6-wireguard-manager"
echo ""
