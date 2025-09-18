#!/bin/bash

# 网络接口检测测试脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 测试get_network_interfaces函数
test_get_network_interfaces() {
    echo -e "${CYAN}测试 get_network_interfaces 函数${NC}"
    echo "=========================================="
    
    # 模拟get_network_interfaces函数
    get_network_interfaces() {
        local interfaces=()
        
        # 使用ip命令获取网络接口
        if command -v ip >/dev/null 2>&1; then
            echo "使用 ip 命令检测网络接口..."
            while IFS= read -r interface; do
                if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
                    interfaces+=("$interface")
                fi
            done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
        else
            # 如果ip命令不可用，使用ifconfig
            if command -v ifconfig >/dev/null 2>&1; then
                echo "使用 ifconfig 命令检测网络接口..."
                while IFS= read -r interface; do
                    if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
                        interfaces+=("$interface")
                    fi
                done < <(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
            else
                # 最后的备选方案
                echo "使用默认网络接口列表..."
                interfaces=("eth0" "ens33" "enp0s3" "wlan0")
            fi
        fi
        
        # 返回数组
        printf '%s\n' "${interfaces[@]}"
    }
    
    # 测试函数
    local interfaces=($(get_network_interfaces))
    
    echo "检测到的网络接口数量: ${#interfaces[@]}"
    echo "网络接口列表:"
    for i in "${!interfaces[@]}"; do
        echo "  $((i+1)). ${interfaces[$i]}"
    done
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}错误: 未找到可用的网络接口${NC}"
        return 1
    else
        echo -e "${GREEN}成功检测到 ${#interfaces[@]} 个网络接口${NC}"
        return 0
    fi
}

# 测试interactive_interface_selection函数
test_interactive_interface_selection() {
    echo -e "${CYAN}测试 interactive_interface_selection 函数${NC}"
    echo "=========================================="
    
    # 模拟interactive_interface_selection函数
    interactive_interface_selection() {
        # 获取网络接口列表
        local interfaces=($(get_network_interfaces))
        
        if [[ ${#interfaces[@]} -eq 0 ]]; then
            echo -e "${RED}错误: 未找到可用的网络接口${NC}"
            echo -e "${YELLOW}请检查网络接口配置${NC}"
            return 1
        fi
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                        网络接口选择                          ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo
        echo -e "${YELLOW}可用的网络接口:${NC}"
        
        for i in "${!interfaces[@]}"; do
            # 获取接口状态和IP信息
            local interface="${interfaces[$i]}"
            local status="未知"
            local ip_info=""
            
            # 检查接口状态和IP信息
            if command -v ip >/dev/null 2>&1; then
                status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
                ip_info=$(ip addr show "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}' | cut -d'/' -f1)
            else
                # 如果ip命令不可用，使用ifconfig
                if command -v ifconfig >/dev/null 2>&1; then
                    status=$(ifconfig "$interface" 2>/dev/null | grep -o "UP\|DOWN" | head -1)
                    ip_info=$(ifconfig "$interface" 2>/dev/null | grep "inet " | head -1 | awk '{print $2}')
                fi
            fi
            
            if [[ -n "$ip_info" ]]; then
                echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status}, IP: ${ip_info})"
            else
                echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status})"
            fi
        done
        
        echo
        echo "模拟选择第一个接口..."
        local selected_interface="${interfaces[0]}"
        echo -e "${GREEN}✓${NC} 已选择网络接口: ${selected_interface}"
        echo "$selected_interface"
        return 0
    }
    
    # 测试函数
    local selected_interface=$(interactive_interface_selection)
    
    if [[ -n "$selected_interface" ]]; then
        echo -e "${GREEN}成功选择网络接口: $selected_interface${NC}"
        return 0
    else
        echo -e "${RED}网络接口选择失败${NC}"
        return 1
    fi
}

# 主测试函数
main() {
    echo -e "${BLUE}网络接口检测功能测试${NC}"
    echo "================================"
    echo
    
    # 测试1: get_network_interfaces函数
    echo -e "${YELLOW}测试1: get_network_interfaces 函数${NC}"
    if test_get_network_interfaces; then
        echo -e "${GREEN}✓ 测试1 通过${NC}"
    else
        echo -e "${RED}✗ 测试1 失败${NC}"
    fi
    echo
    
    # 测试2: interactive_interface_selection函数
    echo -e "${YELLOW}测试2: interactive_interface_selection 函数${NC}"
    if test_interactive_interface_selection; then
        echo -e "${GREEN}✓ 测试2 通过${NC}"
    else
        echo -e "${RED}✗ 测试2 失败${NC}"
    fi
    echo
    
    echo -e "${BLUE}测试完成${NC}"
}

# 运行测试
main
