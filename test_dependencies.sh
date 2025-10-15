#!/bin/bash

# 依赖测试脚本
# 验证依赖是否真的安装了

set -e

echo "=========================================="
echo "🧪 依赖测试脚本"
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
    exit 1
fi
echo "✅ 虚拟环境存在"

echo ""

# 激活虚拟环境
echo "2. 激活虚拟环境..."
source venv/bin/activate || {
    echo "❌ 激活虚拟环境失败"
    exit 1
}
echo "✅ 虚拟环境激活成功"

echo ""

# 测试依赖导入
echo "3. 测试依赖导入..."
echo "   测试 python-dotenv (dotenv)..."
if python -c "import dotenv; print('✅ dotenv 导入成功')" 2>/dev/null; then
    echo "✅ python-dotenv 可用"
else
    echo "❌ python-dotenv 不可用"
    echo "   尝试安装..."
    if pip install python-dotenv==1.0.0; then
        echo "✅ python-dotenv 安装成功"
    else
        echo "❌ python-dotenv 安装失败"
    fi
fi

echo ""

# 测试其他关键依赖
echo "4. 测试其他关键依赖..."
key_packages=(
    "fastapi:fastapi"
    "uvicorn:uvicorn"
    "pydantic:pydantic"
    "sqlalchemy:sqlalchemy"
    "pymysql:pymysql"
    "python-jose:jose"
    "passlib:passlib"
    "python-multipart:multipart"
    "click:click"
    "cryptography:cryptography"
    "psutil:psutil"
    "email-validator:email_validator"
)

all_available=true
for package_info in "${key_packages[@]}"; do
    package_name=$(echo "$package_info" | cut -d':' -f1)
    import_name=$(echo "$package_info" | cut -d':' -f2)
    
    if python -c "import $import_name" 2>/dev/null; then
        echo "   ✅ $package_name"
    else
        echo "   ❌ $package_name"
        all_available=false
    fi
done

if [ "$all_available" = true ]; then
    echo "✅ 所有关键依赖都可用"
else
    echo "❌ 部分依赖不可用"
fi

echo ""

# 测试环境检查脚本
echo "5. 测试环境检查脚本..."
if [ -f "scripts/check_environment.py" ]; then
    echo "   运行环境检查脚本..."
    if python scripts/check_environment.py; then
        echo "✅ 环境检查通过"
    else
        echo "❌ 环境检查失败"
    fi
else
    echo "❌ 环境检查脚本不存在"
fi

echo ""

# 检查pip包列表
echo "6. 检查已安装的包..."
echo "   已安装的包列表:"
pip list | grep -E "(fastapi|uvicorn|pydantic|sqlalchemy|pymysql|python-dotenv|python-jose|passlib|python-multipart|click|cryptography|psutil|email-validator)" | sed 's/^/     /'

echo ""

# 测试应用导入
echo "7. 测试应用导入..."
if python -c "from app.core.database import init_db; print('✅ 数据库模块导入成功')" 2>/dev/null; then
    echo "✅ 应用模块导入成功"
else
    echo "❌ 应用模块导入失败"
    echo "   错误信息:"
    python -c "from app.core.database import init_db" 2>&1 || true
fi

echo ""

echo "=========================================="
echo "🎉 依赖测试完成！"
echo "=========================================="
echo ""
echo "如果发现问题，可以运行以下命令修复:"
echo "cd /opt/ipv6-wireguard-manager/backend"
echo "source venv/bin/activate"
echo "pip install -r requirements-minimal.txt"
echo ""
echo "或者运行快速修复脚本:"
echo "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/quick_fix_dependencies.sh | bash"
