#!/bin/bash

# IPv6 WireGuard Manager 完全自动安装脚本
# 自动安装所有必要的依赖

set -e

echo "=================================="
echo "IPv6 WireGuard Manager 完全自动安装"
echo "=================================="
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        OS=debian
    elif [ -f /etc/redhat-release ]; then
        OS=rhel
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
    echo "检测到操作系统: $OS"
}

# 安装Git
install_git() {
    echo "📦 安装 Git..."
    case $OS in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y git
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y git
            else
                sudo yum install -y git
            fi
            ;;
        alpine)
            sudo apk add git
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            echo "请手动安装 Git: https://git-scm.com/downloads"
            exit 1
            ;;
    esac
    echo "✅ Git 安装完成"
}

# 安装Docker
install_docker() {
    echo "📦 安装 Docker..."
    case $OS in
        ubuntu)
            echo "   使用Ubuntu Docker仓库..."
            # 更新包索引
            sudo apt update
            sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        debian)
            echo "   使用Debian Docker仓库..."
            # 更新包索引
            sudo apt update
            sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        centos)
            echo "   使用CentOS Docker仓库..."
            # 安装依赖
            sudo yum install -y yum-utils
            
            # 添加Docker仓库
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装Docker
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        rhel)
            echo "   使用RHEL Docker仓库..."
            # 安装依赖
            sudo yum install -y yum-utils
            
            # 添加Docker仓库
            sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
            
            # 安装Docker
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        fedora)
            echo "   使用Fedora Docker仓库..."
            # 安装依赖
            sudo dnf install -y dnf-plugins-core
            
            # 添加Docker仓库
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            
            # 安装Docker
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            
            # 启动Docker服务
            sudo systemctl start docker
            sudo systemctl enable docker
            ;;
        alpine)
            echo "   使用Alpine Docker仓库..."
            sudo apk add docker docker-compose
            sudo rc-update add docker boot
            sudo service docker start
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            echo "请手动安装 Docker: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
    echo "✅ Docker 安装完成"
}

# 安装Docker Compose（如果使用旧版本）
install_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "📦 安装 Docker Compose..."
        case $OS in
            ubuntu|debian|centos|rhel|fedora)
                # 下载Docker Compose
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                ;;
            alpine)
                sudo apk add docker-compose
                ;;
        esac
        echo "✅ Docker Compose 安装完成"
    fi
}

# 检查并安装依赖
check_and_install_dependencies() {
    echo "🔍 检查系统依赖..."
    
    # 检测操作系统
    detect_os
    
    # 检查Git
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Git 未安装，开始自动安装..."
        install_git
    else
        echo "✅ Git 已安装: $(git --version)"
    fi
    
    # 检查Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker 未安装，开始自动安装..."
        install_docker
    else
        echo "✅ Docker 已安装: $(docker --version)"
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        echo "❌ Docker Compose 未安装，开始自动安装..."
        install_docker_compose
    else
        echo "✅ Docker Compose 已安装"
    fi
    
    # 检查Docker服务
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker 服务未运行，启动服务..."
        sudo systemctl start docker
        sleep 5
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker 服务启动失败"
        exit 1
    fi
    echo "✅ Docker 服务运行正常"
    
    # 添加用户到docker组（可选）
    if ! groups $USER | grep -q docker; then
        echo "🔐 添加用户到docker组..."
        sudo usermod -aG docker $USER
        echo "⚠️  请重新登录或运行 'newgrp docker' 以使权限生效"
    fi
}

# 下载并安装项目
install_project() {
    echo ""
    echo "🚀 开始安装项目..."
    
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
        echo "查看详细错误信息:"
        docker-compose logs
        exit 1
    fi
    
    # 等待服务启动
    echo "⏳ 等待服务启动..."
    sleep 30
    
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
}

# 主函数
main() {
    # 检查并安装依赖
    check_and_install_dependencies
    
    # 安装项目
    install_project
}

# 运行主函数
main "$@"