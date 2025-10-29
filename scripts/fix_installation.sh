#!/bin/bash
# 统一修复脚本 - 修复安装后的常见问题
# 用法: bash scripts/fix_installation.sh

set -e

INSTALL_DIR="${INSTALL_DIR:-/opt/ipv6-wireguard-manager}"

echo "=========================================="
echo "IPv6 WireGuard Manager - 安装修复工具"
echo "=========================================="
echo ""

# 1. 修复 systemd 服务配置
fix_systemd_service() {
    echo "1. 修复 systemd 服务配置..."
    
    if [[ ! -f /etc/systemd/system/ipv6-wireguard-manager.service ]]; then
        echo "  ⚠️  服务文件不存在，跳过"
        return
    fi
    
    systemctl stop ipv6-wireguard-manager.service 2>/dev/null || true
    
    # 备份
    cp /etc/systemd/system/ipv6-wireguard-manager.service \
       /etc/systemd/system/ipv6-wireguard-manager.service.backup.$(date +%Y%m%d_%H%M%S)
    
    # 修复 Type=notify -> Type=simple
    sed -i 's/^Type=notify/Type=simple/' /etc/systemd/system/ipv6-wireguard-manager.service
    
    echo "  ✓ 服务类型已修复 (Type=simple)"
}

# 2. 修复 API 导入路径
fix_api_imports() {
    echo ""
    echo "2. 修复 API 导入路径..."
    
    if [[ ! -f "$INSTALL_DIR/backend/app/api/__init__.py" ]]; then
        echo "  ⚠️  API 文件不存在，跳过"
        return
    fi
    
    # 备份
    cp "$INSTALL_DIR/backend/app/api/__init__.py" \
       "$INSTALL_DIR/backend/app/api/__init__.py.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 修复导入路径
    sed -i 's|from app\.api\.api_v1 import|from .api_v1.api import|' \
        "$INSTALL_DIR/backend/app/api/__init__.py"
    
    echo "  ✓ API 导入路径已修复"
}

# 3. 重启服务
restart_service() {
    echo ""
    echo "3. 重启服务..."
    
    systemctl daemon-reload
    systemctl restart ipv6-wireguard-manager.service
    
    sleep 3
    
    if systemctl is-active --quiet ipv6-wireguard-manager.service; then
        echo "  ✓ 服务启动成功"
        return 0
    else
        echo "  ✗ 服务启动失败"
        return 1
    fi
}

# 4. 显示访问信息
show_access_info() {
    echo ""
    echo "=========================================="
    echo "📡 访问信息"
    echo "=========================================="
    
    # 获取配置
    API_PORT=$(grep "^SERVER_PORT=" "$INSTALL_DIR/.env" | cut -d= -f2 | tr -d '"' | tr -d "'" 2>/dev/null || echo "8000")
    if [[ -z "$API_PORT" ]]; then
        API_PORT=$(grep "^API_PORT=" "$INSTALL_DIR/.env" | cut -d= -f2 | tr -d '"' | tr -d "'" 2>/dev/null || echo "8000")
    fi
    
    # 获取 IP 地址
    ipv4_addr=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    ipv6_addr=$(ip -6 addr show 2>/dev/null | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^::1' | grep -v '^fe80' | head -1)
    
    echo ""
    if [[ -n "$ipv4_addr" ]]; then
        echo "🌐 IPv4 访问:"
        echo "   前端:    http://$ipv4_addr"
        echo "   API:     http://$ipv4_addr:$API_PORT/docs"
        echo ""
    fi
    
    if [[ -n "$ipv6_addr" ]]; then
        echo "🌐 IPv6 访问:"
        echo "   前端:    http://[$ipv6_addr]"
        echo "   API:     http://[$ipv6_addr]:$API_PORT/docs"
        echo ""
    fi
    
    echo "🏠 本地访问:"
    echo "   前端:    http://localhost"
    echo "   API:     http://localhost:$API_PORT/docs"
    echo ""
    
    # 获取管理员密码
    if [[ -f "$INSTALL_DIR/.env" ]]; then
        admin_pass=$(grep "^FIRST_SUPERUSER_PASSWORD=" "$INSTALL_DIR/.env" | cut -d= -f2 | tr -d '"' | tr -d "'" | head -1 2>/dev/null)
        
        if [[ -n "$admin_pass" ]]; then
            echo "=========================================="
            echo "🔑 登录凭据"
            echo "=========================================="
            echo ""
            echo "   用户名: admin"
            echo "   密码:   $admin_pass"
            echo "   邮箱:   admin@example.com"
            echo ""
            echo "⚠️  请立即登录并修改默认密码！"
            echo ""
        fi
    fi
    
    echo "=========================================="
}

# 主流程
main() {
    fix_systemd_service
    fix_api_imports
    
    if restart_service; then
        echo ""
        echo "✅ 所有修复已应用成功！"
        show_access_info
    else
        echo ""
        echo "❌ 服务启动失败，请查看日志:"
        echo "   systemctl status ipv6-wireguard-manager"
        echo "   journalctl -u ipv6-wireguard-manager -n 50"
        exit 1
    fi
}

# 运行主流程
main

