#!/bin/bash

# 批量修复所有模块文件中的日志函数LOG_FILE路径问题

echo "=== 开始批量修复所有模块文件中的日志函数问题 ==="

# 需要修复的模块文件列表
modules=(
    "modules/api_documentation.sh"
    "modules/backup_restore.sh"
    "modules/bird_config.sh"
    "modules/client_auto_install.sh"
    "modules/client_management.sh"
    "modules/config_management.sh"
    "modules/error_handling.sh"
    "modules/firewall_management.sh"
    "modules/firewall_ports.sh"
    "modules/lazy_loading.sh"
    "modules/monitoring_alerting.sh"
    "modules/multi_tenant.sh"
    "modules/network_management.sh"
    "modules/network_topology.sh"
    "modules/oauth_authentication.sh"
    "modules/performance_enhancements.sh"
    "modules/performance_optimization.sh"
    "modules/repository_config.sh"
    "modules/resource_quota.sh"
    "modules/security_audit_monitoring.sh"
    "modules/system_detection.sh"
    "modules/update_management.sh"
    "modules/user_interface.sh"
    "modules/web_interface_enhanced.sh"
    "modules/web_management.sh"
    "modules/websocket_realtime.sh"
    "modules/wireguard_config.sh"
)

# 修复函数
fix_module_log_functions() {
    local module_file="$1"
    echo "修复 $module_file 中的日志函数..."
    
    # 检查是否使用了日志函数
    if grep -q "log_info\|log_error\|log_warn\|log_success" "$module_file"; then
        echo "  - 发现日志函数使用，添加LOG_FILE变量定义"
        
        # 在文件开头添加LOG_FILE变量定义（如果还没有的话）
        if ! grep -q "LOG_FILE=" "$module_file"; then
            # 找到合适的位置插入LOG_FILE定义
            if grep -q "source.*common_functions.sh" "$module_file"; then
                # 在common_functions.sh导入后添加
                sed -i '/source.*common_functions.sh/a\
\
# 确保日志相关变量已定义\
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"\
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"' "$module_file"
            else
                # 在文件开头添加
                sed -i '1a\
# 确保日志相关变量已定义\
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"\
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"' "$module_file"
            fi
        fi
        
        echo "  ✓ $module_file 日志函数修复完成"
    else
        echo "  - $module_file 未使用日志函数，跳过"
    fi
}

# 批量修复所有模块
for module in "${modules[@]}"; do
    if [[ -f "$module" ]]; then
        fix_module_log_functions "$module"
    else
        echo "⚠ 文件不存在: $module"
    fi
done

echo "=== 所有模块文件日志函数修复完成 ==="
