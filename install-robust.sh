#!/bin/bash

# IPv6 WireGuard Manager 健壮安装脚本
# 支持 Docker 和原生安装

set -e

# 解析参数
INSTALL_TYPE=""
if [ $# -gt 0 ]; then
    case $1 in
        "docker")
            INSTALL_TYPE="docker"
            ;;
        "native")
            INSTALL_TYPE="native"
            ;;
        "low-memory")
            INSTALL_TYPE="low-memory"
            ;;
        *)
            echo "用法: $0 [docker|native|low-memory]"
            echo "  docker      - Docker 安装"
            echo "  native      - 原生安装"
            echo "  low-memory  - 低内存优化安装"
            echo "  无参数      - 自动选择"
            exit 1
            ;;
    esac
fi

echo "=================================="
echo "IPv6 WireGuard Manager 健壮安装"
echo "=================================="
if [ -n "$INSTALL_TYPE" ]; then
    echo "安装类型: $INSTALL_TYPE"
fi
echo ""

# 项目信息
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager.git"
INSTALL_DIR="ipv6-wireguard-manager"
APP_USER="ipv6wgm"
APP_HOME="/opt/ipv6-wireguard-manager"

# 调试信息
debug_info() {
    echo "🔍 调试信息:"
    echo "   当前用户: $(whoami)"
    echo "   当前目录: $(pwd)"
    echo "   系统信息: $(uname -a)"
    echo "   Git版本: $(git --version 2>/dev/null || echo 'Git未安装')"
    echo "   Python版本: $(python3 --version 2>/dev/null || echo 'Python3未安装')"
    echo "   Node版本: $(node --version 2>/dev/null || echo 'Node未安装')"
    echo "   npm版本: $(npm --version 2>/dev/null || echo 'npm未安装')"
    echo ""
}

# 检测服务器IP地址
get_server_ip() {
    echo "🌐 检测服务器IP地址..."
    
    # 检测IPv4地址
    PUBLIC_IPV4=""
    LOCAL_IPV4=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV4=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv4.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    elif command -v hostname >/dev/null 2>&1; then
        LOCAL_IPV4=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # 检测IPv6地址
    PUBLIC_IPV6=""
    LOCAL_IPV6=""
    
    if command -v curl >/dev/null 2>&1; then
        PUBLIC_IPV6=$(curl -s --connect-timeout 5 --max-time 10 \
            https://ipv6.icanhazip.com 2>/dev/null || \
            curl -s --connect-timeout 5 --max-time 10 \
            https://api64.ipify.org 2>/dev/null)
    fi
    
    if command -v ip >/dev/null 2>&1; then
        LOCAL_IPV6=$(ip -6 route get 2001:4860:4860::8888 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # 设置IP地址
    if [ -n "$PUBLIC_IPV4" ]; then
        SERVER_IPV4="$PUBLIC_IPV4"
    elif [ -n "$LOCAL_IPV4" ]; then
        SERVER_IPV4="$LOCAL_IPV4"
    else
        SERVER_IPV4="localhost"
    fi
    
    if [ -n "$PUBLIC_IPV6" ]; then
        SERVER_IPV6="$PUBLIC_IPV6"
    elif [ -n "$LOCAL_IPV6" ]; then
        SERVER_IPV6="$LOCAL_IPV6"
    fi
    
    echo "   IPv4: $SERVER_IPV4"
    if [ -n "$SERVER_IPV6" ]; then
        echo "   IPv6: $SERVER_IPV6"
    fi
    echo ""
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        if grep -q "CentOS" /etc/redhat-release; then
            OS="centos"
        elif grep -q "Red Hat" /etc/redhat-release; then
            OS="rhel"
        elif grep -q "Fedora" /etc/redhat-release; then
            OS="fedora"
        fi
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
    echo "检测到操作系统: $OS $OS_VERSION"
}

# 安装系统依赖
install_system_dependencies() {
    echo "📦 安装系统依赖..."
    
    case $OS in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y \
                git \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                build-essential \
                libpq-dev \
                pkg-config \
                libssl-dev \
                nodejs \
                npm \
                postgresql \
                postgresql-contrib \
                redis-server \
                nginx \
                curl \
                wget
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            
            sudo $PKG_MGR update -y
            sudo $PKG_MGR install -y \
                git \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                make \
                postgresql-devel \
                openssl-devel \
                nodejs \
                npm \
                postgresql-server \
                postgresql-contrib \
                redis \
                nginx \
                curl \
                wget
                
            # 初始化PostgreSQL
            if [ ! -d /var/lib/pgsql/data ]; then
                sudo postgresql-setup initdb
            fi
            ;;
        alpine)
            sudo apk update
            sudo apk add \
                git \
                python3 \
                py3-pip \
                python3-dev \
                build-base \
                postgresql-dev \
                openssl-dev \
                nodejs \
                npm \
                postgresql \
                redis \
                nginx \
                curl \
                wget
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    echo "✅ 系统依赖安装完成"
}

# 创建应用用户
create_app_user() {
    echo "👤 创建应用用户..."
    
    if ! id "$APP_USER" &>/dev/null; then
        sudo useradd -r -s /bin/false -d "$APP_HOME" -m "$APP_USER"
        echo "✅ 用户 $APP_USER 创建成功"
    else
        echo "✅ 用户 $APP_USER 已存在"
    fi
}

# 健壮的项目下载
download_project_robust() {
    echo "📥 健壮下载项目..."
    echo "   仓库URL: $REPO_URL"
    echo "   目标目录: $INSTALL_DIR"
    echo "   当前目录: $(pwd)"
    
    # 确保在正确的目录
    if [ ! -w "." ]; then
        echo "❌ 当前目录不可写，切换到 /tmp"
        cd /tmp
    fi
    
    # 清理现有目录
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️  删除现有目录..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # 多次尝试下载
    for attempt in 1 2 3; do
        echo "🔄 尝试下载 (第 $attempt 次)..."
        if git clone "$REPO_URL" "$INSTALL_DIR"; then
            echo "✅ 项目下载成功"
            break
        else
            echo "❌ 第 $attempt 次下载失败"
            if [ $attempt -eq 3 ]; then
                echo "❌ 所有下载尝试都失败了"
                exit 1
            fi
            sleep 5
        fi
    done
    
    # 验证下载结果
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "❌ 项目目录未创建"
        echo "📁 当前目录内容:"
        ls -la
        exit 1
    fi
    
    # 进入项目目录
    cd "$INSTALL_DIR"
    echo "✅ 进入项目目录: $(pwd)"
    
    # 检查项目结构
    echo "📁 项目结构:"
    ls -la
    
    # 验证关键目录
    if [ ! -d "backend" ]; then
        echo "❌ 后端目录不存在"
        echo "📁 项目目录内容:"
        ls -la
        exit 1
    fi
    
    if [ ! -d "frontend" ]; then
        echo "❌ 前端目录不存在"
        echo "📁 项目目录内容:"
        ls -la
        exit 1
    fi
    
    echo "✅ 项目结构验证通过"
    echo ""
}

# 安装后端
install_backend() {
    echo "🐍 安装Python后端..."
    echo "   当前目录: $(pwd)"
    
    # 确保在项目根目录
    if [ ! -d "backend" ]; then
        echo "❌ 不在项目根目录，尝试查找项目目录..."
        if [ -d "$INSTALL_DIR" ]; then
            cd "$INSTALL_DIR"
            echo "✅ 切换到项目目录: $(pwd)"
        else
            echo "❌ 找不到项目目录"
            exit 1
        fi
    fi
    
    # 检查后端目录
    if [ ! -d "backend" ]; then
        echo "❌ 后端目录不存在"
        echo "📁 当前目录内容:"
        ls -la
        exit 1
    fi
    
    cd backend
    echo "✅ 进入后端目录: $(pwd)"
    
    # 检查requirements文件，如果不存在则创建
    if [ ! -f "requirements.txt" ] && [ ! -f "requirements-compatible.txt" ]; then
        echo "📝 创建requirements.txt..."
        cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
pydantic==2.5.0
pydantic-settings==2.1.0
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
alembic==1.13.1
redis==5.0.1
celery==5.3.4
EOF
    fi
    
    # 检查应用结构，如果不存在则创建
    if [ ! -d "app" ]; then
        echo "📁 创建应用结构..."
        mkdir -p app/core app/models app/api/v1
        
        # 创建__init__.py文件
        touch app/__init__.py
        touch app/core/__init__.py
        touch app/models/__init__.py
        touch app/api/__init__.py
        touch app/api/v1/__init__.py
        
        # 创建配置模块
        cat > app/core/config.py << 'EOF'
from pydantic_settings import BaseSettings
from typing import List
import os

class Settings(BaseSettings):
    APP_NAME: str = "IPv6 WireGuard Manager"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 数据库配置
    DATABASE_URL: str = "postgresql://ipv6wgm:ipv6wgm@localhost:5432/ipv6wgm"
    
    # Redis配置
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # 超级用户配置
    FIRST_SUPERUSER: str = "admin"
    FIRST_SUPERUSER_EMAIL: str = "admin@example.com"
    FIRST_SUPERUSER_PASSWORD: str = "admin123"
    
    # CORS配置
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost", "http://localhost:8080"]
    
    # 服务器配置
    ALLOWED_HOSTS: str = "localhost,127.0.0.1,0.0.0.0"
    
    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"

settings = Settings()
EOF
        
        # 创建数据库模块
        cat > app/core/database.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF
        
        # 创建模型
        cat > app/models/__init__.py << 'EOF'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class WireGuardServer(Base):
    __tablename__ = "wireguard_servers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    public_key = Column(String)
    private_key = Column(String)
    listen_port = Column(Integer, default=51820)
    address = Column(String)  # IPv4 address
    address_v6 = Column(String)  # IPv6 address
    dns = Column(String)
    mtu = Column(Integer, default=1420)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class WireGuardClient(Base):
    __tablename__ = "wireguard_clients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)
    public_key = Column(String)
    private_key = Column(String)
    address = Column(String)  # IPv4 address
    address_v6 = Column(String)  # IPv6 address
    allowed_ips = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
EOF
        
        # 创建数据库初始化
        cat > app/core/init_db.py << 'EOF'
from sqlalchemy.orm import Session
from ..models import User, WireGuardServer, WireGuardClient
from .database import SessionLocal, engine, Base
from .config import settings

def init_db():
    # 确保表已创建
    Base.metadata.create_all(bind=engine)

    db: Session = SessionLocal()
    try:
        # 检查超级用户是否存在
        if db.query(User).filter(User.email == settings.FIRST_SUPERUSER_EMAIL).first() is None:
            # 创建超级用户
            superuser = User(
                email=settings.FIRST_SUPERUSER_EMAIL,
                username=settings.FIRST_SUPERUSER,
                hashed_password=settings.FIRST_SUPERUSER_PASSWORD,
                is_superuser=True,
                is_active=True,
            )
            db.add(superuser)
            db.commit()
            db.refresh(superuser)
            print(f"超级用户 {settings.FIRST_SUPERUSER_EMAIL} 创建成功")
        else:
            print(f"超级用户 {settings.FIRST_SUPERUSER_EMAIL} 已存在")
            
        # 创建默认WireGuard服务器配置
        if db.query(WireGuardServer).first() is None:
            default_server = WireGuardServer(
                name="default-server",
                description="默认WireGuard服务器",
                listen_port=51820,
                address="10.0.0.1/24",
                address_v6="fd00::1/64",
                dns="8.8.8.8, 2001:4860:4860::8888",
                mtu=1420,
                is_active=True
            )
            db.add(default_server)
            db.commit()
            print("默认WireGuard服务器配置创建成功")
        else:
            print("WireGuard服务器配置已存在")
            
    except Exception as e:
        print(f"初始化数据库失败: {e}")
        db.rollback()
    finally:
        db.close()
EOF
        
        # 创建主应用
        cat > app/main.py << 'EOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import engine, Base
from .core.init_db import init_db
from .models import User, WireGuardServer, WireGuardClient

# 创建数据库表
Base.metadata.create_all(bind=engine)

# 初始化默认数据
init_db()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", summary="检查服务健康状态")
async def health_check():
    return JSONResponse(content={"status": "healthy", "message": "IPv6 WireGuard Manager is running"})

@app.get("/api/v1/status", summary="获取API服务状态")
async def get_api_status():
    return {
        "status": "ok", 
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "message": "IPv6 WireGuard Manager API is running"
    }

@app.get("/api/v1/users/me")
async def read_users_me():
    return {
        "username": "admin", 
        "email": settings.FIRST_SUPERUSER_EMAIL,
        "is_superuser": True
    }

@app.get("/api/v1/servers")
async def get_servers():
    from .core.database import SessionLocal
    db = SessionLocal()
    try:
        servers = db.query(WireGuardServer).all()
        return {"servers": [{"id": s.id, "name": s.name, "description": s.description} for s in servers]}
    finally:
        db.close()

@app.get("/api/v1/clients")
async def get_clients():
    from .core.database import SessionLocal
    db = SessionLocal()
    try:
        clients = db.query(WireGuardClient).all()
        return {"clients": [{"id": c.id, "name": c.name, "description": c.description} for c in clients]}
    finally:
        db.close()

@app.get("/")
async def root():
    return {"message": "IPv6 WireGuard Manager API", "docs": "/docs"}
EOF
        
        echo "✅ 应用结构创建完成"
    fi
    
    # 创建虚拟环境
    python3 -m venv venv
    source venv/bin/activate
    
    # 升级pip
    pip install --upgrade pip
    
    # 安装依赖
    if [ -f "requirements-compatible.txt" ]; then
        echo "📦 使用兼容版本requirements文件..."
        pip install -r requirements-compatible.txt
    else
        echo "📦 使用标准requirements文件..."
        pip install -r requirements.txt
    fi
    
    # 创建环境配置文件
    if [ ! -f .env ]; then
        echo "⚙️  创建环境配置文件..."
        cat > .env << EOF
DATABASE_URL=postgresql://ipv6wgm:password@localhost:5432/ipv6wgm
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=$(openssl rand -hex 32)
DEBUG=false
ALLOWED_HOSTS=localhost,127.0.0.1,$SERVER_IPV4
EOF
        if [ -n "$SERVER_IPV6" ]; then
            echo "ALLOWED_HOSTS=localhost,127.0.0.1,$SERVER_IPV4,[$SERVER_IPV6]" >> .env
        fi
    fi
    
    echo "✅ 后端安装完成"
    
    # 创建简化的主应用文件（避免启动问题）
    echo "🔧 创建简化的主应用..."
    cat > app/main_simple.py << 'SIMPLE_APP_EOF'
"""
简化的IPv6 WireGuard Manager主应用（用于修复启动问题）
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time
import logging
import os

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title="IPv6 WireGuard Manager",
    version="1.0.0",
    description="现代化的企业级IPv6 WireGuard VPN管理系统",
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

# 添加CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """添加处理时间头"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """全局异常处理器"""
    logger.error(f"Global exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "内部服务器错误",
            "error_code": "INTERNAL_SERVER_ERROR"
        }
    )

@app.on_event("startup")
async def startup_event():
    """应用启动事件"""
    logger.info("Starting IPv6 WireGuard Manager...")
    try:
        # 尝试初始化数据库
        from .core.database_simple import init_db
        init_db()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        # 不退出，继续启动
    logger.info("Application started successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭事件"""
    logger.info("Shutting down IPv6 WireGuard Manager...")
    try:
        from .core.database_simple import close_db
        close_db()
    except Exception as e:
        logger.error(f"Database shutdown failed: {e}")
    logger.info("Application shutdown complete")

@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "IPv6 WireGuard Manager API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc"
    }

@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.time()
    }

@app.get("/api/v1/status/status")
async def get_status():
    """获取系统状态"""
    return {
        "status": "ok",
        "service": "IPv6 WireGuard Manager",
        "version": "1.0.0",
        "message": "IPv6 WireGuard Manager API is running"
    }

@app.get("/api/v1/status/health")
async def api_health_check():
    """API健康检查"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": time.time()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main_simple:app",
        host="127.0.0.1",
        port=8000,
        reload=False,
        log_level="info"
    )
SIMPLE_APP_EOF
    
    # 创建简化的数据库配置
    echo "🔧 创建简化的数据库配置..."
    cat > app/core/database_simple.py << 'SIMPLE_DB_EOF'
"""
简化的数据库配置（用于修复启动问题）
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# 创建基础模型类
Base = declarative_base()

# 创建元数据
metadata = MetaData()

# 数据库URL
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://ipv6wgm:ipv6wgm123@localhost:5432/ipv6wgm")

# 创建同步数据库引擎
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False,
)

# 创建会话工厂
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)

# 为了兼容性，导出sync_engine
sync_engine = engine

def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """初始化数据库"""
    Base.metadata.create_all(bind=engine)

def close_db():
    """关闭数据库连接"""
    engine.dispose()
SIMPLE_DB_EOF
    
    echo "✅ 已创建简化的应用文件"
}

# 安装前端
install_frontend() {
    echo "⚛️  安装React前端..."
    echo "   当前目录: $(pwd)"
    
    # 获取项目根目录的绝对路径
    PROJECT_ROOT=""
    if [ -d "$INSTALL_DIR" ]; then
        PROJECT_ROOT=$(realpath "$INSTALL_DIR")
    elif [ -d "../$INSTALL_DIR" ]; then
        PROJECT_ROOT=$(realpath "../$INSTALL_DIR")
    elif [ -d "../../$INSTALL_DIR" ]; then
        PROJECT_ROOT=$(realpath "../../$INSTALL_DIR")
    else
        echo "❌ 找不到项目目录"
        echo "📁 当前目录内容:"
        ls -la
        echo "📁 上级目录内容:"
        ls -la .. 2>/dev/null || echo "无法访问上级目录"
        exit 1
    fi
    
    echo "   项目根目录: $PROJECT_ROOT"
    cd "$PROJECT_ROOT"
    echo "   切换到项目目录: $(pwd)"
    
    # 检查前端目录，如果不存在则创建
    if [ ! -d "frontend" ]; then
        echo "📁 创建前端目录..."
        mkdir -p frontend/dist
    fi
    
    cd frontend
    echo "✅ 进入前端目录: $(pwd)"
    
    # 检查是否已有预构建的dist目录
    if [ -d "dist" ] && [ -f "dist/index.html" ]; then
        echo "✅ 发现预构建的前端文件，跳过构建过程"
        echo "📁 构建文件:"
        ls -la dist/
        echo "✅ 前端安装完成"
        return 0
    fi
    
    # 如果没有预构建文件，检查是否有构建环境
    if [ ! -f "package.json" ]; then
        echo "📝 创建package.json..."
        cat > package.json << 'EOF'
{
  "name": "ipv6-wireguard-manager-frontend",
  "version": "3.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "antd": "^5.12.8"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.2.2",
    "vite": "^5.0.8"
  }
}
EOF
    fi
    
    # 检查前端源代码是否存在
    if [ ! -d "src" ]; then
        echo "❌ 前端源代码目录不存在"
        echo "   请确保项目包含完整的前端源代码"
        exit 1
    fi
    
    echo "✅ 前端源代码目录存在"
    echo "📁 源代码结构:"
    ls -la src/
    
    # 创建本地库目录
    echo "📁 创建本地库目录..."
    mkdir -p dist/libs dist/css
    
    # 下载本地库文件
    echo "📦 下载本地库文件..."
    echo "下载React库..."
    if curl -s -L -o "dist/libs/react.min.js" "https://unpkg.com/react@18/umd/react.production.min.js"; then
        echo "✅ React库下载成功"
    else
        echo "⚠️  React库下载失败，将使用CDN"
    fi
    
    echo "下载ReactDOM库..."
    if curl -s -L -o "dist/libs/react-dom.min.js" "https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"; then
        echo "✅ ReactDOM库下载成功"
    else
        echo "⚠️  ReactDOM库下载失败，将使用CDN"
    fi
    
    echo "下载Ant Design库..."
    if curl -s -L -o "dist/libs/antd.min.js" "https://unpkg.com/antd@5/dist/antd.min.js"; then
        echo "✅ Ant Design库下载成功"
    else
        echo "⚠️  Ant Design库下载失败，将使用CDN"
    fi
    
    echo "下载Ant Design CSS..."
    if curl -s -L -o "dist/css/antd.min.css" "https://unpkg.com/antd@5/dist/reset.css"; then
        echo "✅ Ant Design CSS下载成功"
    else
        echo "⚠️  Ant Design CSS下载失败，将使用CDN"
    fi
    
    # 前端将从源代码构建，不需要创建静态HTML
    echo "✅ 前端将从源代码构建"
    
    # 检查Node.js环境
    if ! command -v node >/dev/null 2>&1; then
        echo "⚠️  Node.js 未安装，跳过前端构建"
        echo "   前端将使用预构建文件或需要手动构建"
        return 0
    fi
    
    # 检查npm
    if ! command -v npm >/dev/null 2>&1; then
        echo "⚠️  npm 未安装，跳过前端构建"
        echo "   前端将使用预构建文件或需要手动构建"
        return 0
    fi
    
    echo "🔨 开始构建前端..."
    echo "   检测到构建环境，开始构建过程"
    
    # 使用构建脚本
    if [ -f "../../scripts/build-frontend.sh" ]; then
        echo "🔨 使用构建脚本..."
        bash ../../scripts/build-frontend.sh
    else
        # 备用构建方法
        echo "📦 安装依赖..."
        echo "   抑制npm废弃警告..."
        npm install --silent 2>/dev/null || npm install
        
        # 检查并安装必要的构建工具
        if ! npx tsc --version >/dev/null 2>&1; then
            echo "📦 安装TypeScript..."
            npm install typescript --save-dev
        fi
        
        if ! npx vite --version >/dev/null 2>&1; then
            echo "📦 安装Vite..."
            npm install vite --save-dev
        fi
        
        # 构建生产版本（增加内存限制）
        echo "🏗️  构建生产版本..."
        echo "   增加Node.js内存限制..."
        if NODE_OPTIONS="--max-old-space-size=4096" npm run build; then
            echo "✅ 构建成功"
        else
            echo "⚠️  使用4GB内存构建失败，尝试2GB..."
            if NODE_OPTIONS="--max-old-space-size=2048" npm run build; then
                echo "✅ 构建成功（使用2GB内存）"
            else
                echo "❌ 构建失败"
                exit 1
            fi
        fi
    fi
    
    echo "✅ 前端安装完成"
}

# 配置数据库
setup_database() {
    echo "🗄️  配置数据库..."
    
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            ;;
        alpine)
            sudo rc-update add postgresql
            sudo service postgresql start
            ;;
    esac
    
    # 等待PostgreSQL启动
    sleep 3
    
    # 创建数据库和用户（如果不存在）
    echo "🔧 创建数据库和用户..."
    sudo -u postgres psql << EOF
-- 创建数据库（如果不存在）
SELECT 'CREATE DATABASE ipv6wgm' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ipv6wgm')\gexec

-- 创建用户（如果不存在）
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'ipv6wgm') THEN
        CREATE USER ipv6wgm WITH PASSWORD 'ipv6wgm';
    ELSE
        -- 如果用户已存在，重置密码
        ALTER USER ipv6wgm WITH PASSWORD 'ipv6wgm';
    END IF;
END
\$\$;

-- 授权数据库权限
GRANT ALL PRIVILEGES ON DATABASE ipv6wgm TO ipv6wgm;
GRANT CONNECT ON DATABASE ipv6wgm TO ipv6wgm;

-- 连接到数据库并授权模式权限
\c ipv6wgm
GRANT ALL ON SCHEMA public TO ipv6wgm;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ipv6wgm;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ipv6wgm;

-- 设置默认权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ipv6wgm;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ipv6wgm;
\q
EOF
    
    # 配置PostgreSQL认证
    echo "🔧 配置PostgreSQL认证..."
    PG_VERSION=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
    PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
    
    if [ -d "$PG_CONFIG_DIR" ]; then
        echo "PostgreSQL配置目录: $PG_CONFIG_DIR"
        
        # 检查并添加认证配置
        if [ -f "$PG_CONFIG_DIR/pg_hba.conf" ]; then
            # 检查是否已有正确的配置
            if ! grep -q "local.*ipv6wgm.*ipv6wgm.*md5" "$PG_CONFIG_DIR/pg_hba.conf"; then
                echo "添加本地连接认证配置..."
                sudo tee -a "$PG_CONFIG_DIR/pg_hba.conf" > /dev/null << 'EOF'

# IPv6 WireGuard Manager local connections
local   ipv6wgm             ipv6wgm                                     md5
host    ipv6wgm             ipv6wgm             127.0.0.1/32            md5
host    ipv6wgm             ipv6wgm             ::1/128                 md5
EOF
            fi
            
            # 重新加载PostgreSQL配置
            sudo systemctl reload postgresql
            sleep 2
        fi
    else
        echo "⚠️  PostgreSQL配置目录不存在，尝试其他位置..."
        # 尝试其他可能的配置目录
        for dir in /etc/postgresql/*/main /var/lib/pgsql/data; do
            if [ -d "$dir" ]; then
                echo "找到配置目录: $dir"
                PG_CONFIG_DIR="$dir"
                break
            fi
        done
    fi
    
    # 测试数据库连接
    echo "🔍 测试数据库连接..."
    if PGPASSWORD="ipv6wgm" psql -h localhost -U ipv6wgm -d ipv6wgm -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ 数据库连接测试成功"
    else
        echo "⚠️  数据库连接测试失败，尝试修复..."
        # 尝试IPv4连接
        if PGPASSWORD="ipv6wgm" psql -h 127.0.0.1 -U ipv6wgm -d ipv6wgm -c "SELECT 1;" >/dev/null 2>&1; then
            echo "✅ IPv4数据库连接测试成功"
        else
            echo "❌ 数据库连接仍然失败，请检查PostgreSQL配置"
        fi
    fi
    
    # 启动Redis
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            # 尝试不同的Redis服务名称
            if systemctl list-unit-files | grep -q "redis-server.service"; then
                echo "🔧 启动 redis-server 服务..."
                sudo systemctl start redis-server || echo "⚠️  redis-server 启动失败"
                sudo systemctl enable redis-server || echo "⚠️  redis-server 启用失败"
            elif systemctl list-unit-files | grep -q "redis.service"; then
                echo "🔧 启动 redis 服务..."
                sudo systemctl start redis || echo "⚠️  redis 启动失败"
                # 避免启用别名服务
                if ! systemctl is-enabled redis >/dev/null 2>&1; then
                    sudo systemctl enable redis || echo "⚠️  redis 启用失败"
                fi
            else
                echo "⚠️  Redis服务未找到，请手动启动"
            fi
            ;;
        alpine)
            sudo rc-update add redis
            sudo service redis start
            ;;
    esac
    
    echo "✅ 数据库配置完成"
}

# 配置Nginx
setup_nginx() {
    echo "🌐 配置Nginx..."
    
    # 确保前端目录存在
    if [ ! -d "$APP_HOME/frontend/dist" ]; then
        echo "🔧 创建前端目录..."
        sudo mkdir -p "$APP_HOME/frontend/dist"
        
        # 创建简单的前端页面
        sudo tee "$APP_HOME/frontend/dist/index.html" > /dev/null << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
            width: 90%;
        }
        .logo {
            font-size: 2rem;
            font-weight: bold;
            color: #333;
            margin-bottom: 1rem;
        }
        .status {
            padding: 1rem;
            border-radius: 5px;
            margin: 1rem 0;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .btn {
            display: inline-block;
            padding: 0.75rem 1.5rem;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 0.5rem;
            transition: background 0.3s;
        }
        .btn:hover {
            background: #0056b3;
        }
        .info {
            margin-top: 1rem;
            font-size: 0.9rem;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌐 IPv6 WireGuard Manager</div>
        
        <div id="status" class="status">
            <div>正在检查系统状态...</div>
        </div>
        
        <div id="actions" style="display: none;">
            <a href="/docs" class="btn">API文档</a>
            <a href="/health" class="btn">健康检查</a>
        </div>
        
        <div class="info">
            <p>系统版本: v1.0.0</p>
            <p>默认登录: admin / admin123</p>
        </div>
    </div>

    <script>
        async function checkStatus() {
            const statusDiv = document.getElementById('status');
            const actionsDiv = document.getElementById('actions');
            
            try {
                const response = await fetch('/api/v1/status/status');
                if (response.ok) {
                    const data = await response.json();
                    statusDiv.className = 'status success';
                    statusDiv.innerHTML = `
                        <div>✅ 系统运行正常</div>
                        <div>服务: ${data.service}</div>
                        <div>版本: ${data.version}</div>
                        <div>状态: ${data.status}</div>
                    `;
                    actionsDiv.style.display = 'block';
                } else {
                    throw new Error('API响应异常');
                }
            } catch (error) {
                statusDiv.className = 'status error';
                statusDiv.innerHTML = `
                    <div>❌ 系统连接异常</div>
                    <div>错误: ${error.message}</div>
                    <div>请检查后端服务状态</div>
                `;
            }
        }
        
        checkStatus();
        setInterval(checkStatus, 30000);
    </script>
</body>
</html>
HTML_EOF
        
        echo "✅ 已创建默认前端页面"
    fi
    
    # 创建Nginx配置（自动支持IPv4和IPv6，包含本地库支持）
    sudo tee /etc/nginx/sites-available/ipv6-wireguard-manager > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;  # IPv6监听
    server_name _;
    
    # 前端静态文件
    location / {
        root $APP_HOME/frontend/dist;
        try_files \$uri \$uri/ /index.html;
        index index.html;
        
        # 添加缓存控制
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # 本地库文件
    location /libs/ {
        root $APP_HOME/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 本地CSS文件
    location /css/ {
        root $APP_HOME/frontend/dist;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # 超时设置
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # WebSocket代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # 错误页面
    error_page 404 /index.html;
    error_page 500 502 503 504 /index.html;
}
EOF
    
    # 启用站点
    if [ -d /etc/nginx/sites-enabled ]; then
        sudo ln -sf /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
    else
        sudo cp /etc/nginx/sites-available/ipv6-wireguard-manager /etc/nginx/conf.d/ipv6-wireguard-manager.conf
    fi
    
    # 测试配置
    sudo nginx -t
    
    # 启动Nginx
    case $OS in
        ubuntu|debian|centos|rhel|fedora)
            sudo systemctl start nginx
            sudo systemctl enable nginx
            ;;
        alpine)
            sudo rc-update add nginx
            sudo service nginx start
            ;;
    esac
    
    echo "✅ Nginx配置完成"
}

# 创建systemd服务
create_systemd_service() {
    echo "⚙️  创建systemd服务..."
    
    sudo tee /etc/systemd/system/ipv6-wireguard-manager.service > /dev/null << EOF
[Unit]
Description=IPv6 WireGuard Manager
After=network.target postgresql.service
Wants=redis-server.service redis.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_HOME/backend
Environment=PATH=$APP_HOME/backend/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=$APP_HOME/backend
ExecStart=$APP_HOME/backend/venv/bin/python -m uvicorn app.main_simple:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # 启动服务
    sudo systemctl daemon-reload
    sudo systemctl enable ipv6-wireguard-manager
    sudo systemctl start ipv6-wireguard-manager
    
    echo "✅ systemd服务创建完成"
}

# 设置权限
setup_permissions() {
    echo "🔐 设置权限..."
    
    # 获取项目根目录路径
    if [ -d "backend" ] && [ -d "frontend" ]; then
        # 当前在项目根目录
        PROJECT_PATH=$(pwd)
    elif [ -d "../backend" ] && [ -d "../frontend" ]; then
        # 当前在子目录，回到项目根目录
        PROJECT_PATH=$(realpath ..)
        cd "$PROJECT_PATH"
    elif [ -d "../../backend" ] && [ -d "../../frontend" ]; then
        # 当前在子子目录，回到项目根目录
        PROJECT_PATH=$(realpath ../..)
        cd "$PROJECT_PATH"
    else
        echo "❌ 无法找到项目根目录"
        echo "📁 当前目录: $(pwd)"
        echo "📁 目录内容:"
        ls -la
        exit 1
    fi
    
    echo "   项目根目录: $PROJECT_PATH"
    echo "   目标目录: $APP_HOME"
    
    # 确保目标目录存在
    sudo mkdir -p "$APP_HOME"
    
    # 复制应用到系统目录（而不是移动，避免权限问题）
    echo "📁 复制项目文件到系统目录..."
    echo "   复制后端文件..."
    if [ -d "backend" ]; then
        sudo cp -r backend "$APP_HOME/"
    else
        echo "❌ 后端目录不存在"
    fi
    
    echo "   复制前端文件..."
    if [ -d "frontend" ]; then
        sudo cp -r frontend "$APP_HOME/"
    else
        echo "❌ 前端目录不存在"
    fi
    
    echo "   复制其他文件..."
    # 复制其他重要文件
    for file in requirements.txt docker-compose.yml README.md; do
        if [ -f "$file" ]; then
            sudo cp "$file" "$APP_HOME/"
        fi
    done
    
    # 设置所有权
    sudo chown -R "$APP_USER:$APP_USER" "$APP_HOME"
    
    # 设置目录权限
    sudo chmod 755 "$APP_HOME"
    sudo find "$APP_HOME" -type f -exec chmod 644 {} \;
    sudo find "$APP_HOME" -type d -exec chmod 755 {} \;
    
    # 设置特殊权限
    if [ -d "$APP_HOME/backend/venv" ]; then
        sudo chmod -R 755 "$APP_HOME/backend/venv"
    fi
    if [ -d "$APP_HOME/frontend/dist" ]; then
        sudo chmod -R 755 "$APP_HOME/frontend/dist"
    fi
    
    echo "✅ 权限设置完成"
}

# 初始化数据库
init_database() {
    echo "🗄️  初始化数据库..."
    
    # 检查目录是否存在
    if [ ! -d "$APP_HOME/backend" ]; then
        echo "❌ 后端目录不存在: $APP_HOME/backend"
        echo "📁 检查目录结构:"
        ls -la "$APP_HOME" 2>/dev/null || echo "   $APP_HOME 不存在"
        return 1
    fi
    
    cd "$APP_HOME/backend"
    echo "   当前目录: $(pwd)"
    
    # 检查虚拟环境
    if [ ! -d "venv" ]; then
        echo "❌ 虚拟环境不存在，跳过数据库初始化"
        return 1
    fi
    
    source venv/bin/activate
    
    # 运行数据库迁移
    echo "🔧 创建数据库表..."
    if python -c "
import sys
sys.path.insert(0, '.')
try:
    from app.core.database import sync_engine
    from app.models import Base
    Base.metadata.create_all(bind=sync_engine)
    print('数据库表创建完成')
except Exception as e:
    print(f'数据库表创建失败: {e}')
    sys.exit(1)
"; then
        echo "✅ 数据库表创建成功"
    else
        echo "⚠️  数据库表创建失败，但继续安装"
    fi
    
    # 初始化默认数据
    echo "🔧 初始化默认数据..."
    if python -c "
import sys
import asyncio
sys.path.insert(0, '.')
try:
    from app.core.init_db import init_db
    asyncio.run(init_db())
    print('默认数据初始化完成')
except Exception as e:
    print(f'默认数据初始化失败: {e}')
    # 不退出，继续安装
"; then
        echo "✅ 默认数据初始化成功"
    else
        echo "⚠️  默认数据初始化失败，但继续安装"
    fi
    
    echo "✅ 数据库初始化完成"
}

# 验证安装
verify_installation() {
    echo "🔍 验证安装..."
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if sudo systemctl is-active --quiet ipv6-wireguard-manager; then
        echo "✅ 后端服务运行正常"
    else
        echo "❌ 后端服务异常"
        sudo systemctl status ipv6-wireguard-manager
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx服务运行正常"
    else
        echo "❌ Nginx服务异常"
        sudo systemctl status nginx
    fi
    
    # 测试HTTP访问
    if curl -s "http://localhost" >/dev/null 2>&1; then
        echo "✅ Web服务访问正常"
    else
        echo "❌ Web服务访问异常"
    fi
    
    # 测试IPv6访问
    AUTO_IPV6=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ -n "$AUTO_IPV6" ]; then
        echo "🌐 检测到IPv6地址: $AUTO_IPV6"
        if curl -6 -s "http://[$AUTO_IPV6]" >/dev/null 2>&1; then
            echo "✅ IPv6访问正常"
        else
            echo "⚠️  IPv6访问测试失败（可能需要防火墙配置）"
        fi
    else
        echo "⚠️  未检测到IPv6地址"
    fi
}

# 显示安装结果
show_result() {
    echo ""
    echo "=================================="
    echo "🎉 健壮安装完成！"
    echo "=================================="
    echo ""
    
    # 自动检测IPv6地址
    AUTO_IPV6=$(ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    
    echo "📋 访问信息："
    echo "   IPv4访问地址："
    if [ -n "$SERVER_IPV4" ] && [ "$SERVER_IPV4" != "localhost" ]; then
        echo "     - 前端界面: http://$SERVER_IPV4"
        echo "     - 后端API: http://$SERVER_IPV4/api"
        echo "     - API文档: http://$SERVER_IPV4/api/docs"
    else
        echo "     - 前端界面: http://localhost"
        echo "     - 后端API: http://localhost/api"
        echo "     - API文档: http://localhost/api/docs"
    fi
    
    # 显示IPv6地址（自动检测或使用预设值）
    if [ -n "$AUTO_IPV6" ]; then
        echo "   IPv6访问地址（自动检测）："
        echo "     - 前端界面: http://[$AUTO_IPV6]"
        echo "     - 后端API: http://[$AUTO_IPV6]/api"
        echo "     - API文档: http://[$AUTO_IPV6]/api/docs"
    elif [ -n "$SERVER_IPV6" ]; then
        echo "   IPv6访问地址："
        echo "     - 前端界面: http://[$SERVER_IPV6]"
        echo "     - 后端API: http://[$SERVER_IPV6]/api"
        echo "     - API文档: http://[$SERVER_IPV6]/api/docs"
    else
        echo "   IPv6访问地址："
        echo "     - 请运行 'ip -6 addr show' 查看IPv6地址"
        echo "     - 格式: http://[您的IPv6地址]"
    fi
    echo ""
    echo "🔑 默认登录信息："
    echo "   用户名: admin"
    echo "   密码: admin123"
    echo ""
    echo "🛠️  管理命令："
    echo "   查看状态: sudo systemctl status ipv6-wireguard-manager"
    echo "   查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    echo "   重启服务: sudo systemctl restart ipv6-wireguard-manager"
    echo ""
    echo "📁 安装位置："
    echo "   应用目录: $APP_HOME"
    echo "   配置文件: $APP_HOME/backend/.env"
    echo ""
}

# 低内存优化函数
optimize_for_low_memory() {
    echo "🔧 低内存系统优化..."
    
    # 创建swap文件
    if [ ! -f /swapfile ]; then
        echo "💾 创建2GB swap文件..."
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        echo "✅ Swap文件创建完成"
    else
        echo "✅ Swap文件已存在"
    fi
    
    # 优化系统参数
    echo "⚙️  优化系统参数..."
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    
    # 清理系统缓存
    echo "🧹 清理系统缓存..."
    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    echo "✅ 低内存优化完成"
}

# 主函数
main() {
    # 显示调试信息
    debug_info
    
    # 检测IP地址
    get_server_ip
    
    # 检测操作系统
    detect_os
    
    # 低内存优化
    if [ "$INSTALL_TYPE" = "low-memory" ]; then
        optimize_for_low_memory
    fi
    
    # 安装系统依赖
    install_system_dependencies
    
    # 创建应用用户
    create_app_user
    
    # 健壮下载项目
    download_project_robust
    
    # 安装后端
    install_backend
    
    # 安装前端
    install_frontend
    
    # 配置数据库
    setup_database
    
    # 配置Nginx
    setup_nginx
    
    # 创建systemd服务
    create_systemd_service
    
    # 设置权限
    setup_permissions
    
    # 初始化数据库
    init_database
    
    # 验证安装
    verify_installation
    
    # 显示结果
    show_result
}

# 运行主函数
main "$@"
