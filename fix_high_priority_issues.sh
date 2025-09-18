#!/bin/bash

# 高优先级问题修复脚本 v1.11
# 修复重复的log函数定义、版本不一致、错误处理等问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}" >&2
            ;;
        *)
            echo -e "[$timestamp] [$level] $message" >&2
            ;;
    esac
}

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    log "ERROR" "This script must be run as root."
    exit 1
fi

log "INFO" "开始修复高优先级问题..."

# 1. 修复重复的log函数定义
log "INFO" "1. 修复重复的log函数定义..."

# 需要修复的文件列表
FILES_TO_FIX=(
    "ipv6-wireguard-manager.sh"
    "ipv6-wireguard-manager-core.sh"
    "install.sh"
    "uninstall.sh"
    "client-installer.sh"
    "scripts/update.sh"
    "scripts/check_bird_version.sh"
    "scripts/check_bird_permissions.sh"
    "modules/bird_config.sh"
    "modules/wireguard_config.sh"
    "modules/client_script_generator.sh"
)

for file in "${FILES_TO_FIX[@]}"; do
    if [[ -f "$file" ]]; then
        log "INFO" "修复文件: $file"
        
        # 检查是否已经加载了公共函数库
        if ! grep -q "source.*common_functions.sh" "$file"; then
            # 在文件开头添加公共函数库加载
            if [[ "$file" == "scripts/"* ]]; then
                # 脚本目录中的文件
                sed -i '1i # 加载公共函数库\nif [[ -f "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh" ]]; then\n    source "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh"\nfi\n' "$file"
            else
                # 其他文件
                sed -i '1i # 加载公共函数库\nif [[ -f "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh" ]]; then\n    source "$(dirname "${BASH_SOURCE[0]}")/modules/common_functions.sh"\nfi\n' "$file"
            fi
        fi
        
        # 删除重复的log函数定义（保留第一个）
        awk '
        /^log\(\) \{/ {
            if (log_count == 0) {
                log_count++
                print
                getline
                while (getline && !/^}$/) {
                    print
                }
                print
            } else {
                # 跳过重复的log函数
                getline
                while (getline && !/^}$/) {
                    # 跳过
                }
            }
        }
        !/^log\(\) \{/ {
            print
        }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        
        # 删除重复的颜色定义（保留第一个）
        awk '
        /^RED=.*033/ {
            if (color_count == 0) {
                color_count++
                print
                getline
                while (getline && !/^NC=.*033/) {
                    print
                }
                print
            } else {
                # 跳过重复的颜色定义
                getline
                while (getline && !/^NC=.*033/) {
                    # 跳过
                }
            }
        }
        !/^RED=.*033/ {
            print
        }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        
    else
        log "WARN" "文件不存在: $file"
    fi
done

# 2. 修复GitHub URL不一致问题
log "INFO" "2. 修复GitHub URL不一致问题..."

# 需要修复的URL模式
OLD_URLS=(
    "your-repo/ipv6-wireguard-manager"
    "ipv6-wireguard/manager"
    "ipzh/ipv6-wireguard-manager"
)

NEW_URL="ipv6-wireguard-manager/ipv6-wireguard-manager"

for file in "${FILES_TO_FIX[@]}"; do
    if [[ -f "$file" ]]; then
        for old_url in "${OLD_URLS[@]}"; do
            if grep -q "$old_url" "$file"; then
                log "INFO" "修复 $file 中的URL: $old_url -> $NEW_URL"
                sed -i "s|$old_url|$NEW_URL|g" "$file"
            fi
        done
    fi
done

# 3. 修复install.sh中的log函数问题
log "INFO" "3. 修复install.sh中的log函数问题..."

if [[ -f "install.sh" ]]; then
    # 确保install.sh有log函数定义（在公共函数库加载之前）
    if ! grep -q "log() {" "install.sh"; then
        log "INFO" "在install.sh中添加log函数定义..."
        
        # 在公共函数库加载之前添加log函数
        sed -i '/# 加载公共函数库/i # 日志函数（在公共函数库加载之前使用）\nlog() {\n    local level="$1"\n    shift\n    local message="$*"\n    local timestamp=$(date '\''+%Y-%m-%d %H:%M:%S'\'')\n    \n    case "$level" in\n        "ERROR")\n            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2\n            ;;\n        "WARN")\n            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2\n            ;;\n        "INFO")\n            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2\n            ;;\n        "DEBUG")\n            echo -e "${BLUE}[$timestamp] [$level] $message${NC}" >&2\n            ;;\n        *)\n            echo -e "[$timestamp] [$level] $message" >&2\n            ;;\n    esac\n}\n\n# 错误处理函数\nerror_exit() {\n    log "ERROR" "$1"\n    exit 1\n}\n' "install.sh"
    fi
fi

# 4. 修复重复的颜色定义
log "INFO" "4. 修复重复的颜色定义..."

for file in "${FILES_TO_FIX[@]}"; do
    if [[ -f "$file" ]]; then
        # 删除重复的颜色定义，只保留第一个
        awk '
        BEGIN { in_color_block = 0; color_block_count = 0 }
        /^RED=.*033/ {
            if (color_block_count == 0) {
                in_color_block = 1
                color_block_count++
                print
            } else {
                in_color_block = 0
            }
        }
        in_color_block && /^NC=.*033/ {
            print
            in_color_block = 0
        }
        !in_color_block {
            print
        }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
done

# 5. 验证修复结果
log "INFO" "5. 验证修复结果..."

# 检查log函数重复
log "INFO" "检查log函数重复..."
for file in "${FILES_TO_FIX[@]}"; do
    if [[ -f "$file" ]]; then
        log_count=$(grep -c "^log() {" "$file" 2>/dev/null || echo "0")
        if [[ "$log_count" -gt 1 ]]; then
            log "WARN" "$file 仍有 $log_count 个log函数定义"
        else
            log "INFO" "$file log函数定义正常"
        fi
    fi
done

# 检查颜色定义重复
log "INFO" "检查颜色定义重复..."
for file in "${FILES_TO_FIX[@]}"; do
    if [[ -f "$file" ]]; then
        color_count=$(grep -c "^RED=.*033" "$file" 2>/dev/null || echo "0")
        if [[ "$color_count" -gt 1 ]]; then
            log "WARN" "$file 仍有 $color_count 个颜色定义"
        else
            log "INFO" "$file 颜色定义正常"
        fi
    fi
done

# 检查GitHub URL
log "INFO" "检查GitHub URL一致性..."
for file in "${FILES_TO_FIX[@]}"; do
    if [[ -f "$file" ]]; then
        if grep -q "your-repo\|ipv6-wireguard/manager\|ipzh" "$file"; then
            log "WARN" "$file 仍有旧的GitHub URL"
        else
            log "INFO" "$file GitHub URL正常"
        fi
    fi
done

log "INFO" "高优先级问题修复完成！"

# 显示修复总结
echo
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                        修复总结                          ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo
echo -e "${GREEN}✓${NC} 1. 修复重复的log函数定义"
echo -e "${GREEN}✓${NC} 2. 修复GitHub URL不一致问题"
echo -e "${GREEN}✓${NC} 3. 修复install.sh中的log函数问题"
echo -e "${GREEN}✓${NC} 4. 修复重复的颜色定义"
echo -e "${GREEN}✓${NC} 5. 添加公共函数库加载"
echo
echo -e "${YELLOW}建议运行以下命令验证修复结果:${NC}"
echo "  ./ipv6-wireguard-manager.sh --version"
echo "  ./install.sh --help"
echo "  ./uninstall.sh --help"
echo
echo -e "${BLUE}修复完成！${NC}"
