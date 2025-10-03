#!/bin/bash

# ================================================================
# 数据流处理模块 - 高效处理大数据集和流数据
# ================================================================

# 批量处理配置
BATCH_CONFIG=(
    "BATCH_SIZE=100"
    "BATCH_DELAY=0.5"
    "BATCH_LIMIT=1000"
    "MEMORY_LIMIT=256M"
    "PROGRESS_INTERVAL=100"
)

# 加载批量处理配置
load_batch_config() {
    for config_line in "${BATCH_CONFIG[@]}"; do
        local key="${config_line%%=*}"
        local value="${config_line##*=}"
        export "$key"="$value"
    done
}

# 批量写入文件（高效）
batch_write_to_file() {
    local file_path="$1"
    shift
    local data_array=("$@")
    local batch_size="${BATCH_SIZE:-100}"
    local progress_interval="${PROGRESS_INTERVAL:-100}"
    
    local temp_file="/tmp/batch_write_$$"
    local written_count=0
    local total_count=${#data_array[@]}
    
    echo "开始批量写入文件: $file_path (总计: $total_count 条记录)"
    
    # 分批处理数据
    for ((i=0; i<total_count; i+=batch_size)); do
        local batch_data=()
        local end_index=$((i + batch_size))
        
        # 获取当前批次数据
        for ((j=i; j<end_index && j<total_count; j++)); do
            batch_data+=("${data_array[j]}")
        done
        
        # 写入到临时文件
        printf '%s\n' "${batch_data[@]}" >> "$temp_file"
        ((written_count += ${#batch_data[@]}))
        
        # 显示进度
        if [[ $((written_count % progress_interval)) -eq 0 ]]; then
            local progress_percent=$((written_count * 100 / total_count))
            log_debug "写入进度: $written_count/$total_count ($progress_percent%)"
        fi
        
        # 控制内存使用
        if [[ $((i % 1000)) -eq 0 ]]; then
            sync 2>/dev/null || true
        fi
    done
    
    # 原子性移动文件
    mv "$temp_file" "$file_path"
    log_success "批量写入完成: $file_path (写入记录: $written_count)"
}

# 流式读取文件（内存高效）
stream_read_file() {
    local file_path="$1"
    local callback_function="$2"
    local batch_size="${BATCH_SIZE:-100}"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "文件不存在: $file_path"
        return 1
    fi
    
    log_info "开始流式读取文件: $file_path"
    local line_count=0
    local batch_count=0
    local batch_buffer=()
    
    # 逐行读取文件
    while IFS= read -r line; do
        batch_buffer+=("$line")
        ((line_count++))
        ((batch_count++))
        
        # 达到批次大小时处理
        if [[ $batch_count -eq $batch_size ]]; then
            "$callback_function" "${batch_buffer[@]}"
            batch_buffer=()
            batch_count=0
        fi
    done < "$file_path"
    
    # 处理剩余数据
    if [[ ${#batch_buffer[@]} -gt 0 ]]; then
        "$callback_function" "${batch_buffer[@]}"
    fi
    
    log_success "流式读取完成: $file_path (总行数: $line_count)"
}

# 并行处理数据
parallel_process_data() {
    local data_array=("$@")
    local processor_function="$1"
    local max_processes="${MAX_CONCURRENT_OPS:-4}"
    
    local array_size=${#data_array[@]}
    local chunk_size=$((array_size / max_processes))
    local jobs=()
    
    echo "开始并行处理数据 (并行度: $max_processes)"
    
    # 分批处理
    for ((i=0; i<max_processes; i++)); do
        local start=$((i * chunk_size))
        local end=$(((i + 1) * chunk_size))
        
        # 最后一个批次包含剩余数据
        if [[ $i -eq $((max_processes - 1)) ]]; then
            end=$array_size
        fi
        
        # 提取当前批次数据
        local chunk_data=()
        for ((j=start; j<end; j++)); do
            chunk_data+=("${data_array[j]}")
        done
        
        # 后台处理
        (
            "$processor_function" "${chunk_data[@]}"
        ) &
        
        jobs+=($!)
        echo "启动处理任务 $((i+1))/$max_processes (PID: $!)"
    done
    
    # 等待所有任务完成
    local completed=0
    for job in "${jobs[@]}"; do
        if wait "$job"; then
            ((completed++))
            log_debug "处理任务完成 (PID: $job)"
        else
            log_warn "处理任务失败 (PID: $job)"
        fi
    done
    
    log_success "并行处理完成: $completed/$max_processes 个任务成功"
}

# 内存高效的去重操作
memory_efficient_deduplication() {
    local file_path="$1"
    local output_path="$2"
    local chunk_size="${BATCH_SIZE:-1000}"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "输入文件不存在: $file_path"
        return 1
    fi
    
    echo "开始内存高效去重: $file_path"
    local temp_output="/tmp/dedup_$$"
    local line_count=0
    local unique_count=0
    
    # 使用外部排序进行去重
    if command -v sort &> /dev/null; then
        log_info "使用外部排序进行去重..."
        sort -u "$file_path" > "$temp_output" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            mv "$temp_output" "$output_path"
            unique_count=$(wc -l < "$output_path")
            log_success "外部排序去重完成 (唯一记录: $unique_count)"
            return 0
        fi
    fi
    
    # 回退到内存中处理去重
    declare -A seen_lines
    local batch_buffer=()
    
    while IFS= read -r line; do
        if [[ ! ${seen_lines[$line]} ]]; then
            seen_lines[$line]=1
            batch_buffer+=("$line")
            ((unique_count++))
        fi
        ((line_count++))
        
        # 分批写入
        if [[ ${#batch_buffer[@]} -eq $chunk_size ]]; then
            printf '%s\n' "${batch_buffer[@]}" >> "$temp_output"
            batch_buffer=()
        fi
    done < "$file_path"
    
    # 写入剩余数据
    if [[ ${#batch_buffer[@]} -gt 0 ]]; then
        printf '%s\n' "${batch_buffer[@]}" >> "$temp_output"
    fi
    
    mv "$temp_output" "$output_path"
    log_success "内存中处理去重完成 (总行数: $line_count, 唯一记录: $unique_count)"
}

# 数据压缩和解压
compress_data() {
    local input_file="$1"
    local output_file="$2"
    local compression_level="${3:-6}"
    
    if [[ ! -f "$input_file" ]]; then
        log_error "输入文件不存在: $input_file"
        return 1
    fi
    
    # 选择压缩算法
    local compression_cmd=""
    if command -v gzip &> /dev/null; then
        compression_cmd="gzip -c"
    elif command -v bzip2 &> /dev/null; then
        compression_cmd="bzip2 -c"
    else
        log_warn "未找到压缩工具，跳过压缩"
        cp "$input_file" "$output_file"
        return 0
    fi
    
    echo "开始压缩数据: $input_file"
    
    if $compression_cmd "$input_file" > "$output_file"; then
        local original_size=$(stat -c%s "$input_file" 2>/dev/null || stat -f%z "$input_file" 2>/dev/null || echo "0")
        local compressed_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file" 2>/dev/null || echo "0")
        local compression_ratio=0
        
        if [[ $original_size -gt 0 ]]; then
            compression_ratio=$((compressed_size * 100 / original_size))
        fi
        
        log_success "数据压缩完成 (压缩率: ${compression_ratio}%)"
    else
        log_error "数据压缩失败"
        return 1
    fi
}

# 增量数据处理
incremental_data_processing() {
    local data_file="$1"
    local timestamp_file="$2"
    local output_file="$3"
    
    local last_timestamp=""
    if [[ -f "$timestamp_file" ]]; then
        last_timestamp=$(cat "$timestamp_file")
    fi
    
    local current_timestamp=$(date -Iseconds)
    
    echo "开始增量数据处理 (上次处理时间: ${last_timestamp:-'从未处理'})"
    
    # 这里可以根据时间戳处理增量数据
    # 例如：只处理特定时间段内的数据
    
    # 保存当前时间戳
    echo "$current_timestamp" > "$timestamp_file"
    echo "$current_timestamp" > "$output_file"
    
    log_success "增量数据处理完成"
}

# 性能监控
monitor_processing_performance() {
    local start_time=$(date +%s%3N 2>/dev/null || date +%s)
    local start_memory=$(free | grep Mem | awk '{print $3}')
    
    # 性能统计函数
    echo "性能监控已启动"
    
    # 返回监控函数
    echo "performance_monitor() {
        local current_time=\$(date +%s%3N 2>/dev/null || date +%s)
        local current_memory=\$(free | grep Mem | awk '{print \$3}')
        local elapsed_time=\$((current_time - $start_time))
        local memory_usage=\$((current_memory - $start_memory))
        
        log_debug \"处理性能 - 运行时间: \${elapsed_time}ms, 内存使用: \${memory_usage}KB\"
    }"
}

# 导出函数
export -f batch_write_to_file stream_read_file parallel_process_data
export -f memory_efficient_deduplication compress_data
export -f incremental_data_processing monitor_processing_performance
export -f load_batch_config

# 别名
alias batch_write=batch_write_to_file
alias stream_read=stream_read_file
alias parallel_process=parallel_process_data
alias dedup=memory_efficient_deduplication
alias compress=compress_data
alias incremental_process=incremental_data_processing
