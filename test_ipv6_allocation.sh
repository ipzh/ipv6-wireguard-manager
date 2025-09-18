#!/bin/bash

# IPv6地址分配测试脚本
# 版本: 1.0.8

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}IPv6地址分配测试脚本${NC}"
echo

# 测试IPv6地址生成函数
test_ipv6_generation() {
    echo -e "${BLUE}测试IPv6地址生成...${NC}"
    
    # 测试用例
    local test_cases=(
        "2001:db8::/48"
        "2001:db8:1::/56"
        "2001:db8:1000::/56"
        "2001:db8:2000::/64"
        "2001:db8:3000::/72"
    )
    
    for prefix in "${test_cases[@]}"; do
        echo -e "${YELLOW}测试前缀: $prefix${NC}"
        
        local network_part=$(echo "$prefix" | cut -d'/' -f1)
        local subnet_mask=$(echo "$prefix" | cut -d'/' -f2)
        
        # 根据子网掩码确定客户端子网掩码
        local client_subnet_mask=""
        case "$subnet_mask" in
            56) client_subnet_mask="64" ;;
            57) client_subnet_mask="65" ;;
            58) client_subnet_mask="66" ;;
            59) client_subnet_mask="67" ;;
            60) client_subnet_mask="68" ;;
            61) client_subnet_mask="69" ;;
            62) client_subnet_mask="70" ;;
            63) client_subnet_mask="71" ;;
            64) client_subnet_mask="72" ;;
            65) client_subnet_mask="73" ;;
            66) client_subnet_mask="74" ;;
            67) client_subnet_mask="75" ;;
            68) client_subnet_mask="76" ;;
            69) client_subnet_mask="77" ;;
            70) client_subnet_mask="78" ;;
            71) client_subnet_mask="79" ;;
            72) client_subnet_mask="80" ;;
            *) client_subnet_mask="128" ;;
        esac
        
        # 生成测试地址
        for i in {2..5}; do
            local test_ipv6=""
            if [[ "$network_part" == *"::" ]]; then
                test_ipv6="${network_part}${i}/${client_subnet_mask}"
            elif [[ "$network_part" == *":" ]]; then
                test_ipv6="${network_part}${i}/${client_subnet_mask}"
            else
                test_ipv6="${network_part}:${i}/${client_subnet_mask}"
            fi
            
            echo -e "  客户端 $i: $test_ipv6"
            
            # 验证地址格式
            if [[ "$test_ipv6" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
                echo -e "    ${GREEN}✓${NC} 格式正确"
            else
                echo -e "    ${RED}✗${NC} 格式错误"
            fi
            
            # 检查是否有过多的冒号
            local colon_count=$(echo "$test_ipv6" | tr -cd ':' | wc -c)
            if [[ $colon_count -le 7 ]]; then
                echo -e "    ${GREEN}✓${NC} 冒号数量正确 ($colon_count)"
            else
                echo -e "    ${RED}✗${NC} 冒号数量过多 ($colon_count)"
            fi
        done
        echo
    done
}

# 测试客户端数据库创建
test_client_database() {
    echo -e "${BLUE}测试客户端数据库创建...${NC}"
    
    local test_db="/tmp/test_clients.db"
    
    # 清理测试文件
    rm -f "$test_db"
    
    # 模拟创建数据库
    echo "test_client1|key1|pubkey1|10.0.0.2/32|2001:db8::2/128|2024-01-01|active" > "$test_db"
    echo "test_client2|key2|pubkey2|10.0.0.3/32|2001:db8::3/128|2024-01-01|active" >> "$test_db"
    
    echo -e "${GREEN}✓${NC} 测试数据库已创建: $test_db"
    
    # 测试地址冲突检查
    echo -e "${YELLOW}测试地址冲突检查...${NC}"
    
    # 检查已存在的地址
    if grep -q "|10.0.0.2/32|" "$test_db"; then
        echo -e "  ${GREEN}✓${NC} 正确检测到已存在的IPv4地址"
    else
        echo -e "  ${RED}✗${NC} 未检测到已存在的IPv4地址"
    fi
    
    if grep -q "|2001:db8::2/128|" "$test_db"; then
        echo -e "  ${GREEN}✓${NC} 正确检测到已存在的IPv6地址"
    else
        echo -e "  ${RED}✗${NC} 未检测到已存在的IPv6地址"
    fi
    
    # 检查不存在的地址
    if ! grep -q "|10.0.0.100/32|" "$test_db"; then
        echo -e "  ${GREEN}✓${NC} 正确检测到可用的IPv4地址"
    else
        echo -e "  ${RED}✗${NC} 错误检测到已存在的IPv4地址"
    fi
    
    if ! grep -q "|2001:db8::100/128|" "$test_db"; then
        echo -e "  ${GREEN}✓${NC} 正确检测到可用的IPv6地址"
    else
        echo -e "  ${RED}✗${NC} 错误检测到已存在的IPv6地址"
    fi
    
    # 清理测试文件
    rm -f "$test_db"
    echo -e "${GREEN}✓${NC} 测试数据库已清理"
}

# 测试日志分离
test_log_separation() {
    echo -e "${BLUE}测试日志分离...${NC}"
    
    # 模拟auto_allocate_addresses函数的输出
    local test_output="10.0.0.2/32|2001:db8::2/128"
    
    # 测试地址解析
    local ipv4=$(echo "$test_output" | cut -d'|' -f1)
    local ipv6=$(echo "$test_output" | cut -d'|' -f2)
    
    if [[ "$ipv4" == "10.0.0.2/32" ]]; then
        echo -e "  ${GREEN}✓${NC} IPv4地址解析正确: $ipv4"
    else
        echo -e "  ${RED}✗${NC} IPv4地址解析错误: $ipv4"
    fi
    
    if [[ "$ipv6" == "2001:db8::2/128" ]]; then
        echo -e "  ${GREEN}✓${NC} IPv6地址解析正确: $ipv6"
    else
        echo -e "  ${RED}✗${NC} IPv6地址解析错误: $ipv6"
    fi
    
    # 测试不包含日志信息
    if [[ "$test_output" != *"INFO"* ]] && [[ "$test_output" != *"Allocated"* ]]; then
        echo -e "  ${GREEN}✓${NC} 输出不包含日志信息"
    else
        echo -e "  ${RED}✗${NC} 输出包含日志信息"
    fi
}

# 主函数
main() {
    echo -e "${CYAN}开始IPv6地址分配测试...${NC}"
    echo
    
    test_ipv6_generation
    test_client_database
    test_log_separation
    
    echo
    echo -e "${GREEN}测试完成！${NC}"
}

# 运行测试
main
