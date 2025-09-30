#!/bin/bash

# IPv6 WireGuard Manager 测试状态监控脚本
# 版本: 1.0.0

set -euo pipefail

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)" || exit

# 导入公共函数
if [[ -f "$PROJECT_ROOT/modules/common_functions.sh" ]]; then
    source "$PROJECT_ROOT/modules/common_functions.sh"
else
    echo "错误: 无法导入公共函数模块" >&2
    exit 1
fi

# 配置参数
MONITOR_INTERVAL=60  # 监控间隔（秒）
MAX_FAILURES=3       # 最大失败次数
NOTIFICATION_ENABLED=false  # 是否启用通知
LOG_FILE="/tmp/ipv6wgm_test_monitor.log"

# 显示帮助信息
show_help() {
    cat << EOF
IPv6 WireGuard Manager 测试状态监控脚本

用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -i, --interval SECONDS  设置监控间隔（默认: 60秒）
  -m, --max-failures NUM  设置最大失败次数（默认: 3）
  -n, --notify            启用通知
  -v, --verbose           详细输出
  -d, --daemon            后台运行

示例:
  $0 --interval 30 --notify
  $0 --daemon --max-failures 5
EOF
}

# 检查测试状态
check_test_status() {
    local test_type="$1"
    local start_time=$(date +%s)
    
    log_info "检查测试状态: $test_type"
    
    # 运行测试
    if bash "$PROJECT_ROOT/tests/run_tests.sh" --verbose "$test_type" > "$LOG_FILE" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "测试通过: $test_type (耗时: ${duration}s)"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_error "测试失败: $test_type (耗时: ${duration}s)"
        return 1
    fi
}

# 发送通知
send_notification() {
    local message="$1"
    local status="$2"
    
    if [[ "$NOTIFICATION_ENABLED" == "true" ]]; then
        log_info "发送通知: $message"
        
        # 这里可以添加实际的通知逻辑
        # 例如：发送邮件、Slack消息、Webhook等
        echo "[$(date)] [$status] $message" >> "$LOG_FILE"
    fi
}

# 监控测试
monitor_tests() {
    local test_types=("unit" "integration" "performance" "compatibility")
    local failure_counts=()
    local total_runs=0
    local successful_runs=0
    
    # 初始化失败计数
    for i in "${!test_types[@]}"; do
        failure_counts[$i]=0
    done
    
    log_info "开始监控测试状态..."
    log_info "监控间隔: ${MONITOR_INTERVAL}秒"
    log_info "最大失败次数: $MAX_FAILURES"
    
    while true; do
        total_runs=$((total_runs + 1))
        local current_success=0
        
        log_info "=== 第 $total_runs 轮测试监控 ==="
        
        # 检查每种测试类型
        for i in "${!test_types[@]}"; do
            local test_type="${test_types[$i]}"
            
            if check_test_status "$test_type"; then
                current_success=$((current_success + 1))
                successful_runs=$((successful_runs + 1))
                failure_counts[$i]=0
            else
                failure_counts[$i]=$((failure_counts[$i] + 1))
                
                # 检查是否超过最大失败次数
                if [[ ${failure_counts[$i]} -ge $MAX_FAILURES ]]; then
                    log_error "测试 $test_type 连续失败 ${failure_counts[$i]} 次"
                    send_notification "测试 $test_type 连续失败 ${failure_counts[$i]} 次" "ERROR"
                fi
            fi
        done
        
        # 计算成功率
        local success_rate=$((current_success * 100 / ${#test_types[@]}))
        log_info "本轮成功率: $success_rate% ($current_success/${#test_types[@]})"
        log_info "总体成功率: $((successful_runs * 100 / (total_runs * ${#test_types[@]})))%"
        
        # 发送成功通知
        if [[ $current_success -eq ${#test_types[@]} ]]; then
            send_notification "所有测试通过" "SUCCESS"
        fi
        
        # 等待下一轮
        log_info "等待 ${MONITOR_INTERVAL} 秒..."
        sleep "$MONITOR_INTERVAL"
    done
}

# 生成测试报告
generate_test_report() {
    local report_file="/tmp/ipv6wgm_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "生成测试报告: $report_file"
    
    cat > "$report_file" << EOF
IPv6 WireGuard Manager 测试状态报告
=====================================

生成时间: $(date)
监控间隔: ${MONITOR_INTERVAL}秒
最大失败次数: $MAX_FAILURES

测试配置:
- 单元测试: 启用
- 集成测试: 启用
- 性能测试: 启用
- 兼容性测试: 启用

系统信息:
- 操作系统: $(uname -s)
- 内核版本: $(uname -r)
- 架构: $(uname -m)
- Bash版本: $BASH_VERSION

最近测试日志:
$(tail -n 50 "$LOG_FILE" 2>/dev/null || echo "无日志文件")

EOF

    log_success "测试报告已生成: $report_file"
}

# 清理监控数据
cleanup_monitor() {
    log_info "清理监控数据..."
    
    # 停止监控进程
    pkill -f "test-status-monitor" 2>/dev/null || true
    
    # 清理日志文件
    if [[ -f "$LOG_FILE" ]]; then
        rm -f "$LOG_FILE"
        log_info "已清理日志文件: $LOG_FILE"
    fi
    
    log_success "监控数据清理完成"
}

# 主函数
main() {
    local daemon_mode=false
    local verbose=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            -m|--max-failures)
                MAX_FAILURES="$2"
                shift 2
                ;;
            -n|--notify)
                NOTIFICATION_ENABLED=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -d|--daemon)
                daemon_mode=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 设置详细输出
    if [[ "$verbose" == "true" ]]; then
        set -x
    fi
    
    log_info "IPv6 WireGuard Manager 测试状态监控"
    log_info "===================================="
    
    # 检查依赖
    if ! command -v bash &> /dev/null; then
        log_error "Bash不可用"
        exit 1
    fi
    
    if [[ ! -f "$PROJECT_ROOT/tests/run_tests.sh" ]]; then
        log_error "测试脚本不存在: $PROJECT_ROOT/tests/run_tests.sh"
        exit 1
    fi
    
    # 设置信号处理
    trap cleanup_monitor EXIT INT TERM
    
    # 后台运行
    if [[ "$daemon_mode" == "true" ]]; then
        log_info "后台运行监控..."
        nohup "$0" --interval "$MONITOR_INTERVAL" --max-failures "$MAX_FAILURES" > /dev/null 2>&1 &
        echo "监控进程已启动，PID: $!"
        exit 0
    fi
    
    # 生成初始报告
    generate_test_report
    
    # 开始监控
    monitor_tests
}

# 运行主函数
main "$@"
