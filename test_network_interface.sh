#!/bin/bash

# 网络接口检测功能测试脚本
# 版本: 1.13

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 加载公共函数库
if [[ -f "modules/common_functions.sh" ]]; then
    source "modules/common_functions.sh"
fi

# 测试网络接口检测功能
test_network_interface_detection() {
    echo -e "${CYAN}=== 网络接口检测功能测试 ===${NC}"
    echo
    
    # 测试1: 检查ip命令是否可用
    echo -e "${YELLOW}1. 检查ip命令可用性${NC}"
    if command -v ip >/dev/null 2>&1; then
        echo -e "${GREEN}✓ ip命令可用${NC}"
        ip_version=$(ip -V 2>&1 | head -1)
        echo "  版本: $ip_version"
    else
        echo -e "${RED}✗ ip命令不可用${NC}"
    fi
    echo
    
    # 测试2: 检查ifconfig命令是否可用
    echo -e "${YELLOW}2. 检查ifconfig命令可用性${NC}"
    if command -v ifconfig >/dev/null 2>&1; then
        echo -e "${GREEN}✓ ifconfig命令可用${NC}"
        ifconfig_version=$(ifconfig -V 2>&1 | head -1)
        echo "  版本: $ifconfig_version"
    else
        echo -e "${RED}✗ ifconfig命令不可用${NC}"
    fi
    echo
    
    # 测试3: 使用ip命令获取网络接口
    echo -e "${YELLOW}3. 使用ip命令获取网络接口${NC}"
    if command -v ip >/dev/null 2>&1; then
        echo "执行命令: ip -o link show | awk -F': ' '{print \$2}' | grep -v '^lo\$'"
        interfaces_ip=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
        if [[ -n "$interfaces_ip" ]]; then
            echo -e "${GREEN}✓ 成功获取网络接口${NC}"
            echo "检测到的接口:"
            while IFS= read -r interface; do
                if [[ -n "$interface" ]]; then
                    echo "  - $interface"
                fi
            done <<< "$interfaces_ip"
        else
            echo -e "${RED}✗ 未检测到网络接口${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ ip命令不可用，跳过测试${NC}"
    fi
    echo
    
    # 测试4: 使用ifconfig命令获取网络接口
    echo -e "${YELLOW}4. 使用ifconfig命令获取网络接口${NC}"
    if command -v ifconfig >/dev/null 2>&1; then
        echo "执行命令: ifconfig -a | grep -E '^[a-zA-Z]' | awk '{print \$1}' | cut -d: -f1 | grep -v '^lo\$'"
        interfaces_ifconfig=$(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
        if [[ -n "$interfaces_ifconfig" ]]; then
            echo -e "${GREEN}✓ 成功获取网络接口${NC}"
            echo "检测到的接口:"
            while IFS= read -r interface; do
                if [[ -n "$interface" ]]; then
                    echo "  - $interface"
                fi
            done <<< "$interfaces_ifconfig"
        else
            echo -e "${RED}✗ 未检测到网络接口${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ ifconfig命令不可用，跳过测试${NC}"
    fi
    echo
}

# 测试get_network_interfaces函数
test_get_network_interfaces_function() {
    echo -e "${CYAN}=== 测试get_network_interfaces函数 ===${NC}"
    echo
    
    # 定义get_network_interfaces函数（从主脚本复制）
    get_network_interfaces() {
        local interfaces=()
        
        # 使用ip命令获取网络接口
        if command -v ip >/dev/null 2>&1; then
            while IFS= read -r interface; do
                if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
                    interfaces+=("$interface")
                fi
            done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null)
        else
            # 如果ip命令不可用，使用ifconfig
            if command -v ifconfig >/dev/null 2>&1; then
                while IFS= read -r interface; do
                    if [[ "$interface" != "lo" ]] && [[ -n "$interface" ]]; then
                        interfaces+=("$interface")
                    fi
                done < <(ifconfig -a | grep -E "^[a-zA-Z]" | awk '{print $1}' | cut -d: -f1 | grep -v '^lo$' 2>/dev/null)
            else
                # 最后的备选方案
                echo "警告: 无法使用ip或ifconfig命令检测网络接口" >&2
                interfaces=("eth0" "ens33" "enp0s3" "wlan0")
            fi
        fi
        
        # 返回数组
        printf '%s\n' "${interfaces[@]}"
    }
    
    # 测试函数
    echo -e "${YELLOW}执行get_network_interfaces函数${NC}"
    local interfaces=($(get_network_interfaces))
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}✗ 函数返回空结果${NC}"
        return 1
    else
        echo -e "${GREEN}✓ 函数成功返回 ${#interfaces[@]} 个网络接口${NC}"
        echo "检测到的接口:"
        for i in "${!interfaces[@]}"; do
            echo "  $((i+1)). ${interfaces[$i]}"
        done
        return 0
    fi
}

# 测试interactive_interface_selection函数
test_interactive_interface_selection() {
    echo -e "${CYAN}=== 测试interactive_interface_selection函数 ===${NC}"
    echo
    
    # 定义interactive_interface_selection函数（从主脚本复制）
    interactive_interface_selection() {
        # 获取网络接口列表
        local interfaces=($(get_network_interfaces))
        
        if [[ ${#interfaces[@]} -eq 0 ]]; then
            echo -e "${RED}错误: 未找到可用的网络接口${NC}"
            echo -e "${YELLOW}请检查网络接口配置${NC}"
            return 1
        fi
        
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}                    网络接口选择                              ${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
        echo
        
        # 显示接口列表
        for i in "${!interfaces[@]}"; do
            local interface="${interfaces[$i]}"
            local status="未知"
            local ip_info=""
            
            # 检查接口状态
            if command -v ip >/dev/null 2>&1; then
                status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
                ip_info=$(ip addr show "$interface" 2>/dev/null | grep -o "inet [0-9.]*" | cut -d' ' -f2 | head -1)
            else
                # 如果ip命令不可用，使用ifconfig
                if command -v ifconfig >/dev/null 2>&1; then
                    status=$(ifconfig "$interface" 2>/dev/null | grep -o "UP\|DOWN" | head -1)
                    ip_info=$(ifconfig "$interface" 2>/dev/null | grep -o "inet [0-9.]*" | cut -d' ' -f2 | head -1)
                fi
            fi
            
            # 显示接口信息
            if [[ -n "$ip_info" ]]; then
                echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status}, IP: ${ip_info})"
            else
                echo -e "  ${GREEN}$((i+1)).${NC} ${interface} (状态: ${status})"
            fi
        done
        
        echo
        echo -e "${YELLOW}请选择网络接口 (1-${#interfaces[@]}):${NC}"
        
        # 模拟用户输入（选择第一个接口）
        local choice=1
        echo "模拟选择: $choice"
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#interfaces[@]}" ]]; then
            local selected_interface="${interfaces[$((choice-1))]}"
            echo -e "${GREEN}已选择网络接口: ${selected_interface}${NC}"
            echo "$selected_interface"
            return 0
        else
            echo -e "${RED}无效选择: $choice${NC}"
            return 1
        fi
    }
    
    # 测试函数
    echo -e "${YELLOW}执行interactive_interface_selection函数${NC}"
    local selected_interface=$(interactive_interface_selection)
    
    if [[ -n "$selected_interface" ]]; then
        echo -e "${GREEN}✓ 函数成功选择网络接口: $selected_interface${NC}"
        return 0
    else
        echo -e "${RED}✗ 函数选择网络接口失败${NC}"
        return 1
    fi
}

# 测试网络接口状态检查
test_interface_status() {
    echo -e "${CYAN}=== 测试网络接口状态检查 ===${NC}"
    echo
    
    # 获取网络接口列表
    local interfaces=($(get_network_interfaces))
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        echo -e "${RED}✗ 没有可用的网络接口进行测试${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}检查 ${#interfaces[@]} 个网络接口的状态${NC}"
    echo
    
    for interface in "${interfaces[@]}"; do
        echo -e "${BLUE}接口: $interface${NC}"
        
        # 检查接口状态
        if command -v ip >/dev/null 2>&1; then
            local status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
            local ipv4=$(ip addr show "$interface" 2>/dev/null | grep -o "inet [0-9.]*" | cut -d' ' -f2 | head -1)
            local ipv6=$(ip addr show "$interface" 2>/dev/null | grep -o "inet6 [0-9a-f:]*" | cut -d' ' -f2 | head -1)
            
            echo "  状态: $status"
            [[ -n "$ipv4" ]] && echo "  IPv4: $ipv4"
            [[ -n "$ipv6" ]] && echo "  IPv6: $ipv6"
        else
            echo "  状态: 无法检查（ip命令不可用）"
        fi
        echo
    done
}

# 主测试函数
main() {
    echo -e "${BLUE}IPv6 WireGuard Manager - 网络接口检测功能测试${NC}"
    echo -e "${BLUE}版本: 1.13${NC}"
    echo -e "${BLUE}测试时间: $(date)${NC}"
    echo
    
    local test_results=()
    
    # 运行所有测试
    echo -e "${CYAN}开始测试...${NC}"
    echo
    
    # 测试1: 网络接口检测功能
    if test_network_interface_detection; then
        test_results+=("网络接口检测: ✓ 通过")
    else
        test_results+=("网络接口检测: ✗ 失败")
    fi
    echo
    
    # 测试2: get_network_interfaces函数
    if test_get_network_interfaces_function; then
        test_results+=("get_network_interfaces函数: ✓ 通过")
    else
        test_results+=("get_network_interfaces函数: ✗ 失败")
    fi
    echo
    
    # 测试3: interactive_interface_selection函数
    if test_interactive_interface_selection; then
        test_results+=("interactive_interface_selection函数: ✓ 通过")
    else
        test_results+=("interactive_interface_selection函数: ✗ 失败")
    fi
    echo
    
    # 测试4: 网络接口状态检查
    if test_interface_status; then
        test_results+=("网络接口状态检查: ✓ 通过")
    else
        test_results+=("网络接口状态检查: ✗ 失败")
    fi
    echo
    
    # 显示测试结果
    echo -e "${CYAN}=== 测试结果汇总 ===${NC}"
    for result in "${test_results[@]}"; do
        echo "$result"
    done
    echo
    
    # 统计结果
    local passed=0
    local failed=0
    for result in "${test_results[@]}"; do
        if [[ "$result" == *"✓ 通过"* ]]; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo -e "${BLUE}测试统计:${NC}"
    echo -e "  通过: ${GREEN}$passed${NC}"
    echo -e "  失败: ${RED}$failed${NC}"
    echo -e "  总计: $((passed + failed))"
    echo
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有测试通过！网络接口检测功能正常工作。${NC}"
        return 0
    else
        echo -e "${RED}❌ 有 $failed 个测试失败，请检查相关功能。${NC}"
        return 1
    fi
}

# 运行主测试
main "$@"
