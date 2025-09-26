#!/bin/bash

# 测试全局命令别名创建

# 模拟安装环境
INSTALL_DIR="/tmp/test-ipv6-wireguard-manager"
BIN_DIR="/tmp/test-bin"

# 创建测试目录
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# 创建测试脚本
cat > "$INSTALL_DIR/ipv6-wireguard-manager.sh" << 'EOF'
#!/bin/bash
echo "IPv6 WireGuard Manager 测试脚本"
echo "参数: $@"
EOF

chmod +x "$INSTALL_DIR/ipv6-wireguard-manager.sh"

# 测试符号链接创建
echo "测试符号链接创建..."

# 删除可能存在的旧链接
rm -f "$BIN_DIR/ipv6-wireguard-manager" 2>/dev/null || true

# 创建新的符号链接
if ln -sf "$INSTALL_DIR/ipv6-wireguard-manager.sh" "$BIN_DIR/ipv6-wireguard-manager"; then
    echo "✓ 符号链接创建成功"
    echo "链接目标: $BIN_DIR/ipv6-wireguard-manager -> $INSTALL_DIR/ipv6-wireguard-manager.sh"
else
    echo "✗ 符号链接创建失败"
    exit 1
fi

# 测试全局命令
echo "测试全局命令..."

if command -v ipv6-wireguard-manager &> /dev/null; then
    echo "✓ 全局命令可用"
    echo "运行测试:"
    ipv6-wireguard-manager --test
else
    echo "✗ 全局命令不可用"
    echo "PATH: $PATH"
    echo "ls -la $BIN_DIR/ipv6-wireguard-manager:"
    ls -la "$BIN_DIR/ipv6-wireguard-manager" 2>/dev/null || echo "文件不存在"
fi

# 清理
echo "清理测试文件..."
rm -f "$BIN_DIR/ipv6-wireguard-manager"
rm -rf "$INSTALL_DIR"
rm -rf "$BIN_DIR"

echo "测试完成"
