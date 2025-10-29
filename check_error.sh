#!/bin/bash
# 快速诊断脚本

echo "=== 查看详细启动错误 ==="
journalctl -u ipv6-wireguard-manager.service -n 200 --no-pager | grep -A 5 -B 5 -i "error\|exception\|traceback\|failed"

echo ""
echo "=== 检查 backend/app/main.py 是否存在 ==="
ls -la /opt/ipv6-wireguard-manager/backend/app/main.py

echo ""
echo "=== 手动测试启动 ==="
cd /opt/ipv6-wireguard-manager
source venv/bin/activate
export $(cat .env | grep -v '^#' | xargs)
echo "尝试导入主应用..."
python3 -c "from backend.app.main import app; print('✓ 导入成功')" 2>&1

