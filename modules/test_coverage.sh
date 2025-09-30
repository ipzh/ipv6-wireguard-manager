#!/bin/bash

# 测试覆盖率模块
# 提供测试覆盖率统计和报告功能

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# =============================================================================
# 覆盖率配置
# =============================================================================

# 覆盖率统计变量
declare -A IPV6WGM_COVERAGE_STATS=(
    ["total_lines"]=0
    ["covered_lines"]=0
    ["uncovered_lines"]=0
    ["tested_functions"]=0
    ["untested_functions"]=0
    ["tested_modules"]=0
    ["untested_modules"]=0
)

# 覆盖率数据存储
declare -A IPV6WGM_LINE_COVERAGE=()
declare -A IPV6WGM_FUNCTION_COVERAGE=()
declare -A IPV6WGM_MODULE_COVERAGE=()

# 覆盖率阈值
declare -g IPV6WGM_COVERAGE_THRESHOLD=80
declare -g IPV6WGM_FUNCTION_COVERAGE_THRESHOLD=70
declare -g IPV6WGM_MODULE_COVERAGE_THRESHOLD=90

# 覆盖率报告目录
declare -g IPV6WGM_COVERAGE_REPORT_DIR="/tmp/ipv6wgm_coverage_reports"

# =============================================================================
# 覆盖率分析函数
# =============================================================================

# 分析文件行覆盖率
analyze_file_coverage() {
    local file_path="$1"
    local test_log_file="$2"
    
    if [[ ! -f "$file_path" ]]; then
        log_warning "文件不存在: $file_path"
        return 1
    fi
    
    log_debug "分析文件覆盖率: $file_path"
    
    # 获取文件总行数
    local total_lines=$(wc -l < "$file_path")
    IPV6WGM_COVERAGE_STATS["total_lines"]=$((IPV6WGM_COVERAGE_STATS["total_lines"] + total_lines))
    
    # 分析可执行行
    local executable_lines=0
    local covered_lines=0
    
    # 使用grep分析可执行行（排除注释和空行）
    while IFS= read -r line; do
        local line_num=$(echo "$line" | cut -d: -f1)
        local line_content=$(echo "$line" | cut -d: -f2-)
        
        # 跳过注释行和空行
        if [[ "$line_content" =~ ^[[:space:]]*# ]] || [[ -z "${line_content// }" ]]; then
            continue
        fi
        
        executable_lines=$((executable_lines + 1))
        
        # 检查行是否被测试覆盖
        if [[ -f "$test_log_file" ]] && grep -q "line $line_num" "$test_log_file" 2>/dev/null; then
            covered_lines=$((covered_lines + 1))
            IPV6WGM_LINE_COVERAGE["$file_path:$line_num"]="covered"
        else
            IPV6WGM_LINE_COVERAGE["$file_path:$line_num"]="uncovered"
        fi
    done < <(grep -n "^" "$file_path")
    
    # 更新统计
    IPV6WGM_COVERAGE_STATS["covered_lines"]=$((IPV6WGM_COVERAGE_STATS["covered_lines"] + covered_lines))
    IPV6WGM_COVERAGE_STATS["uncovered_lines"]=$((IPV6WGM_COVERAGE_STATS["uncovered_lines"] + (executable_lines - covered_lines)))
    
    log_debug "文件 $file_path: $covered_lines/$executable_lines 行被覆盖"
}

# 分析函数覆盖率
analyze_function_coverage() {
    local file_path="$1"
    local test_log_file="$2"
    
    if [[ ! -f "$file_path" ]]; then
        log_warning "文件不存在: $file_path"
        return 1
    fi
    
    log_debug "分析函数覆盖率: $file_path"
    
    # 提取函数定义
    local functions=($(grep -n "^[a-zA-Z_][a-zA-Z0-9_]*()" "$file_path" | cut -d: -f1))
    local tested_functions=0
    local untested_functions=0
    
    for line_num in "${functions[@]}"; do
        local function_name=$(sed -n "${line_num}p" "$file_path" | grep -o "^[a-zA-Z_][a-zA-Z0-9_]*")
        
        # 检查函数是否被测试
        if [[ -f "$test_log_file" ]] && grep -q "test.*$function_name" "$test_log_file" 2>/dev/null; then
            tested_functions=$((tested_functions + 1))
            IPV6WGM_FUNCTION_COVERAGE["$file_path:$function_name"]="tested"
        else
            untested_functions=$((untested_functions + 1))
            IPV6WGM_FUNCTION_COVERAGE["$file_path:$function_name"]="untested"
        fi
    done
    
    # 更新统计
    IPV6WGM_COVERAGE_STATS["tested_functions"]=$((IPV6WGM_COVERAGE_STATS["tested_functions"] + tested_functions))
    IPV6WGM_COVERAGE_STATS["untested_functions"]=$((IPV6WGM_COVERAGE_STATS["untested_functions"] + untested_functions))
    
    log_debug "文件 $file_path: $tested_functions 个函数被测试"
}

# 分析模块覆盖率
analyze_module_coverage() {
    local module_dir="$1"
    local test_log_file="$2"
    
    if [[ ! -d "$module_dir" ]]; then
        log_warning "模块目录不存在: $module_dir"
        return 1
    fi
    
    log_debug "分析模块覆盖率: $module_dir"
    
    local total_modules=0
    local tested_modules=0
    local untested_modules=0
    
    # 遍历模块文件
    while IFS= read -r -d '' file; do
        local module_name=$(basename "$file" .sh)
        total_modules=$((total_modules + 1))
        
        # 检查模块是否被测试
        if [[ -f "$test_log_file" ]] && grep -q "test.*$module_name" "$test_log_file" 2>/dev/null; then
            tested_modules=$((tested_modules + 1))
            IPV6WGM_MODULE_COVERAGE["$module_name"]="tested"
        else
            untested_modules=$((untested_modules + 1))
            IPV6WGM_MODULE_COVERAGE["$module_name"]="untested"
        fi
    done < <(find "$module_dir" -name "*.sh" -type f -print0)
    
    # 更新统计
    IPV6WGM_COVERAGE_STATS["tested_modules"]=$((IPV6WGM_COVERAGE_STATS["tested_modules"] + tested_modules))
    IPV6WGM_COVERAGE_STATS["untested_modules"]=$((IPV6WGM_COVERAGE_STATS["untested_modules"] + untested_modules))
    
    log_debug "模块目录 $module_dir: $tested_modules/$total_modules 个模块被测试"
}

# =============================================================================
# 覆盖率计算函数
# =============================================================================

# 计算行覆盖率
calculate_line_coverage() {
    local total_lines="${IPV6WGM_COVERAGE_STATS[total_lines]}"
    local covered_lines="${IPV6WGM_COVERAGE_STATS[covered_lines]}"
    
    if [[ $total_lines -eq 0 ]]; then
        echo "0"
        return
    fi
    
    local coverage_percent=$((covered_lines * 100 / total_lines))
    echo "$coverage_percent"
}

# 计算函数覆盖率
calculate_function_coverage() {
    local tested_functions="${IPV6WGM_COVERAGE_STATS[tested_functions]}"
    local total_functions=$((tested_functions + IPV6WGM_COVERAGE_STATS[untested_functions]))
    
    if [[ $total_functions -eq 0 ]]; then
        echo "0"
        return
    fi
    
    local coverage_percent=$((tested_functions * 100 / total_functions))
    echo "$coverage_percent"
}

# 计算模块覆盖率
calculate_module_coverage() {
    local tested_modules="${IPV6WGM_COVERAGE_STATS[tested_modules]}"
    local total_modules=$((tested_modules + IPV6WGM_COVERAGE_STATS[untested_modules]))
    
    if [[ $total_modules -eq 0 ]]; then
        echo "0"
        return
    fi
    
    local coverage_percent=$((tested_modules * 100 / total_modules))
    echo "$coverage_percent"
}

# 计算总体覆盖率
calculate_overall_coverage() {
    local line_coverage=$(calculate_line_coverage)
    local function_coverage=$(calculate_function_coverage)
    local module_coverage=$(calculate_module_coverage)
    
    # 加权平均：行覆盖率权重50%，函数覆盖率权重30%，模块覆盖率权重20%
    local overall_coverage=$((line_coverage * 50 + function_coverage * 30 + module_coverage * 20))
    overall_coverage=$((overall_coverage / 100))
    
    echo "$overall_coverage"
}

# =============================================================================
# 覆盖率报告生成
# =============================================================================

# 生成文本报告
generate_text_coverage_report() {
    local report_file="$1"
    
    log_info "生成文本覆盖率报告: $report_file"
    
    local line_coverage=$(calculate_line_coverage)
    local function_coverage=$(calculate_function_coverage)
    local module_coverage=$(calculate_module_coverage)
    local overall_coverage=$(calculate_overall_coverage)
    
    cat > "$report_file" << EOF
IPv6 WireGuard Manager 测试覆盖率报告
=====================================

生成时间: $(date)
报告类型: 文本报告

总体覆盖率: ${overall_coverage}%

详细统计:
----------
行覆盖率: ${line_coverage}% (${IPV6WGM_COVERAGE_STATS[covered_lines]}/${IPV6WGM_COVERAGE_STATS[total_lines]})
函数覆盖率: ${function_coverage}% (${IPV6WGM_COVERAGE_STATS[tested_functions]}/$((IPV6WGM_COVERAGE_STATS[tested_functions] + IPV6WGM_COVERAGE_STATS[untested_functions])))
模块覆盖率: ${module_coverage}% (${IPV6WGM_COVERAGE_STATS[tested_modules]}/$((IPV6WGM_COVERAGE_STATS[tested_modules] + IPV6WGM_COVERAGE_STATS[untested_modules])))

覆盖率阈值:
-----------
行覆盖率阈值: ${IPV6WGM_COVERAGE_THRESHOLD}%
函数覆盖率阈值: ${IPV6WGM_FUNCTION_COVERAGE_THRESHOLD}%
模块覆盖率阈值: ${IPV6WGM_MODULE_COVERAGE_THRESHOLD}%

阈值检查:
---------
行覆盖率: $([ $line_coverage -ge $IPV6WGM_COVERAGE_THRESHOLD ] && echo "✓ 通过" || echo "✗ 未达到")
函数覆盖率: $([ $function_coverage -ge $IPV6WGM_FUNCTION_COVERAGE_THRESHOLD ] && echo "✓ 通过" || echo "✗ 未达到")
模块覆盖率: $([ $module_coverage -ge $IPV6WGM_MODULE_COVERAGE_THRESHOLD ] && echo "✓ 通过" || echo "✗ 未达到")

未覆盖的函数:
------------
EOF
    
    # 添加未覆盖的函数列表
    for key in "${!IPV6WGM_FUNCTION_COVERAGE[@]}"; do
        if [[ "${IPV6WGM_FUNCTION_COVERAGE[$key]}" == "untested" ]]; then
            echo "  $key" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

未覆盖的模块:
------------
EOF
    
    # 添加未覆盖的模块列表
    for key in "${!IPV6WGM_MODULE_COVERAGE[@]}"; do
        if [[ "${IPV6WGM_MODULE_COVERAGE[$key]}" == "untested" ]]; then
            echo "  $key" >> "$report_file"
        fi
    done
    
    log_success "文本覆盖率报告已生成: $report_file"
}

# 生成JSON报告
generate_json_coverage_report() {
    local report_file="$1"
    
    log_info "生成JSON覆盖率报告: $report_file"
    
    local line_coverage=$(calculate_line_coverage)
    local function_coverage=$(calculate_function_coverage)
    local module_coverage=$(calculate_module_coverage)
    local overall_coverage=$(calculate_overall_coverage)
    
    cat > "$report_file" << EOF
{
  "report_type": "coverage",
  "generated_at": "$(date -Iseconds)",
  "overall_coverage": $overall_coverage,
  "line_coverage": {
    "percentage": $line_coverage,
    "covered": ${IPV6WGM_COVERAGE_STATS[covered_lines]},
    "total": ${IPV6WGM_COVERAGE_STATS[total_lines]},
    "threshold": $IPV6WGM_COVERAGE_THRESHOLD,
    "passed": $([ $line_coverage -ge $IPV6WGM_COVERAGE_THRESHOLD ] && echo "true" || echo "false")
  },
  "function_coverage": {
    "percentage": $function_coverage,
    "tested": ${IPV6WGM_COVERAGE_STATS[tested_functions]},
    "total": $((IPV6WGM_COVERAGE_STATS[tested_functions] + IPV6WGM_COVERAGE_STATS[untested_functions])),
    "threshold": $IPV6WGM_FUNCTION_COVERAGE_THRESHOLD,
    "passed": $([ $function_coverage -ge $IPV6WGM_FUNCTION_COVERAGE_THRESHOLD ] && echo "true" || echo "false")
  },
  "module_coverage": {
    "percentage": $module_coverage,
    "tested": ${IPV6WGM_COVERAGE_STATS[tested_modules]},
    "total": $((IPV6WGM_COVERAGE_STATS[tested_modules] + IPV6WGM_COVERAGE_STATS[untested_modules])),
    "threshold": $IPV6WGM_MODULE_COVERAGE_THRESHOLD,
    "passed": $([ $module_coverage -ge $IPV6WGM_MODULE_COVERAGE_THRESHOLD ] && echo "true" || echo "false")
  },
  "untested_functions": [
EOF
    
    # 添加未覆盖的函数
    local first=true
    for key in "${!IPV6WGM_FUNCTION_COVERAGE[@]}"; do
        if [[ "${IPV6WGM_FUNCTION_COVERAGE[$key]}" == "untested" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$report_file"
            fi
            echo "    \"$key\"" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF
  ],
  "untested_modules": [
EOF
    
    # 添加未覆盖的模块
    local first=true
    for key in "${!IPV6WGM_MODULE_COVERAGE[@]}"; do
        if [[ "${IPV6WGM_MODULE_COVERAGE[$key]}" == "untested" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$report_file"
            fi
            echo "    \"$key\"" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF
  ]
}
EOF
    
    log_success "JSON覆盖率报告已生成: $report_file"
}

# 生成HTML报告
generate_html_coverage_report() {
    local report_file="$1"
    
    log_info "生成HTML覆盖率报告: $report_file"
    
    local line_coverage=$(calculate_line_coverage)
    local function_coverage=$(calculate_function_coverage)
    local module_coverage=$(calculate_module_coverage)
    local overall_coverage=$(calculate_overall_coverage)
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager 测试覆盖率报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .stats { display: flex; justify-content: space-around; margin: 20px 0; }
        .stat-box { background-color: #e8f4f8; padding: 15px; border-radius: 5px; text-align: center; }
        .stat-value { font-size: 24px; font-weight: bold; color: #2c5aa0; }
        .stat-label { color: #666; }
        .threshold-pass { color: #28a745; }
        .threshold-fail { color: #dc3545; }
        .section { margin: 20px 0; }
        .list { background-color: #f8f9fa; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager 测试覆盖率报告</h1>
        <p>生成时间: $(date)</p>
    </div>
    
    <div class="stats">
        <div class="stat-box">
            <div class="stat-value">${overall_coverage}%</div>
            <div class="stat-label">总体覆盖率</div>
        </div>
        <div class="stat-box">
            <div class="stat-value $([ $line_coverage -ge $IPV6WGM_COVERAGE_THRESHOLD ] && echo "threshold-pass" || echo "threshold-fail")">${line_coverage}%</div>
            <div class="stat-label">行覆盖率</div>
        </div>
        <div class="stat-box">
            <div class="stat-value $([ $function_coverage -ge $IPV6WGM_FUNCTION_COVERAGE_THRESHOLD ] && echo "threshold-pass" || echo "threshold-fail")">${function_coverage}%</div>
            <div class="stat-label">函数覆盖率</div>
        </div>
        <div class="stat-box">
            <div class="stat-value $([ $module_coverage -ge $IPV6WGM_MODULE_COVERAGE_THRESHOLD ] && echo "threshold-pass" || echo "threshold-fail")">${module_coverage}%</div>
            <div class="stat-label">模块覆盖率</div>
        </div>
    </div>
    
    <div class="section">
        <h2>详细统计</h2>
        <ul>
            <li>行覆盖率: ${line_coverage}% (${IPV6WGM_COVERAGE_STATS[covered_lines]}/${IPV6WGM_COVERAGE_STATS[total_lines]})</li>
            <li>函数覆盖率: ${function_coverage}% (${IPV6WGM_COVERAGE_STATS[tested_functions]}/$((IPV6WGM_COVERAGE_STATS[tested_functions] + IPV6WGM_COVERAGE_STATS[untested_functions])))</li>
            <li>模块覆盖率: ${module_coverage}% (${IPV6WGM_COVERAGE_STATS[tested_modules]}/$((IPV6WGM_COVERAGE_STATS[tested_modules] + IPV6WGM_COVERAGE_STATS[untested_modules])))</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>未覆盖的函数</h2>
        <div class="list">
EOF
    
    # 添加未覆盖的函数列表
    for key in "${!IPV6WGM_FUNCTION_COVERAGE[@]}"; do
        if [[ "${IPV6WGM_FUNCTION_COVERAGE[$key]}" == "untested" ]]; then
            echo "            <div>$key</div>" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF
        </div>
    </div>
    
    <div class="section">
        <h2>未覆盖的模块</h2>
        <div class="list">
EOF
    
    # 添加未覆盖的模块列表
    for key in "${!IPV6WGM_MODULE_COVERAGE[@]}"; do
        if [[ "${IPV6WGM_MODULE_COVERAGE[$key]}" == "untested" ]]; then
            echo "            <div>$key</div>" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF
        </div>
    </div>
</body>
</html>
EOF
    
    log_success "HTML覆盖率报告已生成: $report_file"
}

# =============================================================================
# 主覆盖率分析函数
# =============================================================================

# 运行完整的覆盖率分析
run_coverage_analysis() {
    local project_root="$1"
    local test_log_file="$2"
    local output_dir="${3:-$IPV6WGM_COVERAGE_REPORT_DIR}"
    
    log_info "开始覆盖率分析..."
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 重置统计
    IPV6WGM_COVERAGE_STATS=(
        ["total_lines"]=0
        ["covered_lines"]=0
        ["uncovered_lines"]=0
        ["tested_functions"]=0
        ["untested_functions"]=0
        ["tested_modules"]=0
        ["untested_modules"]=0
    )
    
    # 分析模块覆盖率
    if [[ -d "$project_root/modules" ]]; then
        analyze_module_coverage "$project_root/modules" "$test_log_file"
    fi
    
    # 分析主要脚本文件
    local main_scripts=("$project_root/ipv6-wireguard-manager.sh" "$project_root/install.sh" "$project_root/uninstall.sh")
    for script in "${main_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            analyze_file_coverage "$script" "$test_log_file"
            analyze_function_coverage "$script" "$test_log_file"
        fi
    done
    
    # 分析测试脚本
    if [[ -d "$project_root/tests" ]]; then
        while IFS= read -r -d '' file; do
            analyze_file_coverage "$file" "$test_log_file"
            analyze_function_coverage "$file" "$test_log_file"
        done < <(find "$project_root/tests" -name "*.sh" -type f -print0)
    fi
    
    # 生成报告
    local timestamp=$(date +%Y%m%d_%H%M%S)
    generate_text_coverage_report "$output_dir/coverage_report_${timestamp}.txt"
    generate_json_coverage_report "$output_dir/coverage_report_${timestamp}.json"
    generate_html_coverage_report "$output_dir/coverage_report_${timestamp}.html"
    
    # 输出覆盖率摘要
    local overall_coverage=$(calculate_overall_coverage)
    local line_coverage=$(calculate_line_coverage)
    local function_coverage=$(calculate_function_coverage)
    local module_coverage=$(calculate_module_coverage)
    
    log_info "覆盖率分析完成:"
    log_info "  总体覆盖率: ${overall_coverage}%"
    log_info "  行覆盖率: ${line_coverage}%"
    log_info "  函数覆盖率: ${function_coverage}%"
    log_info "  模块覆盖率: ${module_coverage}%"
    
    # 检查是否达到阈值
    local all_thresholds_passed=true
    
    if [[ $line_coverage -lt $IPV6WGM_COVERAGE_THRESHOLD ]]; then
        log_warning "行覆盖率未达到阈值: ${line_coverage}% < ${IPV6WGM_COVERAGE_THRESHOLD}%"
        all_thresholds_passed=false
    fi
    
    if [[ $function_coverage -lt $IPV6WGM_FUNCTION_COVERAGE_THRESHOLD ]]; then
        log_warning "函数覆盖率未达到阈值: ${function_coverage}% < ${IPV6WGM_FUNCTION_COVERAGE_THRESHOLD}%"
        all_thresholds_passed=false
    fi
    
    if [[ $module_coverage -lt $IPV6WGM_MODULE_COVERAGE_THRESHOLD ]]; then
        log_warning "模块覆盖率未达到阈值: ${module_coverage}% < ${IPV6WGM_MODULE_COVERAGE_THRESHOLD}%"
        all_thresholds_passed=false
    fi
    
    if [[ "$all_thresholds_passed" == "true" ]]; then
        log_success "所有覆盖率阈值都已达到"
        return 0
    else
        log_warning "部分覆盖率阈值未达到"
        return 1
    fi
}

# =============================================================================
# 导出函数
# =============================================================================

export -f analyze_file_coverage
export -f analyze_function_coverage
export -f analyze_module_coverage
export -f calculate_line_coverage
export -f calculate_function_coverage
export -f calculate_module_coverage
export -f calculate_overall_coverage
export -f generate_text_coverage_report
export -f generate_json_coverage_report
export -f generate_html_coverage_report
export -f run_coverage_analysis
