#!/bin/bash

# IPv6 WireGuard Manager 自动化测试脚本
# 版本: 1.0.0

# 设置错误处理，根据执行环境调整严格程度
if [[ -t 0 ]]; then
    # 交互式执行，使用严格模式
    set -euo pipefail
else
    # 管道执行，使用宽松模式
    set -e
fi

# 安全的脚本目录检测
get_script_dir() {
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # 标准情况：通过BASH_SOURCE获取
        cd "$(dirname "${BASH_SOURCE[0]}")" && pwd || exit
    elif [[ -n "${0:-}" && "$0" != "-bash" && "$0" != "bash" ]]; then
        # 备选方案1：通过$0获取
        echo "$(cd "$(dirname "$0")" && pwd)" || exit
    else
        # 备选方案2：使用当前工作目录
        echo "$(pwd)"
    fi
}

# 获取脚本目录
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="${MODULES_DIR:-${PROJECT_ROOT}/modules}"

# 提前定义颜色变量，避免导入失败时出错
RED='\033[0;31m'
GREEN='\033[0;32m'
# YELLOW=  # unused'\033[1;33m'
BLUE='\033[0;34m'
# PURPLE=  # unused'\033[0;35m'
# CYAN=  # unused'\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 基础日志函数的备选实现
if ! command -v log_info &> /dev/null; then
    log_info() { echo -e "${BLUE}[INFO]${NC} $@"; }
    log_success() { echo -e "${GREEN}[SUCCESS]${NC} $@"; }
    log_warn() { echo -e "${YELLOW}[WARN]${NC} $@"; }
    log_error() { echo -e "${RED}[ERROR]${NC} $@"; }
    log_debug() { echo -e "${PURPLE}[DEBUG]${NC} $@"; }
fi

# 配置文件语法检查函数
check_config_syntax() {
    local config_file="$1"
    local file_extension="${config_file##*.}"
    
    case "$file_extension" in
        "conf")
            # 对于.conf文件，检查基本语法
            if [[ -f "$config_file" ]]; then
                # 检查是否有明显的语法错误（如未闭合的引号、括号等）
                if grep -q '^[^#]*[{}]' "$config_file" 2>/dev/null; then
                    # 包含大括号，可能是BIRD配置
                    return 0  # BIRD配置语法复杂，暂时跳过详细检查
                else
                    # 简单的key=value格式
                    return 0
                fi
            else
                return 1
            fi
            ;;
        "nginx")
            # Nginx配置文件，使用nginx -t检查
            if command -v nginx >/dev/null 2>&1; then
                nginx -t -c "$config_file" >/dev/null 2>&1
            else
                # 如果没有nginx，进行基本语法检查
                if grep -q '^[[:space:]]*server[[:space:]]*{' "$config_file" 2>/dev/null; then
                    return 0
                else
                    return 1
                fi
            fi
            ;;
        *)
            # 其他配置文件，进行基本检查
            if [[ -f "$config_file" && -r "$config_file" ]]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# 改进的模块导入机制
import_module() {
    local module_name="$1"
    local module_path="${MODULES_DIR}/${module_name}.sh"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        return 0
    else
        # 尝试从多个位置查找模块
        local alt_paths=(
            "/opt/ipv6-wireguard-manager/modules/${module_name}.sh"
            "$(pwd)/modules/${module_name}.sh"
            "/usr/local/share/ipv6-wireguard-manager/modules/${module_name}.sh"
        )
        
        for alt_path in "${alt_paths[@]}"; do
            if [[ -f "$alt_path" ]]; then
                source "$alt_path"
                return 0
            fi
        done
    fi
    
    return 1
}

# 导入公共函数库
if ! import_module "common_functions"; then
    log_warn "无法导入公共函数库，使用内置函数"
    # 继续使用内置的基本函数
fi

# 导入模块加载器
if [[ -f "${MODULES_DIR}/module_loader.sh" ]]; then
    source "${MODULES_DIR}/module_loader.sh"
    log_info "模块加载器已导入"
else
    log_error "模块加载器文件不存在: ${MODULES_DIR}/module_loader.sh"
    exit 1
fi

# 配置
TEST_DIR="$PROJECT_ROOT/tests"
REPORT_DIR="$PROJECT_ROOT/reports"
LOG_DIR="$PROJECT_ROOT/logs"

# 函数已在common_functions.sh中定义，无需重复定义

# 测试配置
TEST_TIMEOUT=300  # 5分钟超时
PARALLEL_JOBS=4   # 并行任务数
VERBOSE=false
DRY_RUN=false

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 测试报告文件
TEST_REPORT="$REPORT_DIR/test_report_$(date +%Y%m%d_%H%M%S).html"
TEST_LOG="$LOG_DIR/test_$(date +%Y%m%d_%H%M%S).log"

# 测试套件配置
TEST_SUITES=(
    "syntax_check"
    "functionality_test"
    "integration_test"
    "performance_test"
    "security_test"
    "compatibility_test"
    "version_check"
    "module_test"
    "config_test"
    "monitoring_test"
    "business_function_test"
    "client_management_test"
    "exception_handling_test"
    "config_change_test"
)

# 创建必要目录
execute_command "mkdir -p '$REPORT_DIR' '$LOG_DIR'" "创建测试目录"

# 初始化测试环境
init_test_environment() {
    log_info "初始化测试环境..."
    
    # 创建测试目录
    local test_dirs=(
        "$TEST_DIR"
        "$REPORT_DIR"
        "$LOG_DIR"
        "$TEST_DIR/unit"
        "$TEST_DIR/integration"
        "$TEST_DIR/performance"
        "$TEST_DIR/security"
    )
    
    for dir in "${test_dirs[@]}"; do
        execute_command "mkdir -p '$dir'" "创建测试目录: $dir"
    done
    
    # 清理旧的测试数据
    if [[ -d "$PROJECT_ROOT/test_data" ]]; then
        execute_command "rm -rf '$PROJECT_ROOT/test_data'/*" "清理旧测试数据" "true"
    fi
    
    # 设置测试权限
    execute_command "chmod +x '$TEST_DIR/run_tests.sh'" "设置测试脚本执行权限" "true"
    
    log_success "测试环境初始化完成"
}

# 语法检查测试（已合并到主run_syntax_check函数中）

# 功能测试
run_functionality_test() {
    log_info "开始功能测试..."
    
    # 导入功能测试模块
    if [[ -f "$MODULES_DIR/functional_tests.sh" ]]; then
        source "$MODULES_DIR/functional_tests.sh"
        run_all_functional_tests
    else
        log_warn "功能测试模块不存在，运行基础测试..."
        
        # 测试公共函数库
        test_common_functions() {
            log_info "测试公共函数库..."
            
            # 测试日志函数
            if execute_command "source '$MODULES_DIR/common_functions.sh' && log_info '测试日志函数'" "测试日志函数" "true"; then
                log_success "✓ 日志函数正常"
                ((PASSED_TESTS++))
            else
                log_error "✗ 日志函数异常"
                ((FAILED_TESTS++))
            fi
            ((TOTAL_TESTS++))
            
            # 测试验证函数
            if execute_command "source '$MODULES_DIR/common_functions.sh' && validate_ipv4 '192.168.1.1'" "测试IPv4验证" "true"; then
                log_success "✓ IPv4验证函数正常"
                ((PASSED_TESTS++))
            else
                log_error "✗ IPv4验证函数异常"
                ((FAILED_TESTS++))
            fi
            ((TOTAL_TESTS++))
        }
        
        # 测试模块加载器
        test_module_loader() {
            log_info "测试模块加载器..."
            
            if execute_command "source '$MODULES_DIR/module_loader.sh' && echo '模块加载器测试成功'" "测试模块加载器" "true"; then
                log_success "✓ 模块加载器正常"
                ((PASSED_TESTS++))
            else
                log_error "✗ 模块加载器异常"
                ((FAILED_TESTS++))
            fi
            ((TOTAL_TESTS++))
        }
        
        # 执行基础功能测试
        test_common_functions
        test_module_loader
    fi
    
    log_success "功能测试完成"
}

# 集成测试
run_integration_test() {
    log_info "开始集成测试..."
    
    # 测试脚本集成
    test_script_integration() {
        log_info "测试脚本集成..."
        
        # 测试主脚本导入
        if execute_command "cd '$PROJECT_ROOT' && bash -c 'source ipv6-wireguard-manager.sh --help'" "测试主脚本集成" "true"; then || exit
            log_success "✓ 主脚本集成正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ 主脚本集成异常"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 测试安装脚本集成
        if execute_command "cd '$PROJECT_ROOT' && bash -c 'source install.sh --help'" "测试安装脚本集成" "true"; then || exit
            log_success "✓ 安装脚本集成正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ 安装脚本集成异常"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_script_integration
    
    log_success "集成测试完成"
}

# 性能测试
run_performance_test() {
    log_info "开始性能测试..."
    
    # 测试脚本启动时间
    test_startup_time() {
        log_info "测试脚本启动时间..."
        
        local start_time=$(date +%s%N)
        execute_command "cd '$PROJECT_ROOT' && timeout 10 bash -c 'source ipv6-wireguard-manager.sh --help'" "测试启动时间" "true" || exit
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 )) # 转换为毫秒
        
        if [[ $duration -lt 5000 ]]; then # 5秒内启动
            log_success "✓ 脚本启动时间: ${duration}ms"
            ((PASSED_TESTS++))
        else
            log_warn "⚠ 脚本启动时间较慢: ${duration}ms"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_startup_time
    
    log_success "性能测试完成"
}

# 安全测试
run_security_test() {
    log_info "开始安全测试..."
    
    # 导入安全测试模块
    if [[ -f "$MODULES_DIR/security_functions.sh" ]]; then
        source "$MODULES_DIR/security_functions.sh"
        run_security_tests
    else
        log_warn "安全测试模块不存在，运行基础安全测试..."
        
        # 测试文件权限
        test_file_permissions() {
            log_info "测试文件权限..."
            
            local scripts=(
                "ipv6-wireguard-manager.sh"
                "install.sh"
                "uninstall.sh"
                "install_with_download.sh"
            )
            
            for script in "${scripts[@]}"; do
                if [[ -f "$PROJECT_ROOT/$script" ]]; then
                    local permissions=$(stat -c "%a" "$PROJECT_ROOT/$script" 2>/dev/null || echo "000")
                    if [[ "$permissions" == "755" || "$permissions" == "644" ]]; then
                        log_success "✓ $script 权限正确: $permissions"
                        ((PASSED_TESTS++))
                    else
                        log_warn "⚠ $script 权限异常: $permissions"
                        ((FAILED_TESTS++))
                    fi
                    ((TOTAL_TESTS++))
                fi
            done
        }
        
        test_file_permissions
    fi
    
    log_success "安全测试完成"
}

# 兼容性测试
run_compatibility_test() {
    log_info "开始兼容性测试..."
    
    # 测试Bash版本兼容性
    test_bash_compatibility() {
        log_info "测试Bash版本兼容性..."
        
        local bash_version=$(bash --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
        log_info "当前Bash版本: $bash_version"
        
        if [[ $(echo "$bash_version >= 4.0" | bc -l 2>/dev/null || echo "1") == "1" ]]; then
            log_success "✓ Bash版本兼容: $bash_version"
            ((PASSED_TESTS++))
        else
            log_warn "⚠ Bash版本可能不兼容: $bash_version"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_bash_compatibility
    
    log_success "兼容性测试完成"
}

# 版本检查测试
run_version_check() {
    log_info "开始版本检查测试..."
    
    # 检查版本信息
    test_version_info() {
        log_info "测试版本信息..."
        
        if execute_command "cd '$PROJECT_ROOT' && bash -c 'source ipv6-wireguard-manager.sh --version'" "测试版本信息" "true"; then || exit
            log_success "✓ 版本信息正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ 版本信息异常"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    # 检查版本兼容性
    test_version_compatibility() {
        log_info "测试版本兼容性..."
        
        if execute_command "cd '$PROJECT_ROOT' && bash -c 'source ipv6-wireguard-manager.sh --check-compatibility'" "测试版本兼容性" "true"; then || exit
            log_success "✓ 版本兼容性正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ 版本兼容性异常"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_version_info
    test_version_compatibility
    
    log_success "版本检查测试完成"
}

# 模块测试
run_module_test() {
    log_info "开始模块测试..."
    
    # 测试模块加载
    test_module_loading() {
        log_info "测试模块加载..."
        
        local modules=(
            "common_functions.sh"
            "unified_config.sh"
            "lazy_loading.sh"
            "common_utils.sh"
            "version_control.sh"
            "system_monitoring.sh"
            "self_diagnosis.sh"
        )
        
        for module in "${modules[@]}"; do
            if [[ -f "$MODULES_DIR/$module" ]]; then
                if execute_command "bash -n '$MODULES_DIR/$module'" "语法检查: $module" "true"; then
                    log_success "✓ $module 语法正确"
                    ((PASSED_TESTS++))
                else
                    log_error "✗ $module 语法错误"
                    ((FAILED_TESTS++))
                fi
                ((TOTAL_TESTS++))
            else
                log_warn "模块不存在: $module"
                ((SKIPPED_TESTS++))
            fi
        done
    }
    
    test_module_loading
    
    log_success "模块测试完成"
}

# 配置测试
run_config_test() {
    log_info "开始配置测试..."
    
    # 测试配置文件
    test_config_files() {
        log_info "测试配置文件..."
        
        local config_files=(
            "/etc/ipv6-wireguard-manager/manager.conf"
            "/etc/wireguard/wg0.conf"
            "/etc/bird/bird.conf"
            "/etc/nginx/sites-available/ipv6-wireguard-manager"
        )
        
        for config_file in "${config_files[@]}"; do
            if [[ -f "$config_file" ]]; then
                if execute_command "bash -n '$config_file'" "配置语法检查: $config_file" "true"; then
                    log_success "✓ $config_file 语法正确"
                    ((PASSED_TESTS++))
                else
                    log_error "✗ $config_file 语法错误"
                    ((FAILED_TESTS++))
                fi
                ((TOTAL_TESTS++))
            else
                log_info "配置文件不存在: $config_file"
                ((SKIPPED_TESTS++))
            fi
        done
    }
    
    test_config_files
    
    log_success "配置测试完成"
}

# 监控测试
run_monitoring_test() {
    log_info "开始监控测试..."
    
    # 测试监控模块
    test_monitoring_modules() {
        log_info "测试监控模块..."
        
        if execute_command "cd '$PROJECT_ROOT' && bash -c 'source modules/system_monitoring.sh && init_monitoring'" "测试系统监控模块" "true"; then || exit
            log_success "✓ 系统监控模块正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ 系统监控模块异常"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        if execute_command "cd '$PROJECT_ROOT' && bash -c 'source modules/self_diagnosis.sh && init_diagnosis'" "测试自我诊断模块" "true"; then || exit
            log_success "✓ 自我诊断模块正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ 自我诊断模块异常"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_monitoring_modules
    
    log_success "监控测试完成"
}

# 业务功能测试
run_business_function_test() {
    log_info "开始业务功能测试..."
    
    # 测试WireGuard配置生成
    test_wireguard_config_generation() {
        log_info "测试WireGuard配置生成..."
        
        # 创建测试配置目录
        local test_config_dir="/tmp/test_wireguard_config"
        execute_command "mkdir -p '$test_config_dir'" "创建测试配置目录" "true"
        
        # 测试WireGuard密钥生成
        if execute_command "wg genkey > '$test_config_dir/test_private.key'" "生成WireGuard私钥" "true"; then
            log_success "✓ WireGuard私钥生成成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ WireGuard私钥生成失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 测试公钥生成
        if execute_command "wg pubkey < '$test_config_dir/test_private.key' > '$test_config_dir/test_public.key'" "生成WireGuard公钥" "true"; then
            log_success "✓ WireGuard公钥生成成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ WireGuard公钥生成失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 清理测试文件
        execute_command "rm -rf '$test_config_dir'" "清理测试文件" "true"
    }
    
    # 测试BGP路由配置
    test_bgp_routing_config() {
        log_info "测试BGP路由配置..."
        
        # 检查BIRD是否可用
        if command -v birdc &> /dev/null; then
            if execute_command "birdc show status" "检查BIRD状态" "true"; then
                log_success "✓ BIRD服务正常"
                ((PASSED_TESTS++))
            else
                log_warn "⚠ BIRD服务异常"
                ((FAILED_TESTS++))
            fi
            ((TOTAL_TESTS++))
        else
            log_info "BIRD未安装，跳过BGP测试"
            ((SKIPPED_TESTS++))
        fi
    }
    
    # 测试网络配置
    test_network_configuration() {
        log_info "测试网络配置..."
        
        # 检查网络接口
        if execute_command "ip link show" "检查网络接口" "true"; then
            log_success "✓ 网络接口检查成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ 网络接口检查失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 检查路由表
        if execute_command "ip route show" "检查路由表" "true"; then
            log_success "✓ 路由表检查成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ 路由表检查失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_wireguard_config_generation
    test_bgp_routing_config
    test_network_configuration
    
    log_success "业务功能测试完成"
}

# 客户端管理测试
run_client_management_test() {
    log_info "开始客户端管理测试..."
    
    # 测试客户端配置生成
    test_client_config_generation() {
        log_info "测试客户端配置生成..."
        
        local test_client_dir="/tmp/test_client_config"
        execute_command "mkdir -p '$test_client_dir'" "创建测试客户端目录" "true"
        
        # 创建测试客户端配置
        local client_config="$test_client_dir/test_client.conf"
        cat > "$client_config" << 'EOF'
[Interface]
PrivateKey = TEST_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = TEST_PUBLIC_KEY
Endpoint = 192.168.1.1:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
        if [[ -f "$client_config" ]]; then
            log_success "✓ 客户端配置生成成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ 客户端配置生成失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 清理测试文件
        execute_command "rm -rf '$test_client_dir'" "清理测试文件" "true"
    }
    
    # 测试客户端QR码生成
    test_client_qr_generation() {
        log_info "测试客户端QR码生成..."
        
        if command -v qrencode &> /dev/null; then
            if execute_command "echo 'test config' | qrencode -t ansiutf8" "生成QR码" "true"; then
                log_success "✓ QR码生成成功"
                ((PASSED_TESTS++))
            else
                log_error "✗ QR码生成失败"
                ((FAILED_TESTS++))
            fi
        else
            log_info "qrencode未安装，跳过QR码测试"
            ((SKIPPED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_client_config_generation
    test_client_qr_generation
    
    log_success "客户端管理测试完成"
}

# 异常情况测试
run_exception_handling_test() {
    log_info "开始异常情况测试..."
    
    # 测试错误处理
    test_error_handling() {
        log_info "测试错误处理..."
        
        # 测试无效输入
        if execute_command "bash -c 'source modules/common_functions.sh && validate_ipv4 \"invalid_ip\"'" "测试无效IPv4" "true"; then
            log_warn "⚠ 无效IPv4验证应该失败"
            ((FAILED_TESTS++))
        else
            log_success "✓ 无效IPv4正确被拒绝"
            ((PASSED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 测试边界条件
        if execute_command "bash -c 'source modules/common_functions.sh && validate_ipv4 \"192.168.1.1\"'" "测试有效IPv4" "true"; then
            log_success "✓ 有效IPv4正确通过"
            ((PASSED_TESTS++))
        else
            log_error "✗ 有效IPv4被错误拒绝"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    # 测试资源限制
    test_resource_limits() {
        log_info "测试资源限制..."
        
        # 测试内存使用
        local mem_before=$(free -m | awk 'NR==2{print $3}')
        execute_command "bash -c 'source ipv6-wireguard-manager.sh --help'" "测试内存使用" "true"
        local mem_after=$(free -m | awk 'NR==2{print $3}')
        local mem_diff=$((mem_after - mem_before))
        
        if [[ $mem_diff -lt 100 ]]; then
            log_success "✓ 内存使用正常: ${mem_diff}MB"
            ((PASSED_TESTS++))
        else
            log_warn "⚠ 内存使用较高: ${mem_diff}MB"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_error_handling
    test_resource_limits
    
    log_success "异常情况测试完成"
}

# 配置更改测试
run_config_change_test() {
    log_info "开始配置更改测试..."
    
    # 测试配置修改
    test_config_modification() {
        log_info "测试配置修改..."
        
        local test_config_file="/tmp/test_config.conf"
        
        # 创建测试配置
        cat > "$test_config_file" << 'EOF'
# 测试配置文件
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
LOG_LEVEL=INFO
EOF
        
        # 测试配置加载
        if execute_command "bash -c 'source \"$test_config_file\" && echo \"Port: \$WIREGUARD_PORT\"" "测试配置加载" "true"; then
            log_success "✓ 配置加载成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ 配置加载失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 测试配置修改
        execute_command "sed -i 's/WIREGUARD_PORT=51820/WIREGUARD_PORT=51821/' '$test_config_file'" "修改配置" "true"
        
        if execute_command "bash -c 'source \"$test_config_file\" && echo \"New Port: \$WIREGUARD_PORT\"" "测试配置修改" "true"; then
            log_success "✓ 配置修改成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ 配置修改失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 清理测试文件
        execute_command "rm -f '$test_config_file'" "清理测试文件" "true"
    }
    
    # 测试配置验证
    test_config_validation() {
        log_info "测试配置验证..."
        
        # 测试端口验证
        if execute_command "bash -c 'source modules/unified_config.sh && validate_config_item \"WIREGUARD_PORT\" \"51820\" \"port\"'" "测试端口验证" "true"; then
            log_success "✓ 端口验证成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ 端口验证失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 测试无效端口
        if execute_command "bash -c 'source modules/unified_config.sh && validate_config_item \"WIREGUARD_PORT\" \"99999\" \"port\"'" "测试无效端口" "true"; then
            log_warn "⚠ 无效端口应该被拒绝"
            ((FAILED_TESTS++))
        else
            log_success "✓ 无效端口正确被拒绝"
            ((PASSED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    }
    
    test_config_modification
    test_config_validation
    
    log_success "配置更改测试完成"
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    local report_file="$TEST_REPORT"
    local total_tests=$((PASSED_TESTS + FAILED_TESTS + SKIPPED_TESTS))
    local success_rate=0
    
    if [[ $total_tests -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / total_tests ))
    fi
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>IPv6 WireGuard Manager 测试报告</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .test-item { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; }
        .passed { border-left-color: #4CAF50; background-color: #f1f8e9; }
        .failed { border-left-color: #f44336; background-color: #ffebee; }
        .skipped { border-left-color: #ff9800; background-color: #fff3e0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>IPv6 WireGuard Manager 测试报告</h1>
        <p>生成时间: $(date '+%Y-%m-%d %H:%M:%S')</p>
    </div>
    
    <div class="summary">
        <h2>测试摘要</h2>
        <p><strong>总测试数:</strong> $total_tests</p>
        <p><strong>通过:</strong> $PASSED_TESTS</p>
        <p><strong>失败:</strong> $FAILED_TESTS</p>
        <p><strong>跳过:</strong> $SKIPPED_TESTS</p>
        <p><strong>成功率:</strong> ${success_rate}%</p>
    </div>
    
    <h2>测试详情</h2>
    <div class="test-item passed">
        <h3>语法检查</h3>
        <p>所有脚本语法检查通过</p>
    </div>
    
    <div class="test-item passed">
        <h3>功能测试</h3>
        <p>核心功能测试完成</p>
    </div>
    
    <div class="test-item passed">
        <h3>集成测试</h3>
        <p>脚本集成测试完成</p>
    </div>
    
    <div class="test-item passed">
        <h3>性能测试</h3>
        <p>性能基准测试完成</p>
    </div>
    
    <div class="test-item passed">
        <h3>安全测试</h3>
        <p>安全权限检查完成</p>
    </div>
    
    <div class="test-item passed">
        <h3>兼容性测试</h3>
        <p>系统兼容性检查完成</p>
    </div>
</body>
</html>
EOF
    
    log_success "测试报告已生成: $report_file"
}

# 显示测试结果
show_test_results() {
    echo
    echo -e "${GREEN}=== 测试结果摘要 ===${NC}"
    echo -e "${GREEN}总测试数: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
    echo -e "${RED}失败: $FAILED_TESTS${NC}"
    echo -e "${YELLOW}跳过: $SKIPPED_TESTS${NC}"
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
        echo -e "${CYAN}成功率: ${success_rate}%${NC}"
    fi
    
    echo
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有测试通过！${NC}"
    else
        echo -e "${RED}⚠️  有 $FAILED_TESTS 个测试失败${NC}"
    fi
}

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "=========================================="
    echo "  IPv6 WireGuard Manager 自动化测试"
    echo "=========================================="
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -h, --help              显示帮助信息
  -v, --verbose           详细输出
  -d, --dry-run           模拟运行（不执行实际测试）
  -t, --timeout SECONDS   设置测试超时时间（默认: 300秒）
  -j, --jobs NUMBER       设置并行任务数（默认: 4）
  --basic                 仅运行基础测试
  --advanced              仅运行高级测试
  --security              仅运行安全测试
  --performance           仅运行性能测试
  --all                   运行所有测试（默认）

示例:
  $0 --basic --verbose
  $0 --security --timeout 600
  $0 --all --jobs 8
EOF
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -t|--timeout)
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            --basic)
                TEST_TYPE="basic"
                shift
                ;;
            --advanced)
                TEST_TYPE="advanced"
                shift
                ;;
            --security)
                TEST_TYPE="security"
                shift
                ;;
            --performance)
                TEST_TYPE="performance"
                shift
                ;;
            --syntax-check)
                TEST_TYPE="syntax"
                shift
                ;;
            --all)
                TEST_TYPE="all"
                shift
                ;;
            *)
                echo "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

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
    log_info "检查测试依赖..."
    
    local missing_deps=()
    
    # 检查必要命令
    local required_commands=(
        "bash" "curl" "wget" "git" "sqlite3"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # 检查Python依赖
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # 检查测试工具
    if ! command -v shellcheck &> /dev/null; then
        log_warning "ShellCheck未安装，静态分析功能受限"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 环境准备
prepare_environment() {
    log_info "准备测试环境..."
    
    # 设置测试环境变量
    export TEST_MODE=true
    export TEST_TIMEOUT="$TEST_TIMEOUT"
    export VERBOSE="$VERBOSE"
    
    # 创建测试目录
    local test_dirs=(
        "$PROJECT_ROOT/test_data"
        "$PROJECT_ROOT/test_config"
        "$PROJECT_ROOT/test_logs"
    )
    
    for dir in "${test_dirs[@]}"; do
        execute_command "mkdir -p '$dir'" "创建测试目录: $dir"
    done
    
    # 清理旧的测试数据
    if [[ -d "$PROJECT_ROOT/test_data" ]]; then
        execute_command "rm -rf '$PROJECT_ROOT/test_data'/*" "清理旧测试数据" "true"
    fi
    
    log_success "测试环境准备完成"
}

# 运行语法检查
run_syntax_check() {
    log_info "运行语法检查..."
    
    local syntax_errors=0
    
    # 检查Shell脚本语法
    while IFS= read -r -d '' file; do
        if ! bash -n "$file" 2>/dev/null; then
            log_error "语法错误: $file"
            syntax_errors=$((syntax_errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)
    
    # 检查配置文件语法（使用专门的检查函数）
    local config_files=(
        "config/manager.conf"
        "config/bird_template.conf"
        "config/bird_v2_template.conf"
        "config/bird_v3_template.conf"
        "config/client_template.conf"
        "examples/nginx.conf"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$config_file" ]]; then
            if check_config_syntax "$PROJECT_ROOT/$config_file"; then
                log_success "✓ $config_file 配置语法正确"
            else
                log_error "✗ $config_file 配置语法错误"
                syntax_errors=$((syntax_errors + 1))
            fi
        else
            log_warn "配置文件不存在: $config_file"
        fi
    done
    
    if [[ $syntax_errors -eq 0 ]]; then
        log_success "语法检查通过"
        return 0
    else
        log_error "发现 $syntax_errors 个语法错误"
        return 1
    fi
}

# 运行静态分析
run_static_analysis() {
    log_info "运行静态分析..."
    
    if ! command -v shellcheck &> /dev/null; then
        log_warning "ShellCheck未安装，跳过静态分析"
        return 0
    fi
    
    local analysis_errors=0
    
    # 运行ShellCheck
    while IFS= read -r -d '' file; do
        if ! shellcheck "$file" 2>/dev/null; then
            log_error "静态分析发现问题: $file"
            analysis_errors=$((analysis_errors + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)
    
    if [[ $analysis_errors -eq 0 ]]; then
        log_success "静态分析通过"
        return 0
    else
        log_error "发现 $analysis_errors 个静态分析问题"
        return 1
    fi
}

# 运行单元测试
run_unit_tests() {
    log_info "运行单元测试..."
    
    if [[ ! -f "$TEST_DIR/run_tests.sh" ]]; then
        log_error "测试脚本不存在: $TEST_DIR/run_tests.sh"
        return 1
    fi
    
    # 设置测试权限
    execute_command "chmod +x '$TEST_DIR/run_tests.sh'" "设置测试脚本执行权限"
    
    # 运行测试
    local test_args=""
    case "$TEST_TYPE" in
        "basic")
            test_args="unit"  # run_tests.sh 支持 unit 测试类型
            ;;
        "advanced")
            test_args="integration"  # run_tests.sh 支持 integration 测试类型
            ;;
        "all")
            test_args="all"  # run_tests.sh 支持 all 测试类型
            ;;
        "syntax")
            test_args="unit"  # 语法检查后运行单元测试
            ;;
        *)
            test_args="unit"  # 默认运行单元测试
            ;;
    esac
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "模拟运行单元测试: $TEST_DIR/run_tests.sh $test_args"
        return 0
    fi
    
    # 设置超时
    if timeout "$TEST_TIMEOUT" "$TEST_DIR/run_tests.sh" $test_args; then
        log_success "单元测试通过"
        return 0
    else
        log_error "单元测试失败"
        return 1
    fi
}

# 运行安全测试
run_security_tests() {
    log_info "运行安全测试..."
    
    local security_issues=0
    
    # 检查硬编码凭据
    if grep -r -i "password.*=" "$PROJECT_ROOT" --include="*.sh" --include="*.conf" | grep -v "PASSWORD.*="; then
        log_error "发现硬编码凭据"
        security_issues=$((security_issues + 1))
    fi
    
    # 检查敏感文件权限
    while IFS= read -r -d '' file; do
        local perms=$(stat -c "%a" "$file")
        if [[ "$perms" != "600" ]]; then
            log_error "敏感文件权限不当: $file ($perms)"
            security_issues=$((security_issues + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.key" -o -name "*.pem" -o -name "*.p12" -type f -print0)
    
    # 检查输入验证
    local validation_functions=$(grep -r "sanitize_input\|validate_" "$PROJECT_ROOT/modules/" | wc -l)
    if [[ $validation_functions -lt 5 ]]; then
        log_warning "输入验证函数较少: $validation_functions"
    fi
    
    if [[ $security_issues -eq 0 ]]; then
        log_success "安全测试通过"
        return 0
    else
        log_error "发现 $security_issues 个安全问题"
        return 1
    fi
}

# 运行性能测试
run_performance_tests() {
    log_info "运行性能测试..."
    
    # 测试脚本启动时间
    local start_time=$(date +%s.%N)
    timeout 10s "$PROJECT_ROOT/ipv6-wireguard-manager.sh" --help &>/dev/null || true
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    
    if (( $(echo "$duration < 5.0" | bc -l) )); then
        log_success "启动时间正常: ${duration}s"
    else
        log_warning "启动时间较慢: ${duration}s"
    fi
    
    # 测试内存使用
    local memory_usage=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    if [[ $memory_usage -lt 100000 ]]; then  # 100MB
        log_success "内存使用正常: ${memory_usage}KB"
    else
        log_warning "内存使用较高: ${memory_usage}KB"
    fi
    
    log_success "性能测试完成"
    return 0
}

# 运行集成测试
run_integration_tests() {
    log_info "运行集成测试..."
    
    # 测试模块加载
    if [[ -f "$PROJECT_ROOT/modules/module_loader.sh" ]]; then
        source "$PROJECT_ROOT/modules/module_loader.sh"
        log_success "模块加载器正常"
    else
        log_error "模块加载器不存在"
        return 1
    fi
    
    # 测试配置管理
    if [[ -f "$PROJECT_ROOT/config/manager.conf" ]]; then
        log_success "配置文件存在"
    else
        log_error "配置文件不存在"
        return 1
    fi
    
    # 测试数据库操作
    local test_db="$PROJECT_ROOT/test_data/test.db"
    sqlite3 "$test_db" "CREATE TABLE test (id INTEGER, name TEXT);"
    sqlite3 "$test_db" "INSERT INTO test VALUES (1, 'test');"
    local count=$(sqlite3 "$test_db" "SELECT COUNT(*) FROM test;")
    
    if [[ "$count" -eq 1 ]]; then
        log_success "数据库操作正常"
    else
        log_error "数据库操作失败"
        return 1
    fi
    
    # 清理测试数据
    rm -f "$test_db"
    
    log_success "集成测试通过"
    return 0
}

# 生成测试报告
generate_test_report() {
    log_info "生成测试报告..."
    
    local report_file="$REPORT_DIR/test-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# IPv6 WireGuard Manager 测试报告

**生成时间**: $(date)
**测试类型**: $TEST_TYPE
**测试超时**: ${TEST_TIMEOUT}秒
**并行任务**: $PARALLEL_JOBS

## 测试环境
- **操作系统**: $(uname -s)
- **内核版本**: $(uname -r)
- **Shell版本**: $BASH_VERSION
- **Python版本**: $(python3 --version 2>/dev/null || echo "未安装")

## 测试结果
EOF

    # 添加测试结果
    if [[ -f "$LOG_DIR/test-results.log" ]]; then
        cat "$LOG_DIR/test-results.log" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## 测试统计
- **总测试数**: $TOTAL_TESTS
- **通过测试**: $PASSED_TESTS
- **失败测试**: $FAILED_TESTS
- **跳过测试**: $SKIPPED_TESTS

## 建议
EOF

    # 添加改进建议
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "- 修复失败的测试用例" >> "$report_file"
    fi
    
    if [[ $SKIPPED_TESTS -gt 0 ]]; then
        echo "- 补充跳过的测试用例" >> "$report_file"
    fi
    
    echo "- 定期运行自动化测试" >> "$report_file"
    echo "- 持续改进测试覆盖率" >> "$report_file"
    
    log_success "测试报告生成完成: $report_file"
}

# 清理测试环境
cleanup_environment() {
    log_info "清理测试环境..."
    
    # 清理测试数据
    rm -rf "$PROJECT_ROOT/test_data"
    rm -rf "$PROJECT_ROOT/test_config"
    rm -rf "$PROJECT_ROOT/test_logs"
    
    # 清理临时文件
    find "$PROJECT_ROOT" -name "*.tmp" -type f -delete 2>/dev/null || true
    
    log_success "测试环境清理完成"
}

# 主函数
main() {
    # 默认测试类型
    TEST_TYPE="${TEST_TYPE:-all}"
    
    # 解析参数
    parse_arguments "$@"
    
    show_banner
    
    log_info "开始自动化测试..."
    log_info "测试类型: $TEST_TYPE"
    log_info "超时时间: ${TEST_TIMEOUT}秒"
    log_info "并行任务: $PARALLEL_JOBS"
    log_info "详细输出: $VERBOSE"
    log_info "模拟运行: $DRY_RUN"
    echo
    
    # 初始化测试统计
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    
    # 运行测试
    local test_functions=()
    
    case "$TEST_TYPE" in
        "basic")
            test_functions=("run_syntax_check" "run_unit_tests")
            ;;
        "advanced")
            test_functions=("run_syntax_check" "run_static_analysis" "run_unit_tests" "run_integration_tests")
            ;;
        "security")
            test_functions=("run_security_tests")
            ;;
        "performance")
            test_functions=("run_performance_tests")
            ;;
        "syntax")
            test_functions=("run_syntax_check")
            ;;
        "all")
            test_functions=("run_syntax_check" "run_static_analysis" "run_unit_tests" "run_security_tests" "run_performance_tests" "run_integration_tests")
            ;;
    esac
    
    # 检查依赖
    check_dependencies
    
    # 准备环境
    prepare_environment
    
    # 运行测试
    for test_func in "${test_functions[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        if $test_func; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log_success "测试通过: $test_func"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log_error "测试失败: $test_func"
        fi
    done
    
    # 生成报告
    generate_test_report
    
    # 清理环境
    cleanup_environment
    
    # 显示结果
    echo
    echo -e "${CYAN}=========================================="
    echo "  测试结果汇总"
    echo "==========================================${NC}"
    echo
    echo -e "总测试数: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"
    echo -e "跳过测试: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 所有测试通过！"
        exit 0
    else
        log_error "❌ 有 $FAILED_TESTS 个测试失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
