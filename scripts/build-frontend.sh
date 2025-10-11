#!/bin/bash

# 前端构建脚本
# 处理TypeScript编译和Vite构建

set -e

echo "⚛️  构建React前端..."

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 不在前端目录中，package.json 不存在"
    exit 1
fi

echo "   当前目录: $(pwd)"

# 检查Node.js和npm
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js 未安装"
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "❌ npm 未安装"
    exit 1
fi

echo "   Node.js版本: $(node --version)"
echo "   npm版本: $(npm --version)"

# 安装依赖
echo "📦 安装依赖..."
npm install

# 检查TypeScript是否可用
if ! npx tsc --version >/dev/null 2>&1; then
    echo "❌ TypeScript 不可用，尝试安装..."
    npm install typescript --save-dev
fi

# 检查Vite是否可用
if ! npx vite --version >/dev/null 2>&1; then
    echo "❌ Vite 不可用，尝试安装..."
    npm install vite --save-dev
fi

# 运行TypeScript编译
echo "🔨 运行TypeScript编译..."
if npx tsc --noEmit; then
    echo "✅ TypeScript编译检查通过"
else
    echo "⚠️  TypeScript编译检查失败，但继续构建..."
fi

# 运行Vite构建
echo "🏗️  运行Vite构建..."
if npx vite build; then
    echo "✅ Vite构建成功"
else
    echo "❌ Vite构建失败"
    exit 1
fi

# 检查构建结果
if [ -d "dist" ]; then
    echo "✅ 构建完成，输出目录: dist"
    echo "📁 构建文件:"
    ls -la dist/
else
    echo "❌ 构建失败，dist目录不存在"
    exit 1
fi

echo "✅ 前端构建完成"
