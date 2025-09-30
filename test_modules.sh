#!/bin/bash

# 简单模块测试脚本
set -e

echo "=== 开始模块测试 ==="

# 测试公共函数库
echo "1. 测试公共函数库..."
if bash -c "source modules/common_functions.sh && echo 'Common functions OK'" 2>/dev/null; then
    echo "✓ 公共函数库测试通过"
else
    echo "✗ 公共函数库测试失败"
fi

# 测试系统检测
echo "2. 测试系统检测..."
if bash -c "source modules/system_detection.sh && echo 'System detection OK'" 2>/dev/null; then
    echo "✓ 系统检测测试通过"
else
    echo "✗ 系统检测测试失败"
fi

# 测试配置管理
echo "3. 测试配置管理..."
if bash -c "source modules/config_manager.sh && echo 'Config manager OK'" 2>/dev/null; then
    echo "✓ 配置管理测试通过"
else
    echo "✗ 配置管理测试失败"
fi

# 测试错误处理
echo "4. 测试错误处理..."
if bash -c "source modules/error_handling.sh && echo 'Error handling OK'" 2>/dev/null; then
    echo "✓ 错误处理测试通过"
else
    echo "✗ 错误处理测试失败"
fi

# 测试模块加载器
echo "5. 测试模块加载器..."
if bash -c "source modules/module_loader.sh && echo 'Module loader OK'" 2>/dev/null; then
    echo "✓ 模块加载器测试通过"
else
    echo "✗ 模块加载器测试失败"
fi

# 测试WireGuard配置
echo "6. 测试WireGuard配置..."
if bash -c "source modules/wireguard_config.sh && echo 'WireGuard config OK'" 2>/dev/null; then
    echo "✓ WireGuard配置测试通过"
else
    echo "✗ WireGuard配置测试失败"
fi

# 测试客户端管理
echo "7. 测试客户端管理..."
if bash -c "source modules/client_management.sh && echo 'Client management OK'" 2>/dev/null; then
    echo "✓ 客户端管理测试通过"
else
    echo "✗ 客户端管理测试失败"
fi

# 测试网络管理
echo "8. 测试网络管理..."
if bash -c "source modules/network_management.sh && echo 'Network management OK'" 2>/dev/null; then
    echo "✓ 网络管理测试通过"
else
    echo "✗ 网络管理测试失败"
fi

# 测试防火墙管理
echo "9. 测试防火墙管理..."
if bash -c "source modules/firewall_management.sh && echo 'Firewall management OK'" 2>/dev/null; then
    echo "✓ 防火墙管理测试通过"
else
    echo "✗ 防火墙管理测试失败"
fi

# 测试监控模块
echo "10. 测试监控模块..."
if bash -c "source modules/system_monitoring.sh && echo 'System monitoring OK'" 2>/dev/null; then
    echo "✓ 监控模块测试通过"
else
    echo "✗ 监控模块测试失败"
fi

echo "=== 模块测试完成 ==="
