#!/bin/bash

# IPv6 WireGuard Manager - MySQL快速修复脚本
# 专门处理Debian 12的MySQL安装问题

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

log_info "开始修复MySQL安装问题..."

# 更新包列表
log_info "更新包列表..."
apt-get update

# 安装MariaDB（Debian 12推荐）
log_info "安装MariaDB..."
if apt-get install -y mariadb-server mariadb-client; then
    log_success "MariaDB安装成功"
else
    log_error "MariaDB安装失败"
    exit 1
fi

# 启动MariaDB服务
log_info "启动MariaDB服务..."
systemctl start mariadb
systemctl enable mariadb

# 等待服务启动
sleep 3

# 配置数据库
log_info "配置数据库..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# 测试数据库连接
log_info "测试数据库连接..."
if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
    log_success "数据库连接测试成功"
else
    log_error "数据库连接测试失败"
    exit 1
fi

log_success "MySQL安装修复完成！"
log_info "数据库信息:"
log_info "  数据库名: ipv6wgm"
log_info "  用户名: ipv6wgm"
log_info "  密码: ipv6wgm_password"
log_info "  主机: localhost"
log_info "  端口: 3306"

echo ""
log_info "现在可以继续运行安装脚本了！"
log_info "运行命令: ./install.sh --skip-deps --skip-db"
