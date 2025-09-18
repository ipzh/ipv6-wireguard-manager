#!/bin/bash

# BIRD版本兼容性修复脚本
# 版本: 1.0.8
# 修复BIRD 2.x版本中birdc命令的兼容性问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本信息
SCRIPT_NAME="BIRD版本兼容性修复脚本"
SCRIPT_VERSION="1.0.8"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    $SCRIPT_NAME                    ║${NC}"
echo -e "${CYAN}║                        版本: $SCRIPT_VERSION                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
    echo -e "${YELLOW}请使用: sudo $0${NC}"
    exit 1
fi

# 检测BIRD版本
detect_bird_version() {
    echo -e "${BLUE}检测BIRD版本...${NC}"
    
    if command -v birdc2 >/dev/null 2>&1; then
        BIRD_VERSION="2.x"
        BIRD_CONTROL="birdc2"
        BIRD_SERVICE="bird2"
        echo -e "${GREEN}✓${NC} 检测到BIRD 2.x版本"
    elif command -v birdc >/dev/null 2>&1; then
        BIRD_VERSION="1.x"
        BIRD_CONTROL="birdc"
        BIRD_SERVICE="bird"
        echo -e "${GREEN}✓${NC} 检测到BIRD 1.x版本"
    else
        echo -e "${RED}✗${NC} 未检测到BIRD安装"
        return 1
    fi
    
    # 显示版本信息
    if [[ "$BIRD_VERSION" == "2.x" ]]; then
        local version_info=$(birdc2 -v 2>&1 | head -1)
        echo -e "${CYAN}版本信息:${NC} $version_info"
    else
        local version_info=$(birdc -v 2>&1 | head -1)
        echo -e "${CYAN}版本信息:${NC} $version_info"
    fi
    
    return 0
}

# 检查BIRD配置语法
check_bird_config() {
    echo -e "${BLUE}检查BIRD配置语法...${NC}"
    
    local config_file="/etc/bird/bird.conf"
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}✗${NC} 配置文件不存在: $config_file"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} 配置文件存在: $config_file"
    
    # 根据BIRD版本使用不同的语法检查命令
    if [[ "$BIRD_VERSION" == "2.x" ]]; then
        echo -e "${YELLOW}使用BIRD 2.x语法检查...${NC}"
        if "$BIRD_CONTROL" configure 2>/dev/null; then
            echo -e "${GREEN}✓${NC} 配置文件语法正确"
            return 0
        else
            echo -e "${RED}✗${NC} 配置文件语法错误"
            echo -e "${YELLOW}详细错误信息:${NC}"
            "$BIRD_CONTROL" configure 2>&1 | head -10
            return 1
        fi
    else
        echo -e "${YELLOW}使用BIRD 1.x语法检查...${NC}"
        if "$BIRD_CONTROL" -c "$config_file" configure 2>/dev/null; then
            echo -e "${GREEN}✓${NC} 配置文件语法正确"
            return 0
        else
            echo -e "${RED}✗${NC} 配置文件语法错误"
            echo -e "${YELLOW}详细错误信息:${NC}"
            "$BIRD_CONTROL" -c "$config_file" configure 2>&1 | head -10
            return 1
        fi
    fi
}

# 修复BIRD配置
fix_bird_config() {
    echo -e "${BLUE}修复BIRD配置...${NC}"
    
    local config_file="/etc/bird/bird.conf"
    local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 备份原配置
    echo -e "${YELLOW}备份原配置文件...${NC}"
    cp "$config_file" "$backup_file"
    echo -e "${GREEN}✓${NC} 配置已备份到: $backup_file"
    
    # 检查并修复常见问题
    echo -e "${YELLOW}检查常见配置问题...${NC}"
    
    # 检查路由器ID
    if ! grep -q "router id" "$config_file"; then
        echo -e "${YELLOW}添加路由器ID...${NC}"
        # 获取第一个IPv4地址作为路由器ID
        local router_id=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
        if [[ -n "$router_id" ]]; then
            sed -i "1i router id $router_id;" "$config_file"
            echo -e "${GREEN}✓${NC} 已添加路由器ID: $router_id"
        else
            echo -e "${YELLOW}⚠${NC} 无法自动获取路由器ID，请手动配置"
        fi
    else
        echo -e "${GREEN}✓${NC} 路由器ID已配置"
    fi
    
    # 检查日志配置
    if ! grep -q "log syslog" "$config_file"; then
        echo -e "${YELLOW}添加日志配置...${NC}"
        sed -i '/router id/a log syslog all;' "$config_file"
        echo -e "${GREEN}✓${NC} 已添加日志配置"
    else
        echo -e "${GREEN}✓${NC} 日志配置已存在"
    fi
    
    # 检查协议配置
    if ! grep -q "protocol device" "$config_file"; then
        echo -e "${YELLOW}添加设备协议...${NC}"
        cat >> "$config_file" << 'EOF'

protocol device {
    scan time 10;
}
EOF
        echo -e "${GREEN}✓${NC} 已添加设备协议"
    else
        echo -e "${GREEN}✓${NC} 设备协议已配置"
    fi
    
    # 检查内核协议
    if ! grep -q "protocol kernel" "$config_file"; then
        echo -e "${YELLOW}添加内核协议...${NC}"
        cat >> "$config_file" << 'EOF'

protocol kernel {
    ipv4 {
        export all;
    };
    ipv6 {
        export all;
    };
}
EOF
        echo -e "${GREEN}✓${NC} 已添加内核协议"
    else
        echo -e "${GREEN}✓${NC} 内核协议已配置"
    fi
}

# 启动BIRD服务
start_bird_service() {
    echo -e "${BLUE}启动BIRD服务...${NC}"
    
    # 检查服务状态
    if systemctl is-active "$BIRD_SERVICE" >/dev/null 2>&1; then
        echo -e "${YELLOW}服务已在运行，重新加载配置...${NC}"
        if systemctl reload "$BIRD_SERVICE" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} 配置重新加载成功"
        else
            echo -e "${YELLOW}重新加载失败，尝试重启服务...${NC}"
            systemctl restart "$BIRD_SERVICE"
        fi
    else
        echo -e "${YELLOW}启动BIRD服务...${NC}"
        if systemctl start "$BIRD_SERVICE" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} BIRD服务启动成功"
        else
            echo -e "${RED}✗${NC} BIRD服务启动失败"
            echo -e "${YELLOW}查看服务状态:${NC}"
            systemctl status "$BIRD_SERVICE" --no-pager -l
            return 1
        fi
    fi
    
    # 启用服务
    if systemctl enable "$BIRD_SERVICE" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD服务已启用"
    else
        echo -e "${YELLOW}⚠${NC} 无法启用BIRD服务"
    fi
}

# 验证修复结果
verify_fix() {
    echo -e "${BLUE}验证修复结果...${NC}"
    
    # 检查服务状态
    if systemctl is-active "$BIRD_SERVICE" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} BIRD服务正在运行"
    else
        echo -e "${RED}✗${NC} BIRD服务未运行"
        return 1
    fi
    
    # 检查配置语法
    if check_bird_config; then
        echo -e "${GREEN}✓${NC} 配置语法正确"
    else
        echo -e "${RED}✗${NC} 配置语法仍有问题"
        return 1
    fi
    
    # 检查BGP状态
    echo -e "${YELLOW}检查BGP状态...${NC}"
    if [[ "$BIRD_VERSION" == "2.x" ]]; then
        "$BIRD_CONTROL" show protocols 2>/dev/null | head -5
    else
        "$BIRD_CONTROL" show protocols 2>/dev/null | head -5
    fi
    
    return 0
}

# 显示使用说明
show_usage() {
    echo -e "${CYAN}使用说明:${NC}"
    echo -e "  $0 [选项]"
    echo
    echo -e "${YELLOW}选项:${NC}"
    echo -e "  --check     仅检查BIRD状态，不进行修复"
    echo -e "  --fix       检查并修复BIRD配置"
    echo -e "  --restart   重启BIRD服务"
    echo -e "  --help      显示此帮助信息"
    echo
    echo -e "${YELLOW}示例:${NC}"
    echo -e "  $0 --check    # 检查BIRD状态"
    echo -e "  $0 --fix      # 修复BIRD配置"
    echo -e "  $0 --restart  # 重启BIRD服务"
}

# 主函数
main() {
    local action="fix"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check)
                action="check"
                shift
                ;;
            --fix)
                action="fix"
                shift
                ;;
            --restart)
                action="restart"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 检测BIRD版本
    if ! detect_bird_version; then
        echo -e "${RED}无法检测BIRD版本，请先安装BIRD${NC}"
        exit 1
    fi
    
    echo
    
    case "$action" in
        "check")
            echo -e "${BLUE}执行BIRD状态检查...${NC}"
            check_bird_config
            ;;
        "fix")
            echo -e "${BLUE}执行BIRD配置修复...${NC}"
            if check_bird_config; then
                echo -e "${GREEN}配置语法正确，无需修复${NC}"
            else
                fix_bird_config
                if check_bird_config; then
                    start_bird_service
                    verify_fix
                else
                    echo -e "${RED}修复失败，请手动检查配置${NC}"
                    exit 1
                fi
            fi
            ;;
        "restart")
            echo -e "${BLUE}重启BIRD服务...${NC}"
            systemctl restart "$BIRD_SERVICE"
            verify_fix
            ;;
    esac
    
    echo
    echo -e "${GREEN}操作完成！${NC}"
}

# 运行主函数
main "$@"
