#!/bin/bash

# 修复install.sh中log_info函数未找到的问题
# 作者: IPv6 WireGuard Manager Team

echo "开始修复install.sh中的log_info函数问题..."

# 检查install.sh文件是否存在
if [[ ! -f "install.sh" ]]; then
    echo "错误: install.sh文件不存在"
    exit 1
fi

# 检查common_functions.sh文件是否存在
if [[ ! -f "modules/common_functions.sh" ]]; then
    echo "错误: modules/common_functions.sh文件不存在"
    exit 1
fi

# 创建备份
cp install.sh install.sh.backup
echo "已创建备份文件: install.sh.backup"

# 修复install.sh中的log_info函数问题
echo "修复install.sh中的log_info函数问题..."

# 在install.sh中添加备用日志函数定义
cat > install.sh.tmp << 'EOF'
#!/bin/bash

# IPv6 WireGuard Manager 安装脚本
# 版本: 1.0.0
# 作者: IPv6 WireGuard Manager Team

set -euo pipefail

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh"
    echo "已加载公共函数库"
else
    echo "警告: 无法加载公共函数库，使用内置函数"
fi

# 颜色定义（如果公共函数库未加载则定义）
RED="${RED:-'\033[0;31m'}"
GREEN="${GREEN:-'\033[0;32m'}"
YELLOW="${YELLOW:-'\033[1;33m'}"
BLUE="${BLUE:-'\033[0;34m'}"
PURPLE="${PURPLE:-'\033[0;35m'}"
CYAN="${CYAN:-'\033[0;36m'}"
WHITE="${WHITE:-'\033[1;37m'}"
INFO_COLOR="${INFO_COLOR:-'\033[0;36m'}"  # 信息颜色（青色）
NC="${NC:-'\033[0m'}"

# 备用日志函数（如果公共函数库未加载）
if ! declare -f log_info >/dev/null 2>&1; then
    log_info() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$log_file"
    }
    
    log_success() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$log_file"
    }
    
    log_warn() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$log_file"
    }
    
    log_error() {
        local log_file="${LOG_FILE:-/tmp/install.log}"
        mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
        echo -e "${RED}[ERROR]${NC} $1" | tee -a "$log_file"
    }
    
    log_debug() {
        if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" ]]; then
            local log_file="${LOG_FILE:-/tmp/install.log}"
            mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
            echo -e "${CYAN}[DEBUG]${NC} $1" | tee -a "$log_file"
        fi
    }
    
    echo "已加载备用日志函数"
fi

# 确保LOG_FILE变量已定义
LOG_FILE="${LOG_FILE:-/tmp/install.log}"

EOF

# 将原始install.sh的其余部分追加到临时文件
tail -n +25 install.sh >> install.sh.tmp

# 替换原文件
mv install.sh.tmp install.sh

echo "修复完成！"
echo "现在install.sh应该可以正常工作了。"

# 测试修复结果
echo "测试修复结果..."
if bash -n install.sh; then
    echo "✓ install.sh语法检查通过"
else
    echo "✗ install.sh语法检查失败"
    exit 1
fi

echo "修复完成！现在可以运行install.sh了。"
