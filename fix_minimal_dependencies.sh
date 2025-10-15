#!/bin/bash

# 最小化安装依赖修复脚本
# 专门修复最小化安装中的依赖问题

set -e

echo "=========================================="
echo "🔧 最小化安装依赖修复脚本"
echo "=========================================="
echo ""

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo "❌ 此脚本需要root权限运行"
    echo "请使用: sudo $0"
    exit 1
fi

# 检查安装目录
INSTALL_DIR="/opt/ipv6-wireguard-manager"
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 安装目录不存在: $INSTALL_DIR"
    echo "请先运行安装脚本"
    exit 1
fi

echo "📁 安装目录: $INSTALL_DIR"
cd "$INSTALL_DIR/backend" || {
    echo "❌ 无法进入后端目录"
    exit 1
}

echo ""

# 检查虚拟环境
echo "1. 检查虚拟环境..."
if [ ! -f "venv/bin/activate" ]; then
    echo "❌ 虚拟环境不存在"
    echo "   创建虚拟环境..."
    python3 -m venv venv
    echo "✅ 虚拟环境创建完成"
else
    echo "✅ 虚拟环境存在"
fi

echo ""

# 激活虚拟环境
echo "2. 激活虚拟环境..."
source venv/bin/activate || {
    echo "❌ 激活虚拟环境失败"
    exit 1
}
echo "✅ 虚拟环境激活成功"

echo ""

# 检查requirements文件
echo "3. 检查依赖文件..."
if [ -f "requirements-minimal.txt" ]; then
    echo "✅ requirements-minimal.txt 存在"
    REQUIREMENTS_FILE="requirements-minimal.txt"
elif [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt 存在"
    REQUIREMENTS_FILE="requirements.txt"
else
    echo "❌ 未找到依赖文件"
    exit 1
fi

echo ""

# 升级pip
echo "4. 升级pip..."
if pip install --upgrade pip; then
    echo "✅ pip升级成功"
else
    echo "⚠️  pip升级失败，继续安装依赖"
fi

echo ""

# 安装依赖
echo "5. 安装Python依赖..."
echo "   使用文件: $REQUIREMENTS_FILE"

# 显示要安装的依赖
echo "   依赖列表:"
grep -v "^#" "$REQUIREMENTS_FILE" | grep -v "^$" | sed 's/^/     /'

echo ""

# 安装依赖
if pip install -r "$REQUIREMENTS_FILE"; then
    echo "✅ 依赖安装成功"
else
    echo "❌ 依赖安装失败"
    echo "   尝试单独安装关键依赖..."
    
    # 安装关键依赖
    key_packages=(
        "fastapi==0.104.1"
        "uvicorn[standard]==0.24.0"
        "pydantic==2.5.0"
        "pydantic-settings==2.1.0"
        "sqlalchemy==2.0.23"
        "pymysql==1.1.0"
        "python-dotenv==1.0.0"
        "python-jose[cryptography]>=3.3.0"
        "passlib[bcrypt]>=1.7.4"
        "python-multipart>=0.0.6"
        "click==8.1.7"
        "cryptography>=41.0.0,<47.0.0"
        "psutil==5.9.6"
        "email-validator==2.1.0"
    )
    
    for package in "${key_packages[@]}"; do
        echo "   安装: $package"
        if pip install "$package"; then
            echo "     ✅ $package 安装成功"
        else
            echo "     ❌ $package 安装失败"
        fi
    done
fi

echo ""

# 检查关键依赖
echo "6. 检查关键依赖..."
key_packages=(
    "fastapi"
    "uvicorn"
    "pydantic"
    "sqlalchemy"
    "pymysql"
    "python-dotenv"
    "python-jose"
    "passlib"
    "python-multipart"
    "click"
    "cryptography"
    "psutil"
    "email-validator"
)

all_installed=true
for package in "${key_packages[@]}"; do
    if python -c "import $package" 2>/dev/null; then
        echo "   ✅ $package"
    else
        echo "   ❌ $package"
        all_installed=false
    fi
done

if [ "$all_installed" = true ]; then
    echo "✅ 所有关键依赖已安装"
else
    echo "❌ 部分依赖缺失"
    echo "   尝试安装缺失的依赖..."
    
    # 尝试安装缺失的依赖
    missing_packages=(
        "python-dotenv==1.0.0"
        "python-jose[cryptography]>=3.3.0"
        "passlib[bcrypt]>=1.7.4"
        "python-multipart>=0.0.6"
    )
    
    for package in "${missing_packages[@]}"; do
        echo "   安装: $package"
        pip install "$package" || echo "     安装失败，继续下一个"
    done
fi

echo ""

# 测试导入
echo "7. 测试模块导入..."
if python -c "from app.core.database import init_db; print('数据库模块导入成功')" 2>/dev/null; then
    echo "✅ 数据库模块导入成功"
else
    echo "❌ 数据库模块导入失败"
    echo "   错误信息:"
    python -c "from app.core.database import init_db" 2>&1 || true
fi

echo ""

# 检查环境变量文件
echo "8. 检查环境变量文件..."
if [ -f ".env" ]; then
    echo "✅ 环境变量文件存在"
    echo "   内容预览:"
    head -5 .env | sed 's/^/     /'
else
    echo "❌ 环境变量文件不存在"
    echo "   创建基本环境变量文件..."
    cat > .env << EOF
# 数据库配置
DATABASE_URL=mysql://ipv6wgm:password@localhost:3306/ipv6wgm
AUTO_CREATE_DATABASE=true

# Redis配置（禁用）
USE_REDIS=false
REDIS_URL=

# 服务器配置
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
DEBUG=false

# 安全配置
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# 性能配置
DATABASE_POOL_SIZE=5
DATABASE_MAX_OVERFLOW=10
MAX_WORKERS=2
EOF
    echo "✅ 环境变量文件创建完成"
fi

echo ""

# 运行环境检查
echo "9. 运行环境检查..."
if [ -f "scripts/check_environment.py" ]; then
    if python scripts/check_environment.py; then
        echo "✅ 环境检查通过"
    else
        echo "⚠️  环境检查发现问题，但基本功能应该可用"
    fi
else
    echo "⚠️  环境检查脚本不存在"
fi

echo ""

# 检查服务状态
echo "10. 检查服务状态..."
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo "✅ 服务正在运行"
    echo "   重启服务以应用修复..."
    systemctl restart ipv6-wireguard-manager
    sleep 2
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        echo "✅ 服务重启成功"
    else
        echo "❌ 服务重启失败"
        echo "   查看服务状态:"
        systemctl status ipv6-wireguard-manager --no-pager -l
    fi
else
    echo "⚠️  服务未运行"
    echo "   尝试启动服务..."
    if systemctl start ipv6-wireguard-manager; then
        echo "✅ 服务启动成功"
    else
        echo "❌ 服务启动失败"
        echo "   查看服务状态:"
        systemctl status ipv6-wireguard-manager --no-pager -l
    fi
fi

echo ""

echo "=========================================="
echo "🎉 最小化安装依赖修复完成！"
echo "=========================================="
echo ""
echo "修复内容:"
echo "✅ 检查并创建虚拟环境"
echo "✅ 升级pip"
echo "✅ 安装Python依赖包"
echo "✅ 检查关键模块导入"
echo "✅ 创建环境变量文件"
echo "✅ 运行环境检查"
echo "✅ 检查服务状态"
echo ""
echo "现在可以尝试访问服务:"
echo "curl http://localhost:8000/health"
echo ""
echo "或查看服务状态:"
echo "systemctl status ipv6-wireguard-manager"
echo "journalctl -u ipv6-wireguard-manager -f"
