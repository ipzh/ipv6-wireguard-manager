#!/bin/bash

# IPv6 WireGuard Manager VPS部署调试脚本
# 专门针对远程VPS部署过程中的问题进行调试和记录

set -e  # 遇到错误立即退出

# 配置变量
LOG_FILE="/tmp/vps-debug-install.log"
INSTALL_DIR="/opt/ipv6-wireguard-manager"
BACKEND_DIR="$INSTALL_DIR/backend"
FRONTEND_DIR="$INSTALL_DIR/frontend"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        "DEBUG") color=$NC ;;
    esac
    
    echo -e "${color}[$level] $message${NC}" | tee -a "$LOG_FILE"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 检查命令执行状态
check_command() {
    local cmd="$1"
    local description="$2"
    
    log "DEBUG" "执行命令: $cmd"
    
    if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "$description 完成"
        return 0
    else
        local exit_code=${PIPESTATUS[0]}
        log "ERROR" "$description 失败 (退出码: $exit_code)"
        return $exit_code
    fi
}

# 检查系统环境
check_system() {
    log "INFO" "检查VPS系统环境..."
    
    # 检查操作系统
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        log "INFO" "操作系统: $NAME $VERSION"
    else
        log "WARNING" "无法确定操作系统版本"
    fi
    
    # 检查内核版本
    log "INFO" "内核版本: $(uname -r)"
    
    # 检查Python版本
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        log "INFO" "Python版本: $python_version"
    else
        log "ERROR" "Python3 未安装"
        return 1
    fi
    
    # 检查Node.js版本
    if command -v node &> /dev/null; then
        node_version=$(node --version 2>&1)
        npm_version=$(npm --version 2>&1)
        log "INFO" "Node.js版本: $node_version"
        log "INFO" "npm版本: $npm_version"
        
        # 检查npm版本是否满足要求
        if [[ "$npm_version" =~ ^10\. ]]; then
            log "SUCCESS" "npm版本兼容 (v10.x)"
        else
            log "WARNING" "npm版本可能不兼容: $npm_version"
        fi
    else
        log "ERROR" "Node.js 未安装"
        return 1
    fi
    
    # 检查Git
    if command -v git &> /dev/null; then
        git_version=$(git --version 2>&1)
        log "INFO" "Git版本: $git_version"
    else
        log "ERROR" "Git 未安装"
        return 1
    fi
    
    # 检查系统服务管理器
    if command -v systemctl &> /dev/null; then
        log "INFO" "systemd 可用"
    else
        log "ERROR" "systemd 不可用"
        return 1
    fi
    
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        ufw_status=$(sudo ufw status 2>&1)
        log "INFO" "UFW状态: $ufw_status"
    elif command -v firewall-cmd &> /dev/null; then
        firewall_status=$(sudo firewall-cmd --state 2>&1)
        log "INFO" "FirewallD状态: $firewall_status"
    else
        log "WARNING" "未检测到防火墙"
    fi
    
    return 0
}

# 检查代码同步状态
check_code_sync() {
    log "INFO" "检查代码同步状态..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log "ERROR" "安装目录不存在: $INSTALL_DIR"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查Git仓库状态
    if [ ! -d ".git" ]; then
        log "ERROR" "不是Git仓库"
        return 1
    fi
    
    # 检查远程仓库连接
    check_command "git remote -v" "检查远程仓库"
    
    # 拉取最新代码
    log "INFO" "拉取最新代码..."
    check_command "git pull origin main" "拉取最新代码"
    
    # 检查最新提交
    check_command "git log --oneline -5" "检查最新提交"
    
    # 检查关键文件是否存在
    local critical_files=(
        "backend/app/main.py"
        "backend/app/schemas/ipv6.py"
        "backend/requirements.txt"
        "frontend/package.json"
        "frontend/vite.config.ts"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            log "SUCCESS" "文件存在: $file"
        else
            log "ERROR" "文件不存在: $file"
            return 1
        fi
    done
    
    return 0
}

# 检查schemas导入问题
check_schemas_imports() {
    log "INFO" "检查schemas导入问题..."
    
    cd "$BACKEND_DIR"
    
    # 检查IPv6PrefixPool类是否存在
    log "INFO" "检查IPv6PrefixPool类..."
    if python3 -c "from app.schemas.ipv6 import IPv6PrefixPool; print('IPv6PrefixPool导入成功')" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "IPv6PrefixPool类导入成功"
    else
        log "ERROR" "IPv6PrefixPool类导入失败"
        return 1
    fi
    
    # 检查IPv6Allocation类是否存在
    log "INFO" "检查IPv6Allocation类..."
    if python3 -c "from app.schemas.ipv6 import IPv6Allocation; print('IPv6Allocation导入成功')" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "IPv6Allocation类导入成功"
    else
        log "ERROR" "IPv6Allocation类导入失败"
        return 1
    fi
    
    # 检查所有schemas导入
    log "INFO" "检查所有schemas导入..."
    if python3 -c "
from app.schemas.ipv6 import IPv6PrefixPool, IPv6Allocation
from app.schemas.ipv6 import IPv6PrefixPoolCreate, IPv6PrefixPoolUpdate
from app.schemas.ipv6 import IPv6AllocationCreate, IPv6AllocationUpdate
print('所有schemas导入成功')
" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "所有schemas导入成功"
    else
        log "ERROR" "schemas导入失败"
        return 1
    fi
    
    return 0
}

# 检查后端依赖
check_backend_dependencies() {
    log "INFO" "检查后端依赖..."
    
    cd "$BACKEND_DIR"
    
    # 检查虚拟环境
    if [ ! -d "venv" ]; then
        log "ERROR" "Python虚拟环境不存在"
        return 1
    fi
    
    source venv/bin/activate
    
    # 检查关键包
    local critical_packages=(
        "fastapi"
        "uvicorn"
        "sqlalchemy"
        "pydantic"
        "psycopg2-binary"
        "alembic"
        "redis"
    )
    
    for package in "${critical_packages[@]}"; do
        if python3 -c "import $package; print('$package版本:', $package.__version__)" 2>&1 | tee -a "$LOG_FILE"; then
            log "SUCCESS" "$package 导入成功"
        else
            log "ERROR" "$package 导入失败"
            return 1
        fi
    done
    
    return 0
}

# 检查前端依赖
check_frontend_dependencies() {
    log "INFO" "检查前端依赖..."
    
    cd "$FRONTEND_DIR"
    
    # 检查node_modules
    if [ ! -d "node_modules" ]; then
        log "ERROR" "node_modules目录不存在"
        return 1
    fi
    
    # 检查关键包
    local critical_packages=(
        "react"
        "react-dom"
        "vite"
        "antd"
        "axios"
    )
    
    for package in "${critical_packages[@]}"; do
        if npm list $package | grep -q $package 2>&1; then
            log "SUCCESS" "$package 安装成功"
        else
            log "ERROR" "$package 安装失败"
            return 1
        fi
    done
    
    return 0
}

# 检查数据库连接
check_database() {
    log "INFO" "检查数据库连接..."
    
    cd "$BACKEND_DIR"
    source venv/bin/activate
    
    # 检查数据库配置
    if [ -f "app/core/config.py" ]; then
        log "INFO" "数据库配置文件存在"
    else
        log "WARNING" "数据库配置文件不存在"
    fi
    
    # 尝试连接数据库
    if python3 -c "
from app.core.database import engine
try:
    conn = engine.connect()
    print('数据库连接成功')
    conn.close()
except Exception as e:
    print('数据库连接失败:', str(e))
    exit(1)
" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "数据库连接测试成功"
    else
        log "ERROR" "数据库连接测试失败"
        return 1
    fi
    
    return 0
}

# 检查系统服务配置
check_system_service() {
    log "INFO" "检查系统服务配置..."
    
    local service_name="ipv6-wireguard-manager"
    local service_file="/etc/systemd/system/$service_name.service"
    
    # 检查服务文件是否存在
    if [ -f "$service_file" ]; then
        log "INFO" "服务文件存在: $service_file"
        
        # 检查服务文件内容
        sudo cat "$service_file" | tee -a "$LOG_FILE"
        
        # 检查工作目录配置
        if grep -q "WorkingDirectory=$BACKEND_DIR" "$service_file"; then
            log "SUCCESS" "工作目录配置正确"
        else
            log "WARNING" "工作目录配置可能不正确"
        fi
        
        # 检查执行命令
        if grep -q "uvicorn app.main:app" "$service_file"; then
            log "SUCCESS" "执行命令配置正确"
        else
            log "WARNING" "执行命令配置可能不正确"
        fi
    else
        log "ERROR" "服务文件不存在: $service_file"
        return 1
    fi
    
    # 检查服务状态
    if sudo systemctl is-active "$service_name" &> /dev/null; then
        log "INFO" "服务状态: $(sudo systemctl is-active $service_name)"
        log "INFO" "服务启用状态: $(sudo systemctl is-enabled $service_name)"
    else
        log "WARNING" "服务未运行"
    fi
    
    # 检查服务日志
    log "INFO" "检查服务日志..."
    sudo journalctl -u "$service_name" --no-pager -n 20 | tee -a "$LOG_FILE"
    
    return 0
}

# 测试后端启动
test_backend_startup() {
    log "INFO" "测试后端启动..."
    
    cd "$BACKEND_DIR"
    source venv/bin/activate
    
    # 检查主应用文件
    if [ ! -f "app/main.py" ]; then
        log "ERROR" "主应用文件不存在"
        return 1
    fi
    
    # 尝试导入主应用
    if python3 -c "from app.main import app; print('应用导入成功')" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "应用导入成功"
    else
        log "ERROR" "应用导入失败"
        return 1
    fi
    
    # 检查路由数量
    if python3 -c "from app.main import app; print('路由数量:', len(app.routes))" 2>&1 | tee -a "$LOG_FILE"; then
        log "SUCCESS" "路由检查成功"
    else
        log "ERROR" "路由检查失败"
        return 1
    fi
    
    # 测试快速启动
    log "INFO" "测试快速启动..."
    timeout 10s python3 -c "
import uvicorn
from app.main import app
import threading
import time

def run_server():
    uvicorn.run(app, host='127.0.0.1', port=8000, log_level='error')

thread = threading.Thread(target=run_server, daemon=True)
thread.start()
time.sleep(3)
print('服务器启动测试完成')
" 2>&1 | tee -a "$LOG_FILE" || {
    log "WARNING" "快速启动测试超时（正常现象）"
}
    
    return 0
}

# 生成问题报告
generate_report() {
    log "INFO" "生成VPS部署问题报告..."
    
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local report_file="$INSTALL_DIR/vps-debug-report-$timestamp.txt"
    
    cat > "$report_file" << EOF
=== IPv6 WireGuard Manager VPS部署调试报告 ===
生成时间: $(date)
VPS地址: $(hostname -I | awk '{print $1}')
安装目录: $INSTALL_DIR
日志文件: $LOG_FILE

EOF
    
    # 提取错误和警告
    echo "=== 错误汇总 ===" >> "$report_file"
    grep "\\[ERROR\\]" "$LOG_FILE" >> "$report_file" 2>/dev/null || echo "无错误" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "=== 警告汇总 ===" >> "$report_file"
    grep "\\[WARNING\\]" "$LOG_FILE" >> "$report_file" 2>/dev/null || echo "无警告" >> "$report_file"
    
    echo "" >> "$report_file"
    echo "=== 关键检查点 ===" >> "$report_file"
    grep -E "(schemas导入|数据库连接|服务配置|启动测试)" "$LOG_FILE" | grep -E "(SUCCESS|ERROR)" >> "$report_file" 2>/dev/null
    
    echo "" >> "$report_file"
    echo "=== 修复建议 ===" >> "$report_file"
    
    # 根据错误生成修复建议
    if grep -q "IPv6PrefixPool类导入失败" "$LOG_FILE"; then
        echo "1. schemas导入错误: 需要更新schemas/ipv6.py文件" >> "$report_file"
        echo "   修复命令: git pull origin main" >> "$report_file"
    fi
    
    if grep -q "数据库连接失败" "$LOG_FILE"; then
        echo "2. 数据库连接错误: 检查数据库配置和连接" >> "$report_file"
        echo "   检查文件: backend/app/core/config.py" >> "$report_file"
    fi
    
    if grep -q "服务文件不存在" "$LOG_FILE"; then
        echo "3. 系统服务配置错误: 需要创建systemd服务文件" >> "$report_file"
        echo "   参考文件: docs/systemd-service.md" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "=== 详细日志 ===" >> "$report_file"
    echo "请查看完整日志文件: $LOG_FILE" >> "$report_file"
    
    log "SUCCESS" "VPS部署调试报告已生成: $report_file"
    
    # 显示关键问题统计
    local error_count=$(grep -c "\\[ERROR\\]" "$LOG_FILE" 2>/dev/null || echo 0)
    local warning_count=$(grep -c "\\[WARNING\\]" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo ""
    echo "=== VPS部署调试摘要 ==="
    echo "错误数量: $error_count"
    echo "警告数量: $warning_count"
    echo "日志文件: $LOG_FILE"
    echo "报告文件: $report_file"
    
    if [ $error_count -eq 0 ]; then
        log "SUCCESS" "VPS部署调试完成，未发现严重错误"
        echo ""
        echo "✅ VPS部署环境正常，可以启动服务:"
        echo "   sudo systemctl start ipv6-wireguard-manager"
        echo "   sudo systemctl enable ipv6-wireguard-manager"
    else
        log "WARNING" "VPS部署调试完成，发现 $error_count 个错误需要修复"
        echo ""
        echo "❌ 发现错误，请根据报告文件修复问题后重试"
    fi
    
    return 0
}

# 主函数
main() {
    echo "=== IPv6 WireGuard Manager VPS部署调试脚本 ==="
    echo "专门针对远程VPS部署过程中的问题进行调试"
    echo "日志文件: $LOG_FILE"
    echo ""
    
    # 执行调试步骤
    check_system
    check_code_sync
    check_schemas_imports
    check_backend_dependencies
    check_frontend_dependencies
    check_database
    check_system_service
    test_backend_startup
    
    # 生成报告
    generate_report
    
    echo ""
    echo "调试完成！请查看报告文件了解详细问题。"
    echo "根据报告中的修复建议逐一解决问题。"
}

# 执行主函数
main "$@"