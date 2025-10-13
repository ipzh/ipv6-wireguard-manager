#!/bin/bash

# 修复CORS和Host验证问题脚本
# 解决外部API连接400错误问题

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
echo "修复CORS和Host验证问题"
echo "=========================================="
echo ""

# 1. 检查当前配置
log_info "1. 检查当前配置..."

CONFIG_FILE="/opt/ipv6-wireguard-manager/backend/app/core/config.py"
MAIN_FILE="/opt/ipv6-wireguard-manager/backend/app/main.py"

if [ -f "$CONFIG_FILE" ]; then
    echo "当前CORS配置:"
    grep -A 10 "BACKEND_CORS_ORIGINS" "$CONFIG_FILE" | head -10
    echo ""
else
    log_error "配置文件不存在: $CONFIG_FILE"
    exit 1
fi

if [ -f "$MAIN_FILE" ]; then
    echo "当前TrustedHost配置:"
    grep -A 3 "TrustedHostMiddleware" "$MAIN_FILE"
    echo ""
else
    log_error "主文件不存在: $MAIN_FILE"
    exit 1
fi

echo ""

# 2. 备份原文件
log_info "2. 备份原文件..."

BACKUP_DIR="/opt/ipv6-wireguard-manager/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp "$CONFIG_FILE" "$BACKUP_DIR/config.py.backup"
cp "$MAIN_FILE" "$BACKUP_DIR/main.py.backup"

log_success "原文件已备份到: $BACKUP_DIR"

echo ""

# 3. 修复CORS配置
log_info "3. 修复CORS配置..."

# 检查是否已经包含 "*"
if grep -q '"*"' "$CONFIG_FILE"; then
    log_info "CORS配置已包含通配符，跳过修改"
else
    log_info "添加CORS通配符配置..."
    
    # 在CORS配置中添加 "*"
    sed -i '/"http:\/\/127.0.0.1"/a\        # 允许所有来源（生产环境建议限制）\n        "*"' "$CONFIG_FILE"
    
    log_success "CORS配置已更新"
fi

echo ""

# 4. 修复TrustedHost配置
log_info "4. 修复TrustedHost配置..."

# 检查是否已经允许所有主机
if grep -q 'allowed_hosts=\["\*"\]' "$MAIN_FILE"; then
    log_info "TrustedHost配置已允许所有主机，跳过修改"
else
    log_info "修改TrustedHost配置..."
    
    # 替换TrustedHost配置
    sed -i 's/allowed_hosts=\["\*"\] if settings\.DEBUG else \["localhost", "127\.0\.0\.1"\]/allowed_hosts=["*"]  # 允许所有主机（生产环境建议限制）/g' "$MAIN_FILE"
    
    log_success "TrustedHost配置已更新"
fi

echo ""

# 5. 重启后端服务
log_info "5. 重启后端服务..."

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

echo ""

# 6. 测试API连接
log_info "6. 测试API连接..."

# 测试本地连接
if curl -f -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
    log_success "本地API连接正常"
else
    log_error "本地API连接失败"
fi

# 测试外部连接
SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
if curl -f -s http://$SERVER_IP:8000/health > /dev/null 2>&1; then
    log_success "外部API连接正常 (IP: $SERVER_IP)"
else
    log_warning "外部API连接仍然失败 (IP: $SERVER_IP)"
    echo "详细错误信息:"
    curl -v http://$SERVER_IP:8000/health 2>&1 | head -10
fi

echo ""

# 7. 测试前端访问
log_info "7. 测试前端访问..."

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

# 8. 检查服务日志
log_info "8. 检查服务日志..."

echo "后端服务日志 (最近5行):"
journalctl -u ipv6-wireguard-manager --no-pager -l | tail -5

echo ""

# 9. 生成修复报告
log_info "9. 生成修复报告..."

REPORT_FILE="/tmp/cors-host-fix-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "CORS和Host验证问题修复报告"
    echo "修复时间: $(date)"
    echo "=========================================="
    echo ""
    echo "修复前问题:"
    echo "- CORS配置不包含外部IP地址"
    echo "- TrustedHostMiddleware限制外部访问"
    echo "- 外部API连接返回400错误"
    echo ""
    echo "修复措施:"
    echo "- 在CORS配置中添加通配符 '*'"
    echo "- 修改TrustedHost允许所有主机"
    echo "- 重启后端服务"
    echo ""
    echo "修复后状态:"
    echo "服务状态:"
    systemctl status ipv6-wireguard-manager --no-pager -l
    echo ""
    echo "API测试:"
    curl -s http://127.0.0.1:8000/health
    echo ""
    curl -s http://$SERVER_IP:8000/health
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
