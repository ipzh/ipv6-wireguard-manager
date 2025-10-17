#!/bin/bash

# IPv6 WireGuard Manager 前端自动部署脚本
# 使用方法: ./deploy.sh [环境] [选项]
# 示例: ./deploy.sh production --backup
#       ./deploy.sh staging --no-backup

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/deploy.conf"

# 默认配置
DEFAULT_CONFIG="
# 部署配置文件
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
"

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

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 前端自动部署脚本

使用方法:
    $0 [环境] [选项]

环境:
    production     生产环境部署
    staging        测试环境部署
    development    开发环境部署

选项:
    --backup       创建备份 (默认)
    --no-backup    不创建备份
    --restart      重启服务 (默认)
    --no-restart   不重启服务
    --cache        清除缓存 (默认)
    --no-cache     不清除缓存
    --test         运行测试
    --dry-run      模拟运行，不执行实际部署
    --help         显示此帮助信息

示例:
    $0 production --backup
    $0 staging --no-backup --no-restart
    $0 production --dry-run

配置文件: $CONFIG_FILE
EOF
}

# 初始化配置文件
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "创建默认配置文件: $CONFIG_FILE"
        echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
        log_warning "请编辑配置文件 $CONFIG_FILE 并设置正确的服务器信息"
        exit 1
    fi
}

# 加载配置
load_config() {
    source "$CONFIG_FILE"
    
    # 验证必需的配置
    if [ -z "$REMOTE_HOST" ] || [ "$REMOTE_HOST" = "your-server.com" ]; then
        log_error "请在配置文件中设置正确的 REMOTE_HOST"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    log_info "检查部署依赖..."
    
    # 检查 rsync
    if ! command -v rsync &> /dev/null; then
        log_error "rsync 未安装，请先安装 rsync"
        exit 1
    fi
    
    # 检查 ssh
    if ! command -v ssh &> /dev/null; then
        log_error "ssh 未安装，请先安装 ssh"
        exit 1
    fi
    
    # 检查本地前端目录
    if [ ! -d "$PROJECT_ROOT/$LOCAL_FRONTEND_PATH" ]; then
        log_error "本地前端目录不存在: $PROJECT_ROOT/$LOCAL_FRONTEND_PATH"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 创建备份
create_backup() {
    if [ "$CREATE_BACKUP" = "true" ]; then
        log_info "创建远程备份..."
        
        local backup_name="frontend_backup_$(date +%Y%m%d_%H%M%S)"
        local backup_cmd="cd $REMOTE_PATH && tar -czf $BACKUP_PATH/$backup_name.tar.gz $LOCAL_FRONTEND_PATH"
        
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY RUN] 执行备份命令: $backup_cmd"
        else
            ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$backup_cmd"
            log_success "备份创建完成: $backup_name.tar.gz"
        fi
    fi
}

# 同步文件
sync_files() {
    log_info "同步前端文件到远程服务器..."
    
    local rsync_opts="-avz --delete --exclude='.git' --exclude='node_modules' --exclude='*.log'"
    
    if [ "$DRY_RUN" = "true" ]; then
        rsync_opts="$rsync_opts --dry-run"
        log_info "[DRY RUN] 模拟同步文件..."
    fi
    
    rsync $rsync_opts \
        -e "ssh -p $REMOTE_PORT" \
        "$PROJECT_ROOT/$LOCAL_FRONTEND_PATH/" \
        "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/$LOCAL_FRONTEND_PATH/"
    
    if [ "$DRY_RUN" != "true" ]; then
        log_success "文件同步完成"
    fi
}

# 设置权限
set_permissions() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] 设置文件权限..."
        return
    fi
    
    log_info "设置文件权限..."
    
    ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" << EOF
        cd $REMOTE_PATH/$LOCAL_FRONTEND_PATH
        
        # 设置目录权限
        find . -type d -exec chmod 755 {} \;
        
        # 设置文件权限
        find . -type f -exec chmod 644 {} \;
        
        # 设置可执行文件权限
        find . -name "*.sh" -exec chmod 755 {} \;
        
        # 设置日志目录权限
        mkdir -p logs
        chmod 777 logs
        
        # 设置缓存目录权限
        mkdir -p cache
        chmod 777 cache
EOF
    
    log_success "权限设置完成"
}

# 清除缓存
clear_cache() {
    if [ "$CLEAR_CACHE" = "true" ]; then
        log_info "清除缓存..."
        
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY RUN] 清除缓存..."
        else
            ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" << EOF
                cd $REMOTE_PATH/$LOCAL_FRONTEND_PATH
                
                # 清除PHP缓存
                find . -name "*.cache" -delete 2>/dev/null || true
                
                # 清除临时文件
                find . -name "*.tmp" -delete 2>/dev/null || true
                
                # 清除日志文件
                find logs -name "*.log" -mtime +7 -delete 2>/dev/null || true
EOF
            log_success "缓存清除完成"
        fi
    fi
}

# 重启服务
restart_services() {
    if [ "$RESTART_SERVICES" = "true" ]; then
        log_info "重启服务..."
        
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY RUN] 重启服务..."
        else
            ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" << EOF
                # 重启PHP服务
                systemctl restart $PHP_SERVICE
                
                # 重启Web服务器
                systemctl reload $WEB_SERVER
                
                # 检查服务状态
                systemctl is-active --quiet $PHP_SERVICE && echo "PHP服务运行正常" || echo "PHP服务异常"
                systemctl is-active --quiet $WEB_SERVER && echo "Web服务器运行正常" || echo "Web服务器异常"
EOF
            log_success "服务重启完成"
        fi
    fi
}

# 运行测试
run_tests() {
    if [ "$RUN_TESTS" = "true" ]; then
        log_info "运行部署测试..."
        
        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY RUN] 运行测试..."
        else
            ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" << EOF
                cd $REMOTE_PATH/$LOCAL_FRONTEND_PATH
                
                # 检查PHP语法
                find . -name "*.php" -exec php -l {} \; | grep -v "No syntax errors"
                
                # 检查文件完整性
                if [ -f "index.php" ]; then
                    echo "主入口文件存在"
                else
                    echo "主入口文件缺失"
                    exit 1
                fi
                
                # 检查配置文件
                if [ -f "config/config.php" ]; then
                    echo "配置文件存在"
                else
                    echo "配置文件缺失"
                    exit 1
                fi
EOF
            log_success "测试完成"
        fi
    fi
}

# 显示部署信息
show_deployment_info() {
    log_info "部署信息:"
    echo "  环境: $ENVIRONMENT"
    echo "  远程主机: $REMOTE_HOST:$REMOTE_PORT"
    echo "  远程路径: $REMOTE_PATH"
    echo "  本地路径: $PROJECT_ROOT/$LOCAL_FRONTEND_PATH"
    echo "  创建备份: $CREATE_BACKUP"
    echo "  重启服务: $RESTART_SERVICES"
    echo "  清除缓存: $CLEAR_CACHE"
    echo "  运行测试: $RUN_TESTS"
    echo "  模拟运行: $DRY_RUN"
    echo
}

# 主函数
main() {
    # 解析参数
    ENVIRONMENT=""
    DRY_RUN="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            production|staging|development)
                ENVIRONMENT="$1"
                shift
                ;;
            --backup)
                CREATE_BACKUP="true"
                shift
                ;;
            --no-backup)
                CREATE_BACKUP="false"
                shift
                ;;
            --restart)
                RESTART_SERVICES="true"
                shift
                ;;
            --no-restart)
                RESTART_SERVICES="false"
                shift
                ;;
            --cache)
                CLEAR_CACHE="true"
                shift
                ;;
            --no-cache)
                CLEAR_CACHE="false"
                shift
                ;;
            --test)
                RUN_TESTS="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查环境参数
    if [ -z "$ENVIRONMENT" ]; then
        log_error "请指定部署环境 (production/staging/development)"
        show_help
        exit 1
    fi
    
    # 初始化
    init_config
    load_config
    check_dependencies
    
    # 显示部署信息
    show_deployment_info
    
    # 确认部署
    if [ "$DRY_RUN" != "true" ]; then
        read -p "确认部署到 $ENVIRONMENT 环境? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            exit 0
        fi
    fi
    
    # 执行部署步骤
    log_info "开始部署到 $ENVIRONMENT 环境..."
    
    create_backup
    sync_files
    set_permissions
    clear_cache
    restart_services
    run_tests
    
    log_success "部署完成！"
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "这是模拟运行，没有实际修改远程服务器"
    fi
}

# 执行主函数
main "$@"
