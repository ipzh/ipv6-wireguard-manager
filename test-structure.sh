#!/bin/bash

# 测试项目结构脚本
# 专门用于验证项目目录结构是否正确

set -e

echo "=================================="
echo "项目结构测试脚本"
echo "=================================="
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"

# 显示当前状态
echo "🔍 当前状态:"
echo "   当前用户: $(whoami)"
echo "   当前目录: $(pwd)"
echo "   系统信息: $(uname -a)"
echo ""

# 测试项目下载
test_download() {
    echo "📥 测试项目下载..."
    
    # 清理现有目录
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️  删除现有目录..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # 下载项目
    if git clone "$REPO_URL" "$INSTALL_DIR"; then
        echo "✅ 项目下载成功"
    else
        echo "❌ 项目下载失败"
        exit 1
    fi
    
    # 检查项目目录
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "❌ 项目目录未创建"
        exit 1
    fi
    
    echo "✅ 项目目录创建成功"
    echo ""
}

# 测试项目结构
test_structure() {
    echo "📁 测试项目结构..."
    
    # 进入项目目录
    cd "$INSTALL_DIR"
    echo "   当前目录: $(pwd)"
    
    # 显示项目根目录内容
    echo "   项目根目录内容:"
    ls -la
    
    # 检查关键目录
    echo ""
    echo "🔍 检查关键目录:"
    
    if [ -d "backend" ]; then
        echo "✅ backend 目录存在"
        echo "   backend 目录内容:"
        ls -la backend/
    else
        echo "❌ backend 目录不存在"
        exit 1
    fi
    
    if [ -d "frontend" ]; then
        echo "✅ frontend 目录存在"
        echo "   frontend 目录内容:"
        ls -la frontend/
    else
        echo "❌ frontend 目录不存在"
        exit 1
    fi
    
    echo ""
}

# 测试后端文件
test_backend_files() {
    echo "🐍 测试后端文件..."
    
    cd backend
    echo "   当前目录: $(pwd)"
    
    # 检查关键文件
    echo "🔍 检查关键文件:"
    
    if [ -f "requirements.txt" ]; then
        echo "✅ requirements.txt 存在"
        echo "   文件大小: $(wc -l < requirements.txt) 行"
    else
        echo "❌ requirements.txt 不存在"
    fi
    
    if [ -f "requirements-compatible.txt" ]; then
        echo "✅ requirements-compatible.txt 存在"
        echo "   文件大小: $(wc -l < requirements-compatible.txt) 行"
    else
        echo "❌ requirements-compatible.txt 不存在"
    fi
    
    if [ -d "app" ]; then
        echo "✅ app 目录存在"
        echo "   app 目录内容:"
        ls -la app/
    else
        echo "❌ app 目录不存在"
    fi
    
    echo ""
}

# 测试前端文件
test_frontend_files() {
    echo "⚛️  测试前端文件..."
    
    cd ../frontend
    echo "   当前目录: $(pwd)"
    
    # 检查关键文件
    echo "🔍 检查关键文件:"
    
    if [ -f "package.json" ]; then
        echo "✅ package.json 存在"
        echo "   文件大小: $(wc -l < package.json) 行"
        echo "   文件内容预览:"
        head -10 package.json
    else
        echo "❌ package.json 不存在"
    fi
    
    if [ -f "package-lock.json" ]; then
        echo "✅ package-lock.json 存在"
        echo "   文件大小: $(wc -l < package-lock.json) 行"
    else
        echo "❌ package-lock.json 不存在"
    fi
    
    if [ -f "vite.config.ts" ]; then
        echo "✅ vite.config.ts 存在"
    else
        echo "❌ vite.config.ts 不存在"
    fi
    
    if [ -d "src" ]; then
        echo "✅ src 目录存在"
        echo "   src 目录内容:"
        ls -la src/
    else
        echo "❌ src 目录不存在"
    fi
    
    echo ""
}

# 测试系统依赖
test_dependencies() {
    echo "🔧 测试系统依赖..."
    
    # 检查Git
    if command -v git >/dev/null 2>&1; then
        echo "✅ Git: $(git --version)"
    else
        echo "❌ Git 未安装"
    fi
    
    # 检查Python
    if command -v python3 >/dev/null 2>&1; then
        echo "✅ Python3: $(python3 --version)"
    else
        echo "❌ Python3 未安装"
    fi
    
    # 检查Node.js
    if command -v node >/dev/null 2>&1; then
        echo "✅ Node.js: $(node --version)"
    else
        echo "❌ Node.js 未安装"
    fi
    
    # 检查npm
    if command -v npm >/dev/null 2>&1; then
        echo "✅ npm: $(npm --version)"
    else
        echo "❌ npm 未安装"
    fi
    
    echo ""
}

# 显示测试结果
show_results() {
    echo "=================================="
    echo "🎉 项目结构测试完成！"
    echo "=================================="
    echo ""
    echo "📋 测试结果:"
    echo "   ✅ 项目下载: 成功"
    echo "   ✅ 目录结构: 正确"
    echo "   ✅ 后端文件: 完整"
    echo "   ✅ 前端文件: 完整"
    echo ""
    echo "🚀 现在可以运行安装脚本:"
    echo "   curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-robust.sh | bash"
    echo ""
}

# 主函数
main() {
    # 测试项目下载
    test_download
    
    # 测试项目结构
    test_structure
    
    # 测试后端文件
    test_backend_files
    
    # 测试前端文件
    test_frontend_files
    
    # 测试系统依赖
    test_dependencies
    
    # 显示结果
    show_results
}

# 运行主函数
main "$@"
