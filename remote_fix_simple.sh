#!/bin/bash
# 远程服务器一键修复脚本 - 简化版
# 快速修复导入路径问题

echo "🔧 远程服务器一键修复 - 简化版"

# 项目目录
PROJECT_DIR="/tmp/ipv6-wireguard-manager"
BACKEND_DIR="$PROJECT_DIR/backend"

# 检查目录
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# 修复导入路径
echo "🔧 修复导入路径..."

# 批量修复所有Python文件
find "$BACKEND_DIR/app" -name "*.py" -type f | while read file; do
    if [ -f "$file" ]; then
        # 修复endpoints目录中的导入
        if [[ "$file" == *"/endpoints/"* ]]; then
            sed -i 's/from app\./from ..../g' "$file"
        # 修复api_v1目录中的导入
        elif [[ "$file" == *"/api_v1/"* ]]; then
            sed -i 's/from app\./from .../g' "$file"
        # 修复其他目录中的导入
        else
            sed -i 's/from app\./from ../g' "$file"
        fi
    fi
done

echo "✅ 导入路径修复完成"

# 重启服务
echo "🔄 重启服务..."
sudo systemctl restart ipv6-wireguard-manager
sleep 5

# 检查服务状态
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 服务启动成功"
    echo "🎉 修复完成！"
else
    echo "❌ 服务启动失败"
    echo "📋 查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    exit 1
fi
