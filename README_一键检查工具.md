# 🔍 IPv6 WireGuard Manager 一键检查工具使用指南

## 📋 工具概述

我已经为您创建了完整的一键检查工具集，能够全面检查IPv6 WireGuard Manager系统的所有组件。

## 🚀 使用方法

### Windows系统（推荐）
```cmd
# 双击运行或命令行执行
one_click_check_simple.bat
```

### Linux/macOS系统
```bash
# 添加执行权限
chmod +x one_click_check.sh

# 运行检查
./one_click_check.sh
```

### Python版本（需要Python环境）
```bash
# 安装依赖
pip install psutil requests

# 运行检查
python scripts/one_click_check.py
```

## 📊 检查结果说明

### 退出码含义
- `0`: 所有检查通过，系统运行正常
- `1`: 发现严重问题，需要修复
- `2`: 发现警告，建议检查

### 检查项目
1. **Python进程状态** - 检查Python服务是否运行
2. **MySQL进程状态** - 检查数据库服务是否运行
3. **Nginx进程状态** - 检查Web服务器是否运行
4. **端口监听状态** - 检查80、8000、3306端口
5. **配置文件检查** - 检查.env、env.local等配置文件
6. **日志目录检查** - 检查日志文件和目录
7. **环境变量检查** - 检查DATABASE_URL等关键变量
8. **系统资源检查** - 检查内存、磁盘使用情况
9. **网络连接测试** - 测试Web和API服务可访问性

## 🔧 常见问题修复

### 服务未运行
```bash
# Linux系统
sudo systemctl start ipv6-wireguard-manager
sudo systemctl start mysql
sudo systemctl start nginx

# Windows系统
net start mysql
net start nginx
```

### 环境变量未设置
```bash
# 设置环境变量
export DATABASE_URL="mysql://ipv6wgm:ipv6wgm_password@127.0.0.1:3306/ipv6wgm"
export SERVER_HOST="127.0.0.1"
export SERVER_PORT="8000"
```

### 配置文件缺失
```bash
# 复制环境配置文件
cp env.local .env
```

### 端口被占用
```bash
# 查看端口占用
netstat -tulpn | grep :8000
sudo lsof -i :8000

# 杀死占用进程
sudo kill -9 <PID>
```

## 📈 检查报告

每次运行检查工具都会生成详细的报告文件：
- 文件名格式：`ipv6-wireguard-manager-check-YYYYMMDD-HHMMSS.txt`
- 包含所有检查项目的详细结果
- 可用于问题分析和系统监控

## 💡 使用建议

1. **首次安装后**：运行一键检查确认系统状态
2. **遇到问题时**：运行检查工具快速定位问题
3. **定期维护**：建议每周运行一次检查
4. **问题排查**：根据检查结果和修复建议进行问题修复

## 🎯 快速开始

1. 双击运行 `one_click_check_simple.bat`
2. 查看检查结果和修复建议
3. 根据建议修复发现的问题
4. 重新运行检查确认问题已解决

现在您可以一键检查所有问题，快速诊断和修复系统问题！
