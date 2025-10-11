#!/bin/bash

# IPv6 WireGuard Manager - 低内存系统安装脚本
# 专为1GB内存系统优化

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="IPv6 WireGuard Manager"
PROJECT_VERSION="3.0.0"
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}"
    echo "=========================================="
    echo "  $PROJECT_NAME v$PROJECT_VERSION"
    echo "  低内存系统优化安装器"
    echo "=========================================="
    echo -e "${NC}"
    echo "🎯 专为1GB内存系统优化"
    echo "⚡ 预计安装时间: 20-50分钟"
    echo "💾 内存使用优化: 最小化资源占用"
    echo ""
}

# 系统检测
detect_system() {
    log_step "检测系统环境..."
    
    # 检测系统资源
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    AVAIL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    CPU_CORES=$(nproc)
    
    echo "🖥️  系统信息:"
    echo "   总内存: ${TOTAL_MEM}MB"
    echo "   可用内存: ${AVAIL_MEM}MB"
    echo "   CPU核心数: $CPU_CORES"
    
    # 内存警告
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        log_warning "⚠️  内存不足1GB，安装可能很慢或失败"
        echo "   建议: 增加swap空间或升级内存"
    elif [ "$TOTAL_MEM" -lt 2048 ]; then
        log_warning "⚠️  内存较少，将使用低内存优化策略"
    else
        log_success "✅ 内存充足"
    fi
    
    echo ""
}

# 优化系统设置
optimize_system() {
    log_step "优化系统设置..."
    
    # 增加swap空间
    if [ ! -f /swapfile ]; then
        log_info "创建2GB swap文件..."
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        log_success "Swap文件创建完成"
    else
        log_info "Swap文件已存在"
    fi
    
    # 优化系统参数
    log_info "优化系统参数..."
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    
    # 清理系统缓存
    log_info "清理系统缓存..."
    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    echo ""
}

# 下载项目
download_project() {
    log_step "下载项目..."
    
    if [ -d "ipv6-wireguard-manager" ]; then
        log_info "项目目录已存在，使用现有目录"
        cd ipv6-wireguard-manager || exit 1
    else
        log_info "从 GitHub 下载项目..."
        if git clone "$REPO_URL" ipv6-wireguard-manager; then
            log_success "项目下载成功"
            cd ipv6-wireguard-manager || exit 1
        else
            log_error "项目下载失败"
            exit 1
        fi
    fi
    
    log_info "进入项目目录: $(pwd)"
    echo ""
}

# 安装后端
install_backend() {
    log_step "安装后端 (预计5-10分钟)..."
    
    cd backend || exit 1
    
    # 使用兼容性更好的依赖文件
    if [ -f "requirements-compatible.txt" ]; then
        log_info "使用兼容性依赖文件..."
        pip install -r requirements-compatible.txt --no-cache-dir
    else
        log_info "使用标准依赖文件..."
        pip install -r requirements.txt --no-cache-dir
    fi
    
    # 创建环境配置
    if [ ! -f ".env" ]; then
        log_info "创建环境配置文件..."
        cp env.example .env
    fi
    
    cd ..
    log_success "后端安装完成"
    echo ""
}

# 安装前端（低内存优化）
install_frontend() {
    log_step "安装前端 (预计15-30分钟)..."
    
    cd frontend || exit 1
    
    # 设置Node.js内存限制
    export NODE_OPTIONS="--max-old-space-size=512"
    
    log_info "安装前端依赖 (内存限制: 512MB)..."
    npm install --silent --no-optional --no-audit --no-fund
    
    log_info "开始前端构建 (低内存模式)..."
    
    # 使用最小化构建配置
    cat > vite.config.low-memory.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
    sourcemap: false,
    minify: false,
    chunkSizeWarningLimit: 1000,
  },
  optimizeDeps: {
    disabled: true,
  },
})
EOF
    
    # 尝试构建
    if NODE_OPTIONS="--max-old-space-size=512" npx vite build --config vite.config.low-memory.js; then
        log_success "前端构建成功"
    else
        log_error "前端构建失败，尝试更激进的优化..."
        
        # 超简化构建
        cat > vite.config.ultra-minimal.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
    sourcemap: false,
    minify: false,
  },
  optimizeDeps: {
    disabled: true,
  },
})
EOF
        
        if NODE_OPTIONS="--max-old-space-size=256" npx vite build --config vite.config.ultra-minimal.js; then
            log_success "前端构建成功 (超简化模式)"
        else
            log_error "前端构建失败"
            exit 1
        fi
    fi
    
    # 清理临时文件
    rm -f vite.config.low-memory.js vite.config.ultra-minimal.js
    
    cd ..
    log_success "前端安装完成"
    echo ""
}

# 配置服务
configure_services() {
    log_step "配置系统服务..."
    
    # 创建后端服务
    sudo tee /etc/systemd/system/ipv6-wireguard-backend.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)/backend
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # 创建前端服务
    sudo tee /etc/systemd/system/ipv6-wireguard-frontend.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager Frontend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)/frontend
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/python3 -m http.server 3000 --directory dist
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd
    sudo systemctl daemon-reload
    
    log_success "服务配置完成"
    echo ""
}

# 启动服务
start_services() {
    log_step "启动服务..."
    
    # 启动后端
    sudo systemctl enable ipv6-wireguard-backend
    sudo systemctl start ipv6-wireguard-backend
    
    # 等待后端启动
    sleep 10
    
    # 启动前端
    sudo systemctl enable ipv6-wireguard-frontend
    sudo systemctl start ipv6-wireguard-frontend
    
    log_success "服务启动完成"
    echo ""
}

# 验证安装
verify_installation() {
    log_step "验证安装..."
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-backend; then
        log_success "后端服务运行正常"
    else
        log_warning "后端服务可能未正常启动"
    fi
    
    if systemctl is-active --quiet ipv6-wireguard-frontend; then
        log_success "前端服务运行正常"
    else
        log_warning "前端服务可能未正常启动"
    fi
    
    # 获取访问地址
    get_access_urls
}

# 获取访问地址
get_access_urls() {
    log_step "获取访问地址..."
    
    # 获取IP地址
    PUBLIC_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || echo "localhost")
    LOCAL_IPV4=$(ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null || echo "localhost")
    
    echo ""
    echo -e "${GREEN}🎉 低内存安装完成！${NC}"
    echo ""
    echo "🌐 访问地址:"
    echo "   前端界面: http://$PUBLIC_IPV4:3000"
    echo "   本地访问: http://$LOCAL_IPV4:3000"
    echo ""
    echo "🔧 管理命令:"
    echo "   查看后端日志: journalctl -u ipv6-wireguard-backend -f"
    echo "   查看前端日志: journalctl -u ipv6-wireguard-frontend -f"
    echo "   重启服务: systemctl restart ipv6-wireguard-backend ipv6-wireguard-frontend"
    echo ""
    echo "💡 低内存优化提示:"
    echo "   - 已创建2GB swap文件"
    echo "   - 使用最小化构建配置"
    echo "   - 禁用不必要的优化"
    echo ""
}

# 主函数
main() {
    show_welcome
    detect_system
    optimize_system
    download_project
    install_backend
    install_frontend
    configure_services
    start_services
    verify_installation
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查日志"; exit 1' ERR

# 执行主函数
main "$@"
