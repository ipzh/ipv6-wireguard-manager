#!/bin/bash

# 测试root权限检查修复

echo "=== 测试root权限检查修复 ==="

# 创建测试目录
TEST_DIR="/tmp/root-check-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || exit

echo "测试目录: $TEST_DIR"

# 创建模拟的安装完成函数
cat > test_install_complete.sh << 'EOF'
#!/bin/bash

# 模拟变量
BIN_DIR="/tmp/test-bin"
INSTALL_DIR="/tmp/test-install"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 模拟安装完成函数
show_installation_complete() {
    echo -e "${GREEN}安装完成！${NC}"
    echo
    
    # 检查是否有root权限来执行脚本
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}注意: 需要root权限才能运行主程序${NC}"
        echo -e "${YELLOW}请使用以下命令之一:${NC}"
        echo -e "  ${CYAN}sudo ipv6-wireguard-manager${NC}"
        echo -e "  ${CYAN}sudo $BIN_DIR/ipv6-wireguard-manager${NC}"
        echo -e "  ${CYAN}sudo $INSTALL_DIR/ipv6-wireguard-manager.sh${NC}"
    else
        # 检查全局命令是否可用
        if command -v ipv6-wireguard-manager &> /dev/null; then
            echo -e "${GREEN}使用全局命令启动...${NC}"
            echo "模拟执行: ipv6-wireguard-manager"
        # 检查安装目录中的可执行文件
        elif [[ -f "$BIN_DIR/ipv6-wireguard-manager" ]]; then
            echo -e "${YELLOW}使用安装目录中的文件启动...${NC}"
            echo "模拟执行: $BIN_DIR/ipv6-wireguard-manager"
        # 检查主脚本文件
        elif [[ -f "$INSTALL_DIR/ipv6-wireguard-manager.sh" ]]; then
            echo -e "${YELLOW}使用主脚本文件启动...${NC}"
            echo "模拟执行: $INSTALL_DIR/ipv6-wireguard-manager.sh"
        else
            echo -e "${RED}错误: 找不到可执行文件${NC}"
            echo -e "${RED}请检查以下位置:${NC}"
            echo -e "  - /usr/local/bin/ipv6-wireguard-manager"
            echo -e "  - $BIN_DIR/ipv6-wireguard-manager"
            echo -e "  - $INSTALL_DIR/ipv6-wireguard-manager.sh"
            echo
            echo -e "${YELLOW}请手动运行以下命令之一:${NC}"
            echo -e "  ${CYAN}sudo ln -sf $BIN_DIR/ipv6-wireguard-manager /usr/local/bin/ipv6-wireguard-manager${NC}"
            echo -e "  ${CYAN}$BIN_DIR/ipv6-wireguard-manager${NC}"
        fi
    fi
    
    echo
    echo -e "${GREEN}感谢使用IPv6 WireGuard Manager！${NC}"
    echo
}

# 执行测试
show_installation_complete
EOF

chmod +x test_install_complete.sh

echo "1. 测试非root用户情况..."
# 模拟非root用户
if [[ $EUID -eq 0 ]]; then
    echo "当前是root用户，切换到非root用户进行测试"
    # 这里我们只是显示预期的行为
    echo "预期行为: 显示需要root权限的提示"
else
    echo "当前是非root用户，直接测试"
    bash test_install_complete.sh
fi

echo "2. 测试root用户情况..."
# 创建模拟的可执行文件
mkdir -p "/tmp/test-bin" "/tmp/test-install"
echo "#!/bin/bash" > "/tmp/test-bin/ipv6-wireguard-manager"
echo "echo '模拟主程序执行'" >> "/tmp/test-bin/ipv6-wireguard-manager"
chmod +x "/tmp/test-bin/ipv6-wireguard-manager"

# 模拟root用户执行
echo "模拟root用户执行:"
EUID=0 bash test_install_complete.sh

echo "3. 测试语法检查..."
if bash -n test_install_complete.sh; then
    echo "✓ 语法检查通过"
else
    echo "✗ 语法检查失败"
fi

# 清理
cd /
rm -rf "$TEST_DIR" "/tmp/test-bin" "/tmp/test-install"
echo "✓ 测试完成，临时目录已清理"
