#!/bin/bash

# 前端构建问题诊断和修复脚本
# 解决前端功能无法正常工作的问题

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
echo "前端构建问题诊断和修复"
echo "=========================================="
echo ""

# 1. 检查前端目录结构
log_info "1. 检查前端目录结构..."

FRONTEND_DIR="/opt/ipv6-wireguard-manager/frontend"
if [ -d "$FRONTEND_DIR" ]; then
    log_success "前端目录存在: $FRONTEND_DIR"
    
    echo "前端目录结构:"
    ls -la "$FRONTEND_DIR" | head -10
    echo ""
    
    # 检查关键文件
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        log_success "package.json存在"
    else
        log_error "package.json不存在"
        exit 1
    fi
    
    if [ -f "$FRONTEND_DIR/src/main.tsx" ]; then
        log_success "main.tsx存在"
    else
        log_error "main.tsx不存在"
        exit 1
    fi
    
    if [ -f "$FRONTEND_DIR/src/App.tsx" ]; then
        log_success "App.tsx存在"
    else
        log_error "App.tsx不存在"
        exit 1
    fi
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
    
    # 检查版本是否满足要求
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        log_success "Node.js版本满足要求 (>=18.0.0)"
    else
        log_warning "Node.js版本过低，建议升级到18.0.0或更高版本"
    fi
else
    log_error "Node.js未安装"
    echo "请安装Node.js: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
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

# 3. 检查依赖安装
log_info "3. 检查依赖安装..."

cd "$FRONTEND_DIR"

if [ -d "node_modules" ]; then
    log_success "node_modules目录存在"
    
    # 检查关键依赖
    if [ -d "node_modules/react" ]; then
        log_success "React依赖已安装"
    else
        log_warning "React依赖缺失"
    fi
    
    if [ -d "node_modules/antd" ]; then
        log_success "Ant Design依赖已安装"
    else
        log_warning "Ant Design依赖缺失"
    fi
    
    if [ -d "node_modules/@reduxjs/toolkit" ]; then
        log_success "Redux Toolkit依赖已安装"
    else
        log_warning "Redux Toolkit依赖缺失"
    fi
else
    log_warning "node_modules目录不存在，需要安装依赖"
    log_info "安装依赖..."
    npm install
    if [ $? -eq 0 ]; then
        log_success "依赖安装成功"
    else
        log_error "依赖安装失败"
        exit 1
    fi
fi

echo ""

# 4. 检查构建配置
log_info "4. 检查构建配置..."

if [ -f "vite.config.ts" ]; then
    log_success "Vite配置文件存在"
    
    # 检查API代理配置
    if grep -q "proxy" vite.config.ts; then
        log_success "API代理配置存在"
    else
        log_warning "API代理配置缺失"
    fi
else
    log_error "Vite配置文件不存在"
    exit 1
fi

if [ -f "tsconfig.json" ]; then
    log_success "TypeScript配置文件存在"
else
    log_warning "TypeScript配置文件不存在"
fi

echo ""

# 5. 检查环境变量配置
log_info "5. 检查环境变量配置..."

# 创建环境变量文件
if [ ! -f ".env" ]; then
    log_info "创建环境变量文件..."
    cat > .env << 'EOF'
# API配置
VITE_API_URL=http://localhost:8000

# 应用配置
VITE_APP_NAME=IPv6 WireGuard Manager
VITE_APP_VERSION=3.0.0

# 开发配置
VITE_DEBUG=true
EOF
    log_success "环境变量文件已创建"
else
    log_success "环境变量文件已存在"
    echo "当前环境变量:"
    cat .env
fi

echo ""

# 6. 清理旧的构建文件
log_info "6. 清理旧的构建文件..."

if [ -d "dist" ]; then
    log_info "清理旧的构建文件..."
    rm -rf dist
    log_success "旧构建文件已清理"
fi

echo ""

# 7. 重新构建前端
log_info "7. 重新构建前端..."

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

# 8. 检查构建结果
log_info "8. 检查构建结果..."

if [ -d "dist" ]; then
    log_success "构建目录已创建"
    
    echo "构建文件列表:"
    ls -la dist/
    echo ""
    
    if [ -f "dist/index.html" ]; then
        log_success "index.html已生成"
        
        # 检查HTML内容
        echo "index.html内容预览:"
        head -10 dist/index.html
        echo ""
        
        # 检查是否有JavaScript和CSS文件引用
        if grep -q "assets/" dist/index.html; then
            log_success "静态资源引用存在"
        else
            log_warning "静态资源引用缺失"
        fi
    else
        log_error "index.html未生成"
    fi
    
    if [ -d "dist/assets" ]; then
        log_success "assets目录已创建"
        
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

# 9. 检查文件权限
log_info "9. 检查文件权限..."

# 确保Nginx可以读取文件
chown -R www-data:www-data dist/ 2>/dev/null || chown -R nginx:nginx dist/ 2>/dev/null || true
chmod -R 755 dist/

log_success "文件权限已设置"

echo ""

# 10. 测试前端访问
log_info "10. 测试前端访问..."

SERVER_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")

# 测试静态文件访问
if curl -f -s http://$SERVER_IP/ > /dev/null 2>&1; then
    log_success "前端HTTP访问正常"
    
    # 检查HTML内容
    echo "前端页面内容预览:"
    curl -s http://$SERVER_IP/ | head -5
    echo ""
    
    # 检查是否有JavaScript错误
    echo "检查JavaScript文件访问:"
    JS_FILE=$(curl -s http://$SERVER_IP/ | grep -o 'assets/[^"]*\.js' | head -1)
    if [ -n "$JS_FILE" ]; then
        if curl -f -s http://$SERVER_IP/$JS_FILE > /dev/null 2>&1; then
            log_success "JavaScript文件访问正常: $JS_FILE"
        else
            log_warning "JavaScript文件访问失败: $JS_FILE"
        fi
    fi
    
    # 检查CSS文件访问
    CSS_FILE=$(curl -s http://$SERVER_IP/ | grep -o 'assets/[^"]*\.css' | head -1)
    if [ -n "$CSS_FILE" ]; then
        if curl -f -s http://$SERVER_IP/$CSS_FILE > /dev/null 2>&1; then
            log_success "CSS文件访问正常: $CSS_FILE"
        else
            log_warning "CSS文件访问失败: $CSS_FILE"
        fi
    fi
else
    log_warning "前端HTTP访问失败"
    echo "详细错误信息:"
    curl -v http://$SERVER_IP/ 2>&1 | head -10
fi

echo ""

# 11. 生成诊断报告
log_info "11. 生成诊断报告..."

REPORT_FILE="/tmp/frontend-build-diagnosis-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "前端构建问题诊断报告"
    echo "诊断时间: $(date)"
    echo "=========================================="
    echo ""
    echo "系统信息:"
    uname -a
    echo ""
    echo "Node.js环境:"
    node --version
    npm --version
    echo ""
    echo "前端目录结构:"
    ls -la "$FRONTEND_DIR"
    echo ""
    echo "构建结果:"
    ls -la "$FRONTEND_DIR/dist"
    echo ""
    echo "HTML内容:"
    head -20 "$FRONTEND_DIR/dist/index.html"
    echo ""
    echo "静态资源:"
    ls -la "$FRONTEND_DIR/dist/assets"
    echo ""
    echo "访问测试:"
    curl -s http://$SERVER_IP/ | head -10
    echo ""
} > "$REPORT_FILE"

log_success "诊断报告已生成: $REPORT_FILE"

echo ""
echo "=========================================="
echo "前端构建诊断完成！"
echo "=========================================="
echo ""
echo "访问信息:"
echo "  前端: http://$SERVER_IP"
echo "  默认登录: admin/admin123"
echo ""
echo "如果问题仍然存在，请检查:"
echo "1. 浏览器控制台是否有JavaScript错误"
echo "2. 网络请求是否正常"
echo "3. 静态资源文件是否可访问"
echo "4. 查看诊断报告: cat $REPORT_FILE"
echo ""
