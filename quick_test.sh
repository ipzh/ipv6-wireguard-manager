#!/bin/bash

echo "=== 快速测试脚本 ==="

# 测试基础模块
echo "1. 测试基础模块..."
bash -c "source modules/common_functions.sh && echo 'Common functions OK'" 2>/dev/null && echo "✓ 公共函数库" || echo "✗ 公共函数库"
bash -c "source modules/system_detection.sh && echo 'System detection OK'" 2>/dev/null && echo "✓ 系统检测" || echo "✗ 系统检测"
bash -c "source modules/config_manager.sh && echo 'Config manager OK'" 2>/dev/null && echo "✓ 配置管理" || echo "✗ 配置管理"

# 测试错误处理
echo "2. 测试错误处理..."
bash -c "source modules/advanced_error_handling.sh && handle_error 1 'test error' 'test'; echo 'Error handling OK'" 2>/dev/null && echo "✓ 错误处理" || echo "✗ 错误处理"

# 测试监控模块
echo "3. 测试监控模块..."
bash -c "source modules/system_monitoring.sh && collect_system_metrics && echo 'Monitoring OK'" 2>/dev/null && echo "✓ 监控模块" || echo "✗ 监控模块"

# 测试WireGuard配置
echo "4. 测试WireGuard配置..."
bash -c "source modules/wireguard_config.sh && test_wireguard_config && echo 'WireGuard OK'" 2>/dev/null && echo "✓ WireGuard配置" || echo "✗ WireGuard配置"

# 测试客户端管理
echo "5. 测试客户端管理..."
bash -c "source modules/client_management.sh && list_clients && echo 'Client management OK'" 2>/dev/null && echo "✓ 客户端管理" || echo "✗ 客户端管理"

# 测试主脚本
echo "6. 测试主脚本..."
bash ipv6-wireguard-manager.sh --help > /dev/null 2>&1 && echo "✓ 主脚本" || echo "✗ 主脚本"

echo "=== 测试完成 ==="
