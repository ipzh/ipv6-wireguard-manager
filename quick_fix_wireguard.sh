#!/bin/bash

# 快速修复WireGuard配置文件中的中文注释问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}快速修复WireGuard配置文件${NC}"
echo "================================"

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}错误: 需要root权限${NC}"
    exit 1
fi

CONFIG_FILE="/etc/wireguard/wg0.conf"

# 检查配置文件是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}错误: WireGuard配置文件不存在${NC}"
    exit 1
fi

# 备份原文件
echo -e "${YELLOW}备份原配置文件...${NC}"
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# 显示问题行
echo -e "${YELLOW}检查配置文件中的问题行...${NC}"
grep -n "当前默认前缀" "$CONFIG_FILE" || echo "未找到问题行"

# 删除包含中文的行
echo -e "${YELLOW}删除包含中文的行...${NC}"
sed -i '/当前默认前缀/d' "$CONFIG_FILE"
sed -i '/IPv6前缀配置/d' "$CONFIG_FILE"
sed -i '/支持的格式/d' "$CONFIG_FILE"
sed -i '/单段前缀/d' "$CONFIG_FILE"
sed -i '/多段前缀/d' "$CONFIG_FILE"
sed -i '/子网前缀/d' "$CONFIG_FILE"

# 删除空行和只包含空格的行
sed -i '/^[[:space:]]*$/d' "$CONFIG_FILE"

# 确保配置文件以空行结尾
echo "" >> "$CONFIG_FILE"

# 显示修复后的文件
echo -e "${GREEN}修复后的配置文件:${NC}"
echo "----------------------------------------"
cat "$CONFIG_FILE"
echo "----------------------------------------"

# 验证语法
echo -e "${YELLOW}验证配置文件语法...${NC}"
if wg-quick strip wg0 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ 配置文件语法正确${NC}"
    
    # 尝试启动服务
    echo -e "${YELLOW}尝试启动WireGuard服务...${NC}"
    if systemctl start wg-quick@wg0.service; then
        echo -e "${GREEN}✓ WireGuard服务启动成功${NC}"
        systemctl status wg-quick@wg0.service --no-pager
    else
        echo -e "${RED}✗ WireGuard服务启动失败${NC}"
        systemctl status wg-quick@wg0.service --no-pager
    fi
else
    echo -e "${RED}✗ 配置文件语法仍有问题${NC}"
    echo "语法检查结果:"
    wg-quick strip wg0 2>&1 || true
fi

echo -e "${BLUE}修复完成${NC}"
