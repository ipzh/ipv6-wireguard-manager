# IPv6 WireGuard Manager API 文档

## 概述

本文档描述了IPv6 WireGuard Manager项目中所有主要函数和模块的API接口。

## 核心模块

### 1. 公共函数库 (modules/common_functions.sh)

#### 日志函数
```bash
log_info "消息内容"           # 信息日志
log_success "消息内容"        # 成功日志
log_warn "消息内容"          # 警告日志
log_error "消息内容"         # 错误日志
log_debug "消息内容"         # 调试日志
```

#### 验证函数
```bash
validate_ipv4 "192.168.1.1"                    # IPv4地址验证
validate_ipv6 "2001:db8::1"                    # IPv6地址验证
validate_cidr "10.0.0.0/24"                    # CIDR格式验证
validate_port "8080"                           # 端口号验证
validate_email "user@example.com"             # 邮箱格式验证
```

#### 文件操作函数
```bash
fix_line_endings "文件路径"                    # 修复行尾符
secure_permissions "路径" "权限" "用户" "组"     # 设置安全权限
backup_file "源文件" "备份目录"                # 备份文件
```

#### 系统函数
```bash
execute_command "命令" "描述" "允许失败" "超时"   # 执行命令
install_dependency "包名" "描述" "允许失败"      # 安装依赖
install_python_dependency "包名" "描述" "允许失败" # 安装Python依赖
detect_os                                    # 检测操作系统
```

### 2. 统一配置管理 (modules/unified_config.sh)

#### 配置管理函数
```bash
init_config_system                           # 初始化配置系统
load_config "配置文件路径"                    # 加载配置文件
create_default_config "配置文件路径"          # 创建默认配置
validate_config_version "配置文件路径"        # 验证配置版本
validate_all_config                          # 验证所有配置项
```

#### 配置操作函数
```bash
get_config_value "配置键" "默认值"            # 获取配置值
set_config_value "配置键" "值" "配置文件"      # 设置配置值
show_config_info                             # 显示配置信息
```

### 3. 懒加载模块 (modules/lazy_loading.sh)

#### 懒加载函数
```bash
init_lazy_loading                            # 初始化懒加载系统
lazy_load "模块名" "强制重载"                 # 懒加载模块
show_module_status                           # 显示模块状态
reload_module "模块名"                       # 重新加载模块
batch_load_modules "模块1" "模块2" ...        # 批量加载模块
```

#### 模块管理函数
```bash
is_module_available "模块名"                 # 检查模块是否可用
get_module_info "模块名"                     # 获取模块信息
```

### 4. 通用工具函数 (modules/common_utils.sh)

#### 界面函数
```bash
show_banner "标题" "版本" "描述"              # 显示横幅
show_help "脚本名" "版本" "描述"             # 显示帮助信息
show_version "脚本名" "版本" "构建日期" "Git提交" # 显示版本信息
```

#### 系统检查函数
```bash
check_root                                  # 检查root权限
check_system_requirements                   # 检查系统要求
check_network_connectivity                  # 检查网络连接
get_system_info                             # 获取系统信息
show_system_status                          # 显示系统状态
```

#### 交互函数
```bash
confirm "消息" "默认值"                      # 确认操作
show_progress "当前" "总数" "描述" "宽度"     # 显示进度条
wait_for_user "消息"                        # 等待用户输入
```

### 5. 版本控制 (modules/version_control.sh)

#### 版本管理函数
```bash
check_version_compatibility                 # 检查版本兼容性
get_version_info                            # 获取版本信息
check_for_updates                          # 检查更新
download_and_install_update "下载URL" "版本" # 下载并安装更新
rollback_version "目标版本"                 # 回滚版本
show_version_history                       # 显示版本历史
```

### 6. 系统监控 (modules/system_monitoring.sh)

#### 监控函数
```bash
init_monitoring                             # 初始化监控系统
collect_system_metrics                      # 收集系统指标
check_alerts                                # 检查告警条件
generate_monitoring_report                  # 生成监控报告
start_monitoring                            # 启动监控服务
stop_monitoring                             # 停止监控服务
show_monitoring_status                      # 显示监控状态
```

#### 指标收集函数
```bash
get_cpu_usage                               # 获取CPU使用率
get_memory_usage                            # 获取内存使用率
get_disk_usage                              # 获取磁盘使用率
get_load_average                            # 获取负载平均值
get_wireguard_peers                         # 获取WireGuard对等体数量
get_wireguard_traffic                       # 获取WireGuard流量统计
get_bgp_neighbors                           # 获取BGP邻居数量
get_bgp_routes                              # 获取BGP路由数量
get_services_status                         # 获取服务状态
```

### 7. 自我诊断 (modules/self_diagnosis.sh)

#### 诊断函数
```bash
init_diagnosis                              # 初始化诊断系统
run_full_diagnosis                          # 运行完整诊断
run_quick_diagnosis                         # 运行快速诊断
generate_diagnosis_report                   # 生成诊断报告
```

#### 检查函数
```bash
check_system_environment                    # 检查系统环境
check_network_configuration                 # 检查网络配置
check_service_status                        # 检查服务状态
check_wireguard_configuration               # 检查WireGuard配置
check_bgp_configuration                     # 检查BGP配置
check_log_files                             # 检查日志文件
```

## 主脚本函数

### IPv6 WireGuard Manager (ipv6-wireguard-manager.sh)

#### 核心函数
```bash
init_config                                 # 初始化配置
detect_system                               # 系统检测
show_main_menu                              # 显示主菜单
quick_install                               # 快速安装
interactive_install                         # 交互式安装
show_help                                   # 显示帮助
show_version                                # 显示版本
```

#### 功能管理函数
```bash
show_feature_management                     # 显示功能管理
install_feature "功能名"                    # 安装功能
uninstall_feature "功能名"                  # 卸载功能
reinstall_feature "功能名"                  # 重新安装功能
show_feature_status                         # 显示功能状态
```

#### 服务管理函数
```bash
start_services                              # 启动服务
configure_wireguard                         # 配置WireGuard
configure_bird                              # 配置BIRD
configure_firewall                          # 配置防火墙
install_dependencies                        # 安装依赖
```

### 安装脚本 (install.sh)

#### 安装函数
```bash
show_install_menu                           # 显示安装菜单
quick_install                               # 快速安装
interactive_install                         # 交互式安装
download_only                               # 仅下载文件
show_help                                   # 显示帮助
```

#### 安装步骤函数
```bash
check_system_requirements                   # 检查系统要求
download_project_files                      # 下载项目文件
install_dependencies                        # 安装依赖
install_wireguard                           # 安装WireGuard
install_bird                                # 安装BIRD
install_firewall                            # 安装防火墙
install_web_interface                       # 安装Web界面
install_monitoring                          # 安装监控
configure_services                          # 配置服务
create_global_alias                         # 创建全局别名
show_installation_complete                  # 显示安装完成
```

### 卸载脚本 (uninstall.sh)

#### 卸载函数
```bash
show_uninstall_menu                         # 显示卸载菜单
quick_uninstall                             # 快速卸载
complete_uninstall                          # 完全卸载
custom_uninstall                            # 自定义卸载
show_help                                   # 显示帮助
```

#### 清理函数
```bash
stop_services                               # 停止服务
disable_services                            # 禁用服务
remove_service_files                        # 移除服务文件
remove_executable_files                     # 移除可执行文件
remove_install_directory                    # 移除安装目录
remove_config_directory                     # 移除配置目录
remove_log_directory                        # 移除日志目录
remove_backup_directory                     # 移除备份目录
remove_wireguard_config                     # 移除WireGuard配置
remove_bird_config                          # 移除BIRD配置
cleanup_firewall_rules                      # 清理防火墙规则
cleanup_system_configuration                # 清理系统配置
```

### 下载安装脚本 (install_with_download.sh)

#### 下载函数
```bash
check_network_connectivity                  # 检查网络连接
check_system_requirements                   # 检查系统要求
download_project_files                      # 下载项目文件
run_install_script                          # 运行安装脚本
cleanup                                     # 清理临时文件
```

## 测试函数

### 自动化测试 (scripts/automated-testing.sh)

#### 测试套件
```bash
run_syntax_check                            # 语法检查测试
run_functionality_test                      # 功能测试
run_integration_test                        # 集成测试
run_performance_test                        # 性能测试
run_security_test                           # 安全测试
run_compatibility_test                      # 兼容性测试
run_version_check                           # 版本检查测试
run_module_test                             # 模块测试
run_config_test                             # 配置测试
run_monitoring_test                         # 监控测试
run_business_function_test                  # 业务功能测试
run_client_management_test                  # 客户端管理测试
run_exception_handling_test                 # 异常情况测试
run_config_change_test                      # 配置更改测试
```

#### 测试工具函数
```bash
init_test_environment                       # 初始化测试环境
generate_test_report                        # 生成测试报告
show_test_results                           # 显示测试结果
```

## 配置示例

### WireGuard服务器配置
```bash
# 位置: /etc/wireguard/wg0.conf
[Interface]
PrivateKey = YOUR_SERVER_PRIVATE_KEY
Address = 10.0.0.1/24, 2001:db8::1/64
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT

[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32, 2001:db8::2/128
```

### BIRD BGP配置
```bash
# 位置: /etc/bird/bird.conf
router id 192.168.1.1;

protocol device {
    scan time 10;
}

protocol kernel {
    learn;
    scan time 20;
    import all;
    export all;
}

protocol bgp BGP_NEIGHBOR {
    local as 65001;
    neighbor 192.168.1.2 as 65002;
    import all;
    export all;
    next hop self;
}
```

### Nginx Web配置
```bash
# 位置: /etc/nginx/sites-available/ipv6-wireguard-manager
server {
    listen 8080;
    listen [::]:8080;
    server_name _;
    root /opt/ipv6-wireguard-manager/web;
    index index.html;
}
```

## 使用示例

### 基本使用
```bash
# 启动管理程序
sudo ipv6-wireguard-manager

# 查看帮助
ipv6-wireguard-manager --help

# 查看版本
ipv6-wireguard-manager --version
```

### 安装使用
```bash
# 快速安装
sudo ./install.sh --quick

# 交互式安装
sudo ./install.sh --interactive

# 仅下载文件
sudo ./install.sh --download-only
```

### 测试使用
```bash
# 运行完整测试
sudo ./scripts/automated-testing.sh

# 运行特定测试
sudo ./scripts/automated-testing.sh --syntax-check
sudo ./scripts/automated-testing.sh --functionality-test
```

### 监控使用
```bash
# 启动监控
sudo ipv6-wireguard-manager --monitor

# 运行诊断
sudo ipv6-wireguard-manager --diagnose
```

## 错误处理

### 常见错误码
- `0`: 成功
- `1`: 一般错误
- `2`: 权限错误
- `3`: 配置错误
- `4`: 网络错误
- `5`: 服务错误

### 错误处理模式
```bash
# 严格模式（默认）
set -euo pipefail

# 宽松模式
set +e

# 自定义错误处理
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
```

## 性能优化

### 懒加载配置
```bash
LAZY_LOAD_ENABLED=true
LAZY_LOAD_CACHE_DIR="/var/cache/ipv6-wireguard-manager"
```

### 缓存配置
```bash
CACHE_ENABLED=true
CACHE_TTL=300
```

### 监控配置
```bash
MONITOR_INTERVAL=60
LOG_RETENTION_DAYS=30
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
```

## 安全考虑

### 权限管理
```bash
# 设置安全权限
secure_permissions "/etc/wireguard" "600" "root" "root"
secure_permissions "/var/log/ipv6-wireguard-manager" "644" "root" "root"
```

### 配置安全
```bash
# 验证配置项
validate_config_item "WIREGUARD_PORT" "51820" "port"
validate_config_item "WEB_PASS" "password123" "password"
```

### 日志安全
```bash
# 设置日志权限
chmod 640 /var/log/ipv6-wireguard-manager/manager.log
chown root:adm /var/log/ipv6-wireguard-manager/manager.log
```

---

**注意**: 本文档会随着项目的发展持续更新。如有疑问，请参考源代码或提交Issue。
