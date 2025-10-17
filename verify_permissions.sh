#!/bin/bash

# IPv6 WireGuard Manager - 权限验证脚本
# 验证所有目录和文件的权限配置

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

echo "🔍 开始权限验证..."

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    log_error "此脚本需要root权限运行"
    exit 1
fi

# 1. 检查安装目录权限
log_info "检查安装目录权限..."
if [[ -d "$INSTALL_DIR" ]]; then
    # 检查目录所有权
    if [[ "$(stat -c %U:%G "$INSTALL_DIR")" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        log_success "✓ 安装目录所有权正确: $SERVICE_USER:$SERVICE_GROUP"
    else
        log_warning "⚠ 安装目录所有权不正确，正在修复..."
        chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
        log_success "✓ 安装目录所有权已修复"
    fi
    
    # 检查目录权限
    if [[ "$(stat -c %a "$INSTALL_DIR")" == "755" ]]; then
        log_success "✓ 安装目录权限正确: 755"
    else
        log_warning "⚠ 安装目录权限不正确，正在修复..."
        chmod 755 "$INSTALL_DIR"
        log_success "✓ 安装目录权限已修复"
    fi
else
    log_error "❌ 安装目录不存在: $INSTALL_DIR"
    exit 1
fi

# 2. 检查前端目录权限
log_info "检查前端目录权限..."
if [[ -d "$FRONTEND_DIR" ]]; then
    # 检查目录所有权
    if [[ "$(stat -c %U:%G "$FRONTEND_DIR")" == "$WEB_USER:$WEB_GROUP" ]]; then
        log_success "✓ 前端目录所有权正确: $WEB_USER:$WEB_GROUP"
    else
        log_warning "⚠ 前端目录所有权不正确，正在修复..."
        chown -R "$WEB_USER:$WEB_GROUP" "$FRONTEND_DIR"
        log_success "✓ 前端目录所有权已修复"
    fi
    
    # 检查目录权限
    if [[ "$(stat -c %a "$FRONTEND_DIR")" == "755" ]]; then
        log_success "✓ 前端目录权限正确: 755"
    else
        log_warning "⚠ 前端目录权限不正确，正在修复..."
        chmod 755 "$FRONTEND_DIR"
        log_success "✓ 前端目录权限已修复"
    fi
    
    # 检查日志目录权限
    if [[ -d "$FRONTEND_DIR/logs" ]]; then
        if [[ "$(stat -c %a "$FRONTEND_DIR/logs")" == "777" ]]; then
            log_success "✓ 日志目录权限正确: 777"
        else
            log_warning "⚠ 日志目录权限不正确，正在修复..."
            chmod -R 777 "$FRONTEND_DIR/logs"
            log_success "✓ 日志目录权限已修复"
        fi
    else
        log_warning "⚠ 日志目录不存在，正在创建..."
        mkdir -p "$FRONTEND_DIR/logs"
        chown -R "$WEB_USER:$WEB_GROUP" "$FRONTEND_DIR/logs"
        chmod -R 777 "$FRONTEND_DIR/logs"
        log_success "✓ 日志目录已创建并设置权限"
    fi
else
    log_error "❌ 前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

# 3. 检查后端文件权限
log_info "检查后端文件权限..."
if [[ -d "$INSTALL_DIR/backend" ]]; then
    # 检查Python文件权限
    find "$INSTALL_DIR/backend" -name "*.py" -type f | while read file; do
        if [[ "$(stat -c %a "$file")" == "644" ]]; then
            log_success "✓ Python文件权限正确: $file"
        else
            log_warning "⚠ Python文件权限不正确，正在修复: $file"
            chmod 644 "$file"
        fi
    done
    
    # 检查脚本文件权限
    find "$INSTALL_DIR" -name "*.sh" -type f | while read file; do
        if [[ "$(stat -c %a "$file")" == "755" ]]; then
            log_success "✓ 脚本文件权限正确: $file"
        else
            log_warning "⚠ 脚本文件权限不正确，正在修复: $file"
            chmod 755 "$file"
        fi
    done
else
    log_error "❌ 后端目录不存在: $INSTALL_DIR/backend"
    exit 1
fi

# 4. 检查前端文件权限
log_info "检查前端文件权限..."
if [[ -d "$FRONTEND_DIR" ]]; then
    # 检查PHP文件权限
    find "$FRONTEND_DIR" -name "*.php" -type f | while read file; do
        if [[ "$(stat -c %a "$file")" == "644" ]]; then
            log_success "✓ PHP文件权限正确: $file"
        else
            log_warning "⚠ PHP文件权限不正确，正在修复: $file"
            chmod 644 "$file"
        fi
    done
    
    # 检查配置文件权限
    find "$FRONTEND_DIR" -name "*.php" -path "*/config/*" -type f | while read file; do
        if [[ "$(stat -c %a "$file")" == "600" ]]; then
            log_success "✓ 配置文件权限正确: $file"
        else
            log_warning "⚠ 配置文件权限不正确，正在修复: $file"
            chmod 600 "$file"
        fi
    done
else
    log_error "❌ 前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

# 5. 检查服务用户和组
log_info "检查服务用户和组..."
if id "$SERVICE_USER" &>/dev/null; then
    log_success "✓ 服务用户存在: $SERVICE_USER"
else
    log_error "❌ 服务用户不存在: $SERVICE_USER"
    exit 1
fi

if getent group "$SERVICE_GROUP" &>/dev/null; then
    log_success "✓ 服务组存在: $SERVICE_GROUP"
else
    log_error "❌ 服务组不存在: $SERVICE_GROUP"
    exit 1
fi

if id "$WEB_USER" &>/dev/null; then
    log_success "✓ Web用户存在: $WEB_USER"
else
    log_error "❌ Web用户不存在: $WEB_USER"
    exit 1
fi

if getent group "$WEB_GROUP" &>/dev/null; then
    log_success "✓ Web组存在: $WEB_GROUP"
else
    log_error "❌ Web组不存在: $WEB_GROUP"
    exit 1
fi

# 6. 检查systemd服务权限
log_info "检查systemd服务权限..."
if [[ -f "/etc/systemd/system/ipv6-wireguard-manager.service" ]]; then
    if [[ "$(stat -c %a "/etc/systemd/system/ipv6-wireguard-manager.service")" == "644" ]]; then
        log_success "✓ systemd服务文件权限正确"
    else
        log_warning "⚠ systemd服务文件权限不正确，正在修复..."
        chmod 644 "/etc/systemd/system/ipv6-wireguard-manager.service"
        log_success "✓ systemd服务文件权限已修复"
    fi
else
    log_warning "⚠ systemd服务文件不存在"
fi

# 7. 检查Nginx配置权限
log_info "检查Nginx配置权限..."
if [[ -f "/etc/nginx/sites-available/ipv6-wireguard-manager" ]]; then
    if [[ "$(stat -c %a "/etc/nginx/sites-available/ipv6-wireguard-manager")" == "644" ]]; then
        log_success "✓ Nginx配置文件权限正确"
    else
        log_warning "⚠ Nginx配置文件权限不正确，正在修复..."
        chmod 644 "/etc/nginx/sites-available/ipv6-wireguard-manager"
        log_success "✓ Nginx配置文件权限已修复"
    fi
else
    log_warning "⚠ Nginx配置文件不存在"
fi

# 8. 检查虚拟环境权限
log_info "检查虚拟环境权限..."
if [[ -d "$INSTALL_DIR/venv" ]]; then
    if [[ "$(stat -c %U:%G "$INSTALL_DIR/venv")" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        log_success "✓ 虚拟环境所有权正确"
    else
        log_warning "⚠ 虚拟环境所有权不正确，正在修复..."
        chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/venv"
        log_success "✓ 虚拟环境所有权已修复"
    fi
    
    # 检查虚拟环境可执行文件权限
    find "$INSTALL_DIR/venv/bin" -type f | while read file; do
        if [[ "$(stat -c %a "$file")" == "755" ]]; then
            log_success "✓ 虚拟环境可执行文件权限正确: $file"
        else
            log_warning "⚠ 虚拟环境可执行文件权限不正确，正在修复: $file"
            chmod 755 "$file"
        fi
    done
else
    log_warning "⚠ 虚拟环境目录不存在"
fi

# 9. 检查日志文件权限
log_info "检查日志文件权限..."
if [[ -d "$INSTALL_DIR/logs" ]]; then
    if [[ "$(stat -c %U:%G "$INSTALL_DIR/logs")" == "$SERVICE_USER:$SERVICE_GROUP" ]]; then
        log_success "✓ 后端日志目录所有权正确"
    else
        log_warning "⚠ 后端日志目录所有权不正确，正在修复..."
        chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/logs"
        log_success "✓ 后端日志目录所有权已修复"
    fi
    
    # 检查日志文件权限
    find "$INSTALL_DIR/logs" -type f | while read file; do
        if [[ "$(stat -c %a "$file")" == "644" ]]; then
            log_success "✓ 后端日志文件权限正确: $file"
        else
            log_warning "⚠ 后端日志文件权限不正确，正在修复: $file"
            chmod 644 "$file"
        fi
    done
else
    log_warning "⚠ 后端日志目录不存在"
fi

# 10. 最终权限总结
log_info "权限验证完成！"
echo ""
log_success "✅ 所有权限配置已验证和修复"
log_info "📁 安装目录: $INSTALL_DIR (所有者: $SERVICE_USER:$SERVICE_GROUP)"
log_info "🌐 前端目录: $FRONTEND_DIR (所有者: $WEB_USER:$WEB_GROUP)"
log_info "👤 服务用户: $SERVICE_USER"
log_info "👥 服务组: $SERVICE_GROUP"
log_info "🌐 Web用户: $WEB_USER"
log_info "👥 Web组: $WEB_GROUP"
echo ""
log_success "🎉 权限验证完成！系统已准备就绪。"
