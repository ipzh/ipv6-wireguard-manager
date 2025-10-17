#!/bin/bash
# 远程服务器一键修复脚本
# 修复导入路径问题并重启服务

set -e  # 遇到错误立即退出

echo "🔧 开始远程服务器一键修复..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/opt/ipv6-wireguard-manager"
FRONTEND_DIR="/var/www/html"
BACKEND_DIR="$PROJECT_DIR/backend"

# 检查项目目录是否存在
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ 项目目录不存在: $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}📁 项目目录: $PROJECT_DIR${NC}"

# 进入项目目录
cd "$PROJECT_DIR"

# 1. 备份当前代码
echo -e "${YELLOW}📦 备份当前代码...${NC}"
if [ -d "backup_$(date +%Y%m%d_%H%M%S)" ]; then
    rm -rf "backup_$(date +%Y%m%d_%H%M%S)"
fi
cp -r backend "backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✅ 代码备份完成${NC}"

# 2. 修复导入路径
echo -e "${YELLOW}🔧 修复导入路径...${NC}"

# 修复 endpoints 目录中的导入
find "$BACKEND_DIR/app/api/api_v1/endpoints" -name "*.py" -type f | while read file; do
    if [ -f "$file" ]; then
        echo "修复文件: $file"
        sed -i 's/from app\.core\.database import get_db/from ....core.database import get_db/g' "$file"
        sed -i 's/from app\.core\.security_enhanced import security_manager/from ....core.security_enhanced import security_manager/g' "$file"
        sed -i 's/from app\.models\.models_complete import/from ....models.models_complete import/g' "$file"
        sed -i 's/from app\.schemas\.common import/from ....schemas.common import/g' "$file"
        sed -i 's/from app\.schemas\.bgp import/from ....schemas.bgp import/g' "$file"
        sed -i 's/from app\.schemas\.ipv6 import/from ....schemas.ipv6 import/g' "$file"
        sed -i 's/from app\.schemas\.network import/from ....schemas.network import/g' "$file"
        sed -i 's/from app\.schemas\.status import/from ....schemas.status import/g' "$file"
        sed -i 's/from app\.services\.ipv6_service import/from ....services.ipv6_service import/g' "$file"
        sed -i 's/from app\.services\.status_service import/from ....services.status_service import/g' "$file"
    fi
done

# 修复 api_v1 目录中的导入
if [ -f "$BACKEND_DIR/app/api/api_v1/auth.py" ]; then
    echo "修复文件: $BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.core\.database import get_db/from ...core.database import get_db/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.core\.config_enhanced import settings/from ...core.config_enhanced import settings/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.core\.security_enhanced import/from ...core.security_enhanced import/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.models\.models_complete import/from ...models.models_complete import/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.schemas\.auth import/from ...schemas.auth import/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.schemas\.user import/from ...schemas.user import/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.services\.user_service import/from ...services.user_service import/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
    sed -i 's/from app\.utils\.rate_limit import/from ...utils.rate_limit import/g' "$BACKEND_DIR/app/api/api_v1/auth.py"
fi

# 修复 core 目录中的导入
if [ -f "$BACKEND_DIR/app/core/security_enhanced.py" ]; then
    echo "修复文件: $BACKEND_DIR/app/core/security_enhanced.py"
    sed -i 's/from app\.core\.config_enhanced import settings/from .config_enhanced import settings/g' "$BACKEND_DIR/app/core/security_enhanced.py"
    sed -i 's/from app\.models\.models_complete import/from ..models.models_complete import/g' "$BACKEND_DIR/app/core/security_enhanced.py"
fi

# 修复 services 目录中的导入
if [ -f "$BACKEND_DIR/app/services/user_service.py" ]; then
    echo "修复文件: $BACKEND_DIR/app/services/user_service.py"
    sed -i 's/from app\.models\.models_complete import/from ..models.models_complete import/g' "$BACKEND_DIR/app/services/user_service.py"
    sed -i 's/from app\.schemas\.user import/from ..schemas.user import/g' "$BACKEND_DIR/app/services/user_service.py"
    sed -i 's/from app\.core\.security_enhanced import/from ..core.security_enhanced import/g' "$BACKEND_DIR/app/services/user_service.py"
    sed -i 's/from app\.utils\.audit import/from ..utils.audit import/g' "$BACKEND_DIR/app/services/user_service.py"
fi

# 修复 models 目录中的导入
if [ -f "$BACKEND_DIR/app/models/models_complete.py" ]; then
    echo "修复文件: $BACKEND_DIR/app/models/models_complete.py"
    sed -i 's/from app\.core\.database import Base/from ..core.database import Base/g' "$BACKEND_DIR/app/models/models_complete.py"
fi

# 修复 utils 目录中的导入
if [ -f "$BACKEND_DIR/app/utils/audit.py" ]; then
    echo "修复文件: $BACKEND_DIR/app/utils/audit.py"
    sed -i 's/from app\.models\.models_complete import/from ..models.models_complete import/g' "$BACKEND_DIR/app/utils/audit.py"
fi

echo -e "${GREEN}✅ 导入路径修复完成${NC}"

# 3. 检查Python语法
echo -e "${YELLOW}🔍 检查Python语法...${NC}"
cd "$BACKEND_DIR"
python3 -m py_compile app/main.py
echo -e "${GREEN}✅ Python语法检查通过${NC}"

# 4. 重启服务
echo -e "${YELLOW}🔄 重启服务...${NC}"
sudo systemctl stop ipv6-wireguard-manager || true
sleep 2
sudo systemctl start ipv6-wireguard-manager
sleep 3

# 5. 检查服务状态
echo -e "${YELLOW}📊 检查服务状态...${NC}"
if systemctl is-active --quiet ipv6-wireguard-manager; then
    echo -e "${GREEN}✅ 服务启动成功${NC}"
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    echo -e "${YELLOW}📋 查看服务日志:${NC}"
    sudo journalctl -u ipv6-wireguard-manager --no-pager -n 20
    exit 1
fi

# 6. 测试API端点
echo -e "${YELLOW}🧪 测试API端点...${NC}"
sleep 5

# 测试健康检查端点
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✅ API健康检查通过${NC}"
else
    echo -e "${RED}❌ API健康检查失败${NC}"
    echo -e "${YELLOW}📋 查看服务日志:${NC}"
    sudo journalctl -u ipv6-wireguard-manager --no-pager -n 20
    exit 1
fi

# 7. 显示服务信息
echo -e "${BLUE}📊 服务信息:${NC}"
echo "服务状态: $(systemctl is-active ipv6-wireguard-manager)"
echo "服务端口: 8000"
echo "API文档: http://localhost:8000/docs"
echo "健康检查: http://localhost:8000/health"

echo -e "${GREEN}🎉 远程服务器一键修复完成！${NC}"
echo -e "${BLUE}💡 提示: 如果仍有问题，请查看日志: sudo journalctl -u ipv6-wireguard-manager -f${NC}"
