#!/bin/bash

# 修复Vite构建在"rendering chunks"阶段卡住的问题

set -e

echo "🔧 修复Vite构建卡住问题..."

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 不在前端目录中，package.json 不存在"
    exit 1
fi

echo "   当前目录: $(pwd)"

# 1. 清理所有缓存和临时文件
echo "🧹 清理所有缓存和临时文件..."
rm -rf dist/
rm -rf node_modules/.vite/
rm -rf .vite/
rm -rf .cache/
npm cache clean --force

# 2. 检查系统资源
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
CPU_CORES=$(nproc)
echo "   系统总内存: ${TOTAL_MEM}MB"
echo "   CPU核心数: ${CPU_CORES}"

# 3. 创建最小化的Vite配置
echo "⚙️  创建最小化Vite配置..."
cat > vite.config.minimal.js << 'EOF'
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
    // 最小化配置，避免复杂的分块
    rollupOptions: {
      output: {
        // 简单的分块策略
        manualChunks: {
          'vendor': ['react', 'react-dom', 'antd'],
        },
        // 设置较小的chunk大小
        chunkFileNames: 'assets/[name].js',
        entryFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name].[ext]',
      },
    },
    // 禁用源码映射
    sourcemap: false,
    // 使用esbuild压缩（更快）
    minify: 'esbuild',
    // 设置较小的chunk大小警告限制
    chunkSizeWarningLimit: 500,
  },
  // 禁用依赖预构建
  optimizeDeps: {
    disabled: true,
  },
})
EOF

# 4. 设置环境变量
export NODE_OPTIONS="--max-old-space-size=2048"
export NODE_ENV="production"

# 5. 尝试构建
echo "🏗️  尝试最小化构建..."
echo "   使用配置文件: vite.config.minimal.js"
echo "   Node.js内存限制: 2GB"

# 设置超时，避免无限等待
timeout 300 npx vite build --config vite.config.minimal.js || {
    echo "❌ 构建超时，尝试更激进的优化..."
    
    # 创建超简化配置
    cat > vite.config.ultra-minimal.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    // 超简化配置
    rollupOptions: {
      output: {
        // 不进行分块
        inlineDynamicImports: true,
      },
    },
    sourcemap: false,
    minify: false, // 禁用压缩
    chunkSizeWarningLimit: 1000,
  },
  optimizeDeps: {
    disabled: true,
  },
})
EOF
    
    echo "🏗️  尝试超简化构建..."
    timeout 180 npx vite build --config vite.config.ultra-minimal.js || {
        echo "❌ 所有构建方法都失败"
        echo "💡 建议："
        echo "   1. 检查系统内存是否充足"
        echo "   2. 尝试重启系统"
        echo "   3. 使用Docker安装方式"
        exit 1
    }
}

# 6. 检查构建结果
if [ -d "dist" ]; then
    echo "✅ 构建成功！"
    echo "📁 构建文件:"
    ls -la dist/
    
    # 显示构建统计
    echo "📊 构建统计:"
    du -sh dist/
    echo "   文件数量: $(find dist -type f | wc -l)"
    
    # 清理临时配置文件
    rm -f vite.config.minimal.js vite.config.ultra-minimal.js
else
    echo "❌ 构建失败，dist目录不存在"
    exit 1
fi

echo "✅ Vite构建卡住问题修复完成"
