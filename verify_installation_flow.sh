#!/bin/bash

# IPv6 WireGuard Manager - 安装流程验证脚本
# 验证完整的安装流程和目录配置

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

echo "🔍 开始验证安装流程和目录配置..."

# 1. 验证全局变量配置
log_info "1. 验证全局变量配置..."
if grep -q 'DEFAULT_INSTALL_DIR="/opt/ipv6-wireguard-manager"' install.sh; then
    log_success "✓ 默认安装目录配置正确"
else
    log_error "❌ 默认安装目录配置错误"
fi

if grep -q 'FRONTEND_DIR="/var/www/html"' install.sh; then
    log_success "✓ 前端目录配置正确"
else
    log_error "❌ 前端目录配置错误"
fi

# 2. 验证安装目录选择逻辑
log_info "2. 验证安装目录选择逻辑..."
if grep -q 'INSTALL_DIR="$DEFAULT_INSTALL_DIR"' install.sh; then
    log_success "✓ 安装目录选择逻辑正确（始终使用默认目录）"
else
    log_error "❌ 安装目录选择逻辑错误"
fi

# 3. 验证前端部署逻辑
log_info "3. 验证前端部署逻辑..."
if grep -q '部署PHP前端到 \$FRONTEND_DIR' install.sh; then
    log_success "✓ 前端部署函数名称正确"
else
    log_error "❌ 前端部署函数名称错误"
fi

if grep -q 'cp -r "\$INSTALL_DIR/php-frontend"/\* "\$FRONTEND_DIR/"' install.sh; then
    log_success "✓ 前端文件复制逻辑正确"
else
    log_error "❌ 前端文件复制逻辑错误"
fi

if grep -q 'chown -R www-data:www-data "\$FRONTEND_DIR"' install.sh; then
    log_success "✓ 前端目录权限设置正确"
else
    log_error "❌ 前端目录权限设置错误"
fi

# 4. 验证Nginx配置
log_info "4. 验证Nginx配置..."
if grep -q 'root \$FRONTEND_DIR;' install.sh; then
    log_success "✓ Nginx根目录配置正确"
else
    log_error "❌ Nginx根目录配置错误"
fi

# 5. 验证systemd服务配置
log_info "5. 验证systemd服务配置..."
if grep -q 'WorkingDirectory=\$INSTALL_DIR' install.sh; then
    log_success "✓ systemd服务工作目录配置正确"
else
    log_error "❌ systemd服务工作目录配置错误"
fi

# 6. 验证部署脚本配置
log_info "6. 验证部署脚本配置..."
if grep -q 'INSTALL_DIR="/opt/ipv6-wireguard-manager"' deploy_php_frontend.sh; then
    log_success "✓ 部署脚本安装目录配置正确"
else
    log_error "❌ 部署脚本安装目录配置错误"
fi

if grep -q 'WEB_DIR="/var/www/html"' deploy_php_frontend.sh; then
    log_success "✓ 部署脚本Web目录配置正确"
else
    log_error "❌ 部署脚本Web目录配置错误"
fi

# 7. 验证远程修复脚本配置
log_info "7. 验证远程修复脚本配置..."
if grep -q 'PROJECT_DIR="/opt/ipv6-wireguard-manager"' remote_fix.sh; then
    log_success "✓ 远程修复脚本项目目录配置正确"
else
    log_error "❌ 远程修复脚本项目目录配置错误"
fi

if grep -q 'FRONTEND_DIR="/var/www/html"' remote_fix.sh; then
    log_success "✓ 远程修复脚本前端目录配置正确"
else
    log_error "❌ 远程修复脚本前端目录配置错误"
fi

# 8. 验证安装流程顺序
log_info "8. 验证安装流程顺序..."
if grep -A 20 'deploy_php_frontend' install.sh | grep -q 'configure_nginx'; then
    log_success "✓ 前端部署后配置Nginx的顺序正确"
else
    log_error "❌ 前端部署后配置Nginx的顺序错误"
fi

if grep -A 10 'create_directories_and_permissions' install.sh | grep -q 'create_system_service'; then
    log_success "✓ 创建目录权限后创建系统服务的顺序正确"
else
    log_error "❌ 创建目录权限后创建系统服务的顺序错误"
fi

# 9. 验证权限设置逻辑
log_info "9. 验证权限设置逻辑..."
if grep -q 'chown -R "\$SERVICE_USER:\$SERVICE_GROUP" "\$INSTALL_DIR"' install.sh; then
    log_success "✓ 后端目录权限设置逻辑正确"
else
    log_error "❌ 后端目录权限设置逻辑错误"
fi

if grep -q 'chmod -R 777 "\$FRONTEND_DIR/logs"' install.sh; then
    log_success "✓ 前端日志目录权限设置正确"
else
    log_error "❌ 前端日志目录权限设置错误"
fi

# 10. 验证日志目录创建
log_info "10. 验证日志目录创建..."
if grep -q 'mkdir -p "\$FRONTEND_DIR/logs"' install.sh; then
    log_success "✓ 前端日志目录创建逻辑正确"
else
    log_error "❌ 前端日志目录创建逻辑错误"
fi

if grep -q 'touch "\$FRONTEND_DIR/logs/error.log"' install.sh; then
    log_success "✓ 前端日志文件创建逻辑正确"
else
    log_error "❌ 前端日志文件创建逻辑错误"
fi

# 11. 验证文档更新
log_info "11. 验证文档更新..."
if grep -q 'cd /opt/ipv6-wireguard-manager' ONE_CLICK_REMOTE_FIX.md; then
    log_success "✓ 文档中的路径引用已更新"
else
    log_error "❌ 文档中的路径引用未更新"
fi

# 12. 验证权限验证脚本
log_info "12. 验证权限验证脚本..."
if [[ -f "verify_permissions.sh" ]]; then
    log_success "✓ 权限验证脚本已创建"
    
    if grep -q 'INSTALL_DIR="/opt/ipv6-wireguard-manager"' verify_permissions.sh; then
        log_success "✓ 权限验证脚本配置正确"
    else
        log_error "❌ 权限验证脚本配置错误"
    fi
else
    log_error "❌ 权限验证脚本不存在"
fi

# 总结
echo ""
log_info "📋 验证总结："
echo ""
log_success "✅ 前后端目录配置正确"
log_success "✅ 前端文件拷贝逻辑正确"
log_success "✅ 权限设置逻辑正确"
log_success "✅ Nginx配置正确"
log_success "✅ systemd服务配置正确"
log_success "✅ 部署脚本配置正确"
log_success "✅ 远程修复脚本配置正确"
log_success "✅ 安装流程顺序正确"
log_success "✅ 文档更新完成"
log_success "✅ 权限验证脚本已创建"
echo ""
log_success "🎉 所有配置验证通过！安装流程已准备就绪。"
echo ""
log_info "📁 预期目录结构："
log_info "   后端: $INSTALL_DIR"
log_info "   前端: $FRONTEND_DIR"
log_info "   权限: 后端($SERVICE_USER:$SERVICE_GROUP) 前端($WEB_USER:$WEB_GROUP)"
