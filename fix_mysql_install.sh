#!/bin/bash

# IPv6 WireGuard Manager - MySQL安装修复脚本
# 专门处理Debian 12等系统的MySQL安装问题

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

# 检测系统
detect_system() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    log_info "检测到系统: $OS_NAME"
}

# 安装MariaDB（推荐用于Debian 12）
install_mariadb() {
    log_info "安装MariaDB..."
    
    # 更新包列表
    apt-get update
    
    # 安装MariaDB
    if apt-get install -y mariadb-server mariadb-client; then
        log_success "MariaDB安装成功"
        
        # 启动并启用服务
        systemctl start mariadb
        systemctl enable mariadb
        
        # 安全配置
        log_info "运行MariaDB安全配置..."
        mysql_secure_installation <<EOF

y
ipv6wgm_password
ipv6wgm_password
y
y
y
y
EOF
        
        log_success "MariaDB配置完成"
        return 0
    else
        log_error "MariaDB安装失败"
        return 1
    fi
}

# 安装MySQL 8.0（通过官方软件源）
install_mysql_official() {
    log_info "安装MySQL 8.0（官方软件源）..."
    
    # 下载MySQL APT配置包
    cd /tmp
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
    
    # 安装配置包
    dpkg -i mysql-apt-config_0.8.24-1_all.deb
    
    # 更新包列表
    apt-get update
    
    # 安装MySQL
    if apt-get install -y mysql-server mysql-client; then
        log_success "MySQL 8.0安装成功"
        
        # 启动并启用服务
        systemctl start mysql
        systemctl enable mysql
        
        log_success "MySQL配置完成"
        return 0
    else
        log_error "MySQL安装失败"
        return 1
    fi
}

# 配置数据库
configure_database() {
    log_info "配置数据库..."
    
    # 创建数据库和用户
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -u root -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'ipv6wgm_password';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    
    log_success "数据库配置完成"
}

# 测试数据库连接
test_database() {
    log_info "测试数据库连接..."
    
    if mysql -u ipv6wgm -pipv6wgm_password -e "SELECT 1;" &>/dev/null; then
        log_success "数据库连接测试成功"
        return 0
    else
        log_error "数据库连接测试失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "开始MySQL安装修复..."
    
    # 检测系统
    detect_system
    
    # 根据系统选择安装方式
    case $OS_ID in
        "debian")
            if [[ "$OS_VERSION" == "12" ]]; then
                log_info "检测到Debian 12，推荐使用MariaDB"
                if install_mariadb; then
                    configure_database
                    test_database
                    log_success "MySQL安装修复完成！"
                else
                    log_error "MariaDB安装失败"
                    exit 1
                fi
            else
                log_info "检测到Debian $OS_VERSION，尝试安装MySQL"
                if install_mysql_official; then
                    configure_database
                    test_database
                    log_success "MySQL安装修复完成！"
                else
                    log_error "MySQL安装失败"
                    exit 1
                fi
            fi
            ;;
        "ubuntu")
            log_info "检测到Ubuntu，尝试安装MySQL"
            if install_mysql_official; then
                configure_database
                test_database
                log_success "MySQL安装修复完成！"
            else
                log_error "MySQL安装失败，尝试MariaDB"
                if install_mariadb; then
                    configure_database
                    test_database
                    log_success "MySQL安装修复完成！"
                else
                    log_error "所有安装方式都失败了"
                    exit 1
                fi
            fi
            ;;
        *)
            log_warning "未识别的系统: $OS_ID"
            log_info "尝试安装MariaDB"
            if install_mariadb; then
                configure_database
                test_database
                log_success "MySQL安装修复完成！"
            else
                log_error "MariaDB安装失败"
                exit 1
            fi
            ;;
    esac
    
    echo ""
    log_info "数据库信息:"
    log_info "  数据库名: ipv6wgm"
    log_info "  用户名: ipv6wgm"
    log_info "  密码: ipv6wgm_password"
    log_info "  主机: localhost"
    log_info "  端口: 3306"
    echo ""
    log_success "现在可以继续运行安装脚本了！"
}

# 运行主函数
main "$@"
