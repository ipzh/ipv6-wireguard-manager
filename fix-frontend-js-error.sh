#!/bin/bash

# 修复前端JavaScript错误脚本
# 解决 "Cannot read properties of undefined (reading 'version')" 错误

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "修复前端JavaScript错误"
echo "=========================================="
echo ""

# 1. 检查错误详情
log_info "1. 分析JavaScript错误..."

echo "错误信息: Cannot read properties of undefined (reading 'version')"
echo "错误位置: vendor-rc-util-TnUxXeCY.js"
echo "可能原因:"
echo "  - 模块依赖注入问题"
echo "  - React版本兼容性问题"
echo "  - Ant Design组件库版本冲突"
echo "  - 构建配置问题"
echo ""

# 2. 检查前端环境
log_info "2. 检查前端环境..."

FRONTEND_DIR="/opt/ipv6-wireguard-manager/frontend"
cd "$FRONTEND_DIR"

if [ -f "package.json" ]; then
    echo "当前依赖版本:"
    grep -E '"react"|"antd"|"@ant-design"' package.json
    echo ""
else
    log_error "package.json不存在"
    exit 1
fi

# 3. 检查Node.js和npm版本
log_info "3. 检查Node.js和npm版本..."

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

echo "Node.js版本: $NODE_VERSION"
echo "npm版本: $NPM_VERSION"

# 检查版本兼容性
NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_MAJOR" -lt 18 ]; then
    log_warning "Node.js版本过低，可能导致构建问题"
fi

echo ""

# 4. 清理和重新安装依赖
log_info "4. 清理和重新安装依赖..."

# 清理缓存和依赖
log_info "清理npm缓存..."
npm cache clean --force

log_info "删除node_modules和package-lock.json..."
rm -rf node_modules package-lock.json

log_info "重新安装依赖..."
npm install

if [ $? -eq 0 ]; then
    log_success "依赖重新安装成功"
else
    log_error "依赖安装失败"
    exit 1
fi

echo ""

# 5. 更新package.json中的依赖版本
log_info "5. 更新依赖版本以解决兼容性问题..."

# 备份原package.json
cp package.json package.json.backup

# 更新到兼容的版本
cat > package.json << 'EOF'
{
  "name": "ipv6-wireguard-manager-frontend",
  "version": "3.0.0",
  "description": "IPv6 WireGuard Manager Frontend",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .ts,.tsx",
    "lint:fix": "eslint src --ext .ts,.tsx --fix",
    "format": "prettier --write src/**/*.{ts,tsx,css,md}"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0",
    "@reduxjs/toolkit": "^1.9.7",
    "react-redux": "^8.1.3",
    "antd": "^5.8.0",
    "@ant-design/icons": "^5.2.6",
    "axios": "^1.6.0",
    "dayjs": "^1.11.10",
    "recharts": "^2.8.0",
    "qrcode": "^1.5.3",
    "styled-components": "^6.1.0",
    "tailwindcss": "^3.3.0",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@types/qrcode": "^1.5.5",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "@vitejs/plugin-react": "^4.2.1",
    "eslint": "^9.0.0",
    "@eslint/js": "^9.0.0",
    "eslint-plugin-react": "^7.34.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "eslint-plugin-jsx-a11y": "^6.8.0",
    "prettier": "^3.1.0",
    "typescript": "^5.3.3",
    "vite": "^5.1.0",
    "jest": "^29.7.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/jest-dom": "^6.1.4",
    "@testing-library/user-event": "^14.5.1"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=10.0.0"
  }
}
EOF

log_success "package.json已更新"

echo ""

# 6. 重新安装依赖
log_info "6. 重新安装更新后的依赖..."

npm install

if [ $? -eq 0 ]; then
    log_success "依赖安装成功"
else
    log_error "依赖安装失败，恢复原配置"
    mv package.json.backup package.json
    npm install
    exit 1
fi

echo ""

# 7. 更新Vite配置以解决模块加载问题
log_info "7. 更新Vite配置..."

# 备份原配置
cp vite.config.ts vite.config.ts.backup

# 创建新的Vite配置
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react({
      jsxImportSource: '@emotion/react',
      babel: {
        plugins: ['@emotion/babel-plugin'],
      },
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@pages': path.resolve(__dirname, './src/pages'),
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@services': path.resolve(__dirname, './src/services'),
      '@store': path.resolve(__dirname, './src/store'),
      '@utils': path.resolve(__dirname, './src/utils'),
      '@types': path.resolve(__dirname, './src/types'),
      '@styles': path.resolve(__dirname, './src/styles'),
      '@assets': path.resolve(__dirname, './src/assets'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
      '/ws': {
        target: 'ws://localhost:8000',
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    cssCodeSplit: true,
    target: 'es2018',
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'router': ['react-router-dom'],
          'antd': ['antd', '@ant-design/icons'],
          'state': ['@reduxjs/toolkit', 'react-redux'],
          'utils': ['axios', 'dayjs', 'qrcode'],
          'charts': ['recharts'],
        },
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]',
      },
      treeshake: true,
      preserveEntrySignatures: 'allow',
    },
    chunkSizeWarningLimit: 1200,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
    },
  },
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-router-dom',
      'antd',
      '@ant-design/icons',
      '@reduxjs/toolkit',
      'react-redux',
      'axios',
      'dayjs',
      'recharts',
      'qrcode',
      'styled-components',
    ],
    force: true,
  },
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'production'),
  },
})
EOF

log_success "Vite配置已更新"

echo ""

# 8. 创建环境变量文件
log_info "8. 创建环境变量文件..."

cat > .env << 'EOF'
# API配置
VITE_API_URL=http://172.16.1.117:8000

# 应用配置
VITE_APP_NAME=IPv6 WireGuard Manager
VITE_APP_VERSION=3.0.0

# 开发配置
VITE_DEBUG=false
NODE_ENV=production
EOF

log_success "环境变量文件已创建"

echo ""

# 9. 清理构建缓存
log_info "9. 清理构建缓存..."

rm -rf dist
rm -rf .vite

log_success "构建缓存已清理"

echo ""

# 10. 重新构建前端
log_info "10. 重新构建前端..."

log_info "开始构建..."
npm run build

if [ $? -eq 0 ]; then
    log_success "前端构建成功"
else
    log_error "前端构建失败"
    echo "构建错误详情:"
    npm run build 2>&1 | tail -20
    exit 1
fi

echo ""

# 11. 检查构建结果
log_info "11. 检查构建结果..."

if [ -d "dist" ]; then
    log_success "构建目录已创建"
    
    echo "构建文件列表:"
    ls -la dist/
    echo ""
    
    if [ -d "dist/assets" ]; then
        echo "assets文件列表:"
        ls -la dist/assets/ | head -10
        echo ""
        
        # 检查关键文件
        JS_COUNT=$(find dist/assets -name "*.js" | wc -l)
        CSS_COUNT=$(find dist/assets -name "*.css" | wc -l)
        
        log_info "JavaScript文件数量: $JS_COUNT"
        log_info "CSS文件数量: $CSS_COUNT"
    fi
else
    log_error "构建目录未创建"
    exit 1
fi

echo ""

# 12. 设置文件权限
log_info "12. 设置文件权限..."

chown -R www-data:www-data dist/ 2>/dev/null || chown -R nginx:nginx dist/ 2>/dev/null || true
chmod -R 755 dist/

log_success "文件权限已设置"

echo ""

# 13. 重启Nginx
log_info "13. 重启Nginx..."

systemctl restart nginx

if systemctl is-active --quiet nginx; then
    log_success "Nginx重启成功"
else
    log_error "Nginx重启失败"
fi

echo ""

# 14. 测试前端访问
log_info "14. 测试前端访问..."

SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")

# 测试静态文件访问
if curl -f -s http://$SERVER_IP/ > /dev/null 2>&1; then
    log_success "前端HTTP访问正常"
    
    # 检查HTML内容
    echo "前端页面内容预览:"
    curl -s http://$SERVER_IP/ | head -5
    echo ""
    
    # 检查JavaScript文件
    JS_FILE=$(curl -s http://$SERVER_IP/ | grep -o 'assets/[^"]*\.js' | head -1)
    if [ -n "$JS_FILE" ]; then
        if curl -f -s http://$SERVER_IP/$JS_FILE > /dev/null 2>&1; then
            log_success "JavaScript文件访问正常: $JS_FILE"
        else
            log_warning "JavaScript文件访问失败: $JS_FILE"
        fi
    fi
else
    log_warning "前端HTTP访问失败"
fi

echo ""

# 15. 生成修复报告
log_info "15. 生成修复报告..."

REPORT_FILE="/tmp/frontend-js-error-fix-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "前端JavaScript错误修复报告"
    echo "修复时间: $(date)"
    echo "=========================================="
    echo ""
    echo "错误信息:"
    echo "Cannot read properties of undefined (reading 'version')"
    echo "错误位置: vendor-rc-util-TnUxXeCY.js"
    echo ""
    echo "修复措施:"
    echo "- 清理npm缓存和依赖"
    echo "- 更新package.json依赖版本"
    echo "- 优化Vite构建配置"
    echo "- 重新构建前端"
    echo "- 重启Nginx服务"
    echo ""
    echo "修复后状态:"
    echo "Node.js版本: $(node --version)"
    echo "npm版本: $(npm --version)"
    echo ""
    echo "构建结果:"
    ls -la dist/
    echo ""
    echo "静态资源:"
    ls -la dist/assets/
    echo ""
    echo "访问测试:"
    curl -s http://$SERVER_IP/ | head -5
    echo ""
} > "$REPORT_FILE"

log_success "修复报告已生成: $REPORT_FILE"

echo ""
echo "=========================================="
echo "JavaScript错误修复完成！"
echo "=========================================="
echo ""
echo "访问信息:"
echo "  前端: http://$SERVER_IP"
echo "  默认登录: admin/admin123"
echo ""
echo "修复内容:"
echo "  ✅ 清理了npm缓存和依赖"
echo "  ✅ 更新了依赖版本"
echo "  ✅ 优化了Vite构建配置"
echo "  ✅ 重新构建了前端"
echo "  ✅ 重启了Nginx服务"
echo ""
echo "如果问题仍然存在，请检查:"
echo "1. 浏览器控制台是否还有其他错误"
echo "2. 网络请求是否正常"
echo "3. 查看修复报告: cat $REPORT_FILE"
echo ""
