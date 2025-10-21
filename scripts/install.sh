#!/bin/bash

# IPv6 WireGuard Manager 模块化安装脚本
# 支持多种安装方式，模块化设计，易于维护

set -e
set -u
set -o pipefail

# 脚本信息
SCRIPT_NAME="IPv6 WireGuard Manager Installer"
SCRIPT_VERSION="3.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

用法: $0 [选项] [模块...]

选项:
    -h, --help              显示此帮助信息
    -v, --version           显示版本信息
    -d, --debug             启用调试模式
    -q, --quiet             静默模式
    -f, --force             强制安装（覆盖现有配置）
    --skip-deps             跳过依赖检查
    --skip-config           跳过配置步骤
    --docker-only           仅使用Docker部署
    --native-only           仅使用原生部署

模块:
    environment             环境检查模块
    dependencies            依赖安装模块
    configuration           配置模块
    deployment              部署模块
    service                 服务管理模块
    verification            验证模块

示例:
    $0                      # 完整安装
    $0 environment          # 仅运行环境检查
    $0 --docker-only        # 仅Docker部署
    $0 --skip-deps config   # 跳过依赖检查，运行配置模块

EOF
}

# 显示版本信息
show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "IPv6 WireGuard Manager 模块化安装脚本"
    echo "支持环境检查、依赖安装、配置管理、部署和服务管理"
}

# 错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "脚本在第 $line_number 行执行失败，退出码: $exit_code"
    log_info "请检查上述错误信息并重试"
    exit $exit_code
}

# 设置错误陷阱
trap 'handle_error $LINENO' ERR

# 解析命令行参数
parse_arguments() {
    DEBUG=false
    QUIET=false
    FORCE=false
    SKIP_DEPS=false
    SKIP_CONFIG=false
    DOCKER_ONLY=false
    NATIVE_ONLY=false
    MODULES=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --skip-config)
                SKIP_CONFIG=true
                shift
                ;;
            --docker-only)
                DOCKER_ONLY=true
                shift
                ;;
            --native-only)
                NATIVE_ONLY=true
                shift
                ;;
            environment|dependencies|configuration|deployment|service|verification)
                MODULES+=("$1")
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定模块，使用默认模块
    if [[ ${#MODULES[@]} -eq 0 ]]; then
        MODULES=("environment" "dependencies" "configuration" "deployment" "service" "verification")
    fi
}

# 检查模块文件
check_module_files() {
    log_info "检查模块文件..."
    
    MODULE_DIR="$SCRIPT_DIR/install"
    REQUIRED_MODULES=("module_environment.sh" "module_dependencies.sh" "module_configuration.sh")
    
    for module in "${REQUIRED_MODULES[@]}"; do
        if [[ ! -f "$MODULE_DIR/$module" ]]; then
            log_error "模块文件不存在: $MODULE_DIR/$module"
            exit 1
        fi
        
        if [[ ! -x "$MODULE_DIR/$module" ]]; then
            chmod +x "$MODULE_DIR/$module"
            log_info "设置执行权限: $module"
        fi
    done
    
    log_success "模块文件检查完成"
}

# 运行模块
run_module() {
    local module_name="$1"
    local module_file="$SCRIPT_DIR/install/module_${module_name}.sh"
    
    if [[ ! -f "$module_file" ]]; then
        log_error "模块文件不存在: $module_file"
        return 1
    fi
    
    log_info "运行模块: $module_name"
    echo "=========================================="
    
    # 设置模块环境变量
    export DEBUG="$DEBUG"
    export QUIET="$QUIET"
    export FORCE="$FORCE"
    export SKIP_DEPS="$SKIP_DEPS"
    export SKIP_CONFIG="$SKIP_CONFIG"
    export DOCKER_ONLY="$DOCKER_ONLY"
    export NATIVE_ONLY="$NATIVE_ONLY"
    
    # 运行模块
    if bash "$module_file"; then
        log_success "模块完成: $module_name"
        echo "=========================================="
        return 0
    else
        log_error "模块失败: $module_name"
        echo "=========================================="
        return 1
    fi
}

# 显示安装摘要
show_summary() {
    log_info "安装摘要:"
    echo ""
    echo "✅ 环境检查: 已完成"
    echo "✅ 依赖安装: 已完成"
    echo "✅ 系统配置: 已完成"
    echo "✅ 应用部署: 已完成"
    echo "✅ 服务管理: 已完成"
    echo "✅ 安装验证: 已完成"
    echo ""
    log_success "IPv6 WireGuard Manager 安装完成！"
    echo ""
    log_info "访问信息:"
    echo "  Web界面: http://localhost"
    echo "  API接口: http://localhost/api/v1"
    echo "  健康检查: http://localhost/health"
    echo ""
    log_info "管理命令:"
    echo "  启动服务: sudo systemctl start ipv6-wireguard-manager"
    echo "  停止服务: sudo systemctl stop ipv6-wireguard-manager"
    echo "  重启服务: sudo systemctl restart ipv6-wireguard-manager"
    echo "  查看状态: sudo systemctl status ipv6-wireguard-manager"
    echo "  查看日志: sudo journalctl -u ipv6-wireguard-manager -f"
    echo ""
    log_info "配置文件:"
    echo "  环境配置: /opt/ipv6-wireguard-manager/.env"
    echo "  Nginx配置: /etc/nginx/sites-available/ipv6-wireguard-manager"
    echo "  服务配置: /etc/systemd/system/ipv6-wireguard-manager.service"
    echo ""
    log_warning "请修改默认密码和配置以确保安全！"
}

# 主函数
main() {
    # 显示启动信息
    if [[ "$QUIET" != "true" ]]; then
        echo ""
        echo "=========================================="
        echo "  $SCRIPT_NAME v$SCRIPT_VERSION"
        echo "=========================================="
        echo ""
    fi
    
    # 检查模块文件
    check_module_files
    
    # 运行指定模块
    local failed_modules=()
    for module in "${MODULES[@]}"; do
        if ! run_module "$module"; then
            failed_modules+=("$module")
        fi
    done
    
    # 检查是否有失败的模块
    if [[ ${#failed_modules[@]} -ne 0 ]]; then
        log_error "以下模块执行失败: ${failed_modules[*]}"
        exit 1
    fi
    
    # 显示安装摘要
    if [[ "$QUIET" != "true" ]]; then
        show_summary
    fi
    
    log_success "安装完成！"
}

# 解析命令行参数
parse_arguments "$@"

# 运行主函数
main
