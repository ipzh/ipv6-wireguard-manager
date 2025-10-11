#!/bin/bash

# 分块优化的前端构建脚本
# 解决Vite构建在"rendering chunks"阶段卡住的问题

set -e

echo "⚛️  分块优化前端构建..."

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 不在前端目录中，package.json 不存在"
    exit 1
fi

echo "   当前目录: $(pwd)"

# 检查系统资源
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
CPU_CORES=$(nproc)
echo "   系统总内存: ${TOTAL_MEM}MB"
echo "   CPU核心数: ${CPU_CORES}"

# 根据系统资源调整构建参数
if [ "$TOTAL_MEM" -gt 4096 ] && [ "$CPU_CORES" -gt 2 ]; then
    NODE_MEMORY="4096"
    CHUNK_SIZE="1000"
    echo "   使用高性能配置: 4GB内存, 1000chunk大小"
elif [ "$TOTAL_MEM" -gt 2048 ] && [ "$CPU_CORES" -gt 1 ]; then
    NODE_MEMORY="2048"
    CHUNK_SIZE="500"
    echo "   使用中等配置: 2GB内存, 500chunk大小"
else
    NODE_MEMORY="1024"
    CHUNK_SIZE="200"
    echo "   使用低配置: 1GB内存, 200chunk大小"
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

# 清理环境
echo "🧹 清理构建环境..."
rm -rf dist/ node_modules/.vite/ .vite/
npm cache clean --force

# 安装依赖
echo "📦 安装依赖..."
npm install --silent 2>/dev/null || npm install

# 创建优化的Vite配置
echo "⚙️  创建优化的Vite配置..."
cat > vite.config.optimized.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@store': path.resolve(__dirname, './src/store'),
    },
  },
  build: {
    // 优化分块策略
    rollupOptions: {
      output: {
        // 手动分块，避免大文件
        manualChunks: {
          // 将React相关库分离
          'react-vendor': ['react', 'react-dom'],
          // 将Ant Design分离
          'antd-vendor': ['antd', '@ant-design/icons'],
          // 将路由相关分离
          'router-vendor': ['react-router-dom'],
          // 将状态管理分离
          'state-vendor': ['@reduxjs/toolkit', 'react-redux'],
          // 将工具库分离
          'utils-vendor': ['axios', 'dayjs'],
        },
        // 设置chunk大小限制
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]',
      },
    },
    // 设置构建目标
    target: 'es2015',
    // 启用压缩
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
    // 设置chunk大小警告限制
    chunkSizeWarningLimit: 1000,
    // 启用源码映射（可选）
    sourcemap: false,
  },
  // 优化依赖预构建
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'antd',
      '@ant-design/icons',
      'react-router-dom',
    ],
  },
  // 开发服务器配置
  server: {
    port: 3000,
    host: true,
  },
})
EOF

# 设置环境变量
export NODE_OPTIONS="--max-old-space-size=$NODE_MEMORY"
export VITE_CHUNK_SIZE="$CHUNK_SIZE"

echo "🏗️  开始分块优化构建..."
echo "   使用配置文件: vite.config.optimized.js"
echo "   Node.js内存限制: ${NODE_MEMORY}MB"
echo "   分块大小限制: ${CHUNK_SIZE}"

# 使用优化的配置构建
if npx vite build --config vite.config.optimized.js; then
    echo "✅ 分块优化构建成功"
else
    echo "❌ 分块优化构建失败，尝试标准构建..."
    
    # 回退到标准构建
    if npx vite build; then
        echo "✅ 标准构建成功"
    else
        echo "❌ 所有构建方法都失败"
        exit 1
    fi
fi

# 检查构建结果
if [ -d "dist" ]; then
    echo "✅ 构建完成，输出目录: dist"
    echo "📁 构建文件:"
    ls -la dist/
    
    # 显示构建统计
    echo "📊 构建统计:"
    du -sh dist/
    echo "   文件数量: $(find dist -type f | wc -l)"
    
    # 显示chunk文件大小
    echo "📦 Chunk文件大小:"
    find dist/assets -name "*.js" -exec ls -lh {} \; | head -10
    
    # 清理临时配置文件
    rm -f vite.config.optimized.js
else
    echo "❌ 构建失败，dist目录不存在"
    exit 1
fi

echo "✅ 分块优化前端构建完成"
