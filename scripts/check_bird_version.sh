#!/bin/bash

# BIRD版本检测脚本
# 用于检测系统中安装的BIRD版本并显示相关信息

set -euo pipefail

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../modules/common_functions.sh"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
BIRD_VERSION=""
BIRD_MAJOR_VERSION=""
BIRD_EXECUTABLE=""
BIRD_CONTROL=""

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac
}

# 检测BIRD版本
detect_bird_version() {
    log "INFO" "Detecting BIRD version..."
    
    if command -v bird >/dev/null 2>&1; then
        # 尝试获取BIRD版本信息
        local version_output=$(bird --version 2>&1 || echo "")
        
        if [[ "$version_output" =~ BIRD[[:space:]]+([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
            BIRD_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            BIRD_MAJOR_VERSION="${BASH_REMATCH[1]}"
            BIRD_EXECUTABLE="bird"
            BIRD_CONTROL="birdc"
            log "INFO" "Detected BIRD version: $BIRD_VERSION"
        elif [[ "$version_output" =~ BIRD[[:space:]]+([0-9]+)\.([0-9]+) ]]; then
            BIRD_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
            BIRD_MAJOR_VERSION="${BASH_REMATCH[1]}"
            BIRD_EXECUTABLE="bird"
            BIRD_CONTROL="birdc"
            log "INFO" "Detected BIRD version: $BIRD_VERSION"
        else
            # 尝试从包管理器获取版本信息
            if command -v dpkg >/dev/null 2>&1; then
                local dpkg_version=$(dpkg -l | grep -E '^ii[[:space:]]+bird[0-9]*' | awk '{print $3}' | head -1)
                if [[ -n "$dpkg_version" ]]; then
                    BIRD_VERSION="$dpkg_version"
                    BIRD_MAJOR_VERSION=$(echo "$dpkg_version" | cut -d'.' -f1)
                    BIRD_EXECUTABLE="bird"
                    BIRD_CONTROL="birdc"
                    log "INFO" "Detected BIRD version from dpkg: $BIRD_VERSION"
                fi
            elif command -v rpm >/dev/null 2>&1; then
                local rpm_version=$(rpm -q bird 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
                if [[ -n "$rpm_version" ]]; then
                    BIRD_VERSION="$rpm_version"
                    BIRD_MAJOR_VERSION=$(echo "$rpm_version" | cut -d'.' -f1)
                    BIRD_EXECUTABLE="bird"
                    BIRD_CONTROL="birdc"
                    log "INFO" "Detected BIRD version from rpm: $BIRD_VERSION"
                fi
            fi
        fi
    fi
    
    # 检查BIRD 2.x
    if [[ -z "$BIRD_VERSION" ]] && command -v bird2 >/dev/null 2>&1; then
        BIRD_MAJOR_VERSION="2"
        BIRD_VERSION="2.x"
        BIRD_EXECUTABLE="bird2"
        BIRD_CONTROL="birdc2"
        log "INFO" "Detected BIRD 2.x from bird2 command"
    fi
    
    # 检查BIRD 1.x (legacy)
    if [[ -z "$BIRD_VERSION" ]] && command -v bird6 >/dev/null 2>&1; then
        BIRD_MAJOR_VERSION="1"
        BIRD_VERSION="1.x"
        BIRD_EXECUTABLE="bird6"
        BIRD_CONTROL="birdc6"
        log "WARN" "Detected BIRD 1.x (legacy version)"
    fi
    
    if [[ -z "$BIRD_VERSION" ]]; then
        log "ERROR" "BIRD is not installed or not in PATH"
        return 1
    fi
    
    return 0
}

# 显示BIRD信息
show_bird_info() {
    echo -e "${CYAN}=== BIRD版本信息 ===${NC}"
    echo -e "版本: ${GREEN}$BIRD_VERSION${NC}"
    echo -e "主版本: ${GREEN}$BIRD_MAJOR_VERSION${NC}"
    echo -e "可执行文件: ${GREEN}$BIRD_EXECUTABLE${NC}"
    echo -e "控制命令: ${GREEN}$BIRD_CONTROL${NC}"
    echo
    
    # 显示版本兼容性
    case "$BIRD_MAJOR_VERSION" in
        "1")
            echo -e "${YELLOW}注意: BIRD 1.x是旧版本，可能不完全支持所有功能${NC}"
            ;;
        "2")
            echo -e "${GREEN}BIRD 2.x - 完全支持${NC}"
            ;;
        "3")
            echo -e "${GREEN}BIRD 3.x - 完全支持${NC}"
            ;;
        *)
            echo -e "${YELLOW}未知版本，可能不完全支持${NC}"
            ;;
    esac
    echo
}

# 检查BIRD服务状态
check_bird_service() {
    echo -e "${CYAN}=== BIRD服务状态 ===${NC}"
    
    if systemctl is-active bird >/dev/null 2>&1; then
        echo -e "服务状态: ${GREEN}运行中${NC}"
        
        # 显示服务信息
        echo -e "服务文件: ${BLUE}/etc/systemd/system/bird.service${NC}"
        
        # 检查配置文件
        if [[ -f /etc/bird/bird.conf ]]; then
            echo -e "配置文件: ${BLUE}/etc/bird/bird.conf${NC}"
        else
            echo -e "配置文件: ${RED}未找到${NC}"
        fi
        
        # 检查日志
        if [[ -f /var/log/bird/bird.log ]]; then
            echo -e "日志文件: ${BLUE}/var/log/bird/bird.log${NC}"
        else
            echo -e "日志文件: ${YELLOW}未找到${NC}"
        fi
        
    else
        echo -e "服务状态: ${RED}未运行${NC}"
    fi
    echo
}

# 检查BIRD配置
check_bird_config() {
    echo -e "${CYAN}=== BIRD配置检查 ===${NC}"
    
    if [[ -f /etc/bird/bird.conf ]]; then
        echo -e "配置文件存在: ${GREEN}是${NC}"
        
        # 检查配置语法
        if command -v "$BIRD_CONTROL" >/dev/null 2>&1; then
            # BIRD 2.x 使用 configure 命令，BIRD 1.x 使用 -c 选项
            if [[ "$BIRD_CONTROL" == "birdc2" ]]; then
                if "$BIRD_CONTROL" configure 2>/dev/null; then
                    echo -e "配置语法: ${GREEN}正确${NC}"
                else
                    echo -e "配置语法: ${RED}错误${NC}"
                fi
            else
                if "$BIRD_CONTROL" -c /etc/bird/bird.conf configure 2>/dev/null; then
                    echo -e "配置语法: ${GREEN}正确${NC}"
                else
                    echo -e "配置语法: ${RED}错误${NC}"
                fi
            fi
        else
            echo -e "配置语法: ${YELLOW}无法检查 (控制命令不可用)${NC}"
        fi
        
        # 显示配置摘要
        echo -e "配置摘要:"
        grep -E "^(router id|protocol|log)" /etc/bird/bird.conf | head -10 | sed 's/^/  /'
        
    else
        echo -e "配置文件: ${RED}不存在${NC}"
    fi
    echo
}

# 显示BIRD路由信息
show_bird_routes() {
    echo -e "${CYAN}=== BIRD路由信息 ===${NC}"
    
    if command -v "$BIRD_CONTROL" >/dev/null 2>&1; then
        if systemctl is-active bird >/dev/null 2>&1; then
            echo -e "${BLUE}静态路由:${NC}"
            "$BIRD_CONTROL" show route protocol static 2>/dev/null || echo "  无静态路由"
            echo
            
            echo -e "${BLUE}BGP路由:${NC}"
            "$BIRD_CONTROL" show route protocol bgp 2>/dev/null || echo "  无BGP路由"
            echo
            
            echo -e "${BLUE}BGP邻居:${NC}"
            "$BIRD_CONTROL" show protocols all bgp 2>/dev/null || echo "  无BGP邻居"
        else
            echo -e "${YELLOW}BIRD服务未运行，无法获取路由信息${NC}"
        fi
    else
        echo -e "${YELLOW}BIRD控制命令不可用${NC}"
    fi
    echo
}

# 主函数
main() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    BIRD版本检测工具                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # 检测BIRD版本
    if ! detect_bird_version; then
        log "ERROR" "无法检测BIRD版本"
        exit 1
    fi
    
    # 显示信息
    show_bird_info
    check_bird_service
    check_bird_config
    show_bird_routes
    
    echo -e "${GREEN}BIRD版本检测完成${NC}"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
