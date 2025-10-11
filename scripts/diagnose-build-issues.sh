#!/bin/bash

# 诊断前端构建问题的脚本

echo "🔍 诊断前端构建问题..."

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 不在前端目录中，package.json 不存在"
    exit 1
fi

echo "   当前目录: $(pwd)"

# 1. 系统资源检查
echo "📊 系统资源检查:"
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
AVAIL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

echo "   总内存: ${TOTAL_MEM}MB"
echo "   可用内存: ${AVAIL_MEM}MB"
echo "   CPU核心数: ${CPU_CORES}"
echo "   系统负载: ${LOAD_AVG}"

# 内存建议
if [ "$AVAIL_MEM" -lt 1024 ]; then
    echo "⚠️  可用内存不足1GB，建议使用最小化构建"
elif [ "$AVAIL_MEM" -lt 2048 ]; then
    echo "⚠️  可用内存不足2GB，建议使用内存优化构建"
else
    echo "✅ 内存充足，可以使用标准构建"
fi

# 2. Node.js环境检查
echo ""
echo "🔧 Node.js环境检查:"
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "   Node.js版本: $NODE_VERSION"
    
    # 检查Node.js版本
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -lt 16 ]; then
        echo "⚠️  Node.js版本过低，建议升级到16+"
    else
        echo "✅ Node.js版本合适"
    fi
else
    echo "❌ Node.js未安装"
fi

if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm --version)
    echo "   npm版本: $NPM_VERSION"
else
    echo "❌ npm未安装"
fi

# 3. 项目文件检查
echo ""
echo "📁 项目文件检查:"
if [ -f "package.json" ]; then
    echo "✅ package.json 存在"
    
    # 检查关键依赖
    if grep -q "vite" package.json; then
        echo "✅ Vite 依赖存在"
    else
        echo "❌ Vite 依赖缺失"
    fi
    
    if grep -q "react" package.json; then
        echo "✅ React 依赖存在"
    else
        echo "❌ React 依赖缺失"
    fi
else
    echo "❌ package.json 不存在"
fi

if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
    echo "✅ Vite 配置文件存在"
else
    echo "⚠️  Vite 配置文件不存在，将使用默认配置"
fi

# 4. 构建历史检查
echo ""
echo "📈 构建历史检查:"
if [ -d "dist" ]; then
    echo "✅ dist 目录存在"
    echo "   文件数量: $(find dist -type f | wc -l)"
    echo "   目录大小: $(du -sh dist | cut -f1)"
else
    echo "⚠️  dist 目录不存在，这是首次构建"
fi

if [ -d "node_modules" ]; then
    echo "✅ node_modules 目录存在"
    echo "   依赖数量: $(find node_modules -maxdepth 1 -type d | wc -l)"
else
    echo "❌ node_modules 目录不存在，需要安装依赖"
fi

# 5. 磁盘空间检查
echo ""
echo "💾 磁盘空间检查:"
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h . | awk 'NR==2 {print $4}')

echo "   磁盘使用率: ${DISK_USAGE}%"
echo "   可用空间: ${DISK_AVAIL}"

if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠️  磁盘空间不足，建议清理"
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  磁盘空间紧张"
else
    echo "✅ 磁盘空间充足"
fi

# 6. 网络连接检查
echo ""
echo "🌐 网络连接检查:"
if ping -c 1 registry.npmjs.org >/dev/null 2>&1; then
    echo "✅ npm 注册表连接正常"
else
    echo "⚠️  npm 注册表连接异常"
fi

# 7. 构建建议
echo ""
echo "💡 构建建议:"

if [ "$AVAIL_MEM" -lt 1024 ]; then
    echo "   推荐使用: bash ../../scripts/fix-chunk-rendering.sh"
elif [ "$AVAIL_MEM" -lt 2048 ]; then
    echo "   推荐使用: bash ../../scripts/build-frontend-memory-optimized.sh"
else
    echo "   推荐使用: bash ../../scripts/build-frontend-chunk-optimized.sh"
fi

# 8. 常见问题解决方案
echo ""
echo "🔧 常见问题解决方案:"
echo "   1. 如果构建卡在 'rendering chunks':"
echo "      - 使用: bash ../../scripts/fix-chunk-rendering.sh"
echo "   2. 如果出现内存不足错误:"
echo "      - 使用: bash ../../scripts/build-frontend-memory-optimized.sh"
echo "   3. 如果构建速度慢:"
echo "      - 使用: bash ../../scripts/build-frontend-chunk-optimized.sh"
echo "   4. 如果所有方法都失败:"
echo "      - 尝试重启系统"
echo "      - 使用Docker安装方式"

echo ""
echo "✅ 诊断完成"
