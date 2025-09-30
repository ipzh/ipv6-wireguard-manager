# 项目结构说明

## 📁 目录结构

```
IPv6-WireGuard-Manager/
├── 📄 核心脚本
│   ├── ipv6-wireguard-manager.sh    # 主程序脚本
│   ├── install.sh                   # 安装脚本
│   ├── install_with_download.sh     # 带下载的安装脚本
│   ├── uninstall.sh                 # 卸载脚本
│   └── update.sh                    # 更新脚本
│
├── 📁 modules/                      # 功能模块目录 (50+ 个模块)
│   ├── common_functions.sh          # 公共函数库
│   ├── variable_management.sh       # 变量管理系统
│   ├── function_management.sh       # 函数管理系统
│   ├── unified_config.sh            # 统一配置管理
│   ├── wireguard_config.sh          # WireGuard配置
│   ├── bird_config.sh               # BGP配置
│   ├── network_management.sh        # 网络管理
│   ├── firewall_management.sh       # 防火墙管理
│   ├── client_management.sh         # 客户端管理
│   ├── system_monitoring.sh         # 系统监控
│   ├── performance_optimizer.sh     # 性能优化
│   ├── enhanced_windows_compatibility.sh  # Windows兼容性
│   └── ... (更多模块)
│
├── 📁 config/                       # 配置文件目录
│   ├── manager.conf                 # 主配置文件
│   ├── bird_template.conf           # BIRD配置模板
│   ├── client_template.conf         # 客户端配置模板
│   └── firewall_rules.conf          # 防火墙规则
│
├── 📁 examples/                     # 示例文件目录
│   ├── wireguard-server.conf        # 服务器配置示例
│   ├── wireguard-client.conf        # 客户端配置示例
│   ├── bird.conf                    # BGP配置示例
│   └── clients.csv                  # 客户端列表示例
│
├── 📁 docs/                         # 文档目录
│   ├── INSTALLATION.md              # 安装指南
│   ├── USAGE.md                     # 使用手册
│   ├── API.md                       # API文档
│   └── TESTING_GUIDE.md             # 测试指南
│
├── 📁 scripts/                      # 脚本目录
│   ├── automated-testing.sh         # 自动化测试
│   ├── deploy.sh                    # 部署脚本
│   └── windows-compatibility-test.ps1  # Windows测试
│
├── 📁 tests/                        # 测试目录
│   ├── comprehensive_test_suite.sh  # 全面测试套件
│   ├── test_cases.sh                # 测试用例
│   └── test_config.yml              # 测试配置
│
├── 📁 templates/                    # 模板目录
│   ├── standard_import_template.sh  # 标准导入模板
│   └── robust_import_template.sh    # 健壮导入模板
│
├── 📁 logs/                         # 日志目录
├── 📁 reports/                      # 报告目录
├── 📄 README.md                     # 项目说明
├── 📄 FEATURES_OVERVIEW.md          # 功能特性总览
├── 📄 QUICK_START_GUIDE.md          # 快速开始指南
├── 📄 PROJECT_STRUCTURE.md          # 项目结构说明
├── 📄 ci.yml                        # GitHub Actions配置
├── 📄 docker-compose.yml            # Docker配置
└── 📄 Dockerfile                    # Docker镜像配置
```

## 🏗️ 核心模块分类

### 1. 基础架构模块
- `common_functions.sh` - 公共函数库
- `variable_management.sh` - 变量管理系统
- `function_management.sh` - 函数管理系统
- `unified_config.sh` - 统一配置管理

### 2. 网络管理模块
- `wireguard_config.sh` - WireGuard配置
- `bird_config.sh` - BGP配置
- `network_management.sh` - 网络管理
- `firewall_management.sh` - 防火墙管理

### 3. 客户端管理模块
- `client_management.sh` - 客户端管理
- `client_auto_install.sh` - 客户端自动安装

### 4. 监控和诊断模块
- `system_monitoring.sh` - 系统监控
- `resource_monitoring.sh` - 资源监控
- `self_diagnosis.sh` - 系统自诊断

### 5. 性能优化模块
- `performance_optimizer.sh` - 性能优化
- `lazy_loading.sh` - 模块懒加载
- `config_cache.sh` - 配置缓存

### 6. 错误处理模块
- `error_handling.sh` - 错误处理
- `enhanced_error_handling.sh` - 增强错误处理

### 7. 系统兼容性模块
- `system_detection.sh` - 系统检测
- `enhanced_system_compatibility.sh` - 增强系统兼容性
- `enhanced_windows_compatibility.sh` - Windows兼容性

### 8. 安全和认证模块
- `security_functions.sh` - 安全功能
- `security_audit_monitoring.sh` - 安全审计监控
- `oauth_authentication.sh` - OAuth认证

### 9. Web界面模块
- `web_management.sh` - Web管理
- `web_interface_enhanced.sh` - 增强Web界面
- `websocket_realtime.sh` - WebSocket实时通信

### 10. 测试和验证模块
- `functional_tests.sh` - 功能测试
- `test_coverage.sh` - 测试覆盖
- `unified_test_framework.sh` - 统一测试框架

## 🔧 配置文件说明

### 主配置文件 (`config/manager.conf`)
- 系统全局配置
- 功能开关设置
- 路径配置
- 日志配置

### 模板文件 (`config/*_template.conf`)
- BIRD配置模板
- 客户端配置模板
- 防火墙规则模板

### 示例文件 (`examples/`)
- 各种配置示例
- 使用案例
- 最佳实践

## 📊 测试结构

### 测试脚本
- `comprehensive_test_suite.sh` - 全面测试套件
- `test_optimizations.sh` - 优化测试
- `test_root_permission.sh` - 权限测试

### 测试配置
- `test_config.yml` - 测试配置
- `test_cases.sh` - 测试用例

## 🚀 部署结构

### 安装脚本
- `install.sh` - 主安装脚本
- `install_with_download.sh` - 带下载的安装脚本

### Docker支持
- `Dockerfile` - Docker镜像配置
- `docker-compose.yml` - Docker Compose配置

### CI/CD
- `ci.yml` - GitHub Actions工作流

## 📚 文档结构

### 核心文档
- `README.md` - 项目说明
- `FEATURES_OVERVIEW.md` - 功能特性总览
- `QUICK_START_GUIDE.md` - 快速开始指南

### 详细文档 (`docs/`)
- `INSTALLATION.md` - 安装指南
- `USAGE.md` - 使用手册
- `API.md` - API文档
- `TESTING_GUIDE.md` - 测试指南

---

*项目结构说明 - 2025-09-30*
