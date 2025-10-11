#!/bin/bash

# 修复Python依赖问题

echo "🔧 修复Python依赖问题..."
echo ""

# 检查Python版本
echo "🐍 检查Python版本..."
python3 --version

# 检查pip版本
echo "📦 检查pip版本..."
pip3 --version

# 升级pip
echo "⬆️  升级pip..."
pip3 install --upgrade pip

# 安装构建依赖
echo "🔨 安装构建依赖..."
case $(uname -s) in
    Linux)
        if command -v apt >/dev/null 2>&1; then
            sudo apt update
            sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y gcc openssl-devel libffi-devel python3-devel
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y gcc openssl-devel libffi-devel python3-devel
        fi
        ;;
    Darwin)
        if command -v brew >/dev/null 2>&1; then
            brew install openssl libffi
        fi
        ;;
esac

# 清理pip缓存
echo "🧹 清理pip缓存..."
pip3 cache purge

# 尝试安装兼容版本的cryptography
echo "🔐 安装兼容版本的cryptography..."
pip3 install --upgrade cryptography

# 如果还是失败，尝试安装预编译版本
if [ $? -ne 0 ]; then
    echo "⚠️  尝试安装预编译版本..."
    pip3 install --only-binary=all cryptography
fi

# 安装其他可能有问题的依赖
echo "📚 安装其他依赖..."
pip3 install --upgrade setuptools wheel

# 尝试安装requirements
echo "📋 安装项目依赖..."
if [ -f "backend/requirements-compatible.txt" ]; then
    pip3 install -r backend/requirements-compatible.txt
elif [ -f "backend/requirements.txt" ]; then
    pip3 install -r backend/requirements.txt
else
    echo "❌ 未找到requirements文件"
    exit 1
fi

echo ""
echo "✅ 依赖修复完成！"
echo ""
echo "如果仍有问题，请尝试："
echo "1. 使用虚拟环境: python3 -m venv venv && source venv/bin/activate"
echo "2. 升级Python到3.9+版本"
echo "3. 使用conda环境: conda create -n ipv6wgm python=3.11"
echo ""
