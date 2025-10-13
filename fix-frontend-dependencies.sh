#!/bin/bash

# IPv6 WireGuard Manager - 前端依赖修复脚本
# 修复过时的依赖包和npm版本警告

echo "🔧 开始修复前端依赖问题..."

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在frontend目录下运行此脚本"
    exit 1
fi

# 更新npm到最新版本
echo "📦 更新npm到最新版本..."
npm install -g npm@latest

# 清理node_modules和package-lock.json
echo "🧹 清理旧的依赖文件..."
rm -rf node_modules package-lock.json

# 安装依赖
echo "📥 安装最新依赖..."
npm install

# 修复安全漏洞
echo "🔒 修复安全漏洞..."
npm audit fix

# 如果还有漏洞，尝试强制修复
if [ $? -ne 0 ]; then
    echo "⚠️  尝试强制修复安全漏洞..."
    npm audit fix --force
fi

# 检查依赖状态
echo "📊 检查依赖状态..."
npm audit

# 检查过时的包
echo "🔄 检查过时的包..."
npm outdated

echo "✅ 前端依赖修复完成！"
echo ""
echo "📋 建议操作："
echo "1. 运行 'npm run build' 测试构建是否正常"
echo "2. 运行 'npm run lint' 检查代码规范"
echo "3. 运行 'npm test' 运行测试"