#!/bin/bash

# IPv6 WireGuard Manager 备份脚本

set -e

BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="ipv6wgm_backup_${TIMESTAMP}"

echo "💾 开始备份 IPv6 WireGuard Manager..."

# 创建备份目录
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}

# 备份数据库
echo "🗄️  备份数据库..."
docker-compose exec -T db pg_dump -U ipv6wgm ipv6wgm > ${BACKUP_DIR}/${BACKUP_NAME}/database.sql

# 备份配置文件
echo "📁 备份配置文件..."
cp -r backend/.env ${BACKUP_DIR}/${BACKUP_NAME}/ 2>/dev/null || true
cp -r docker-compose.yml ${BACKUP_DIR}/${BACKUP_NAME}/
cp -r backend/app/core/config.py ${BACKUP_DIR}/${BACKUP_NAME}/ 2>/dev/null || true

# 备份WireGuard配置
echo "🔐 备份WireGuard配置..."
mkdir -p ${BACKUP_DIR}/${BACKUP_NAME}/wireguard
cp -r /etc/wireguard/* ${BACKUP_DIR}/${BACKUP_NAME}/wireguard/ 2>/dev/null || true

# 备份数据目录
echo "📊 备份数据目录..."
cp -r data/ ${BACKUP_DIR}/${BACKUP_NAME}/ 2>/dev/null || true

# 创建备份信息文件
echo "📝 创建备份信息..."
cat > ${BACKUP_DIR}/${BACKUP_NAME}/backup_info.txt << EOF
备份时间: $(date)
备份版本: $(git rev-parse HEAD 2>/dev/null || echo "unknown")
系统信息: $(uname -a)
Docker版本: $(docker --version)
备份内容:
- 数据库 (PostgreSQL)
- 配置文件
- WireGuard配置
- 数据目录
EOF

# 压缩备份
echo "📦 压缩备份文件..."
cd ${BACKUP_DIR}
tar -czf ${BACKUP_NAME}.tar.gz ${BACKUP_NAME}
rm -rf ${BACKUP_NAME}
cd ..

echo "✅ 备份完成: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo ""
echo "💡 恢复备份: ./scripts/restore.sh ${BACKUP_NAME}.tar.gz"
