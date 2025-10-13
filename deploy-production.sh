#!/bin/bash

# IPv6 WireGuard Manager 生产环境部署脚本

echo "🚀 开始部署 IPv6 WireGuard Manager 生产环境..."

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查Docker和Docker Compose
check_prerequisites() {
    echo -e "${BLUE}🔍 检查系统依赖...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 系统依赖检查通过${NC}"
}

# 创建环境文件
create_env_file() {
    echo -e "${BLUE}📝 创建环境配置文件...${NC}"
    
    if [ ! -f .env.production ]; then
        cat > .env.production << EOF
# 生产环境配置
POSTGRES_PASSWORD=password
REDIS_PASSWORD=redis123
SECRET_KEY=$(openssl rand -hex 32)
GRAFANA_PASSWORD=admin123

# 应用配置
DEBUG=false
LOG_LEVEL=INFO
API_V1_STR=/api/v1
SERVER_HOST=0.0.0.0
SERVER_PORT=8000

# 数据库配置（使用VPS标准配置）
DATABASE_URL=postgresql://ipv6wgm:password@postgres:5432/ipv6wgm
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30

# Redis配置
REDIS_URL=redis://:redis123@redis:6379/0
REDIS_POOL_SIZE=10

# 监控配置
ENABLE_METRICS=true
METRICS_PORT=9090
EOF
        echo -e "${GREEN}✅ 环境配置文件创建成功${NC}"
    else
        echo -e "${YELLOW}⚠️  环境配置文件已存在，跳过创建${NC}"
    fi
}

# 构建Docker镜像
build_images() {
    echo -e "${BLUE}🔨 构建Docker镜像...${NC}"
    
    # 构建后端镜像
    echo -e "${BLUE}📦 构建后端镜像...${NC}"
    docker build -f backend/Dockerfile.production -t ipv6-wireguard-backend:latest ./backend
    
    # 构建前端镜像
    echo -e "${BLUE}📦 构建前端镜像...${NC}"
    docker build -f frontend/Dockerfile.production -t ipv6-wireguard-frontend:latest ./frontend
    
    echo -e "${GREEN}✅ Docker镜像构建完成${NC}"
}

# 启动服务
start_services() {
    echo -e "${BLUE}🚀 启动服务...${NC}"
    
    # 使用生产环境配置启动服务
    docker-compose -f docker-compose.production.yml up -d
    
    echo -e "${GREEN}✅ 服务启动完成${NC}"
}

# 等待服务就绪
wait_for_services() {
    echo -e "${BLUE}⏳ 等待服务就绪...${NC}"
    
    # 等待数据库
    echo -e "${BLUE}🗄️  等待数据库就绪...${NC}"
    until docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U ipv6wgm -d ipv6wgm &> /dev/null; do
        echo -e "${YELLOW}⏳ 数据库正在启动...${NC}"
        sleep 5
    done
    echo -e "${GREEN}✅ 数据库就绪${NC}"
    
    # 等待后端服务
    echo -e "${BLUE}🔧 等待后端服务就绪...${NC}"
    until curl -f http://localhost:8000/api/v1/health &> /dev/null; do
        echo -e "${YELLOW}⏳ 后端服务正在启动...${NC}"
        sleep 5
    done
    echo -e "${GREEN}✅ 后端服务就绪${NC}"
    
    # 等待前端服务
    echo -e "${BLUE}🌐 等待前端服务就绪...${NC}"
    until curl -f http://localhost:80 &> /dev/null; do
        echo -e "${YELLOW}⏳ 前端服务正在启动...${NC}"
        sleep 5
    done
    echo -e "${GREEN}✅ 前端服务就绪${NC}"
}

# 初始化数据库
init_database() {
    echo -e "${BLUE}🗃️  初始化数据库...${NC}"
    
    # 运行数据库初始化（使用新的健康检查功能）
    docker-compose -f docker-compose.production.yml exec -T backend python -c "
from app.core.database import init_db
import asyncio
print('开始数据库初始化...')
result = asyncio.run(init_db())
print(f'数据库初始化完成: {result}')
"
    
    echo -e "${GREEN}✅ 数据库初始化完成${NC}"
}

# 显示部署信息
show_deployment_info() {
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo ""
    echo -e "${BLUE}📊 服务访问信息：${NC}"
    echo -e "  🌐 前端应用: ${GREEN}http://localhost${NC}"
    echo -e "  🔧 后端API: ${GREEN}http://localhost:8000${NC}"
    echo -e "  📚 API文档: ${GREEN}http://localhost:8000/docs${NC}"
    echo -e "  📈 监控面板: ${GREEN}http://localhost:3000${NC}"
    echo -e "  📊 Prometheus: ${GREEN}http://localhost:9090${NC}"
    echo ""
    echo -e "${BLUE}🔑 默认登录信息：${NC}"
    echo -e "  用户名: ${GREEN}admin${NC}"
    echo -e "  密码: ${GREEN}admin123${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  请及时修改默认密码！${NC}"
}

# 主部署流程
main() {
    echo -e "${BLUE}🔧 IPv6 WireGuard Manager 生产环境部署${NC}"
    echo ""
    
    # 检查依赖
    check_prerequisites
    
    # 创建环境文件
    create_env_file
    
    # 构建镜像
    build_images
    
    # 启动服务
    start_services
    
    # 等待服务就绪
    wait_for_services
    
    # 初始化数据库
    init_database
    
    # 显示部署信息
    show_deployment_info
    
    echo -e "${GREEN}✅ 部署流程完成！${NC}"
}

# 执行主函数
main "$@"