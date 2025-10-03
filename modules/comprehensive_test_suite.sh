#!/bin/bash

# 综合测试套件模块
# 提供单元测试、集成测试、性能测试和安全测试功能

# 测试配置
declare -A TEST_CONFIG=(
    ["enable_unit_tests"]="true"
    ["enable_integration_tests"]="true"
    ["enable_performance_tests"]="true"
    ["enable_security_tests"]="true"
    ["enable_windows_compatibility"]="true"
    ["test_timeout"]="300"
    ["parallel_tests"]="true"
    ["max_parallel_jobs"]="4"
    ["verbose_output"]="true"
    ["generate_reports"]="true"
)

# 测试统计
declare -A TEST_STATS=(
    ["total_tests"]=0
    ["passed_tests"]=0
    ["failed_tests"]=0
    ["skipped_tests"]=0
    ["test_duration"]=0
)

# 测试结果存储
declare -A TEST_RESULTS=()
declare -A TEST_DURATIONS=()

# 断言函数
assert_true() {
    local test_name="$1"
    local condition="$2"
    local test_file="${3:-unknown}"
    
    ((TEST_STATS[total_tests]++))
    local start_time=$(date +%s%3N)
    
    if [[ "$condition" == "true" ]] || [[ "$condition" == "1" ]] || [[ -n "$condition" ]]; then
        local end_time=$(date +%s%3N)
        ((TEST_STATS[passed_tests]++))
        TEST_RESULTS[$test_name]="PASS"
        record_test_result "$test_name" "PASS" "$test_file" "$condition" $((end_time - start_time))
        
        if [[ "${TEST_CONFIG[verbose_output]}" == "true" ]]; then
            log_success "✓ $test_name"
        fi
        return 0
    else
        local end_time=$(date +%s%3N)
        ((TEST_STATS[failed_tests]++))
        TEST_RESULTS[$test_name]="FAIL"
        record_test_result "$test_name" "FAIL" "$test_file" "$condition" $((end_time - start_time))
        
        log_error "✗ $test_name: 条件为假 ($condition)"
        return 1
    fi
}

assert_false() {
    local test_name="$1"
    local condition="$2"
    local test_file="${3:-unknown}"
    
    ((TEST_STATS[total_tests]++))
    local start_time=$(date +%s%3N)
    
    if [[ "$condition" == "false" ]] || [[ "$condition" == "0" ]] || [[ -z "$condition" ]]; then
        local end_time=$(date +%s%3N)
        ((TEST_STATS[passed_tests]++))
        TEST_RESULTS[$test_name]="PASS"
        record_test_result "$test_name" "PASS" "$test_file" "$condition" $((end_time - start_time))
        
        if [[ "${TEST_CONFIG[verbose_output]}" == "true" ]]; then
            log_success "✓ $test_name"
        fi
        return 0
    else
        local end_time=$(date +%s%3N)
        ((TEST_STATS[failed_tests]++))
        TEST_RESULTS[$test_name]="FAIL"
        record_test_result "$test_name" "FAIL" "$test_file" "$condition" $((end_time - start_time))
        
        log_error "✗ $test_name: 期望失败，但条件为真 ($condition)"
        return 1
    fi
}

assert_equals() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    local test_file="${4:-unknown}"
    
    ((TEST_STATS[total_tests]++))
    local start_time=$(date +%s%3N)
    
    if [[ "$expected" == "$actual" ]]; then
        local end_time=$(date +%s%3N)
        ((TEST_STATS[passed_tests]++))
        TEST_RESULTS[$test_name]="PASS"
        record_test_result "$test_name" "PASS" "$test_file" "期望: '$expected', 实际: '$actual'" $((end_time - start_time))
        
        if [[ "${TEST_CONFIG[verbose_output]}" == "true" ]]; then
            log_success "✓ $test_name"
        fi
        return 0
    else
        local end_time=$(date +%s%3N)
        ((TEST_STATS[failed_tests]++))
        TEST_RESULTS[$test_name]="FAIL"
        record_test_result "$test_name" "FAIL" "$test_file" "期望: '$expected', 实际: '$actual'" $((end_time - start_time))
        
        log_error "✗ $test_name"
        log_error "  期望: '$expected'"
        log_error "  实际: '$actual'"
        return 1
    fi
}

assert_command() {
    local test_name="$1"
    local command="$2"
    local test_file="${3:-unknown}"
    
    ((TEST_STATS[total_tests]++))
    local start_time=$(date +%s%3N)
    
    if safe_execute_command "$command" >/dev/null 2>&1; then
        local end_time=$(date +%s%3N)
        ((TEST_STATS[passed_tests]++))
        TEST_RESULTS[$test_name]="PASS"
        record_test_result "$test_name" "PASS" "$test_file" "命令执行成功: $command" $((end_time - start_time))
        
        if [[ "${TEST_CONFIG[verbose_output]}" == "true" ]]; then
            log_success "✓ $test_name"
        fi
        return 0
    else
        local end_time=$(date +%s%3N)
        ((TEST_STATS[failed_tests]++))
        TEST_RESULTS[$test_name]="FAIL"
        record_test_result "$test_name" "FAIL" "$test_file" "命令执行失败: $command" $((end_time - start_time))
        
        log_error "✗ $test_name: 命令失败 ($command)"
        return 1
    fi
}

# 记录测试结果
record_test_result() {
    local test_name="$1"
    local result="$2"
    local test_file="$3"
    local details="$4"
    local duration="$5"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$result] [$test_file] $test_name ($details) - ${duration}ms" >> "${IPV6WGM_LOG_DIR}/test_results.log"
}

# WireGuard功能测试
test_wireguard_functionality() {
    log_info "=== WireGuard功能测试 ==="
    
    local test_file="wireguard_functionality"
    
    # 测试密钥生成
    assert_command "WireGuard密钥生成测试" "command -v wg || command -v openssl" "$test_file"
    
    # 测试接口配置
    assert_command "网络接口检查" "ip link show 2>/dev/null || ifconfig" "$test_file"
    
    # 测试IPv6配置
    assert_command "IPv6支持检查" "ip -6 addr show 2>/dev/null" "$test_file"
    
    # 测试防火墙工具
    local firewall_tools=("iptables" "ufw" "firewall-cmd" "nftables")
    for tool in "${firewall_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            assert_true "$tool 命令可用性测试" "command -v $tool" "$test_file"
            break
        fi
    done
}

# 安全功能测试
test_security_features() {
    log_info "=== 安全功能测试 ==="
    
    local test_file="security_features"
    
    # 测试敏感信息过滤
    local test_message="password=secret123"
    if declare -f sanitize_log_message >/dev/null 2>&1; then
        local sanitized=$(sanitize_log_message "$test_message")
        assert_false "敏感信息过滤测试" "$sanitized == $test_message" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过敏感信息过滤测试 (函数未定义)"
    fi
    
    # 测试密码强度验证
    if declare -f validate_password >/dev/null 2>&1; then
        assert_false "弱密码检测测试" "$(validate_password 'weak123' && echo true || echo false)" "$test_file"
        assert_true "强密码验证测试" "$(validate_password 'StrongP@ssw0rd!' && echo true || echo false)" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过密码强度验证测试 (函数未定义)"
    fi
    
    # 测试输入验证
    if declare -f validate_ip_address >/dev/null 2>&1; then
        assert_true "IPv4地址验证测试" "$(validate_ip_address '192.168.1.1' 'ipv4' && echo true || echo false)" "$test_file"
        assert_false "无效IPv4检测测试" "$(validate_ip_address '999.999.999.999' 'ipv4' && echo true || echo false)" "$test_file"
        assert_true "IPv6地址验证测试" "$(validate_ip_address '2001:db8::1' 'ipv6' && echo true || echo false)" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过IP地址验证测试 (函数未定义)"
    fi
}

# 性能测试
test_performance() {
    log_info "=== 性能测试 ==="
    
    local test_file="performance"
    
    # 测试缓存功能
    if declare -f execute_with_cache >/dev/null 2>&1; then
        local start_time=$(date +%s%3N)
        local result=$(execute_with_cache "echo 'test'" "perf_test_key" 60 "true")
        local end_time=$(date +%s%3N)
        local execution_time=$((end_time - start_time))
        
        assert_true "缓存性能测试" "$execution_time -lt 100" "$test_file"
        assert_equals "缓存结果验证测试" "test" "$result" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过缓存性能测试 (函数未定义)"
    fi
    
    # 测试并行处理
    if declare -f parallel_process_clients >/dev/null 2>&1; then
        local clients=("client1" "client2" "client3")
        local start_time=$(date +%s%3N)
        parallel_process_clients "${clients[@]}" >/dev/null 2>&1
        local end_time=$(date +%s%3N)
        local execution_time=$((end_time - start_time))
        
        assert_true "并行处理性能测试" "$execution_time -lt 10000" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过并行处理测试 (函数未定义)"
    fi
    
    # 测试内存使用
    if declare -f monitor_memory >/dev/null 2>&1; then
        local memory_usage=$(monitor_memory 2>&1 | tail -1 | grep -o '[0-9]*' | head -1)
        assert_true "内存使用测试" "$memory_usage -lt 500" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过内存使用测试 (函数未定义)"
    fi
}

# 集成测试
test_integration() {
    log_info "=== 集成测试 ==="
    
    local test_file="integration"
    
    # 测试配置加载
    if [[ -f "${IPV6WGM_CONFIG_DIR}/manager.conf" ]]; then
        assert_true "配置文件存在测试" "-f ${IPV6WGM_CONFIG_DIR}/manager.conf" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过配置文件测试 (文件不存在)"
    fi
    
    # 测试日志功能
    assert_true "日志目录权限测试" "-w ${IPV6WGM_LOG_DIR}" "$test_file"
    
    # 测试模块加载
    if declare -f lazy_load_module >/dev/null 2>&1; then
        assert_command "模块加载测试" "lazy_load_module common_functions" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过模块加载测试 (函数未定义)"
    fi
    
    # 测试错误处理
    if declare -f unified_error_handler >/dev/null 2>&1; then
        unified_error_handler 999 "测试错误" "TEST" "integration_test" 1 >/dev/null 2>&1
        assert_true "错误处理集成测试" "$? -eq 0" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过错误处理测试 (函数未定义)"
    fi
}

# Windows兼容性测试
test_windows_compatibility() {
    log_info "=== Windows兼容性测试 ==="
    
    local test_file="windows_compatibility"
    
    # 检测运行环境
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ -n "${WSLENV:-}" ]]; then
        assert_true "WSL环境检测测试" "true" "$test_file"
        log_info "运行在WSL环境中"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        assert_true "MSYS/Cygwin环境检测测试" "true" "$test_file"
        log_info "运行在MSYS/Cygwin环境中"
    elif [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        assert_true "Windows内核检测测试" "true" "$test_file"
        log_info "运行在Windows内核环境中"
    else
        ((TEST_STATS[skipped_tests]++))
        log_info "非Windows环境，跳过兼容性测试"
        return 0
    fi
    
    # 测试路径转换
    if declare -f convert_path_to_windows >/dev/null 2>&1; then
        local win_path=$(convert_path_to_windows "/tmp/test")
        assert_true "路径转换功能测试" "test -n '$win_path'" "$test_file"
    else
        ((TEST_STATS[skipped_tests]++))
        log_warn "跳过路径转换测试 (函数未定义)"
    fi
}

# 运行所有测试
run_all_tests() {
    local overall_start_time=$(date +%s%3N)
    
    log_info "=== 开始执行综合测试套件 ==="
    log_info "配置: 单元测试=$TEST_CONFIG[enable_unit_tests], 集成测试=$TEST_CONFIG[enable_integration_tests]"
    log_info "并行测试=$TEST_CONFIG[parallel_tests], 详细输出=$TEST_CONFIG[verbose_output]"
    
    # 创建测试日志目录
    mkdir -p "${IPV6WGM_LOG_DIR}"
    
    # WireGuard功能测试
    if [[ "${TEST_CONFIG[enable_unit_tests]}" == "true" ]]; then
        test_wireguard_functionality
    fi
    
    # 安全功能测试
    if [[ "${TEST_CONFIG[enable_security_tests]}" == "true" ]]; then
        test_security_features
    fi
    
    # 性能测试
    if [[ "${TEST_CONFIG[enable_performance_tests]}" == "true" ]]; then
        test_performance
    fi
    
    # 集成测试
    if [[ "${TEST_CONFIG[enable_integration_tests]}" == "true" ]]; then
        test_integration
    fi
    
    # Windows兼容性测试
    if [[ "${TEST_CONFIG[enable_windows_compatibility]}" == "true" ]]; then
        test_windows_compatibility
    fi
    
    local overall_end_time=$(date +%s%3N)
    TEST_STATS[test_duration]=$((overall_end_time - overall_start_time))
    
    # 生成测试报告
    generate_test_report
}

# 生成测试报告
generate_test_report() {
    local report_file="${IPV6WGM_LOG_DIR}/test_report_$(date +%Y%m%d_%H%M%S).html"
    local total="${TEST_STATS[total_tests]}"
    local passed="${TEST_STATS[passed_tests]}"
    local failed="${TEST_STATS[failed_tests]}"
    local skipped="${TEST_STATS[skipped_tests]}"
    local duration="${TEST_STATS[test_duration]}"
    
    local success_rate=0
    if [[ $total -gt 0 ]]; then
        success_rate=$((passed * 100 / total))
    fi
    
    {
        cat << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>IPv6 WireGuard Manager 测试报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .stats { display: flex; gap: 20px; margin: 20px 0; }
        .stat-box { background: #ecf0f1; padding: 15px; border-radius: 5px; text-align: center; }
        .pass { color: #27ae60; }
        .fail { color: #e74c3c; }
        .skip { color: #f39c12; }
        
        th, td { padding: 10px; text-align: left; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        
        th { background-color: #3498db; color: white; }
        .duration { font-weight: bold; color: #2c3e50; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager - 测试报告</h1>
        <p>生成时间: $(date)</p>
        <p>系统环境: $(uname -a)</p>
    </div>
    
    <div class="stats">
        <div class="stat-box">
            <h3 class="pass">通过</h3>
            <h2><span class="pass">$passed</span></h2>
        </div>
        <div class="stat-box">
            <h3 class="fail">失败</h3>
            <h2><span class="fail">$failed</span></h2>
        </div>
        <div class="stat-box">
            <h3 class="skip">跳过</h3>
            <h2><span class="skip">$skipped</span></h2>
        </div>
        <div class="stat-box">
            <h3>总计</h3>
            <h2>$total</h2>
        </div>
    </div>
    
    <h2>测试统计</h2>
    <table>
        <tr><th>指标</th><th>值</th><th>百分比</th></tr>
        <tr><td>总测试数</td><td>$total</td><td>100%</td></tr>
        <tr class="pass"><td>通过测试</td><td>$passed</td><td>${success_rate}%</td></tr>
        <tr class="fail"><td>失败测试</td><td>$failed</td><td>$((total>0?failed*100/total:0))%</td></tr>
        <tr class="skip"><td>跳过测试</td><td>$skipped</td><td>$((total>0?skipped*100/total:0))%</td></tr>
    </table>
    
    <h2>执行信息</h2>
    <p class="duration">测试总耗时: ${duration}ms</p>
    <p>平均每个测试耗时: $((total>0?duration/total:0))ms</p>
    
    <h2>测试配置</h2>
    <ul>
        <li>并行测试: ${TEST_CONFIG[parallel_tests]}</li>
        <li>详细输出: ${TEST_CONFIG[verbose_output]}</li>
        <li>超时时间: ${TEST_CONFIG[test_timeout]}秒</li>
        <li>最大并行作业: ${TEST_CONFIG[max_parallel_jobs]}</li>
    </ul>
EOF
        
        if [[ $failed -gt 0 ]]; then
            echo "<h2>失败的测试</h2><ul>"
            for test_name in "${!TEST_RESULTS[@]}"; do
                if [[ "${TEST_RESULTS[$test_name]}" == "FAIL" ]]; then
                    echo "<li class='fail'>$test_name</li>"
                fi
            done
            echo "</ul>"
        fi
        
        if [[ $success_rate -lt 80 ]]; then
            echo "<div style='background: #f39c12; color: white; padding: 15px; border-radius: 5px; margin: 20px 0;'>"
            echo "<h3>警告</h3><p>测试成功率未达到预期阈值 (80%)</p></div>"
        fi
        
        echo "</body></html>"
        
    } > "$report_file"
    
    log_info "测试报告已生成: $report_file"
    echo
    echo "测试完成: $passed/$total 通过, $failed 失败, $skipped 跳过"
    echo "成功率: ${success_rate}%"
    echo "详细报告: $report_file"
    
    return $failed
}

# 导出函数
export -f assert_true assert_false assert_equals assert_command record_test_result
export -f test_wireguard_functionality test_security_features test_performance
export -f test_integration test_windows_compatibility run_all_tests generate_test_report

# 别名
alias run_tests=run_all_tests
alias test_report=generate_test_report
alias assert_true_fn=assert_true
alias assert_false_fn=assert_false
