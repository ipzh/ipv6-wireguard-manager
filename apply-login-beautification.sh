#!/bin/bash

# 应用登录页面美化脚本
# 重新构建前端以应用美化效果

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
echo "应用登录页面美化"
echo "=========================================="
echo ""

# 1. 检查前端目录
log_info "1. 检查前端目录..."

FRONTEND_DIR="/opt/ipv6-wireguard-manager/frontend"
if [ -d "$FRONTEND_DIR" ]; then
    log_success "前端目录存在: $FRONTEND_DIR"
    cd "$FRONTEND_DIR"
else
    log_error "前端目录不存在: $FRONTEND_DIR"
    exit 1
fi

echo ""

# 2. 检查Node.js环境
log_info "2. 检查Node.js环境..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    log_success "Node.js已安装: $NODE_VERSION"
else
    log_error "Node.js未安装"
    exit 1
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    log_success "npm已安装: $NPM_VERSION"
else
    log_error "npm未安装"
    exit 1
fi

echo ""

# 3. 检查依赖
log_info "3. 检查依赖..."

if [ -d "node_modules" ]; then
    log_success "依赖已安装"
else
    log_warning "依赖未安装，开始安装..."
    npm install
    if [ $? -eq 0 ]; then
        log_success "依赖安装成功"
    else
        log_error "依赖安装失败"
        exit 1
    fi
fi

echo ""

# 4. 创建环境变量文件
log_info "4. 创建环境变量文件..."

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

# 5. 清理构建缓存
log_info "5. 清理构建缓存..."

rm -rf dist .vite
npm cache clean --force

log_success "构建缓存已清理"

echo ""

# 6. 重新构建前端
log_info "6. 重新构建前端..."

log_info "开始构建美化后的前端..."
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

# 7. 检查构建结果
log_info "7. 检查构建结果..."

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
        
        if [ "$JS_COUNT" -gt 0 ] && [ "$CSS_COUNT" -gt 0 ]; then
            log_success "静态资源文件生成正常"
        else
            log_warning "静态资源文件可能有问题"
        fi
    else
        log_error "assets目录未创建"
    fi
else
    log_error "构建目录未创建"
    exit 1
fi

echo ""

# 8. 设置文件权限
log_info "8. 设置文件权限..."

chown -R www-data:www-data dist/ 2>/dev/null || chown -R nginx:nginx dist/ 2>/dev/null || true
chmod -R 755 dist/

log_success "文件权限已设置"

echo ""

# 9. 重启Nginx
log_info "9. 重启Nginx..."

systemctl restart nginx

if systemctl is-active --quiet nginx; then
    log_success "Nginx重启成功"
else
    log_error "Nginx重启失败"
fi

echo ""

# 10. 测试美化后的登录页面
log_info "10. 测试美化后的登录页面..."

SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")

# 测试静态文件访问
if curl -f -s http://$SERVER_IP/ > /dev/null 2>&1; then
    log_success "美化后的登录页面访问正常"
    
    # 检查HTML内容
    echo "登录页面内容预览:"
    curl -s http://$SERVER_IP/ | head -5
    echo ""
    
    # 检查CSS文件
    CSS_FILE=$(curl -s http://$SERVER_IP/ | grep -o 'assets/[^"]*\.css' | head -1)
    if [ -n "$CSS_FILE" ]; then
        if curl -f -s http://$SERVER_IP/$CSS_FILE > /dev/null 2>&1; then
            log_success "CSS文件访问正常: $CSS_FILE"
        else
            log_warning "CSS文件访问失败: $CSS_FILE"
        fi
    fi
    
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
    log_warning "登录页面访问失败"
    echo "详细错误信息:"
    curl -v http://$SERVER_IP/ 2>&1 | head -10
fi

echo ""

# 11. 生成美化报告
log_info "11. 生成美化报告..."

REPORT_FILE="/tmp/login-beautification-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "登录页面美化报告"
    echo "美化时间: $(date)"
    echo "=========================================="
    echo ""
    echo "美化内容:"
    echo "- 现代化渐变背景设计"
    echo "- 动态粒子效果和几何装饰"
    echo "- 响应式双栏布局"
    echo "- 毛玻璃效果和阴影"
    echo "- 实时时间显示"
    echo "- 特性展示卡片"
    echo "- 快速登录功能"
    echo "- 增强的交互效果"
    echo "- 移动端适配"
    echo "- 深色模式支持"
    echo ""
    echo "技术特性:"
    echo "- React 18 + TypeScript"
    echo "- Ant Design 5.x 组件库"
    echo "- Tailwind CSS 样式"
    echo "- 自定义CSS动画"
    echo "- 响应式设计"
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

log_success "美化报告已生成: $REPORT_FILE"

echo ""
echo "=========================================="
echo "登录页面美化完成！"
echo "=========================================="
echo ""
echo "美化特性:"
echo "  ✨ 现代化渐变背景"
echo "  🎨 动态粒子效果"
echo "  📱 响应式设计"
echo "  🔒 安全提示"
echo "  ⚡ 快速登录"
echo "  🕒 实时时间"
echo "  🌙 深色模式支持"
echo ""
echo "访问信息:"
echo "  美化登录页: http://$SERVER_IP"
echo "  默认登录: admin/admin123"
echo ""
echo "如果问题仍然存在，请检查:"
echo "1. 浏览器控制台是否有错误"
echo "2. 静态资源文件是否可访问"
echo "3. 查看美化报告: cat $REPORT_FILE"
echo ""
