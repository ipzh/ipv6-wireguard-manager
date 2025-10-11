#!/bin/bash

# 内存优化的前端构建脚本
# 解决JavaScript堆内存不足问题

set -e

echo "⚛️  内存优化前端构建..."

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 不在前端目录中，package.json 不存在"
    exit 1
fi

echo "   当前目录: $(pwd)"

# 检查系统内存
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
echo "   系统总内存: ${TOTAL_MEM}MB"

# 根据系统内存调整Node.js内存限制
if [ "$TOTAL_MEM" -gt 4096 ]; then
    NODE_MEMORY="4096"
    echo "   使用4GB内存限制"
elif [ "$TOTAL_MEM" -gt 2048 ]; then
    NODE_MEMORY="2048"
    echo "   使用2GB内存限制"
elif [ "$TOTAL_MEM" -gt 1024 ]; then
    NODE_MEMORY="1024"
    echo "   使用1GB内存限制"
else
    NODE_MEMORY="512"
    echo "   使用512MB内存限制"
fi

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

# 清理npm缓存
echo "🧹 清理npm缓存..."
npm cache clean --force

# 安装依赖（抑制废弃警告）
echo "📦 安装依赖..."
echo "   抑制npm废弃警告..."
npm install --silent 2>/dev/null || npm install

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

# 设置Node.js内存限制并运行构建
echo "🏗️  运行内存优化构建..."
echo "   Node.js内存限制: ${NODE_MEMORY}MB"

# 尝试构建，如果失败则降低内存要求
for memory in $NODE_MEMORY 2048 1024 512; do
    echo "   尝试使用 ${memory}MB 内存..."
    if NODE_OPTIONS="--max-old-space-size=$memory" npx vite build; then
        echo "✅ Vite构建成功（使用${memory}MB内存）"
        break
    else
        echo "❌ 使用${memory}MB内存构建失败"
        if [ "$memory" = "512" ]; then
            echo "❌ 所有内存限制都失败"
            exit 1
        fi
    fi
done

# 检查构建结果
if [ -d "dist" ]; then
    echo "✅ 构建完成，输出目录: dist"
    echo "📁 构建文件:"
    ls -la dist/
    
    # 显示构建文件大小
    echo "📊 构建统计:"
    du -sh dist/
    echo "   文件数量: $(find dist -type f | wc -l)"
else
    echo "❌ 构建失败，dist目录不存在"
    exit 1
fi

echo "✅ 内存优化前端构建完成"
