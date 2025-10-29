#!/bin/bash

#=============================================================================
# IPv6 WireGuard Manager - 修复版安装脚本
# 专门修复Debian 13 MySQL连接问题
#=============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 修复MySQL连接问题
fix_mysql_connection() {
    log_info "🔧 修复MySQL连接问题..."
    
    # 检查MySQL服务状态
    if systemctl is-active --quiet mysql; then
        log_success "MySQL服务正在运行"
    elif systemctl is-active --quiet mariadb; then
        log_success "MariaDB服务正在运行"
    else
        log_warning "数据库服务未运行，尝试启动..."
        if systemctl start mysql 2>/dev/null; then
            log_success "MySQL服务启动成功"
        elif systemctl start mariadb 2>/dev/null; then
            log_success "MariaDB服务启动成功"
        else
            log_error "无法启动数据库服务"
            return 1
        fi
    fi
    
    # 检查root用户连接
    log_info "检查MySQL root用户连接..."
    if mysql -u root -e "SELECT 1;" 2>/dev/null; then
        log_success "MySQL root用户连接正常"
    else
        log_warning "MySQL root用户需要密码或无权限"
        log_info "尝试设置root密码..."
        
        # 尝试使用mysql_secure_installation的自动化方式
        mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true
        mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true
        
        if mysql -u root -e "SELECT 1;" 2>/dev/null; then
            log_success "MySQL root用户连接修复成功"
        else
            log_error "MySQL root用户连接仍然失败"
            log_info "请手动执行以下命令修复："
            log_info "sudo mysql_secure_installation"
            return 1
        fi
    fi
    
    return 0
}

# 重新创建数据库用户
recreate_database_user() {
    local db_user="ipv6wgm"
    local db_password="ipv6wgm_password_$(date +%s)"
    local db_name="ipv6wgm"
    
    log_info "重新创建数据库用户: $db_user"
    
    # 删除可能存在的旧用户
    mysql -u root -e "DROP USER IF EXISTS '$db_user'@'localhost';" 2>/dev/null || true
    mysql -u root -e "DROP USER IF EXISTS '$db_user'@'127.0.0.1';" 2>/dev/null || true
    
    # 重新创建数据库
    mysql -u root -e "DROP DATABASE IF EXISTS $db_name;" 2>/dev/null || true
    mysql -u root -e "CREATE DATABASE $db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || {
        log_error "数据库创建失败"
        return 1
    }
    
    # 检测数据库类型并创建用户
    DB_SERVER_VERSION=$(mysql -V 2>/dev/null || true)
    if echo "$DB_SERVER_VERSION" | grep -qi "mariadb"; then
        log_info "检测到MariaDB，使用MariaDB语法"
        mysql -u root -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';" || {
            log_error "用户创建失败 (localhost)"
            return 1
        }
        mysql -u root -e "CREATE USER '$db_user'@'127.0.0.1' IDENTIFIED BY '$db_password';" || {
            log_error "用户创建失败 (127.0.0.1)"
            return 1
        }
    else
        log_info "检测到MySQL，使用MySQL语法"
        mysql -u root -e "CREATE USER '$db_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';" || {
            log_error "用户创建失败 (localhost)"
            return 1
        }
        mysql -u root -e "CREATE USER '$db_user'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '$db_password';" || {
            log_error "用户创建失败 (127.0.0.1)"
            return 1
        }
    fi
    
    # 授予权限
    mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';" || {
        log_error "权限授予失败 (localhost)"
        return 1
    }
    mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'127.0.0.1';" || {
        log_error "权限授予失败 (127.0.0.1)"
        return 1
    }
    mysql -u root -e "FLUSH PRIVILEGES;" || {
        log_error "权限刷新失败"
        return 1
    }
    
    # 测试连接
    log_info "测试数据库用户连接..."
    if mysql -u "$db_user" -p"$db_password" -h 127.0.0.1 -e "SELECT 1;" 2>/dev/null; then
        log_success "数据库用户连接测试成功"
        
        # 保存数据库信息到文件
        cat > /tmp/database_info.txt << EOF
数据库用户: $db_user
数据库密码: $db_password
数据库名称: $db_name
数据库主机: 127.0.0.1
数据库端口: 3306
连接URL: mysql://$db_user:$db_password@127.0.0.1:3306/$db_name?charset=utf8mb4
EOF
        log_success "数据库信息已保存到 /tmp/database_info.txt"
        return 0
    else
        log_error "数据库用户连接测试失败"
        return 1
    fi
}

# 主函数
main() {
    log_info "🚀 开始修复IPv6 WireGuard Manager数据库连接问题..."
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
    
    # 修复MySQL连接
    if ! fix_mysql_connection; then
        log_error "MySQL连接修复失败"
        exit 1
    fi
    
    # 重新创建数据库用户
    if ! recreate_database_user; then
        log_error "数据库用户创建失败"
        exit 1
    fi
    
    log_success "🎉 数据库连接问题修复完成！"
    log_info "现在可以重新运行安装脚本："
    log_info "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash"
}

# 运行主函数
main "$@"
