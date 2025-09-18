# IPv6 WireGuard Manager - 模块化架构说明

## 概述

IPv6 WireGuard Manager 采用模块化架构设计，将不同的功能分离到独立的模块文件中，提高了代码的可维护性和可扩展性。

## 重要更新

**BIRD版本默认设置**: 从版本1.0.1开始，系统默认优先安装BIRD 2.x版本，如果BIRD 2.x不可用，则自动回退到BIRD 1.x版本。这确保了更好的性能和功能支持。

**IPv6子网段支持**: 从版本1.0.3开始，客户端地址分配支持从/56到/72的灵活子网段范围，根据网络前缀自动确定客户端子网掩码，提供更灵活的部署选项。

## 文件结构

```
IPv6 WireGuard/
├── ipv6-wireguard-manager.sh          # 完整版本脚本（包含所有功能）
├── ipv6-wireguard-manager-core.sh     # 模块化版本脚本（仅包含基础功能）
├── modules/                           # 模块目录
│   ├── server_management.sh           # 服务器管理模块
│   ├── network_management.sh          # 网络管理模块
│   ├── firewall_management.sh         # 防火墙管理模块
│   ├── system_maintenance.sh          # 系统维护模块
│   ├── backup_restore.sh              # 备份恢复模块
│   ├── update_management.sh           # 更新管理模块
│   ├── client_management.sh           # 客户端管理模块（已存在）
│   ├── bird_config.sh                 # BIRD配置模块（已存在）
│   ├── firewall_config.sh             # 防火墙配置模块（已存在）
│   ├── system_detection.sh            # 系统检测模块（已存在）
│   └── wireguard_config.sh            # WireGuard配置模块（已存在）
└── MODULAR_ARCHITECTURE.md            # 本文档
```

## 模块说明

### 1. 服务器管理模块 (`server_management.sh`)

**功能：**
- 服务状态查看
- 启动/停止/重启服务
- 配置重载
- 服务日志查看
- 系统资源监控
- 网络连接状态

**主要函数：**
- `server_management_menu()` - 主菜单
- `show_service_status()` - 显示服务状态
- `start_services_manually()` - 手动启动服务
- `stop_services_manually()` - 手动停止服务
- `restart_services_manually()` - 手动重启服务
- `reload_configurations()` - 重载配置
- `view_service_logs()` - 查看服务日志
- `show_system_resources()` - 显示系统资源
- `show_network_connections()` - 显示网络连接

### 2. 网络管理模块 (`network_management.sh`)

**功能：**
- IPv6前缀管理
- BGP邻居配置
- 路由表查看
- 网络接口管理
- 网络诊断工具
- BGP状态查看
- 网络统计信息

**主要函数：**
- `network_config_menu()` - 主菜单
- `ipv6_prefix_management()` - IPv6前缀管理
- `bgp_neighbor_management()` - BGP邻居管理
- `view_routing_table()` - 查看路由表
- `network_interface_management()` - 网络接口管理
- `network_diagnostics()` - 网络诊断
- `view_bgp_status()` - 查看BGP状态
- `show_network_statistics()` - 网络统计

### 3. 防火墙管理模块 (`firewall_management.sh`)

**功能：**
- 防火墙状态查看
- 启用/禁用防火墙
- 防火墙规则管理
- 端口管理
- 服务管理
- 防火墙日志查看

**主要函数：**
- `firewall_management_menu()` - 主菜单
- `show_firewall_status()` - 显示防火墙状态
- `toggle_firewall()` - 启用/禁用防火墙
- `view_firewall_rules()` - 查看防火墙规则
- `add_firewall_rule()` - 添加防火墙规则
- `remove_firewall_rule()` - 删除防火墙规则
- `port_management()` - 端口管理
- `service_management()` - 服务管理
- `view_firewall_logs()` - 查看防火墙日志

### 4. 系统维护模块 (`system_maintenance.sh`)

**功能：**
- 系统状态检查
- 性能监控
- 日志管理
- 磁盘空间管理
- 系统更新
- 进程管理
- 系统清理
- 安全扫描

**主要函数：**
- `system_maintenance_menu()` - 主菜单
- `system_status_check()` - 系统状态检查
- `performance_monitoring()` - 性能监控
- `log_management()` - 日志管理
- `disk_space_management()` - 磁盘空间管理
- `system_update()` - 系统更新
- `process_management()` - 进程管理
- `system_cleanup()` - 系统清理
- `security_scan()` - 安全扫描

### 5. 备份恢复模块 (`backup_restore.sh`)

**功能：**
- 创建配置备份
- 恢复配置备份
- 列出备份文件
- 删除备份文件
- 自动备份设置
- 导出/导入配置

**主要函数：**
- `backup_restore_menu()` - 主菜单
- `create_config_backup()` - 创建配置备份
- `restore_config_backup()` - 恢复配置备份
- `list_backups()` - 列出备份文件
- `delete_backup()` - 删除备份文件
- `auto_backup_settings()` - 自动备份设置
- `export_config()` - 导出配置
- `import_config()` - 导入配置

### 6. 更新管理模块 (`update_management.sh`)

**功能：**
- 检查更新
- 版本信息显示
- 更新管理器
- 系统包更新
- 更新日志
- 自动更新设置

**主要函数：**
- `update_check_menu()` - 主菜单
- `check_for_updates()` - 检查更新
- `show_version_info()` - 显示版本信息
- `update_manager()` - 更新管理器
- `update_system_packages()` - 系统包更新
- `show_update_log()` - 显示更新日志
- `auto_update_settings()` - 自动更新设置

### 7. 客户端管理模块 (`client_management.sh`)

**功能：**
- 添加/删除客户端
- 批量客户端管理
- 客户端配置生成
- 客户端状态跟踪
- QR码生成（移动设备）
- 地址池管理
- IPv6子网段支持（/56到/72）

**主要函数：**
- `client_management_menu()` - 主菜单
- `add_client()` - 添加客户端
- `remove_client()` - 删除客户端
- `list_clients()` - 列出客户端
- `generate_client_config()` - 生成客户端配置
- `auto_allocate_addresses()` - 自动分配地址
- `get_current_ipv6_network()` - 获取当前IPv6网络配置
- `show_address_pool_status()` - 显示地址池状态
- `show_available_addresses()` - 显示可用地址

**IPv6子网段支持：**
- 支持从/56到/72的灵活子网段范围
- 根据网络前缀自动确定客户端子网掩码
- 动态网络配置检测
- 智能地址分配和冲突检测

## 使用方法

### 运行方式选择

IPv6 WireGuard Manager 提供两种运行方式：

#### 方式1: 模块化版本（推荐）
```bash
# 使用新的模块化核心脚本
./ipv6-wireguard-manager-core.sh
```
- **特点**: 轻量级核心脚本，按需加载功能模块
- **优势**: 启动更快，内存占用更少，便于维护
- **适用**: 日常使用和开发环境

#### 方式2: 完整版本
```bash
# 使用包含所有功能的原始脚本
./ipv6-wireguard-manager.sh
```
- **特点**: 包含所有功能的完整脚本
- **优势**: 无需模块文件，单文件部署
- **适用**: 离线环境或简化部署

### 使用符号链接
```bash
# 使用完整命令
ipv6-wg-manager

# 或使用简写命令
wg-manager
```

**建议**: 推荐使用模块化版本，它提供了更好的性能和可维护性。

### 模块加载机制

核心脚本使用 `load_module()` 函数动态加载模块：

```bash
# 加载模块并调用函数
load_module "server_management" && server_management_menu
```

## 优势

1. **模块化设计**：每个功能模块独立，便于维护和扩展
2. **代码复用**：模块可以在不同脚本中重复使用
3. **易于调试**：问题定位更精确，只需检查相关模块
4. **灵活部署**：可以选择性部署需要的模块
5. **版本控制**：模块可以独立版本控制
6. **团队协作**：不同开发者可以负责不同模块

## 扩展指南

### 添加新模块

1. 在 `modules/` 目录下创建新的 `.sh` 文件
2. 实现模块的主要函数
3. 在核心脚本中添加模块加载调用
4. 更新主菜单以包含新功能

### 修改现有模块

1. 直接编辑对应的模块文件
2. 确保函数名称和接口保持一致
3. 测试模块功能是否正常

## 注意事项

1. 所有模块文件必须具有执行权限
2. 模块文件中的函数名不能与主脚本冲突
3. 模块文件应该包含必要的错误处理
4. 建议在修改模块前备份原始文件

## 兼容性

- 模块化架构与原始脚本完全兼容
- 所有现有功能都已迁移到相应模块
- 用户可以选择使用任一版本
- 配置文件格式保持不变

## BIRD版本支持

### 支持的BIRD版本
- **BIRD 2.x** (推荐) - 默认安装版本，提供更好的性能和功能
- **BIRD 1.x** (兼容) - 自动回退版本，确保在BIRD 2.x不可用时仍能正常工作

### 安装优先级
1. 优先尝试安装BIRD 2.x (`bird2`包)
2. 如果BIRD 2.x不可用，自动安装BIRD 1.x (`bird`包)
3. 支持所有主要Linux发行版

### 服务管理
- 自动检测已安装的BIRD版本
- 支持BIRD 1.x和2.x的服务管理
- 兼容不同的控制台命令 (`birdc` vs `birdc2`)

## 性能对比

| 特性 | 模块化版本 | 完整版本 |
|------|------------|----------|
| 启动速度 | 快 | 慢 |
| 内存占用 | 低 | 高 |
| 维护性 | 优秀 | 一般 |
| 部署复杂度 | 中等 | 简单 |
| 功能完整性 | 完整 | 完整 |
| 推荐程度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

## 最佳实践

1. **开发环境**: 使用模块化版本，便于调试和开发
2. **生产环境**: 使用模块化版本，获得更好的性能
3. **离线部署**: 使用完整版本，减少依赖
4. **快速测试**: 使用完整版本，单文件部署

---

**推荐**: 使用模块化版本 `./ipv6-wireguard-manager-core.sh` 获得最佳性能体验。