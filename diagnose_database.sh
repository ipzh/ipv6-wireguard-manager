#!/bin/bash

# 数据库服务诊断脚本
# 用于检查MySQL/MariaDB服务状态

set -e

echo "=========================================="
echo "🔍 数据库服务诊断脚本"
echo "=========================================="
echo ""

# 检查系统信息
echo "1. 系统信息:"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "   操作系统: $NAME $VERSION_ID"
else
    echo "   操作系统: Unknown"
fi
echo "   架构: $(uname -m)"
echo ""

# 检查已安装的数据库包
echo "2. 已安装的数据库包:"
if command -v dpkg &> /dev/null; then
    echo "   MySQL相关包:"
    dpkg -l | grep -i mysql | awk '{print "     " $2 " " $3}' || echo "     无MySQL包"
    echo "   MariaDB相关包:"
    dpkg -l | grep -i mariadb | awk '{print "     " $2 " " $3}' || echo "     无MariaDB包"
elif command -v rpm &> /dev/null; then
    echo "   MySQL相关包:"
    rpm -qa | grep -i mysql || echo "     无MySQL包"
    echo "   MariaDB相关包:"
    rpm -qa | grep -i mariadb || echo "     无MariaDB包"
else
    echo "   无法检测包管理器"
fi
echo ""

# 检查systemd服务
echo "3. systemd服务状态:"
echo "   MySQL服务:"
if systemctl list-unit-files | grep -q "mysql.service"; then
    echo "     ✅ mysql.service 存在"
    systemctl is-enabled mysql.service 2>/dev/null && echo "     ✅ 已启用" || echo "     ❌ 未启用"
    systemctl is-active mysql.service 2>/dev/null && echo "     ✅ 运行中" || echo "     ❌ 未运行"
else
    echo "     ❌ mysql.service 不存在"
fi

echo "   MariaDB服务:"
if systemctl list-unit-files | grep -q "mariadb.service"; then
    echo "     ✅ mariadb.service 存在"
    systemctl is-enabled mariadb.service 2>/dev/null && echo "     ✅ 已启用" || echo "     ❌ 未启用"
    systemctl is-active mariadb.service 2>/dev/null && echo "     ✅ 运行中" || echo "     ❌ 未运行"
else
    echo "     ❌ mariadb.service 不存在"
fi
echo ""

# 检查进程
echo "4. 数据库进程:"
mysql_processes=$(ps aux | grep -E "(mysql|mariadb)" | grep -v grep | wc -l)
if [ "$mysql_processes" -gt 0 ]; then
    echo "   ✅ 发现 $mysql_processes 个数据库进程:"
    ps aux | grep -E "(mysql|mariadb)" | grep -v grep | awk '{print "     " $11 " " $12 " " $13}'
else
    echo "   ❌ 未发现数据库进程"
fi
echo ""

# 检查端口
echo "5. 数据库端口监听:"
if netstat -tlnp 2>/dev/null | grep -q ":3306"; then
    echo "   ✅ 端口3306正在监听:"
    netstat -tlnp 2>/dev/null | grep ":3306" | awk '{print "     " $0}'
else
    echo "   ❌ 端口3306未监听"
fi
echo ""

# 检查数据库命令
echo "6. 数据库命令可用性:"
if command -v mysql &> /dev/null; then
    echo "   ✅ mysql命令可用: $(which mysql)"
    mysql --version 2>/dev/null || echo "     版本信息获取失败"
else
    echo "   ❌ mysql命令不可用"
fi

if command -v mysqld &> /dev/null; then
    echo "   ✅ mysqld命令可用: $(which mysqld)"
    mysqld --version 2>/dev/null || echo "     版本信息获取失败"
else
    echo "   ❌ mysqld命令不可用"
fi
echo ""

# 检查配置文件
echo "7. 数据库配置文件:"
config_files=(
    "/etc/mysql/my.cnf"
    "/etc/mysql/mysql.conf.d/mysqld.cnf"
    "/etc/mysql/conf.d/mysqld.cnf"
    "/etc/my.cnf"
    "/etc/mariadb.conf.d/50-server.cnf"
)

for config in "${config_files[@]}"; do
    if [ -f "$config" ]; then
        echo "   ✅ 找到配置文件: $config"
    fi
done
echo ""

# 尝试连接数据库
echo "8. 数据库连接测试:"
if command -v mysql &> /dev/null; then
    if mysql -u root -e "SELECT 1;" 2>/dev/null; then
        echo "   ✅ 可以以root用户连接数据库"
    elif mysql -u root -e "SELECT 1;" 2>&1 | grep -q "Access denied"; then
        echo "   ⚠️  root用户需要密码"
    else
        echo "   ❌ 无法连接数据库"
    fi
else
    echo "   ❌ mysql命令不可用，无法测试连接"
fi
echo ""

# 提供修复建议
echo "=========================================="
echo "🔧 修复建议"
echo "=========================================="
echo ""

# 检查是否有数据库包但服务未启动
if (dpkg -l | grep -q -i mysql || dpkg -l | grep -q -i mariadb) && ! systemctl is-active mysql.service 2>/dev/null && ! systemctl is-active mariadb.service 2>/dev/null; then
    echo "检测到数据库包已安装但服务未启动，建议："
    echo ""
    echo "1. 启动MySQL服务:"
    echo "   sudo systemctl start mysql"
    echo "   sudo systemctl enable mysql"
    echo ""
    echo "2. 或启动MariaDB服务:"
    echo "   sudo systemctl start mariadb"
    echo "   sudo systemctl enable mariadb"
    echo ""
    echo "3. 检查服务状态:"
    echo "   sudo systemctl status mysql"
    echo "   sudo systemctl status mariadb"
    echo ""
fi

# 检查是否需要安装数据库
if ! (dpkg -l | grep -q -i mysql || dpkg -l | grep -q -i mariadb); then
    echo "未检测到数据库包，建议安装："
    echo ""
    echo "1. 安装MariaDB（推荐）:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install mariadb-server mariadb-client"
    echo ""
    echo "2. 或安装MySQL:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install mysql-server mysql-client"
    echo ""
fi

echo "=========================================="
echo "🎯 诊断完成"
echo "=========================================="
