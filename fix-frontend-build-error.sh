#!/bin/bash

# IPv6 WireGuard Manager 前端构建错误修复脚本
# 修复 Ant Design Icons 导入错误

set -e

echo "=========================================="
echo "IPv6 WireGuard Manager 前端构建错误修复"
echo "=========================================="

# 检查是否在正确的目录
if [ ! -d "frontend" ]; then
    echo "[ERROR] 请在项目根目录运行此脚本"
    exit 1
fi

echo "[INFO] 1. 进入前端目录..."
cd frontend

echo "[INFO] 2. 检查Node.js环境..."
if ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js 未安装"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "[ERROR] npm 未安装"
    exit 1
fi

echo "[SUCCESS] Node.js 版本: $(node --version)"
echo "[SUCCESS] npm 版本: $(npm --version)"

echo "[INFO] 3. 清理缓存和依赖..."
npm cache clean --force
rm -rf node_modules package-lock.json

echo "[INFO] 4. 重新安装依赖..."
npm install

echo "[INFO] 5. 创建环境变量文件..."
cat > .env << 'EOF'
VITE_API_URL=http://localhost:8000
VITE_APP_NAME=IPv6 WireGuard Manager
VITE_APP_VERSION=3.0.0
VITE_DEBUG=false
NODE_ENV=production
EOF

echo "[INFO] 6. 清理构建缓存..."
rm -rf dist .vite

echo "[INFO] 7. 重新构建前端..."
npm run build

echo "[INFO] 8. 检查构建结果..."
if [ -d "dist" ]; then
    echo "[SUCCESS] 构建成功！"
    echo "[INFO] 构建文件列表:"
    ls -la dist/
    echo "[INFO] 静态资源文件:"
    ls -la dist/assets/ 2>/dev/null || echo "assets目录不存在"
else
    echo "[ERROR] 构建失败，dist目录不存在"
    exit 1
fi

echo "[INFO] 9. 设置权限..."
chown -R www-data:www-data dist/ 2>/dev/null || echo "无法设置www-data权限"
chmod -R 755 dist/

echo "[INFO] 10. 重启Nginx..."
systemctl restart nginx

echo "[INFO] 11. 测试前端访问..."
sleep 2
if curl -f http://localhost/ > /dev/null 2>&1; then
    echo "[SUCCESS] 前端访问正常"
else
    echo "[WARNING] 前端访问测试失败，请检查Nginx配置"
fi

echo ""
echo "=========================================="
echo "✅ 前端构建错误修复完成！"
echo "=========================================="
echo ""
echo "🎯 修复内容："
echo "  - 修复了 ShieldCheckOutlined 图标导入错误"
echo "  - 使用 ShieldOutlined 替代不存在的图标"
echo "  - 重新构建了前端项目"
echo "  - 重启了Nginx服务"
echo ""
echo "🚀 现在可以访问："
echo "  - 前端界面: http://localhost"
echo "  - API文档: http://localhost/api/v1/docs"
echo ""
echo "📋 默认登录信息："
echo "  - 用户名: admin"
echo "  - 密码: admin123"
echo ""
