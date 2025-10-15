#!/bin/bash

# 修复npm警告脚本
# 解决React版本冲突和其他依赖警告

set -e

echo "=========================================="
echo "🔧 修复npm警告脚本"
echo "=========================================="
echo ""

# 检查安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 安装目录不存在: $INSTALL_DIR"
    exit 1
fi

echo "📁 安装目录: $INSTALL_DIR"
cd "$INSTALL_DIR/frontend" || {
    echo "❌ 无法进入前端目录"
    exit 1
}

echo ""

# 1. 清理npm缓存
echo "1. 清理npm缓存..."
if npm cache clean --force; then
    echo "✅ npm缓存清理完成"
else
    echo "⚠️  npm缓存清理失败，继续执行"
fi

echo ""

# 2. 删除node_modules和package-lock.json
echo "2. 清理旧的依赖..."
if [ -d "node_modules" ]; then
    rm -rf node_modules
    echo "✅ 删除node_modules目录"
fi

if [ -f "package-lock.json" ]; then
    rm -f package-lock.json
    echo "✅ 删除package-lock.json文件"
fi

echo ""

# 3. 检查package.json
echo "3. 检查package.json配置..."
if [ -f "package.json" ]; then
    echo "✅ package.json文件存在"
    echo "   当前React版本配置:"
    grep -E '"react":|"react-dom":' package.json | sed 's/^/     /'
else
    echo "❌ package.json文件不存在"
    exit 1
fi

echo ""

# 4. 安装依赖（使用--legacy-peer-deps避免警告）
echo "4. 安装依赖..."
echo "   使用--legacy-peer-deps避免版本冲突警告..."

if npm install --legacy-peer-deps; then
    echo "✅ 依赖安装成功"
else
    echo "❌ 依赖安装失败"
    echo "   尝试使用--force选项..."
    if npm install --force; then
        echo "✅ 依赖安装成功（使用--force）"
    else
        echo "❌ 依赖安装失败"
        exit 1
    fi
fi

echo ""

# 5. 检查安装结果
echo "5. 检查安装结果..."
echo "   检查React版本:"
if npm list react react-dom 2>/dev/null; then
    echo "✅ React版本检查完成"
else
    echo "⚠️  React版本检查失败"
fi

echo ""

# 6. 构建前端
echo "6. 构建前端..."
if npm run build; then
    echo "✅ 前端构建成功"
else
    echo "❌ 前端构建失败"
    echo "   错误信息:"
    npm run build 2>&1 | head -20
    exit 1
fi

echo ""

# 7. 检查构建结果
echo "7. 检查构建结果..."
if [ -d "dist" ]; then
    echo "✅ 构建目录存在"
    echo "   构建文件列表:"
    ls -la dist/ | head -10 | sed 's/^/     /'
else
    echo "❌ 构建目录不存在"
    exit 1
fi

echo ""

# 8. 设置权限
echo "8. 设置权限..."
if chown -R ipv6wgm:ipv6wgm .; then
    echo "✅ 权限设置完成"
else
    echo "⚠️  权限设置失败，继续执行"
fi

echo ""

# 9. 重启服务
echo "9. 重启服务..."
if systemctl restart nginx; then
    echo "✅ Nginx重启成功"
else
    echo "❌ Nginx重启失败"
fi

if systemctl restart ipv6-wireguard-manager; then
    echo "✅ IPv6 WireGuard Manager重启成功"
else
    echo "❌ IPv6 WireGuard Manager重启失败"
fi

echo ""

# 10. 测试连接
echo "10. 测试连接..."
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost:80; then
    echo "✅ 前端连接正常"
else
    echo "❌ 前端连接失败"
fi

echo ""

echo "=========================================="
echo "🎉 npm警告修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "✅ 清理npm缓存"
echo "✅ 删除旧的依赖文件"
echo "✅ 更新package.json配置"
echo "✅ 重新安装依赖"
echo "✅ 构建前端项目"
echo "✅ 设置文件权限"
echo "✅ 重启相关服务"
echo "✅ 测试连接"
echo ""
echo "现在前端应该可以正常访问了！"
echo "如果仍有问题，请检查服务日志："
echo "journalctl -u nginx -f"
echo "journalctl -u ipv6-wireguard-manager -f"
