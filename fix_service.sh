#!/bin/bash
# 修复 ipv6-wireguard-manager 服务启动问题

set -e

echo "=========================================="
echo "修复 ipv6-wireguard-manager 服务"
echo "=========================================="
echo ""

INSTALL_DIR="/opt/ipv6-wireguard-manager"

# 1. 检查 backend 目录结构
echo "1. 检查 backend 目录结构..."
if [[ ! -f "$INSTALL_DIR/backend/app/main.py" ]]; then
    echo "✗ backend/app/main.py 不存在！"
    echo "检查 backend 目录内容:"
    ls -la "$INSTALL_DIR/backend/" 2>/dev/null || echo "backend 目录不存在"
    
    echo ""
    echo "请确认以下问题："
    echo "1. 是否正确克隆了代码仓库？"
    echo "2. backend 目录是否存在？"
    echo "3. 是否需要从 Git 重新拉取代码？"
    echo ""
    
    read -p "是否需要从当前目录重新初始化项目？(y/n): " answer
    if [[ "$answer" == "y" ]]; then
        echo "请先确保您在正确的项目目录中，然后手动运行 install.sh"
    fi
    exit 1
else
    echo "✓ backend/app/main.py 存在"
fi

# 2. 检查虚拟环境和依赖
echo ""
echo "2. 检查 Python 虚拟环境..."
if [[ ! -f "$INSTALL_DIR/venv/bin/uvicorn" ]]; then
    echo "✗ uvicorn 不存在，重新安装依赖..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    pip install -r requirements.txt
else
    echo "✓ uvicorn 存在"
fi

# 3. 测试 Python 导入
echo ""
echo "3. 测试 Python 模块导入..."
cd "$INSTALL_DIR"
source venv/bin/activate

# 加载环境变量
if [[ -f "$INSTALL_DIR/.env" ]]; then
    export $(cat "$INSTALL_DIR/.env" | grep -v '^#' | grep -v '^$' | xargs)
fi

# 测试导入
python3 << 'EOF'
import sys
import os

print("Python 路径:", sys.path)
print("当前目录:", os.getcwd())
print("")

try:
    print("测试导入 backend.app.main...")
    from backend.app.main import app
    print("✓ 导入成功")
    print("✓ App 对象:", app)
except ImportError as e:
    print("✗ 导入失败:", e)
    print("\n检查 backend 目录结构:")
    import os
    if os.path.exists('backend'):
        for root, dirs, files in os.walk('backend'):
            level = root.replace('backend', '').count(os.sep)
            indent = ' ' * 2 * level
            print(f'{indent}{os.path.basename(root)}/')
            subindent = ' ' * 2 * (level + 1)
            for file in files[:10]:  # 只显示前10个文件
                print(f'{subindent}{file}')
    sys.exit(1)
except Exception as e:
    print("✗ 其他错误:", e)
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

if [[ $? -ne 0 ]]; then
    echo ""
    echo "Python 导入测试失败！"
    exit 1
fi

# 4. 检查数据库连接
echo ""
echo "4. 检查数据库连接..."
python3 << 'EOF'
import os
from sqlalchemy import create_engine, text

db_url = os.getenv('DATABASE_URL', '')
if not db_url:
    print("✗ DATABASE_URL 未设置")
    exit(1)

# 隐藏密码显示
safe_url = db_url.split('@')[1] if '@' in db_url else db_url
print(f"数据库 URL: ...@{safe_url}")

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✓ 数据库连接成功")
except Exception as e:
    print(f"✗ 数据库连接失败: {e}")
    exit(1)
EOF

if [[ $? -ne 0 ]]; then
    echo ""
    echo "数据库连接测试失败！"
    echo "请检查："
    echo "1. MySQL 服务是否运行: systemctl status mysql"
    echo "2. 数据库配置是否正确: cat $INSTALL_DIR/.env | grep DATABASE"
    exit 1
fi

# 5. 检查端口占用
echo ""
echo "5. 检查端口占用..."
API_PORT=$(grep "^API_PORT=" "$INSTALL_DIR/.env" | cut -d= -f2 | tr -d '"' | tr -d "'" || echo "8000")
if ss -tlnp | grep -q ":$API_PORT "; then
    echo "✗ 端口 $API_PORT 已被占用:"
    ss -tlnp | grep ":$API_PORT "
    echo ""
    echo "请停止占用端口的进程或修改 .env 中的 API_PORT"
    exit 1
else
    echo "✓ 端口 $API_PORT 可用"
fi

# 6. 检查文件权限
echo ""
echo "6. 检查文件权限..."
SERVICE_USER=$(grep "^User=" /etc/systemd/system/ipv6-wireguard-manager.service | cut -d= -f2 || echo "ipv6wgm")
echo "服务运行用户: $SERVICE_USER"

if ! id "$SERVICE_USER" &>/dev/null; then
    echo "✗ 用户 $SERVICE_USER 不存在"
    exit 1
fi

# 修复权限
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
echo "✓ 已设置目录权限为 $SERVICE_USER"

# 7. 手动测试启动
echo ""
echo "7. 手动测试启动 (5秒)..."
cd "$INSTALL_DIR"
sudo -u "$SERVICE_USER" bash << 'EOSU'
source venv/bin/activate
export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
timeout 5 venv/bin/uvicorn backend.app.main:app --host :: --port ${API_PORT:-8000} --log-level debug 2>&1 | head -50
EOSU

echo ""
echo "8. 重启服务..."
systemctl daemon-reload
systemctl restart ipv6-wireguard-manager.service
sleep 3

echo ""
echo "9. 检查服务状态..."
systemctl status ipv6-wireguard-manager.service --no-pager -l

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "如果服务仍然失败，请运行："
echo "  journalctl -u ipv6-wireguard-manager.service -f"
echo ""
echo "查看实时日志以获取更多信息"

