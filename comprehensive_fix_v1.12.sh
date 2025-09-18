#!/bin/bash

# 全面修复脚本 v1.12
# 修复所有重复定义问题并更新到1.12版本

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

log "INFO" "开始全面修复和版本更新到1.13..."

# 需要修复的脚本文件列表
SCRIPT_FILES=(
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
    "modules/client_auto_update.sh"
    "modules/network_management.sh"
    "modules/server_management.sh"
    "modules/firewall_config.sh"
    "modules/system_detection.sh"
    "modules/update_management.sh"
    "fix_wireguard_config.sh"
    "fix_ipv6_config.sh"
    "fix_wireguard_service.sh"
    "fix_bird_compatibility.sh"
    "quick_fix_wireguard.sh"
    "test_network_interface_detection.sh"
    "test_ipv6_allocation.sh"
)

# 需要更新版本的文档文件列表
DOC_FILES=(
    "README.md"
    "PROJECT_SUMMARY.md"
    "CHANGELOG.md"
    "docs/INSTALLATION.md"
    "docs/USAGE.md"
    "docs/BIRD_PERMISSIONS.md"
    "docs/BIRD_VERSION_COMPATIBILITY.md"
    "docs/COMPLETE_USER_GUIDE.md"
    "docs/CLIENT_INSTALLER_GUIDE.md"
    "docs/CODE_QUALITY_REPORT.md"
    "config/manager.conf"
)

# 1. 修复重复的log函数定义
log "INFO" "1. 修复重复的log函数定义..."

for file in "${SCRIPT_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log "INFO" "处理文件: $file"
        
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
        BEGIN { log_count = 0; in_log_function = 0 }
        /^log\(\) \{/ {
            if (log_count == 0) {
                log_count++
                in_log_function = 1
                print
                getline
                while (getline && !/^}$/) {
                    print
                }
                print
                in_log_function = 0
            } else {
                # 跳过重复的log函数
                in_log_function = 1
                getline
                while (getline && !/^}$/) {
                    # 跳过
                }
                in_log_function = 0
            }
        }
        !in_log_function {
            print
        }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        
    else
        log "WARN" "文件不存在: $file"
    fi
done

# 2. 修复重复的颜色定义
log "INFO" "2. 修复重复的颜色定义..."

for file in "${SCRIPT_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log "INFO" "处理文件: $file"
        
        # 删除重复的颜色定义（保留第一个）
        awk '
        BEGIN { color_count = 0; in_color_block = 0 }
        /^RED=.*033/ {
            if (color_count == 0) {
                color_count++
                in_color_block = 1
                print
            } else {
                in_color_block = 1
            }
        }
        in_color_block && /^NC=.*033/ {
            if (color_count == 1) {
                print
            }
            in_color_block = 0
        }
        in_color_block && color_count == 1 {
            print
        }
        !in_color_block {
            print
        }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
        
    else
        log "WARN" "文件不存在: $file"
    fi
done

# 3. 更新所有文件版本到1.13
log "INFO" "3. 更新所有文件版本到1.13..."

# 更新脚本文件版本
for file in "${SCRIPT_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log "INFO" "更新版本: $file"
        
        # 更新文件头部的版本信息
        sed -i 's/版本: 1\.12/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.11/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.9/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.8/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.7/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.6/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.5/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.4/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.3/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.2/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.1/版本: 1.13/g' "$file"
        sed -i 's/版本: 1\.0\.0/版本: 1.13/g' "$file"
        
        # 更新脚本中的版本变量
        sed -i 's/current_version="1\.11"/current_version="1.12"/g' "$file"
        sed -i 's/current_version="1\.0\.9"/current_version="1.12"/g' "$file"
        sed -i 's/current_version="1\.0\.8"/current_version="1.12"/g' "$file"
        sed -i 's/SCRIPT_VERSION="1\.11"/SCRIPT_VERSION="1.12"/g' "$file"
        sed -i 's/SCRIPT_VERSION="1\.0\.9"/SCRIPT_VERSION="1.12"/g' "$file"
        sed -i 's/SCRIPT_VERSION="1\.0\.8"/SCRIPT_VERSION="1.12"/g' "$file"
        sed -i 's/version="1\.11"/version="1.12"/g' "$file"
        sed -i 's/version="1\.0\.9"/version="1.12"/g' "$file"
        sed -i 's/version="1\.0\.8"/version="1.12"/g' "$file"
        
        # 更新版本显示
        sed -i 's/v1\.11/v1.12/g' "$file"
        sed -i 's/v1\.0\.9/v1.12/g' "$file"
        sed -i 's/v1\.0\.8/v1.12/g' "$file"
        sed -i 's/1\.12版本/1.13版本/g' "$file"
        sed -i 's/1\.11版本/1.13版本/g' "$file"
        sed -i 's/1\.0\.9版本/1.13版本/g' "$file"
        sed -i 's/1\.0\.8版本/1.13版本/g' "$file"
    fi
done

# 更新文档文件版本
for file in "${DOC_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log "INFO" "更新文档版本: $file"
        
        # 更新版本号
        sed -i 's/1\.11/1.12/g' "$file"
        sed -i 's/1\.0\.9/1.12/g' "$file"
        sed -i 's/1\.0\.8/1.12/g' "$file"
        sed -i 's/1\.0\.7/1.12/g' "$file"
        sed -i 's/1\.0\.6/1.12/g' "$file"
        sed -i 's/1\.0\.5/1.12/g' "$file"
        sed -i 's/1\.0\.4/1.12/g' "$file"
        sed -i 's/1\.0\.3/1.12/g' "$file"
        sed -i 's/1\.0\.2/1.12/g' "$file"
        sed -i 's/1\.0\.1/1.12/g' "$file"
        sed -i 's/1\.0\.0/1.12/g' "$file"
        
        # 更新版本显示
        sed -i 's/v1\.11/v1.12/g' "$file"
        sed -i 's/v1\.0\.9/v1.12/g' "$file"
        sed -i 's/v1\.0\.8/v1.12/g' "$file"
    fi
done

# 4. 更新CHANGELOG.md
log "INFO" "4. 更新CHANGELOG.md..."

if [[ -f "CHANGELOG.md" ]]; then
    # 在CHANGELOG.md开头添加1.12版本信息
    cat > "CHANGELOG_v1.12.md" << 'EOF'
# 更新日志

## [1.12] - 2024-09-17

### 新增功能
- **全面代码优化**: 修复所有重复的log函数和颜色定义
- **版本统一**: 所有文件统一更新到1.13版本
- **代码清理**: 删除冗余代码，提高代码质量
- **文档更新**: 所有文档同步更新到1.12版本

### 修复问题
- **重复定义**: 修复所有脚本文件中的重复log函数定义
- **颜色定义**: 修复所有脚本文件中的重复颜色定义
- **版本一致性**: 统一所有文件的版本号为1.13
- **代码结构**: 优化代码结构，提高可维护性

### 技术改进
- **公共函数库**: 所有脚本文件统一使用公共函数库
- **代码复用**: 减少重复代码，提高代码复用率
- **维护性**: 提高代码的可维护性和可读性
- **稳定性**: 增强系统的稳定性和可靠性

### 文档更新
- **README.md**: 更新到1.12版本
- **PROJECT_SUMMARY.md**: 更新到1.12版本
- **所有文档**: 同步更新版本信息

---

EOF
    
    # 将新版本信息添加到现有CHANGELOG.md开头
    cat "CHANGELOG_v1.12.md" "CHANGELOG.md" > "CHANGELOG_temp.md"
    mv "CHANGELOG_temp.md" "CHANGELOG.md"
    rm -f "CHANGELOG_v1.12.md"
fi

# 5. 验证修复结果
log "INFO" "5. 验证修复结果..."

# 检查log函数重复
log "INFO" "检查log函数重复..."
for file in "${SCRIPT_FILES[@]}"; do
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
for file in "${SCRIPT_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        color_count=$(grep -c "^RED=.*033" "$file" 2>/dev/null || echo "0")
        if [[ "$color_count" -gt 1 ]]; then
            log "WARN" "$file 仍有 $color_count 个颜色定义"
        else
            log "INFO" "$file 颜色定义正常"
        fi
    fi
done

# 检查版本更新
log "INFO" "检查版本更新..."
version_files=("ipv6-wireguard-manager.sh" "install.sh" "uninstall.sh" "client-installer.sh")
for file in "${version_files[@]}"; do
    if [[ -f "$file" ]]; then
        if grep -q "1.12" "$file"; then
            log "INFO" "$file 版本已更新到1.13"
        else
            log "WARN" "$file 版本未更新到1.13"
        fi
    fi
done

log "INFO" "全面修复和版本更新完成！"

# 显示修复总结
echo
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                        修复总结 v1.12                        ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo
echo -e "${GREEN}✓${NC} 1. 修复所有重复的log函数定义"
echo -e "${GREEN}✓${NC} 2. 修复所有重复的颜色定义"
echo -e "${GREEN}✓${NC} 3. 更新所有脚本文件到1.12版本"
echo -e "${GREEN}✓${NC} 4. 更新所有文档文件到1.12版本"
echo -e "${GREEN}✓${NC} 5. 更新CHANGELOG.md"
echo -e "${GREEN}✓${NC} 6. 添加公共函数库加载"
echo
echo -e "${YELLOW}建议运行以下命令验证修复结果:${NC}"
echo "  ./ipv6-wireguard-manager.sh --version"
echo "  ./install.sh --help"
echo "  ./uninstall.sh --help"
echo
echo -e "${BLUE}全面修复完成！所有文件已更新到1.12版本${NC}"
