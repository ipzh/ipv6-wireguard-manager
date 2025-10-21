#!/bin/bash

# 依赖安装模块
# 安装系统依赖和Python包

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测包管理器
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
        log_success "检测到APT包管理器"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
        log_success "检测到YUM包管理器"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
        log_success "检测到DNF包管理器"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
        log_success "检测到Pacman包管理器"
    elif command -v brew &> /dev/null; then
        PACKAGE_MANAGER="brew"
        log_success "检测到Homebrew包管理器"
    else
        log_error "未检测到支持的包管理器"
        exit 1
    fi
}

# 安装系统依赖
install_system_dependencies() {
    log_info "安装系统依赖..."
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt-get update
            sudo apt-get install -y \
                python3-pip \
                python3-venv \
                python3-dev \
                build-essential \
                libssl-dev \
                libffi-dev \
                libmysqlclient-dev \
                pkg-config \
                curl \
                wget \
                git \
                nginx \
                mysql-client \
                redis-tools
            ;;
        "yum"|"dnf")
            sudo $PACKAGE_MANAGER update -y
            sudo $PACKAGE_MANAGER install -y \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                openssl-devel \
                libffi-devel \
                mysql-devel \
                pkgconfig \
                curl \
                wget \
                git \
                nginx \
                mysql \
                redis
            ;;
        "pacman")
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm \
                python-pip \
                python-virtualenv \
                base-devel \
                openssl \
                libffi \
                mysql \
                pkg-config \
                curl \
                wget \
                git \
                nginx \
                redis
            ;;
        "brew")
            brew update
            brew install \
                python@3.11 \
                mysql \
                redis \
                nginx \
                curl \
                wget \
                git
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 安装Python依赖
install_python_dependencies() {
    log_info "安装Python依赖..."
    
    # 检查pip
    if ! command -v pip3 &> /dev/null; then
        log_error "pip3未安装，请先安装Python包管理器"
        exit 1
    fi
    
    # 升级pip
    pip3 install --upgrade pip
    
    # 安装基础依赖
    pip3 install --upgrade \
        setuptools \
        wheel \
        pip-tools
    
    # 安装项目依赖
    if [[ -f "backend/requirements.txt" ]]; then
        log_info "安装项目Python依赖..."
        pip3 install -r backend/requirements.txt
    else
        log_warning "requirements.txt不存在，跳过Python依赖安装"
    fi
    
    log_success "Python依赖安装完成"
}

# 安装PHP依赖
install_php_dependencies() {
    log_info "检查PHP扩展..."
    
    # 检查必需扩展
    REQUIRED_EXTENSIONS=("session" "json" "mbstring" "filter" "pdo" "pdo_mysql" "curl" "openssl")
    MISSING_EXTENSIONS=()
    
    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            MISSING_EXTENSIONS+=("$ext")
        fi
    done
    
    if [[ ${#MISSING_EXTENSIONS[@]} -ne 0 ]]; then
        log_warning "缺少PHP扩展: ${MISSING_EXTENSIONS[*]}"
        log_info "请手动安装缺少的扩展"
        
        case $PACKAGE_MANAGER in
            "apt")
                for ext in "${MISSING_EXTENSIONS[@]}"; do
                    case $ext in
                        "pdo_mysql")
                            sudo apt-get install -y php-mysql
                            ;;
                        "curl")
                            sudo apt-get install -y php-curl
                            ;;
                        "mbstring")
                            sudo apt-get install -y php-mbstring
                            ;;
                    esac
                done
                ;;
            "yum"|"dnf")
                for ext in "${MISSING_EXTENSIONS[@]}"; do
                    case $ext in
                        "pdo_mysql")
                            sudo $PACKAGE_MANAGER install -y php-mysql
                            ;;
                        "curl")
                            sudo $PACKAGE_MANAGER install -y php-curl
                            ;;
                        "mbstring")
                            sudo $PACKAGE_MANAGER install -y php-mbstring
                            ;;
                    esac
                done
                ;;
        esac
    else
        log_success "所有必需PHP扩展已安装"
    fi
}

# 安装Docker依赖
install_docker_dependencies() {
    if command -v docker &> /dev/null; then
        log_info "Docker已安装，跳过Docker安装"
        return
    fi
    
    log_info "安装Docker..."
    
    case $PACKAGE_MANAGER in
        "apt")
            # 安装Docker
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            rm get-docker.sh
            
            # 安装Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "yum"|"dnf")
            sudo $PACKAGE_MANAGER install -y docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
        "pacman")
            sudo pacman -S --noconfirm docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            ;;
        "brew")
            brew install docker docker-compose
            ;;
    esac
    
    # 添加用户到docker组
    if [[ $EUID -ne 0 ]]; then
        sudo usermod -aG docker $USER
        log_info "已将用户添加到docker组，请重新登录以生效"
    fi
    
    log_success "Docker安装完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 验证Python
    if python3 -c "import fastapi, sqlalchemy, pydantic" 2>/dev/null; then
        log_success "Python依赖验证通过"
    else
        log_warning "Python依赖验证失败，请检查安装"
    fi
    
    # 验证PHP
    if php -m | grep -q "pdo_mysql"; then
        log_success "PHP依赖验证通过"
    else
        log_warning "PHP依赖验证失败，请检查扩展安装"
    fi
    
    # 验证Docker
    if command -v docker &> /dev/null && docker --version >/dev/null 2>&1; then
        log_success "Docker验证通过"
    else
        log_warning "Docker验证失败，请检查安装"
    fi
}

# 主安装函数
install_dependencies() {
    log_info "开始安装依赖..."
    echo ""
    
    detect_package_manager
    install_system_dependencies
    install_python_dependencies
    install_php_dependencies
    install_docker_dependencies
    verify_installation
    
    echo ""
    log_success "依赖安装完成！"
    echo ""
    log_info "安装总结:"
    echo "  ✅ 系统依赖: 已安装"
    echo "  ✅ Python依赖: 已安装"
    echo "  ✅ PHP扩展: 已检查"
    echo "  ✅ Docker: 已安装"
    echo ""
    log_info "下一步: 运行配置模块"
}
