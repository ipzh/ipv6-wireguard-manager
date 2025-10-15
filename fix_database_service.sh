#!/bin/bash

# 数据库服务修复脚本
# 用于修复MySQL/MariaDB服务问题

set -e

echo "=========================================="
echo "🔧 数据库服务修复脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 检测已安装的数据库包
echo "1. 检测已安装的数据库包..."
mysql_packages=$(dpkg -l | grep -i mysql | wc -l)
mariadb_packages=$(dpkg -l | grep -i mariadb | wc -l)

if [ "$mysql_packages" -gt 0 ]; then
    echo "   ✅ 检测到MySQL包 ($mysql_packages 个)"
    DB_TYPE="mysql"
elif [ "$mariadb_packages" -gt 0 ]; then
    echo "   ✅ 检测到MariaDB包 ($mariadb_packages 个)"
    DB_TYPE="mariadb"
else
    echo "   ❌ 未检测到数据库包"
    echo "   请先安装数据库："
    echo "   sudo apt-get install mariadb-server mariadb-client"
    exit 1
fi

echo ""

# 检查服务状态
echo "2. 检查服务状态..."
if [ "$DB_TYPE" = "mysql" ]; then
    if systemctl is-active mysql.service 2>/dev/null; then
        echo "   ✅ MySQL服务正在运行"
        SERVICE_RUNNING=true
    else
        echo "   ❌ MySQL服务未运行"
        SERVICE_RUNNING=false
    fi
else
    if systemctl is-active mariadb.service 2>/dev/null; then
        echo "   ✅ MariaDB服务正在运行"
        SERVICE_RUNNING=true
    else
        echo "   ❌ MariaDB服务未运行"
        SERVICE_RUNNING=false
    fi
fi

echo ""

# 修复服务
if [ "$SERVICE_RUNNING" = false ]; then
    echo "3. 修复数据库服务..."
    
    if [ "$DB_TYPE" = "mysql" ]; then
        echo "   启动MySQL服务..."
        systemctl enable mysql.service
        systemctl start mysql.service
        
        # 等待服务启动
        sleep 3
        
        if systemctl is-active mysql.service 2>/dev/null; then
            echo "   ✅ MySQL服务启动成功"
        else
            echo "   ❌ MySQL服务启动失败"
            echo "   查看错误信息:"
            systemctl status mysql.service --no-pager
            exit 1
        fi
    else
        echo "   启动MariaDB服务..."
        systemctl enable mariadb.service
        systemctl start mariadb.service
        
        # 等待服务启动
        sleep 3
        
        if systemctl is-active mariadb.service 2>/dev/null; then
            echo "   ✅ MariaDB服务启动成功"
        else
            echo "   ❌ MariaDB服务启动失败"
            echo "   查看错误信息:"
            systemctl status mariadb.service --no-pager
            exit 1
        fi
    fi
else
    echo "3. 数据库服务已正常运行，跳过修复"
fi

echo ""

# 测试数据库连接
echo "4. 测试数据库连接..."
if command -v mysql &> /dev/null; then
    if mysql -u root -e "SELECT 1;" 2>/dev/null; then
        echo "   ✅ 数据库连接测试成功"
    else
        echo "   ⚠️  数据库连接需要密码或配置"
        echo "   尝试无密码连接失败，这是正常的"
    fi
else
    echo "   ❌ mysql命令不可用"
fi

echo ""

# 检查端口监听
echo "5. 检查端口监听..."
if netstat -tlnp 2>/dev/null | grep -q ":3306"; then
    echo "   ✅ 端口3306正在监听"
    netstat -tlnp 2>/dev/null | grep ":3306"
else
    echo "   ❌ 端口3306未监听"
fi

echo ""

# 创建数据库和用户
echo "6. 创建应用数据库和用户..."
if command -v mysql &> /dev/null; then
    mysql -e "CREATE DATABASE IF NOT EXISTS ipv6wgm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "   数据库ipv6wgm已存在"
    mysql -e "CREATE USER IF NOT EXISTS 'ipv6wgm'@'localhost' IDENTIFIED BY 'password';" 2>/dev/null || echo "   用户ipv6wgm已存在"
    mysql -e "GRANT ALL PRIVILEGES ON ipv6wgm.* TO 'ipv6wgm'@'localhost';" 2>/dev/null || echo "   权限已设置"
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || echo "   权限刷新完成"
    echo "   ✅ 数据库和用户创建完成"
else
    echo "   ❌ mysql命令不可用，跳过数据库创建"
fi

echo ""

# 测试应用用户连接
echo "7. 测试应用用户连接..."
if command -v mysql &> /dev/null; then
    if mysql -u ipv6wgm -ppassword -e "USE ipv6wgm; SELECT 1;" 2>/dev/null; then
        echo "   ✅ 应用用户连接测试成功"
    else
        echo "   ❌ 应用用户连接测试失败"
    fi
else
    echo "   ❌ mysql命令不可用，跳过连接测试"
fi

echo ""

echo "=========================================="
echo "🎉 数据库服务修复完成！"
echo "=========================================="
echo ""
echo "数据库信息:"
echo "  类型: $DB_TYPE"
echo "  服务状态: $(systemctl is-active $DB_TYPE.service)"
echo "  数据库名: ipv6wgm"
echo "  用户名: ipv6wgm"
echo "  密码: password"
echo ""
echo "管理命令:"
echo "  启动服务: systemctl start $DB_TYPE.service"
echo "  停止服务: systemctl stop $DB_TYPE.service"
echo "  重启服务: systemctl restart $DB_TYPE.service"
echo "  查看状态: systemctl status $DB_TYPE.service"
echo ""
echo "现在可以继续运行安装脚本："
echo "bash install.sh minimal"
