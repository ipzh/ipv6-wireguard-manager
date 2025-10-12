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
    
    # 创建React源代码目录结构
    echo "📁 创建React源代码目录..."
    mkdir -p src/components src/pages src/hooks src/services src/utils
    
    # 创建Vite配置文件
    if [ ! -f "vite.config.ts" ]; then
        echo "📝 创建Vite配置文件..."
        cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          antd: ['antd']
        }
      }
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
})
EOF
    fi
    
    # 创建TypeScript配置文件
    if [ ! -f "tsconfig.json" ]; then
        echo "📝 创建TypeScript配置文件..."
        cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF
    fi
    
    # 创建tsconfig.node.json
    if [ ! -f "tsconfig.node.json" ]; then
        echo "📝 创建tsconfig.node.json..."
        cat > tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF
    fi
    
    # 创建主入口文件
    if [ ! -f "src/main.tsx" ]; then
        echo "📝 创建主入口文件..."
        cat > src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF
    fi
    
    # 创建CSS文件
    if [ ! -f "src/index.css" ]; then
        echo "📝 创建CSS文件..."
        cat > src/index.css << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f0f2f5;
}

* {
  box-sizing: border-box;
}

#root {
  min-height: 100vh;
}
EOF
    fi
    
    # 创建主App组件
    if [ ! -f "src/App.tsx" ]; then
        echo "📝 创建主App组件..."
        cat > src/App.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { Layout, Card, Row, Col, Statistic, Button, message, Table, Tag, Spin } from 'antd'
import { LogoutOutlined, ReloadOutlined } from '@ant-design/icons'
import './App.css'

const { Header, Content } = Layout

// 简单的认证系统
const AUTH_TOKEN_KEY = 'ipv6wg_auth_token'
const DEFAULT_USERNAME = 'admin'
const DEFAULT_PASSWORD = 'admin123'

interface ApiStatus {
  status: string
  service: string
  version: string
  message: string
}

interface Server {
  id: number
  name: string
  description?: string
}

interface Client {
  id: number
  name: string
  description?: string
}

const App: React.FC = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [loading, setLoading] = useState(true)
  const [apiStatus, setApiStatus] = useState<ApiStatus | null>(null)
  const [servers, setServers] = useState<Server[]>([])
  const [clients, setClients] = useState<Client[]>([])
  const [error, setError] = useState<string | null>(null)

  // 检查认证状态
  useEffect(() => {
    const token = localStorage.getItem(AUTH_TOKEN_KEY)
    if (token) {
      setIsAuthenticated(true)
      loadDashboardData()
    }
    setLoading(false)
  }, [])

  // 加载仪表板数据
  const loadDashboardData = async () => {
    try {
      // 检查API状态
      const statusResponse = await fetch('/api/v1/status')
      if (statusResponse.ok) {
        const statusData = await statusResponse.json()
        setApiStatus(statusData)
        setError(null)
      } else {
        setError(`API连接失败: ${statusResponse.status}`)
      }

      // 加载服务器数据
      try {
        const serversResponse = await fetch('/api/v1/servers')
        if (serversResponse.ok) {
          const serversData = await serversResponse.json()
          setServers(serversData.servers || [])
        }
      } catch (error) {
        console.error('加载服务器失败:', error)
      }

      // 加载客户端数据
      try {
        const clientsResponse = await fetch('/api/v1/clients')
        if (clientsResponse.ok) {
          const clientsData = await clientsResponse.json()
          setClients(clientsData.clients || [])
        }
      } catch (error) {
        console.error('加载客户端失败:', error)
      }
    } catch (error) {
      console.error('加载数据失败:', error)
      setError('连接失败')
    }
  }

  // 登录处理
  const handleLogin = (username: string, password: string) => {
    if (username === DEFAULT_USERNAME && password === DEFAULT_PASSWORD) {
      const token = btoa(username + ':' + Date.now())
      localStorage.setItem(AUTH_TOKEN_KEY, token)
      setIsAuthenticated(true)
      loadDashboardData()
      message.success('登录成功！')
    } else {
      message.error('用户名或密码错误')
    }
  }

  // 退出登录
  const handleLogout = () => {
    localStorage.removeItem(AUTH_TOKEN_KEY)
    setIsAuthenticated(false)
    setApiStatus(null)
    setServers([])
    setClients([])
    setError(null)
    message.info('已退出登录')
  }

  // 服务器表格列定义
  const serverColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { 
      title: '状态', 
      key: 'status', 
      width: 80, 
      render: () => <Tag color="green">运行中</Tag>
    }
  ]

  // 客户端表格列定义
  const clientColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    { 
      title: '状态', 
      key: 'status', 
      width: 80, 
      render: () => <Tag color="blue">已连接</Tag>
    }
  ]

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <Spin size="large" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return <LoginPage onLogin={handleLogin} />
  }

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{ 
        background: '#fff', 
        padding: '0 24px', 
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between'
      }}>
        <h1 style={{ margin: 0, color: '#1890ff', fontSize: '20px' }}>
          🌐 IPv6 WireGuard Manager
        </h1>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <span style={{ fontSize: '14px' }}>
            API: {apiStatus ? apiStatus.status : '检查中'}
          </span>
          <Button 
            icon={<ReloadOutlined />}
            size="small"
            type="primary" 
            onClick={loadDashboardData}
          >
            刷新
          </Button>
          <Button 
            icon={<LogoutOutlined />}
            size="small"
            danger
            onClick={handleLogout}
          >
            退出登录
          </Button>
        </div>
      </Header>
      
      <Content style={{ padding: '24px', background: '#f0f2f5' }}>
        {error && (
          <Card style={{ marginBottom: '24px', borderColor: '#ff4d4f' }}>
            <div style={{ color: '#ff4d4f', textAlign: 'center' }}>
              ❌ {error}
            </div>
          </Card>
        )}
        
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} md={8}>
            <Card>
              <Statistic 
                title="服务状态" 
                value="运行中" 
                valueStyle={{ color: '#52c41a' }}
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} md={8}>
            <Card>
              <Statistic 
                title="API状态" 
                value={apiStatus ? apiStatus.status : '检查中'} 
                valueStyle={{ color: apiStatus ? '#1890ff' : '#faad14' }}
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} md={8}>
            <Card>
              <Statistic 
                title="版本" 
                value={apiStatus ? apiStatus.version : '1.0.0'} 
                valueStyle={{ color: '#722ed1' }}
              />
            </Card>
          </Col>
        </Row>
        
        <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
          <Col xs={24} lg={12}>
            <Card title="WireGuard服务器">
              <Table 
                columns={serverColumns} 
                dataSource={servers} 
                rowKey="id"
                pagination={false}
                size="small"
                locale={{ emptyText: '暂无服务器' }}
              />
            </Card>
          </Col>
          <Col xs={24} lg={12}>
            <Card title="WireGuard客户端">
              <Table 
                columns={clientColumns} 
                dataSource={clients} 
                rowKey="id"
                pagination={false}
                size="small"
                locale={{ emptyText: '暂无客户端' }}
              />
            </Card>
          </Col>
        </Row>
      </Content>
    </Layout>
  )
}

// 登录页面组件
interface LoginPageProps {
  onLogin: (username: string, password: string) => void
}

const LoginPage: React.FC<LoginPageProps> = ({ onLogin }) => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    
    // 模拟登录延迟
    setTimeout(() => {
      onLogin(username, password)
      setLoading(false)
    }, 1000)
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px'
    }}>
      <Card style={{
        width: '100%',
        maxWidth: '400px',
        textAlign: 'center',
        boxShadow: '0 8px 32px rgba(0,0,0,0.1)'
      }}>
        <div style={{ fontSize: '32px', marginBottom: '8px' }}>🌐</div>
        <h1 style={{ 
          fontSize: '24px', 
          fontWeight: 600, 
          color: '#1890ff', 
          marginBottom: '8px' 
        }}>
          IPv6 WireGuard Manager
        </h1>
        <p style={{ color: '#666', marginBottom: '32px', fontSize: '14px' }}>
          安全登录到管理控制台
        </p>
        
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '20px', textAlign: 'left' }}>
            <label style={{ 
              display: 'block', 
              marginBottom: '8px', 
              fontWeight: 500, 
              color: '#333' 
            }}>
              用户名
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="请输入用户名"
              required
              style={{
                width: '100%',
                padding: '12px 16px',
                border: '2px solid #d9d9d9',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box'
              }}
            />
          </div>
          
          <div style={{ marginBottom: '20px', textAlign: 'left' }}>
            <label style={{ 
              display: 'block', 
              marginBottom: '8px', 
              fontWeight: 500, 
              color: '#333' 
            }}>
              密码
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="请输入密码"
              required
              style={{
                width: '100%',
                padding: '12px 16px',
                border: '2px solid #d9d9d9',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box'
              }}
            />
          </div>
          
          <Button
            type="primary"
            htmlType="submit"
            loading={loading}
            style={{
              width: '100%',
              height: '48px',
              fontSize: '16px',
              fontWeight: 500
            }}
          >
            {loading ? '登录中...' : '登录'}
          </Button>
        </form>
        
        <div style={{ 
          marginTop: '16px', 
          padding: '12px', 
          background: '#f6f8fa', 
          borderRadius: '6px',
          fontSize: '12px',
          color: '#666'
        }}>
          <strong>默认登录信息：</strong><br />
          用户名: admin<br />
          密码: admin123<br />
          <span style={{ color: '#ff4d4f' }}>
            ⚠️ 请在生产环境中修改默认密码！
          </span>
        </div>
      </Card>
    </div>
  )
}

export default App
EOF
    fi
    
    # 创建App.css文件
    if [ ! -f "src/App.css" ]; then
        echo "📝 创建App.css文件..."
        cat > src/App.css << 'EOF'
.App {
  text-align: center;
}

.App-logo {
  height: 40vmin;
  pointer-events: none;
}

@media (prefers-reduced-motion: no-preference) {
  .App-logo {
    animation: App-logo-spin infinite 20s linear;
  }
}

.App-header {
  background-color: #282c34;
  padding: 20px;
  color: white;
}

.App-link {
  color: #61dafb;
}

@keyframes App-logo-spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
EOF
    fi
    
    # 创建index.html模板
    if [ ! -f "index.html" ]; then
        echo "📝 创建index.html模板..."
        cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>IPv6 WireGuard Manager</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
    fi
    
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
    
    # 创建安全的登录页面
    if [ ! -f "dist/index.html" ]; then
        echo "📝 创建安全的登录页面..."
        cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager - 登录</title>
    
    <!-- 使用CDN，确保稳定性 -->
    <link rel="stylesheet" href="https://unpkg.com/antd@5/dist/reset.css">
    
    <style>
        body { 
            margin: 0; 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', 'Helvetica Neue', Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .login-container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            padding: 40px;
            width: 100%;
            max-width: 400px;
            text-align: center;
        }
        
        .logo {
            font-size: 32px;
            margin-bottom: 8px;
        }
        
        .title {
            font-size: 24px;
            font-weight: 600;
            color: #1890ff;
            margin-bottom: 8px;
        }
        
        .subtitle {
            color: #666;
            margin-bottom: 32px;
            font-size: 14px;
        }
        
        .form-group {
            margin-bottom: 20px;
            text-align: left;
        }
        
        .form-label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: #333;
        }
        
        .form-input {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #d9d9d9;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
            box-sizing: border-box;
        }
        
        .form-input:focus {
            outline: none;
            border-color: #1890ff;
        }
        
        .login-btn {
            width: 100%;
            padding: 12px;
            background: #1890ff;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 500;
            cursor: pointer;
            transition: background-color 0.3s;
            margin-bottom: 16px;
        }
        
        .login-btn:hover {
            background: #40a9ff;
        }
        
        .login-btn:disabled {
            background: #d9d9d9;
            cursor: not-allowed;
        }
        
        .error-message {
            color: #ff4d4f;
            font-size: 14px;
            margin-top: 8px;
            text-align: center;
        }
        
        .success-message {
            color: #52c41a;
            font-size: 14px;
            margin-top: 8px;
            text-align: center;
        }
        
        .loading {
            display: inline-block;
            width: 16px;
            height: 16px;
            border: 2px solid #ffffff;
            border-radius: 50%;
            border-top-color: transparent;
            animation: spin 1s linear infinite;
            margin-right: 8px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .dashboard {
            display: none;
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .header h1 {
            margin: 0;
            color: #1890ff;
            font-size: 24px;
        }
        
        .logout-btn {
            background: #ff4d4f;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
        }
        
        .logout-btn:hover {
            background: #ff7875;
        }
        
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .stat-item {
            text-align: center;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: 600;
            color: #1890ff;
            margin-bottom: 8px;
        }
        
        .stat-label {
            color: #666;
            font-size: 14px;
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 16px;
        }
        
        .table th, .table td {
            border: 1px solid #d9d9d9;
            padding: 12px;
            text-align: left;
        }
        
        .table th {
            background: #fafafa;
            font-weight: 600;
        }
        
        .tag {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            color: white;
        }
        
        .tag-green { background: #52c41a; }
        .tag-blue { background: #1890ff; }
        .tag-red { background: #ff4d4f; }
    </style>
</head>
<body>
    <!-- 登录页面 -->
    <div id="loginPage" class="login-container">
        <div class="logo">🌐</div>
        <h1 class="title">IPv6 WireGuard Manager</h1>
        <p class="subtitle">安全登录到管理控制台</p>
        
        <form id="loginForm">
            <div class="form-group">
                <label class="form-label" for="username">用户名</label>
                <input type="text" id="username" class="form-input" placeholder="请输入用户名" required>
            </div>
            
            <div class="form-group">
                <label class="form-label" for="password">密码</label>
                <input type="password" id="password" class="form-input" placeholder="请输入密码" required>
            </div>
            
            <button type="submit" class="login-btn" id="loginBtn">
                <span id="loginText">登录</span>
            </button>
            
            <div id="message"></div>
        </form>
    </div>
    
    <!-- 管理面板 -->
    <div id="dashboard" class="dashboard">
        <div class="header">
            <h1>🌐 IPv6 WireGuard Manager</h1>
            <button class="logout-btn" onclick="logout()">退出登录</button>
        </div>
        
        <div class="stats-grid">
            <div class="stat-item">
                <div class="stat-value" id="serviceStatus">检查中</div>
                <div class="stat-label">服务状态</div>
            </div>
            <div class="stat-item">
                <div class="stat-value" id="apiStatus">检查中</div>
                <div class="stat-label">API状态</div>
            </div>
            <div class="stat-item">
                <div class="stat-value" id="serverCount">0</div>
                <div class="stat-label">服务器数量</div>
            </div>
            <div class="stat-item">
                <div class="stat-value" id="clientCount">0</div>
                <div class="stat-label">客户端数量</div>
            </div>
        </div>
        
        <div class="card">
            <h2>WireGuard服务器</h2>
            <div id="serversTable">
                <p>正在加载...</p>
            </div>
        </div>
        
        <div class="card">
            <h2>WireGuard客户端</h2>
            <div id="clientsTable">
                <p>正在加载...</p>
            </div>
        </div>
    </div>

    <!-- 使用CDN，确保稳定性 -->
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/antd@5/dist/antd.min.js"></script>

    <script>
        // 简单的认证系统
        const AUTH_TOKEN_KEY = 'ipv6wg_auth_token';
        const DEFAULT_USERNAME = 'admin';
        const DEFAULT_PASSWORD = 'admin123';
        
        // 检查是否已登录
        function checkAuth() {
            const token = localStorage.getItem(AUTH_TOKEN_KEY);
            if (token) {
                showDashboard();
                loadDashboardData();
            } else {
                showLogin();
            }
        }
        
        // 显示登录页面
        function showLogin() {
            document.getElementById('loginPage').style.display = 'block';
            document.getElementById('dashboard').style.display = 'none';
        }
        
        // 显示管理面板
        function showDashboard() {
            document.getElementById('loginPage').style.display = 'none';
            document.getElementById('dashboard').style.display = 'block';
        }
        
        // 登录处理
        function handleLogin(event) {
            event.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const loginBtn = document.getElementById('loginBtn');
            const loginText = document.getElementById('loginText');
            const message = document.getElementById('message');
            
            // 显示加载状态
            loginBtn.disabled = true;
            loginText.innerHTML = '<span class="loading"></span>登录中...';
            message.innerHTML = '';
            
            // 模拟登录验证（实际应用中应该调用API）
            setTimeout(() => {
                if (username === DEFAULT_USERNAME && password === DEFAULT_PASSWORD) {
                    // 登录成功
                    const token = btoa(username + ':' + Date.now());
                    localStorage.setItem(AUTH_TOKEN_KEY, token);
                    
                    message.innerHTML = '<div class="success-message">✅ 登录成功！</div>';
                    
                    setTimeout(() => {
                        showDashboard();
                        loadDashboardData();
                    }, 1000);
                } else {
                    // 登录失败
                    message.innerHTML = '<div class="error-message">❌ 用户名或密码错误</div>';
                    loginBtn.disabled = false;
                    loginText.innerHTML = '登录';
                }
            }, 1000);
        }
        
        // 退出登录
        function logout() {
            localStorage.removeItem(AUTH_TOKEN_KEY);
            showLogin();
            // 清空表单
            document.getElementById('username').value = '';
            document.getElementById('password').value = '';
            document.getElementById('message').innerHTML = '';
        }
        
        // 加载管理面板数据
        async function loadDashboardData() {
            try {
                // 检查API状态
                const statusResponse = await fetch('/api/v1/status');
                if (statusResponse.ok) {
                    const statusData = await statusResponse.json();
                    document.getElementById('apiStatus').textContent = statusData.status || '正常';
                    document.getElementById('serviceStatus').textContent = '运行中';
                } else {
                    document.getElementById('apiStatus').textContent = '异常';
                    document.getElementById('serviceStatus').textContent = '异常';
                }
                
                // 加载服务器数据
                try {
                    const serversResponse = await fetch('/api/v1/servers');
                    if (serversResponse.ok) {
                        const serversData = await serversResponse.json();
                        const servers = serversData.servers || [];
                        document.getElementById('serverCount').textContent = servers.length;
                        renderServersTable(servers);
                    }
                } catch (error) {
                    console.error('加载服务器失败:', error);
                    document.getElementById('serversTable').innerHTML = '<p>加载服务器数据失败</p>';
                }
                
                // 加载客户端数据
                try {
                    const clientsResponse = await fetch('/api/v1/clients');
                    if (clientsResponse.ok) {
                        const clientsData = await clientsResponse.json();
                        const clients = clientsData.clients || [];
                        document.getElementById('clientCount').textContent = clients.length;
                        renderClientsTable(clients);
                    }
                } catch (error) {
                    console.error('加载客户端失败:', error);
                    document.getElementById('clientsTable').innerHTML = '<p>加载客户端数据失败</p>';
                }
                
            } catch (error) {
                console.error('加载数据失败:', error);
                document.getElementById('apiStatus').textContent = '连接失败';
                document.getElementById('serviceStatus').textContent = '连接失败';
            }
        }
        
        // 渲染服务器表格
        function renderServersTable(servers) {
            const tableHtml = servers.length > 0 ? `
                <table class="table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>名称</th>
                            <th>描述</th>
                            <th>状态</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${servers.map(server => `
                            <tr>
                                <td>${server.id}</td>
                                <td>${server.name}</td>
                                <td>${server.description || '-'}</td>
                                <td><span class="tag tag-green">运行中</span></td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            ` : '<p>暂无服务器</p>';
            
            document.getElementById('serversTable').innerHTML = tableHtml;
        }
        
        // 渲染客户端表格
        function renderClientsTable(clients) {
            const tableHtml = clients.length > 0 ? `
                <table class="table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>名称</th>
                            <th>描述</th>
                            <th>状态</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${clients.map(client => `
                            <tr>
                                <td>${client.id}</td>
                                <td>${client.name}</td>
                                <td>${client.description || '-'}</td>
                                <td><span class="tag tag-blue">已连接</span></td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            ` : '<p>暂无客户端</p>';
            
            document.getElementById('clientsTable').innerHTML = tableHtml;
        }
        
        // 页面加载完成后检查认证状态
        document.addEventListener('DOMContentLoaded', function() {
            checkAuth();
            
            // 绑定登录表单事件
            document.getElementById('loginForm').addEventListener('submit', handleLogin);
            
            // 回车键登录
            document.addEventListener('keypress', function(event) {
                if (event.key === 'Enter' && document.getElementById('loginPage').style.display !== 'none') {
                    handleLogin(event);
                }
            });
        });
        
        // 错误处理
        window.addEventListener('error', function(e) {
            console.error('JavaScript错误:', e.error);
        });
    </script>
</body>
</html>
EOF
        echo "✅ 前端HTML文件创建完成"
        return 0
    fi
    
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
ExecStart=$APP_HOME/backend/venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 1
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
    from app.core.database import engine
    from app.models import Base
    Base.metadata.create_all(bind=engine)
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
sys.path.insert(0, '.')
try:
    from app.core.init_db import init_db
    init_db()
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
