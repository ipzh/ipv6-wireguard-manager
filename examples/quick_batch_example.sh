#!/bin/bash

# 快速批量添加客户端示例脚本
# 此脚本演示如何使用快速批量添加功能
#
# 注意: 此功能需要BIRD BGP服务支持
# 系统默认安装BIRD 2.x版本，提供更好的性能

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}IPv6 WireGuard Manager - 快速批量添加客户端示例${NC}"
echo

# 示例1: 添加10个客户端，使用默认前缀 "client"
echo -e "${YELLOW}示例1: 添加10个客户端 (client1-client10)${NC}"
echo "命令: quick_batch_add_clients 10"
echo "结果: 自动分配地址，避免冲突"
echo

# 示例2: 添加5个移动设备客户端
echo -e "${YELLOW}示例2: 添加5个移动设备 (mobile1-mobile5)${NC}"
echo "命令: quick_batch_add_clients 5 mobile"
echo "结果: 自动分配地址，避免冲突"
echo

# 示例3: 添加20个用户客户端，从索引100开始
echo -e "${YELLOW}示例3: 添加20个用户 (user100-user119)${NC}"
echo "命令: quick_batch_add_clients 20 user 100"
echo "结果: 自动分配地址，避免冲突"
echo

# 示例4: 使用CSV文件批量添加
echo -e "${YELLOW}示例4: 使用CSV文件批量添加${NC}"
echo "文件: examples/clients.csv"
echo "命令: batch_generate_clients examples/clients.csv true"
echo "结果: 支持自动地址分配和手动指定地址"
echo

echo -e "${GREEN}功能特点:${NC}"
echo "✓ 自动地址分配 - 避免IP地址冲突"
echo "✓ 智能地址池管理 - 自动选择可用地址"
echo "✓ 批量操作 - 一次添加多个客户端"
echo "✓ 灵活配置 - 支持自定义名称前缀和起始索引"
echo "✓ 冲突检测 - 自动检测和避免地址冲突"
echo "✓ 状态跟踪 - 实时显示添加结果"
echo "✓ IPv6地址正确配置 - 服务器使用具体地址，客户端从子网段分配"
echo "✓ 灵活子网段支持 - 支持/56到/72的子网段范围，自动分配合适的子网掩码"
echo

echo -e "${BLUE}使用方法:${NC}"
echo "1. 在客户端管理菜单中选择 '7. 快速批量添加客户端'"
echo "2. 输入要添加的客户端数量"
echo "3. 选择客户端名称前缀（可选）"
echo "4. 选择起始索引（可选）"
echo "5. 系统自动分配地址并创建配置"
echo

echo -e "${YELLOW}注意事项:${NC}"
echo "• 系统会自动检测可用地址，避免冲突"
echo "• 支持IPv4和IPv6地址自动分配"
echo "• 每个客户端都会生成完整的配置包"
echo "• 服务器配置会自动更新"
echo "• 支持大量客户端场景（最多1000个）"
