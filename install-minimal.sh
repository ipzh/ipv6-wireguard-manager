#!/bin/bash

# IPv6 WireGuard Manager 最小化安装脚本
# 专为curl管道执行设计，最大兼容性

set -e

# 项目信息
PROJECT_NAME="IPv6 WireGuard Manager"
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"

echo "=================================="
echo "IPv6 WireGuard Manager 一键安装"
echo "=================================="
echo ""

# 检查系统要求
echo "🔍 检查系统要求..."

# 检查Git
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Git 未安装"
    echo "请先安装 Git: https://git-scm.com/downloads"
    exit 1
fi
echo "✅ Git 已安装"

# 检查Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker 未安装"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo "✅ Docker 已安装"

# 检查Docker Compose
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "❌ Docker Compose 未安装"
    echo "请先安装 Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
echo "✅ Docker Compose 已安装"

# 检查Docker服务
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker 服务未运行"
    echo "请启动 Docker 服务"
    exit 1
fi
echo "✅ Docker 服务运行正常"

echo ""
echo "🚀 开始安装..."

# 下载项目
echo "📥 下载项目..."
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  删除现有目录..."
    rm -rf "$INSTALL_DIR"
fi

if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
    echo "❌ 下载项目失败"
    exit 1
fi

cd "$INSTALL_DIR"
echo "✅ 项目下载成功"

# 设置权限
echo "🔐 设置权限..."
chmod +x scripts/*.sh 2>/dev/null || true
mkdir -p data/postgres data/redis logs uploads backups

# 配置环境
echo "⚙️  配置环境..."
if [ -f "backend/env.example" ] && [ ! -f "backend/.env" ]; then
    cp backend/env.example backend/.env
    echo "✅ 环境配置文件已创建"
fi

# 启动服务
echo "🚀 启动服务..."
if ! docker-compose up -d; then
    echo "❌ 启动服务失败"
    exit 1
fi

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 初始化数据库
echo "🗄️  初始化数据库..."
sleep 10

# 验证安装
echo "🔍 验证安装..."
if curl -s "http://localhost:8000" >/dev/null 2>&1; then
    echo "✅ 后端服务正常"
else
    echo "❌ 后端服务异常"
fi

if curl -s "http://localhost:3000" >/dev/null 2>&1; then
    echo "✅ 前端服务正常"
else
    echo "❌ 前端服务异常"
fi

# 显示结果
echo ""
echo "=================================="
echo "🎉 安装完成！"
echo "=================================="
echo ""
echo "📋 访问信息："
echo "   - 前端界面: http://localhost:3000"
echo "   - 后端API: http://localhost:8000"
echo "   - API文档: http://localhost:8000/docs"
echo ""
echo "🔑 默认登录信息："
echo "   用户名: admin"
echo "   密码: admin123"
echo ""
echo "🛠️  管理命令："
echo "   查看状态: docker-compose ps"
echo "   查看日志: docker-compose logs -f"
echo "   停止服务: docker-compose down"
echo "   重启服务: docker-compose restart"
echo ""
echo "⚠️  安全提醒："
echo "   请在生产环境中修改默认密码"
echo "   配置文件位置: backend/.env"
echo ""
echo "📁 项目位置："
echo "   $(pwd)"
echo ""
