#!/bin/bash

# IPv6 WireGuard Manager 恢复脚本

set -e

if [ $# -eq 0 ]; then
    echo "❌ 请指定备份文件"
    echo "用法: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE=$1
BACKUP_DIR="backups"

if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
    echo "❌ 备份文件不存在: ${BACKUP_DIR}/${BACKUP_FILE}"
    exit 1
fi

echo "🔄 开始恢复 IPv6 WireGuard Manager..."

# 停止服务
echo "🛑 停止服务..."
docker-compose down

# 解压备份文件
echo "📦 解压备份文件..."
cd ${BACKUP_DIR}
tar -xzf ${BACKUP_FILE}
BACKUP_NAME=$(basename ${BACKUP_FILE} .tar.gz)
cd ..

# 恢复数据库
echo "🗄️  恢复数据库..."
docker-compose up -d db
sleep 10
docker-compose exec -T db psql -U ipv6wgm -d ipv6wgm < ${BACKUP_DIR}/${BACKUP_NAME}/database.sql

# 恢复配置文件
echo "📁 恢复配置文件..."
cp ${BACKUP_DIR}/${BACKUP_NAME}/.env backend/ 2>/dev/null || true
cp ${BACKUP_DIR}/${BACKUP_NAME}/docker-compose.yml . 2>/dev/null || true

# 恢复数据目录
echo "📊 恢复数据目录..."
cp -r ${BACKUP_DIR}/${BACKUP_NAME}/data/ . 2>/dev/null || true

# 启动所有服务
echo "🚀 启动所有服务..."
docker-compose up -d

echo "✅ 恢复完成"
echo ""
echo "💡 提示："
echo "   - 请检查服务状态: docker-compose ps"
echo "   - 查看日志: ./scripts/logs.sh"
