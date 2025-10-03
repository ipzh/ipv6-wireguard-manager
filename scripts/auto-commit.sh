#!/bin/bash

# IPv6 WireGuard Manager 自动提交脚本
# 监控文件变化并自动提交到Git仓库

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
WATCH_INTERVAL=30  # 监控间隔（秒）
AUTO_PUSH=true     # 是否自动推送到远程仓库
COMMIT_PREFIX="auto"  # 自动提交前缀

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 检查Git仓库状态
check_git_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是Git仓库"
        exit 1
    fi
    
    if ! git remote get-url origin > /dev/null 2>&1; then
        log_warn "未配置远程仓库origin"
        AUTO_PUSH=false
    fi
}

# 生成提交信息
generate_commit_message() {
    local changed_files=$(git diff --cached --name-only | wc -l)
    local deleted_files=$(git diff --cached --diff-filter=D --name-only | wc -l)
    local added_files=$(git diff --cached --diff-filter=A --name-only | wc -l)
    local modified_files=$(git diff --cached --diff-filter=M --name-only | wc -l)
    
    local message="${COMMIT_PREFIX}: 自动提交 - "
    
    if [[ $added_files -gt 0 ]]; then
        message+="新增${added_files}个文件 "
    fi
    
    if [[ $modified_files -gt 0 ]]; then
        message+="修改${modified_files}个文件 "
    fi
    
    if [[ $deleted_files -gt 0 ]]; then
        message+="删除${deleted_files}个文件 "
    fi
    
    message+="($(date '+%H:%M:%S'))"
    
    echo "$message"
}

# 自动提交函数
auto_commit() {
    # 检查是否有变化
    if git diff --quiet && git diff --cached --quiet; then
        return 0
    fi
    
    log_info "检测到文件变化，准备自动提交..."
    
    # 显示变化的文件
    local changed_files=$(git status --porcelain)
    if [[ -n "$changed_files" ]]; then
        log_info "变化的文件:"
        echo "$changed_files" | while read -r line; do
            echo "  $line"
        done
    fi
    
    # 添加所有变化到暂存区
    git add -A
    
    # 检查是否有暂存的变化
    if git diff --cached --quiet; then
        log_info "没有需要提交的变化"
        return 0
    fi
    
    # 生成提交信息
    local commit_message=$(generate_commit_message)
    
    # 提交变化
    if git commit -m "$commit_message"; then
        log_success "自动提交成功: $commit_message"
        
        # 自动推送到远程仓库
        if [[ "$AUTO_PUSH" == "true" ]]; then
            log_info "推送到远程仓库..."
            if git push origin $(git branch --show-current) 2>/dev/null; then
                log_success "推送成功"
            else
                log_warn "推送失败，可能需要手动推送"
            fi
        fi
    else
        log_error "提交失败"
        return 1
    fi
}

# 监控循环
monitor_changes() {
    log_info "开始监控文件变化..."
    log_info "监控间隔: ${WATCH_INTERVAL}秒"
    log_info "自动推送: $AUTO_PUSH"
    log_info "按 Ctrl+C 停止监控"
    
    while true; do
        auto_commit
        sleep $WATCH_INTERVAL
    done
}

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 自动提交脚本

用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -i, --interval SECONDS  设置监控间隔（默认: 30秒）
  -p, --push              启用自动推送到远程仓库
  -n, --no-push           禁用自动推送
  --prefix PREFIX         设置提交信息前缀（默认: auto）
  --once                  只执行一次检查和提交
  --status                显示当前Git状态

示例:
  $0                      # 使用默认设置开始监控
  $0 -i 60 -p            # 60秒间隔，启用自动推送
  $0 --once              # 只执行一次提交
  $0 --status            # 显示Git状态
EOF
}

# 显示Git状态
show_status() {
    log_info "Git仓库状态:"
    git status --short
    
    log_info "最近的提交:"
    git log --oneline -5
    
    if git remote get-url origin > /dev/null 2>&1; then
        log_info "远程仓库: $(git remote get-url origin)"
        log_info "当前分支: $(git branch --show-current)"
    fi
}

# 信号处理
cleanup() {
    log_info "收到停止信号，正在清理..."
    log_info "自动提交监控已停止"
    exit 0
}

trap cleanup SIGINT SIGTERM

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--interval)
            WATCH_INTERVAL="$2"
            shift 2
            ;;
        -p|--push)
            AUTO_PUSH=true
            shift
            ;;
        -n|--no-push)
            AUTO_PUSH=false
            shift
            ;;
        --prefix)
            COMMIT_PREFIX="$2"
            shift 2
            ;;
        --once)
            check_git_status
            auto_commit
            exit $?
            ;;
        --status)
            check_git_status
            show_status
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 主程序
main() {
    log_info "IPv6 WireGuard Manager 自动提交脚本启动"
    
    # 检查Git仓库
    check_git_status
    
    # 开始监控
    monitor_changes
}

# 运行主程序
main "$@"