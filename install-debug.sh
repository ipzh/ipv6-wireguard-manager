#!/bin/bash

# IPv6 WireGuard Manager 调试安装脚本
# 提供详细的调试信息和错误检查

set -e

echo "=================================="
echo "IPv6 WireGuard Manager 调试安装"
echo "=================================="
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"

# 调试信息
debug_info() {
    echo "🔍 调试信息:"
    echo "   当前用户: $(whoami)"
    echo "   当前目录: $(pwd)"
    echo "   系统信息: $(uname -a)"
    echo "   Git版本: $(git --version 2>/dev/null || echo 'Git未安装')"
    echo "   Python版本: $(python3 --version 2>/dev/null || echo 'Python3未安装')"
    echo "   Node版本: $(node --version 2>/dev/null || echo 'Node未安装')"
    echo "   npm版本: $(npm --version 2>/dev/null || echo 'npm未安装')"
    echo ""
}

# 检测服务器IP地址
get_server_ip() {
    echo "🌐 检测服务器IP地址..."
    
    # 检测IPv4地址
    PUBLIC_IPV4=""
    LOCAL_IPV4=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV4=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv4.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    elif command -v hostname >/dev/null 2>&1; then
        LOCAL_IPV4=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 设置IP地址
    if [ -n "$PUBLIC_IPV4" ]; then
        SERVER_IPV4="$PUBLIC_IPV4"
    elif [ -n "$LOCAL_IPV4" ]; then
        SERVER_IPV4="$LOCAL_IPV4"
    else
        SERVER_IPV4="localhost"
    fi
    
    echo "   IPv4: $SERVER_IPV4"
    echo ""
}

# 下载项目
download_project() {
    echo "📥 下载项目..."
    echo "   仓库URL: $REPO_URL"
    echo "   目标目录: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️  删除现有目录..."
        rm -rf "$INSTALL_DIR"
    fi
    
    echo "🔄 开始克隆仓库..."
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        echo "❌ 下载项目失败"
        echo "🔍 可能的原因:"
        echo "   - 网络连接问题"
        echo "   - Git未安装"
        echo "   - 仓库URL错误"
        exit 1
    fi
    
    # 检查下载是否成功
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "❌ 项目目录未创建"
        exit 1
    fi
    
    echo "✅ 项目下载成功"
    echo "📁 项目结构:"
    ls -la "$INSTALL_DIR"
    echo ""
    
    # 检查关键目录是否存在
    if [ ! -d "$INSTALL_DIR/backend" ]; then
        echo "❌ 后端目录不存在"
        echo "📁 项目目录内容:"
        ls -la "$INSTALL_DIR"
        exit 1
    fi
    
    if [ ! -d "$INSTALL_DIR/frontend" ]; then
        echo "❌ 前端目录不存在"
        echo "📁 项目目录内容:"
        ls -la "$INSTALL_DIR"
        exit 1
    fi
    
    echo "✅ 项目结构检查通过"
    echo ""
}

# 检查后端
check_backend() {
    echo "🔍 检查后端目录..."
    
    # 确保在项目根目录
    if [ ! -d "backend" ]; then
        echo "❌ 不在项目根目录，尝试查找项目目录..."
        if [ -d "$INSTALL_DIR" ]; then
            cd "$INSTALL_DIR"
            echo "✅ 切换到项目目录: $(pwd)"
        else
            echo "❌ 找不到项目目录"
            exit 1
        fi
    fi
    
    # 检查后端目录
    if [ ! -d "backend" ]; then
        echo "❌ 后端目录不存在"
        echo "📁 当前目录内容:"
        ls -la
        exit 1
    fi
    
    cd backend
    echo "   当前目录: $(pwd)"
    echo "   目录内容:"
    ls -la
    
    # 检查requirements文件
    if [ -f "requirements.txt" ]; then
        echo "✅ 找到 requirements.txt"
        echo "   文件内容预览:"
        head -10 requirements.txt
    elif [ -f "requirements-compatible.txt" ]; then
        echo "✅ 找到 requirements-compatible.txt"
        echo "   文件内容预览:"
        head -10 requirements-compatible.txt
    else
        echo "❌ 未找到requirements文件"
        exit 1
    fi
    
    echo ""
}

# 检查前端
check_frontend() {
    echo "🔍 检查前端目录..."
    
    # 确保在项目根目录
    if [ ! -d "frontend" ]; then
        echo "❌ 不在项目根目录，尝试查找项目目录..."
        if [ -d "$INSTALL_DIR" ]; then
            cd "$INSTALL_DIR"
            echo "✅ 切换到项目目录: $(pwd)"
        else
            echo "❌ 找不到项目目录"
            exit 1
        fi
    fi
    
    # 检查前端目录
    if [ ! -d "frontend" ]; then
        echo "❌ 前端目录不存在"
        echo "📁 当前目录内容:"
        ls -la
        exit 1
    fi
    
    cd frontend
    echo "   当前目录: $(pwd)"
    echo "   目录内容:"
    ls -la
    
    # 检查package.json
    if [ -f "package.json" ]; then
        echo "✅ 找到 package.json"
        echo "   文件内容预览:"
        head -20 package.json
    else
        echo "❌ 未找到package.json文件"
        exit 1
    fi
    
    echo ""
}

# 主函数
main() {
    # 显示调试信息
    debug_info
    
    # 检测IP地址
    get_server_ip
    
    # 下载项目
    download_project
    
    # 检查后端
    check_backend
    
    # 检查前端
    check_frontend
    
    echo "🎉 调试检查完成！"
    echo ""
    echo "如果所有检查都通过，可以运行完整的安装脚本："
    echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-vps-quick.sh | bash"
    echo ""
}

# 运行主函数
main "$@"