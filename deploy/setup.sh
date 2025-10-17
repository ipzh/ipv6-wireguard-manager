#!/bin/bash

# IPv6 WireGuard Manager 部署系统快速设置脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查rsync
    if ! command -v rsync &> /dev/null; then
        missing_deps+=("rsync")
    fi
    
    # 检查ssh
    if ! command -v ssh &> /dev/null; then
        missing_deps+=("openssh-client")
    fi
    
    # 检查tar
    if ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        
        # 提供安装建议
        if command -v apt-get &> /dev/null; then
            log_info "Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            log_info "CentOS/RHEL: sudo yum install ${missing_deps[*]}"
        elif command -v brew &> /dev/null; then
            log_info "macOS: brew install ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    log_success "系统依赖检查通过"
}

# 创建配置文件
create_config() {
    local config_file="deploy.conf"
    
    if [ -f "$config_file" ]; then
        log_warning "配置文件已存在: $config_file"
        read -p "是否覆盖现有配置? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "跳过配置文件创建"
            return
        fi
    fi
    
    log_info "创建配置文件..."
    
    cat > "$config_file" << 'EOF'
# IPv6 WireGuard Manager 部署配置文件
# 请根据实际情况修改以下配置

# 远程服务器配置
REMOTE_HOST=your-server.com
REMOTE_USER=root
REMOTE_PORT=22
REMOTE_PATH=/var/www/ipv6-wireguard-manager

# 本地配置
LOCAL_FRONTEND_PATH=php-frontend
BACKUP_PATH=backups
LOG_PATH=logs

# 部署选项
CREATE_BACKUP=true
RESTART_SERVICES=true
CLEAR_CACHE=true
RUN_TESTS=false

# 服务配置
WEB_SERVER=nginx
PHP_SERVICE=php8.1-fpm
EOF
    
    log_success "配置文件已创建: $config_file"
    log_warning "请编辑配置文件并设置正确的服务器信息"
}

# 设置脚本权限
set_permissions() {
    log_info "设置脚本执行权限..."
    
    chmod +x deploy.sh
    
    if [ -f "deploy.bat" ]; then
        log_info "Windows批处理脚本已准备就绪"
    fi
    
    if [ -f "deploy.ps1" ]; then
        log_info "PowerShell脚本已准备就绪"
    fi
    
    log_success "脚本权限设置完成"
}

# 创建SSH密钥
create_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_rsa"
    
    if [ -f "$key_file" ]; then
        log_info "SSH密钥已存在: $key_file"
        return
    fi
    
    log_info "创建SSH密钥..."
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    ssh-keygen -t rsa -b 4096 -f "$key_file" -N "" -C "ipv6-wireguard-deploy"
    
    log_success "SSH密钥已创建: $key_file"
    log_info "请将公钥复制到远程服务器:"
    echo "ssh-copy-id -p 22 user@your-server.com"
    echo "或者手动复制以下公钥内容:"
    cat "$key_file.pub"
}

# 测试连接
test_connection() {
    local config_file="deploy.conf"
    
    if [ ! -f "$config_file" ]; then
        log_warning "配置文件不存在，跳过连接测试"
        return
    fi
    
    # 加载配置
    source "$config_file"
    
    if [ "$REMOTE_HOST" = "your-server.com" ]; then
        log_warning "请先配置正确的服务器信息"
        return
    fi
    
    log_info "测试SSH连接..."
    
    if ssh -p "$REMOTE_PORT" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH连接成功'" 2>/dev/null; then
        log_success "SSH连接测试通过"
    else
        log_error "SSH连接失败"
        log_info "请检查以下项目:"
        echo "1. 服务器地址和端口是否正确"
        echo "2. 用户名是否正确"
        echo "3. SSH密钥是否已配置"
        echo "4. 服务器是否允许SSH连接"
    fi
}

# 显示使用说明
show_usage() {
    log_info "部署系统设置完成！"
    echo
    echo "使用方法:"
    echo "  Linux/macOS: ./deploy.sh production --backup"
    echo "  Windows:     deploy\\deploy.bat production --backup"
    echo "  PowerShell:  .\\deploy.ps1 production -Backup"
    echo
    echo "下一步:"
    echo "1. 编辑 deploy.conf 配置文件"
    echo "2. 配置SSH密钥认证"
    echo "3. 测试连接: ./deploy.sh production --dry-run"
    echo "4. 执行部署: ./deploy.sh production --backup"
    echo
    echo "更多信息请查看 README.md 文件"
}

# 主函数
main() {
    log_info "IPv6 WireGuard Manager 部署系统快速设置"
    echo
    
    check_dependencies
    create_config
    set_permissions
    
    read -p "是否创建SSH密钥? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_ssh_key
    fi
    
    read -p "是否测试SSH连接? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_connection
    fi
    
    show_usage
}

# 执行主函数
main "$@"
