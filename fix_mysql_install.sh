#!/bin/bash

# MySQL安装问题修复脚本
# 解决不同Linux发行版的MySQL包名问题

set -e

echo "=========================================="
echo "🔧 MySQL安装问题修复脚本"
echo "=========================================="
echo ""

# 检测系统信息
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$NAME"
    OS_VERSION="$VERSION_ID"
else
    OS_NAME="Unknown"
    OS_VERSION="Unknown"
fi

echo "检测到系统: $OS_NAME $OS_VERSION"
echo ""

# 检测包管理器
if command -v apt-get &> /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v yum &> /dev/null; then
    PACKAGE_MANAGER="yum"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
elif command -v zypper &> /dev/null; then
    PACKAGE_MANAGER="zypper"
else
    PACKAGE_MANAGER="unknown"
fi

echo "包管理器: $PACKAGE_MANAGER"
echo ""

# 安装MySQL/MariaDB
install_database() {
    echo "开始安装数据库..."
    
    case $PACKAGE_MANAGER in
        "apt")
            echo "使用APT包管理器..."
            apt-get update
            
            # 尝试多种MySQL/MariaDB包
            if apt-get install -y mariadb-server mariadb-client 2>/dev/null; then
                echo "✅ MariaDB安装成功"
                DB_SERVICE="mariadb"
            elif apt-get install -y mysql-server mysql-client 2>/dev/null; then
                echo "✅ MySQL安装成功"
                DB_SERVICE="mysql"
            elif apt-get install -y mysql-server-8.0 mysql-client-8.0 2>/dev/null; then
                echo "✅ MySQL 8.0安装成功"
                DB_SERVICE="mysql"
            elif apt-get install -y mysql-server-5.7 mysql-client-5.7 2>/dev/null; then
                echo "✅ MySQL 5.7安装成功"
                DB_SERVICE="mysql"
            else
                echo "❌ 无法安装MySQL或MariaDB"
                echo ""
                echo "请尝试手动安装："
                echo "1. 添加MySQL官方源："
                echo "   wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb"
                echo "   dpkg -i mysql-apt-config_0.8.24-1_all.deb"
                echo "   apt-get update"
                echo "   apt-get install mysql-server"
                echo ""
                echo "2. 或者安装MariaDB："
                echo "   apt-get install mariadb-server"
                exit 1
            fi
            ;;
        "yum"|"dnf")
            echo "使用YUM/DNF包管理器..."
            $PACKAGE_MANAGER install -y mariadb-server mariadb
            DB_SERVICE="mariadb"
            ;;
        "pacman")
            echo "使用Pacman包管理器..."
            pacman -S --noconfirm mariadb
            DB_SERVICE="mariadb"
            ;;
        "zypper")
            echo "使用Zypper包管理器..."
            zypper install -y mariadb mariadb-server
            DB_SERVICE="mariadb"
            ;;
        *)
            echo "❌ 不支持的包管理器: $PACKAGE_MANAGER"
            exit 1
            ;;
    esac
}

# 配置数据库
configure_database() {
    echo ""
    echo "配置数据库..."
    
    # 启动数据库服务
    systemctl enable $DB_SERVICE
    systemctl start $DB_SERVICE
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet $DB_SERVICE; then
        echo "✅ $DB_SERVICE服务运行正常"
    else
        echo "❌ $DB_SERVICE服务启动失败"
        systemctl status $DB_SERVICE
        exit 1
    fi
    
    # 创建数据库和用户
    echo "创建数据库和用户..."
    mysql -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "数据库已存在"
    mysql -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || echo "用户已存在"
    mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';" 2>/dev/null || echo "权限已设置"
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || echo "权限刷新完成"
    
    echo "✅ 数据库配置完成"
}

# 测试数据库连接
test_database() {
    echo ""
    echo "测试数据库连接..."
    
    if mysql -u ipv6wgm -ppassword -e "USE ipv6wgm; SHOW TABLES;" 2>/dev/null; then
        echo "✅ 数据库连接测试成功"
    else
        echo "❌ 数据库连接测试失败"
        echo "请检查数据库配置"
        exit 1
    fi
}

# 主函数
main() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ 此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
    
    install_database
    configure_database
    test_database
    
    echo ""
    echo "=========================================="
    echo "🎉 MySQL/MariaDB安装和配置完成！"
    echo "=========================================="
    echo ""
    echo "数据库信息:"
    echo "  服务名称: $DB_SERVICE"
    echo "  数据库名: ipv6wgm"
    echo "  用户名: ipv6wgm"
    echo "  密码: password"
    echo ""
    echo "管理命令:"
    echo "  启动服务: systemctl start $DB_SERVICE"
    echo "  停止服务: systemctl stop $DB_SERVICE"
    echo "  重启服务: systemctl restart $DB_SERVICE"
    echo "  查看状态: systemctl status $DB_SERVICE"
    echo ""
    echo "现在可以继续运行安装脚本："
    echo "bash install.sh minimal"
}

# 运行主函数
main "$@"
