# IPv6 WireGuard Manager - 诊断工具指南

## 🔍 诊断工具概览

本项目提供了多个层次的诊断工具，用于全面检查API服务的状态和问题：

### 1. 系统级诊断工具

#### `deep_api_diagnosis.sh` - 深度系统诊断
**功能**: 全面检查系统环境、服务状态、网络连接等
**检查项目**:
- ✅ 系统环境（OS、内核、内存、磁盘）
- ✅ 用户和权限
- ✅ Python环境
- ✅ 应用文件完整性
- ✅ 目录结构
- ✅ 数据库连接
- ✅ 网络端口
- ✅ 服务状态
- ✅ API连接性
- ✅ 前端连接性
- ✅ 日志和错误
- ✅ 系统资源

**使用方法**:
```bash
chmod +x deep_api_diagnosis.sh
./deep_api_diagnosis.sh
```

#### `comprehensive_api_diagnosis.sh` - 综合诊断（推荐）
**功能**: 结合系统检查和代码分析的全面诊断
**特点**:
- 🔄 自动运行所有诊断工具
- 🛠️ 自动尝试修复发现的问题
- 📊 提供详细的修复建议
- 🎯 一站式解决方案

**使用方法**:
```bash
chmod +x comprehensive_api_diagnosis.sh
./comprehensive_api_diagnosis.sh
```

### 2. 代码级诊断工具

#### `deep_code_analysis.py` - 代码分析
**功能**: 深度检查代码层面的问题
**检查项目**:
- ✅ Python语法检查
- ✅ 导入依赖检查
- ✅ 配置文件验证
- ✅ 主应用文件检查
- ✅ 数据库模型检查
- ✅ API路由检查
- ✅ 环境文件检查
- ✅ 依赖文件检查

**使用方法**:
```bash
python3 deep_code_analysis.py
```

### 3. 专项修复工具

#### `quick_fix_wireguard_permissions.sh` - WireGuard权限修复
**功能**: 专门修复WireGuard目录权限问题
**特点**:
- 🎯 针对WireGuard目录权限问题
- 🔧 自动创建必要目录
- 🔐 设置正确的权限
- 🚀 重启服务并验证

**使用方法**:
```bash
chmod +x quick_fix_wireguard_permissions.sh
./quick_fix_wireguard_permissions.sh
```

#### `fix_permissions.sh` - 通用权限修复
**功能**: 修复所有权限相关问题
**使用方法**:
```bash
chmod +x fix_permissions.sh
./fix_permissions.sh
```

## 🚀 快速诊断流程

### 1. 一键综合诊断（推荐）
```bash
# 运行综合诊断，自动检查和修复
./comprehensive_api_diagnosis.sh
```

### 2. 分步诊断
```bash
# 步骤1: 系统级检查
./deep_api_diagnosis.sh

# 步骤2: 代码级检查
python3 deep_code_analysis.py

# 步骤3: 权限修复
./quick_fix_wireguard_permissions.sh

# 步骤4: 验证修复结果
./deep_api_diagnosis.sh
```

### 3. 问题特定诊断
```bash
# 如果遇到权限问题
./quick_fix_wireguard_permissions.sh

# 如果遇到服务启动问题
./fix_permissions.sh

# 如果遇到API连接问题
./deep_api_diagnosis.sh
```

## 📊 诊断结果解读

### 成功指标
- ✅ **SUCCESS**: 检查通过，无问题
- ℹ️ **INFO**: 信息性消息，正常状态

### 警告指标
- ⚠️ **WARNING**: 潜在问题，建议关注
- 通常不影响基本功能，但可能影响性能或稳定性

### 错误指标
- ❌ **ERROR**: 严重问题，需要立即修复
- 通常会导致服务无法正常运行

## 🛠️ 常见问题修复

### 1. 权限问题
**症状**: `PermissionError: [Errno 13] Permission denied`
**修复**:
```bash
./quick_fix_wireguard_permissions.sh
```

### 2. 服务启动失败
**症状**: 服务状态为 `activating (auto-restart)`
**修复**:
```bash
./fix_permissions.sh
sudo systemctl restart ipv6-wireguard-manager
```

### 3. API连接失败
**症状**: `curl: (7) Failed to connect to localhost port 8000`
**修复**:
```bash
./comprehensive_api_diagnosis.sh
```

### 4. 数据库连接问题
**症状**: 数据库连接失败
**修复**:
```bash
sudo systemctl restart mysql
# 或
sudo systemctl restart mariadb
```

### 5. 前端页面空白
**症状**: 前端页面显示空白或Nginx默认页面
**修复**:
```bash
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
```

## 🔧 高级诊断

### 手动检查服务状态
```bash
# 查看服务状态
sudo systemctl status ipv6-wireguard-manager

# 查看服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# 查看端口监听
netstat -tlnp | grep -E ":(80|8000) "

# 测试API连接
curl -f http://localhost:8000/api/v1/health
```

### 手动检查文件权限
```bash
# 检查安装目录权限
ls -la /opt/ipv6-wireguard-manager/

# 检查关键目录权限
ls -la /opt/ipv6-wireguard-manager/uploads/
ls -la /opt/ipv6-wireguard-manager/wireguard/
```

### 手动检查配置文件
```bash
# 检查环境配置
cat /opt/ipv6-wireguard-manager/.env

# 检查服务配置
cat /etc/systemd/system/ipv6-wireguard-manager.service

# 检查Nginx配置
sudo nginx -t
```

## 📝 诊断报告

诊断工具会生成详细的报告，包括：

1. **系统环境信息**
2. **服务状态检查**
3. **权限验证结果**
4. **网络连接测试**
5. **错误和警告汇总**
6. **修复建议**

## 🆘 获取帮助

如果诊断工具无法解决问题，请：

1. **收集诊断信息**:
   ```bash
   ./comprehensive_api_diagnosis.sh > diagnosis_report.txt 2>&1
   ```

2. **查看详细日志**:
   ```bash
   sudo journalctl -u ipv6-wireguard-manager --no-pager -n 100
   ```

3. **检查系统资源**:
   ```bash
   free -h
   df -h
   top
   ```

4. **使用CLI工具**:
   ```bash
   ipv6-wireguard-manager status
   ipv6-wireguard-manager logs -f
   ipv6-wireguard-manager monitor
   ```

## 🔄 定期维护

建议定期运行诊断工具：

```bash
# 每日检查
./deep_api_diagnosis.sh

# 每周全面检查
./comprehensive_api_diagnosis.sh

# 每月代码分析
python3 deep_code_analysis.py
```

这样可以及早发现和解决问题，确保系统稳定运行。
