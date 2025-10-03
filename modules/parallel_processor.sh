#!/bin/bash

# 并行处理器模块
# 提供高效的并行处理、任务队列和资源管理功能

# 并行配置
declare -A PARALLEL_CONFIG=(
    ["max_workers"]="4"
    ["queue_size"]="100"
    ["timeout"]="300"
    ["retry_count"]="3"
    ["worker_type"]="background"  # background, foreground
)

# 任务队列
declare -A TASK_QUEUE=()
declare -A TASK_STATUS=()
declare -A TASK_RESULTS=()
declare -A TASK_ERRORS=()

# 任务统计
declare -A PARALLEL_STATS=(
    ["total_tasks"]=0
    ["completed_tasks"]=0
    ["failed_tasks"]=0
    ["active_workers"]=0
    ["queue_size"]=0
)

# 创建任务
create_task() {
    local task_id="$1"
    local task_command="$2"
    local task_data="${3:-}"
    local priority="${4:-normal}"  # high, normal, low
    
    local task_info="$task_command|$task_data|$priority|$(date +%s)"
    TASK_QUEUE[$task_id]="$task_info"
    TASK_STATUS[$task_id]="pending"
    
    ((PARALLEL_STATS[total_tasks]++))
    ((PARALLEL_STATS[queue_size]++))
    
    log_debug "任务已创建: $task_id (优先级: $priority)"
}

# 执行单个任务
execute_task() {
    local task_id="$1"
    local task_info="${TASK_QUEUE[$task_id]}"
    
    if [[ -z "$task_info" ]]; then
        log_error "任务不存在: $task_id"
        return 1
    fi
    
    # 解析任务信息
    IFS='|' read -r command data priority timestamp <<< "$task_info"
    
    # 更新任务状态
    TASK_STATUS[$task_id]="running"
    ((PARALLEL_STATS[active_workers]++))
    
    log_debug "开始执行任务: $task_id"
    
    # 执行命令
    local result
    local error_output
    
    if [[ -n "$data" ]]; then
        # 使用管道传递数据
        result=$(echo "$data" | bash -c "$command" 2>&1)
    else
        # 直接执行命令
        result=$(bash -c "$command" 2>&1)
    fi
    
    local exit_code=$?
    
    # 处理执行结果
    if [[ $exit_code -eq 0 ]]; then
        TASK_RESULTS[$task_id]="$result"
        TASK_STATUS[$task_id]="completed"
        ((PARALLEL_STATS[completed_tasks]++))
        log_debug "任务执行成功: $task_id"
    else
        TASK_ERRORS[$task_id]="$result"
        TASK_STATUS[$task_id]="failed"
        ((PARALLEL_STATS[failed_tasks]++))
        log_error "任务执行失败: $task_id (错误: $result)"
    fi
    
    ((PARALLEL_STATS[active_workers]--))
    ((PARALLEL_STATS[queue_size]--))
    
    # 清理任务
    unset TASK_QUEUE[$task_id]
    
    return $exit_code
}

# 工作线程
worker_thread() {
    local worker_id="$1"
    
    log_debug "工作线程启动: $worker_id"
    
    while true; do
        # 查找待执行任务
        local next_task=""
        local next_priority="low"
        
        # 按优先级查找任务
        for task_id in "${!TASK_QUEUE[@]}"; do
            local task_info="${TASK_QUEUE[$task_id]}"
            IFS='|' read -r command data priority timestamp <<< "$task_info"
            
            # 检查优先级（high > normal > low）
            case "$priority" in
                "high")
                    if [[ "$next_priority" == "normal" || "$next_priority" == "low" ]]; then
                        next_task="$task_id"
                        next_priority="$priority"
                    fi
                    ;;
                "normal")
                    if [[ "$next_priority" == "low" ]]; then
                        next_task="$task_id"
                        next_priority="$priority"
                    fi
                    ;;
                "low")
                    if [[ -z "$next_task" ]]; then
                        next_task="$task_id"
                        next_priority="$priority"
                    fi
                    ;;
            esac
        done
        
        if [[ -n "$next_task" ]]; then
            execute_task "$next_task"
        else
            # 没有待执行任务，短暂休息
            sleep 0.1
        fi
    done
}

# 并行执行任务
parallel_execute() {
    local tasks_file="$1"
    local max_workers="${PARALLEL_CONFIG[max_workers]}"
    local timeout="${PARALLEL_CONFIG[timeout]}"
    
    log_info "开始并行执行任务 (工作线程数: $max_workers)"
    
    # 启动工作线程
    local workers=()
    for ((i=1; i<=max_workers; i++)); do
        worker_thread "$i" &
        workers+=($!)
        log_debug "启动工作线程: $i (PID: $!)"
    done
    
    # 从文件读取任务
    if [[ -f "$tasks_file" ]]; then
        local task_id=1
        while IFS='|' read -r command data priority; do
            create_task "task_$task_id" "$command" "$data" "$priority"
            ((task_id++))
        done < "$tasks_file"
    fi
    
    # 等待任务完成
    local start_time=$(date +%s)
    while [[ ${PARALLEL_STATS[queue_size]} -gt 0 ]]; do
        local current_time=$(date +%s)
        
        # 检查超时
        if (( current_time - start_time > timeout )); then
            log_error "并行执行超时 (${timeout}s)"
            break
        fi
        
        sleep 1
        
        # 打印进度
        local progress=$((PARALLEL_STATS[completed_tasks] * 100 / PARALLEL_STATS[total_tasks]))
        printf "\r进度: %d%% (%d/%d 任务完成)" "$progress" "${PARALLEL_STATS[completed_tasks]}" "${PARALLEL_STATS[total_tasks]}"
    done
    
    echo
    log_success "并行执行完成"
    
    # 终止工作线程
    for worker_pid in "${workers[@]}"; do
        kill "$worker_pid" 2>/dev/null || true
    done
    
    # 显示统计信息
    show_parallel_stats
}

# 显示并行统计信息
show_parallel_stats() {
    echo
    echo "=== 并行处理统计 ==="
    echo "总任务数: ${PARALLEL_STATS[total_tasks]}"
    echo "已完成: ${PARALLEL_STATS[completed_tasks]}"
    echo "失败任务: ${PARALLEL_STATS[failed_tasks]}"
    echo "活跃工作线程: ${PARALLEL_STATS[active_workers]}"
    echo "队列大小: ${PARALLEL_STATS[queue_size]}"
    
    # 计算成功率
    if [[ ${PARALLEL_STATS[total_tasks]} -gt 0 ]]; then
        local success_rate=$((PARALLEL_STATS[completed_tasks] * 100 / PARALLEL_STATS[total_tasks]))
        echo "成功率: ${success_rate}%"
    fi
}

# 任务结果查询
get_task_result() {
    local task_id="$1"
    
    if [[ -n "${TASK_RESULTS[$task_id]:-}" ]]; then
        echo "${TASK_RESULTS[$task_id]}"
        return 0
    elif [[ -n "${TASK_ERRORS[$task_id]:-}" ]]; then
        echo "${TASK_ERRORS[$task_id]}" >&2
        return 1
    else
        log_warn "任务结果不存在: $task_id"
        return 1
    fi
}

# 任务状态查询
get_task_status() {
    local task_id="$1"
    
    echo "${TASK_STATUS[$task_id]:-unknown}"
}

# 批量客户端处理
parallel_process_clients() {
    local client_list=("$@")
    local temp_tasks_file="/tmp/parallel_clients_$$"
    
    # 创建任务文件
    for client in "${client_list[@]}"; do
        echo "echo 'Processing client: $client'; sleep 1; echo 'client_$client_completed'" >> "$temp_tasks_file"
    done
    
    # 并行执行
    parallel_execute "$temp_tasks_file"
    
    # 清理临时文件
    rm -f "$temp_tasks_file"
}

# 并行网络检查
parallel_network_check() {
    local hosts=("$@")
    local results=()
    
    log_info "并行检查网络连接..."
    
    for host in "${hosts[@]}"; do
        (
            if ping -c 1 "$host" >/dev/null 2>&1; then
                echo "SUCCESS:$host"
            else
                echo "FAILED:$host"
            fi
        ) &
    done
    
    # 等待所有ping完成
    wait
    
    log_success "网络检查完成"
}

# 清理任务数据
cleanup_tasks() {
    TASK_QUEUE=()
    TASK_STATUS=()
    TASK_RESULTS=()
    TASK_ERRORS=()
    
    log_info "任务数据已清理"
}

# 导出函数
export -f create_task execute_task worker_thread parallel_execute
export -f show_parallel_stats get_result get_task_status parallel_process_clients
export -f parallel_network_check cleanup_tasks

# 别名
alias task_create=create_task
alias task_execute=execute_task
alias parallel_run=parallel_execute
alias task_status=get_task_status
alias task_result=get_task_result
