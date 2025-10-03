#!/bin/bash

# API文档自动生成模块
# 自动分析代码并生成完整的API文档

# 文档配置
declare -A DOC_CONFIG=(
    ["output_format"]="markdown"  # markdown, html, json
    ["output_dir"]="${IPV6WGM_LOG_DIR}/api_docs"
    ["include_private"]="false"
    ["generate_examples"]="true"
    ["auto_update"]="true"
)

# API数据结构
declare -A API_FUNCTIONS=()
declare -A API_MODULES=()
declare -A API_EXAMPLES=()

# 分析模块文件并提取函数信息
analyze_module_functions() {
    local module_file="$1"
    local module_name="$(basename "$module_file" .sh)"
    
    log_info "分析模块: $module_name"
    
    # 提取公共函数
    local functions=($(grep "^[a-zA-Z_][a-zA-Z0-9_]*(" "$module_file" | grep -v "function" | cut -d'(' -f1 | sort -u))
    
    # 提取函数文档
    for func in "${functions[@]}"; do
        analyze_function_header "$module_file" "$func" "$module_name"
    done
    
    API_MODULES[$module_name]="${#functions[@]}"
}

# 分析函数头部信息
analyze_function_header() {
    local file="$1"
    local function_name="$2"
    local module_name="$3"
    
    # 查找函数定义
    local func_line=$(grep -n "^[[:space:]]*${function_name}(" "$file" | head -1 | cut -d: -f1)
    if [[ -z "$func_line" ]]; then
        return 0
    fi
    
    # 提取函数注释（函数定义前的注释）
    local comments=()
    local current_line=$((func_line - 1))
    
    while [[ $current_line -gt 0 ]]; do
        local line=$(sed -n "${current_line}p" "$file")
        if [[ "$line" =~ ^[[:space:]]*#.*$ ]]; then
            comments+=("$line")
            ((current_line--))
        else
            break
        fi
    done
    
    # 提取参数
    local func_def=$(sed -n "${func_line}p" "$file")
    local params=($(echo "$func_def" | grep -o 'local [a-zA-Z_][a-zA-Z0-9_]*=' | cut -d' ' -f2 | cut -d'=' -f1))
    
    # 存储函数信息
    local func_info="$module_name|$function_name|${#comments[@]}|${params[*]}|"
    for comment in "${comments[@]}"; do
        func_info="${func_info}${comment#\# };"
    done
    
    API_FUNCTIONS[$function_name]="$func_info"
}

# 生成示例代码
generate_function_examples() {
    local function_name="$1"
    local func_info="${API_FUNCTIONS[$function_name]}"
    
    IFS='|' read -r module_name func_name comment_count params examples <<< "$func_info"
    
    local example_code=""
    
    case "$function_name" in
        "log_info"|"log_error"|"log_warning"|"log_success")
            example_code="
\`\`\`bash
# 基本用法
log_info \"系统启动完成\"
log_error \"配置文件错误\"
log_warning \"缓存空间不足\"

# 条件日志
if [[ \$DEBUG_MODE == \"true\" ]]; then
    log_info \"调试信息: \$debug_data\"
fi
\`\`\`"
            ;;
        "safe_execute_command")
            example_code="
\`\`\`bash
# 安全命令执行
result=\$(safe_execute_command \"wg show wg0\" 30 \"true\")

# 带错误处理
if ! safe_execute_command \"systemctl restart wg-quICK@wg0\" >/dev/null 2>&1; then
    log_error \"服务重启失败\"
    exit 1
fi
\`\`\`"
            ;;
        "validate_ip_address")
            example_code="
\`\`\`bash
# IPv4地址验证
if validate_ip_address \"192.168.1.1\" \"ipv4\"; then
    echo \"有效的IPv4地址\"
fi

# IPv6地址验证
if validate_ip_address \"2001:db8::1\" \"ipv6\"; then
    echo \"有效的IPv6地址\"
fi

# 双向验证
if validate_ip_address \"192.168.1.1\"; then
    echo \"有效的IP地址\"
fi
\`\`\`"
            ;;
        "execute_with_cache")
            example_code="
\`\`\`bash
# 基本缓存使用
result=\$(execute_with_cache \"wg show\" \"wg_status\" 300)

# 强制刷新缓存
result=\$(execute_with_cache \"ping -c 1 8.8.8.8\" \"ping_test\" 60 \"true\")

# 带超时的缓存执行
result=\$(execute_with_cache \"complex_command\" \"cache_key\" 600)
\`\`\`"
            ;;
        "unified_error_handler")
            example_code="
\`\`\`bash
# 基本错误处理
unified_error_handler 101 \"权限不足\" \"PERMISSION\" \"network_config\"

# 带恢复策略的错误处理
unified_error_handler 7 \"网络连接失败\" \"NETWORK\" \"client_connection\" 3

# 配置错误处理
unified_error_handler 103 \"配置文件无效\" \"CONFIG\" \"config_validation\"
\`\`\`"
            ;;
        *)
            example_code="
\`\`\`bash
# 函数调用示例
$function_name
\`\`\`"
            ;;
    esac
    
    API_EXAMPLES[$function_name]="$example_code"
}

# 生成API概览
generate_api_overview() {
    local output_file="$1"
    
    {
        echo "# IPv6 WireGuard Manager API文档"
        echo ""
        echo "## 📖 API概览"
        echo ""
        echo "API文档自动生成时间: \$(date)"
        echo "项目版本: ${IPV6WGM_VERSION:-1.0.0}"
        echo ""
        echo "### 📊 统计信息"
        echo ""
        echo "- **总模块数**: ${#API_MODULES[@]}个"
        echo "- **总函数数**: ${#API_FUNCTIONS[@]}个"
        echo "- **生成示例**: ${#API_EXAMPLES[@]}个"
        echo ""
        
        echo "### 🏗️ 模块结构"
        echo ""
        echo "| 模块名 | 函数数量 | 描述 |"
        echo "|--------|----------|------|"
        
        for module in "${!API_MODULES[@]}"; do
            local func_count="${API_MODULES[$module]}"
            echo "| $module | $func_count | $(get_module_description "$module") |"
        done
        
        echo ""
        echo "---"
        echo ""
        
    } > "$output_file"
}

# 获取模块描述
get_module_description() {
    local module="$1"
    
    case "$module" in
        "common_functions") echo "公共函数库" ;;
        "wireguard_config") echo "WireGuard配置管理" ;;
        "web_management") echo "Web管理界面" ;;
        "security_functions") echo "安全功能模块" ;;
        "firewall_management") echo "防火墙管理" ;;
        "oauth_authentication") echo "OAuth认证" ;;
        "monitoring_alerting") echo "监控告警" ;;
        "backup_restore") echo "备份恢复" ;;
        "unified_error_manager") echo "统一错误管理" ;;
        "enhanced_cache_system") echo "增强缓存系统" ;;
        "memory_optimizer") echo "内存优化器" ;;
        "parallel_processor") echo "并行处理器" ;;
        "comprehensive_test_suite") echo "综合测试套件" ;;
        *) echo "功能模块" ;;
    esac
}

# 生成函数详细文档
generate_function_details() {
    local output_file="$1"
    
    echo "# 函数详细文档" >> "$output_file"
    echo "" >> "$output_file"
    
    # 按模块分组函数
    local modules=($(printf '%s\n' "${!API_MODULES[@]}" | sort))
    
    for module in "${modules[@]}"; do
        echo "## $module" >> "$output_file"
        echo "" >> "$output_file"
        echo "$(get_module_description "$module")" >> "$output_file"
        echo "" >> "$output_file"
        
        # 查找属于此模块的函数
        local module_functions=()
        for func in "${!API_FUNCTIONS[@]}"; do
            local func_info="${API_FUNCTIONS[$func]}"
            IFS='|' read -r func_module func_name <<< "$func_info"
            if [[ "$func_module" == "$module" ]]; then
                module_functions+=("$func")
            fi
        done
        
        # 按字母顺序排序函数
        IFS=$'\n' sorted_funcs=(\$(sort <<<\"\${module_functions[*]}\"))
        
        for func in "${sorted_funcs[@]}"; do
            generate_single_function_doc "$func" "$output_file"
        done
        
        echo "" >> "$output_file"
    done
}

# 生成单个函数的文档
generate_single_function_doc()` {
    local function_name="$1"
    local output_file="$2"
    local func_info="${API_FUNCTIONS[$function_name]}"
    
    IFS='|' read -r module_name func_name comment_count params examples <<< "$func_info"
    
    {
        echo "### $function_name"
        echo ""
        
        # 函数描述
        if [[ $comment_count -gt 0 ]]; then
            echo "${examples}" | sed 's/;/\n/g' | sed 's/^[\s]*//'
            echo ""
        else
            echo "这是 $module_name 模块中的一个函数。"
            echo ""
        fi
        
        # 参数信息
        if [[ -n "$params" ]]; then
            echo "**参数**:"
            echo ""
            for param in ${params[@]}; do
                echo "- \`$param\`: $(get_parameter_description "$function_name" "$param")"
            done
            echo ""
        fi
        
        # 返回值
        echo "**返回值**: $(get_function_return_description "$function_name")"
        echo ""
        
        # 使用示例
        if [[ -n "${API_EXAMPLES[$function_name]:-}" ]]; then
            echo "**使用示例:**
${API_EXAMPLES[$function_name]}"
            echo ""
        fi
        
        echo "---"
        echo ""
        
    } >> "$output_file"
}

# 获取参数描述
get_parameter_description() {
    local func="$1"
    local param="$2"
    
    case "$param" in
        "message"|"msg") echo "要输出的消息内容" ;;
        "log_level") echo "日志级别 (INFO/ERROR/WARNING/SUCCESS)" ;;
        "config_file") echo "配置文件路径" ;;
        "command") echo "要执行的命令" ;;
        "timeout") echo "超时时间（秒）" ;;
        "ip"|"ip_address") echo "IP地址" ;;
        "port") echo "端口号" ;;
        "cache_key") echo "缓存键名" ;;
        "error_code") echo "错误代码" ;;
        "error_message") echo "错误消息" ;;
        "error_type") echo "错误类型 (PERMISSION/NETWORK/CONFIG/SYSTEM)" ;;
        "context") echo "错误上下文描述" ;;
        *) echo "参数值" ;;
    esac
}

# 获取函数返回值描述
get_function_return_description() {
    local func="$1"
    
    case "$func" in
        "validate_*") echo "成功返回0，失败返回1" ;;
        "get_*"|"read_*"|"load_*") echo "返回相应的数据值" ;;
        "log_*") echo "无返回值，直接输出到日志" ;;
        "check_*"|"is_*") echo "检查结果为真时返回0，为假时返回1" ;;
        "execute_*") echo "命令执行成功时返回0，失败时返回非零值" ;;
        "generate_*") echo "返回生成的密钥、密码或其他生成的内容" ;;
        *) echo "通常返回0表示成功，非零值表示失败" ;;
    esac
}

# 生成快速参考
generate_quick_reference() {
    local output_file="$1"
    
    {
        echo "# API快速参考"
        echo ""
        echo "## 🔧 常用工具函数"
        echo ""
        echo "| 函数名 | 用途 | 示例 |"
        echo "|--------|------|------|"
        echo "| \`log_info\` | 信息日志 | \`log_info \"启动完成\"\` |"
        echo "| \`log_error\` | 错误日志 | \`log_error \"配置错误\"\` |"
        echo "| \`safe_execute_command\` | 安全执行 | \`safe_execute_command \"wg show\"\` |"
        echo "| \`validate_ip_address\` | IP验证 | \`validate_ip_address \"192.168.1.1\"\` |"
        echo "| \`execute_with_cache\` | 缓存执行 | \`execute_with_cache \"command\" \"key\"\` |"
        echo ""
        
        echo "## 🔒 安全相关函数"
        echo ""
        echo "| 函数名 | 用途 |"
        echo "|--------|------|"
        echo "| \`sanitize_input\` | 输入清理 |"
        echo "| \`validate_password\` | 密码验证 |"
        echo "| \`unified_error_handler\` | 统一错误处理 |"
        echo "| \`secure_store_config\` | 安全存储配置 |"
        echo ""
        
        echo "## ⚡ 性能相关函数"
        echo ""
        echo "| 函数名 | 用途 |"
        echo "|--------|------|"
        echo "| \`execute_with_cache\` | 带缓存的执行 |"
        echo "| \`parallel_execute\` | 并行执行 |"
        echo "| \`monitor_memory\` | 内存监控 |"
        echo "| \`optimize_performance\` | 性能优化 |"
        echo ""
        
        echo "## 🧪 测试相关函数"
        echo ""
        echo "| 函数名 | 用途 |"
        echo "|--------|------|"
        echo "| \`assert_true\` | 断言真值 |"
        echo "| \`assert_equals\` | 断言相等 |"
        echo "| \`run_all_tests\` | 运行所有测试 |"
        echo ""
        
    } >> "$output_file"
}

# 主函数：生成API文档
generate_api_documentation() {
    log_info "开始生成API文档..."
    
    # 创建输出目录
    mkdir -p "${DOC_CONFIG[output_dir]}"
    
    # 分析所有模块文件
    local modules_dir="${SCRIPT_DIR}/modules"
    if [[ -d "$modules_dir" ]]; then
        for module_file in "${modules_dir}"/*.sh; do
            if [[ -f "$module_file" ]]; then
                analyze_module_functions "$module_file"
            fi
        done
    fi
    
    # 生成示例代码
    for func in "${!API_FUNCTIONS[@]}"; do
        generate_function_examples "$func"
    done
    
    # 生成主文档文件
    local main_doc="${DOC_CONFIG[output_dir]}/API.md"
    
    generate_api_overview "$main_doc"
    generate_function_details "$main_doc"
    generate_quick_reference "$main_doc"
    
    # 生成JSON格式的API数据
    local json_doc="${DOC_CONFIG[output_dir]}/api_data.json"
    generate_json_api_data "$json_doc"
    
    # 生成HTML版本（如果有jq）
    if command -v jq >/dev/null 2>&1; then
        local html_doc="${DOC_CONFIG[output_dir]}/API.html"
        generate_html_api_doc "$html_doc"
    fi
    
    log_success "API文档生成完成: ${DOC_CONFIG[output_dir]}"
    log_info "文档文件:"
    log_info "  - API.md (Markdown格式)"
    log_info "  - api_data.json (JSON格式)"
    [[ -f "${DOC_CONFIG[output_dir]}/API.html" ]] && log_info "  - API.html (HTML格式)"
}

# 生成JSON格式API数据
generate_json_api_data() {
    local output_file="$1"
    
    {
        echo "{"
        echo "  \"api_version\": \"${IPV6WGM_VERSION:-1.0.0}\","
        echo "  \"generated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"modules\": {"
        
        local module_count=0
        for module in "${!API_MODULES[@]}"; do
            [[ $module_count -gt 0 ]] && echo ","
            echo "    \"$module\": {"
            echo "      \"description\": \"$(get_module_description "$module")\","
            echo "      \"function_count\": ${API_MODULES[$module]},"
            echo "      \"functions\": ["
            
            local func_count=0
            for func in "${!API_FUNCTIONS[@]}"; do
                local func_info="${API_FUNCTIONS[$func]}"
                IFS='|' read -r func_module func_name <<< "$func_info"
                if [[ "$func_module" == "$module" ]]; then
                    [[ $func_count -gt 0 ]] && echo ","
                    echo "        \"$func\""
                    ((func_count++))
                fi
            done
            
            echo "      ]"
            echo "    }"
            ((module_count++))
        done
        
        echo "  }"
        echo "}"
        
    } > "$output_file"
}

# 生成HTML格式文档
generate_html_api_doc() {
    local output_file="$1"
    
    {
        cat << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPv6 WireGuard Manager API文档</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .toc { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .function-section { margin: 30px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .highlight { background: #fff3cd; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager API文档</h1>
        <p>自动生成时间: $(date)</p>
    </div>
    
    <div class="toc">
        <h2>📚 目录</h2>
        <ul>
            <li><a href="#overview">API概览</a></li>
            <li><a href="#functions">函数详细文档</a></li>
            <li><a href="#examples">使用示例</a></li>
        </ul>
    </div>
    
    <div id="overview">
        <h2>📖 API概览</h2>
        <p>IPv6 WireGuard Manager 提供了丰富的函数API来管理WireGuard VPN配置。</p>
        
        <h3>📊 统计信息</h3>
        <ul>
            <li><strong>总模块数</strong>: ${#API_MODULES[@]}个</li>
            <li><strong>总函数数</strong>: ${#API_FUNCTIONS[@]}个</li>
            <li><strong>生成示例</strong>: ${#API_EXAMPLES[@]}个</li>
        </ul>
    </div>
    
    <div id="functions">
        <h2>🔧 函数详细文档</h2>
        <p>以下是所有可用的函数API及其详细说明。</p>
    </div>
    
    <div id="examples">
        <h2>💡 使用示例</h2>
        <div class="highlight">
            <p>查看具体的函数文档获取更多示例代码。</p>
        </div>
    </div>
</body>
</html>
EOF
    } > "$output_file"
}

# 导出函数
export -f analyze_module_functions analyze_function_header generate_function_examples
export -f generate_api_documentation generate_json_api_data generate_html_api_doc
export -f get_module_description get_parameter_description get_function_return_description

# 别名
alias gen_api_docs=generate_api_documentation
alias api_docs=generate_api_documentation
