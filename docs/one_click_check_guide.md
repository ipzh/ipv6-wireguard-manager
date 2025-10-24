# 🔍 IPv6 WireGuard Manager 一键检查工具

## 📋 功能概述

一键检查工具能够全面检查IPv6 WireGuard Manager系统的所有组件，包括：

- ✅ Python环境和依赖包
- ✅ 服务状态（Python、MySQL、Nginx）
- ✅ 数据库连接
- ✅ 端口监听和网络服务
- ✅ 配置文件和环境变量
- ✅ 日志文件和错误统计
- ✅ 系统资源使用情况
- ✅ 文件权限
- ✅ 生成综合诊断报告

## 🚀 快速使用

### Windows系统
```cmd
# 双击运行或命令行执行
one_click_check.bat
```

### Linux/macOS系统
```bash
# 添加执行权限
chmod +x one_click_check.sh

# 运行检查
./one_click_check.sh
```

### Python直接运行
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

### 报告文件
检查完成后会生成JSON格式的综合诊断报告：
- 文件名格式：`ipv6-wireguard-manager-comprehensive-check-YYYYMMDD-HHMMSS.json`
- 包含所有检查项目的详细结果
- 可用于问题分析和系统监控

## 🔧 检查项目详解

### 1. Python环境检查
- Python版本和路径
- 关键依赖包安装状态
- 包导入测试

### 2. 服务状态检查
- Python进程运行状态
- MySQL进程运行状态
- Nginx进程运行状态
- 进程数量和PID信息

### 3. 数据库连接检查
- DATABASE_URL环境变量
- 数据库连接测试
- 连接参数验证

### 4. 端口监听检查
- 关键端口监听状态（80, 443, 8000, 3306, 9000）
- Web服务可访问性测试
- API服务可访问性测试

### 5. 配置文件检查
- .env环境配置文件
- env.local本地配置
- config.json配置文件
- 后端配置文件
- 数据库初始化脚本
- 安装脚本

### 6. 环境变量检查
- 数据库相关变量
- 服务器配置变量
- WireGuard配置变量
- 日志配置变量
- 超级用户配置

### 7. 日志文件检查
- 日志目录存在性
- 日志文件列表和大小
- 最新日志内容
- 错误和警告统计

### 8. 系统资源检查
- 内存使用情况
- 磁盘使用情况
- CPU使用情况
- 资源使用率警告

### 9. 文件权限检查
- 关键目录权限
- 文件写权限
- 目录存在性

## 🚨 常见问题修复

### Python包缺失
```bash
pip install -r requirements.txt
```

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

### 数据库连接失败
1. 检查MySQL服务状态
2. 验证DATABASE_URL配置
3. 检查防火墙设置
4. 确认数据库用户权限

### 端口被占用
```bash
# 查看端口占用
netstat -tulpn | grep :8000
sudo lsof -i :8000

# 杀死占用进程
sudo kill -9 <PID>
```

### 权限问题
```bash
# Linux系统
sudo chown -R www-data:www-data /opt/ipv6-wireguard-manager/
sudo chmod -R 755 /opt/ipv6-wireguard-manager/
```

## 📈 高级用法

### 自定义输出文件
```bash
python scripts/one_click_check.py --output my_report.json
```

### 静默模式
```bash
python scripts/one_click_check.py --quiet
```

### 定期检查
```bash
# 添加到crontab，每小时检查一次
0 * * * * /path/to/one_click_check.sh
```

## 🔍 故障排除

### 检查工具本身的问题
1. 确认Python版本 >= 3.7
2. 确认psutil和requests包已安装
3. 确认脚本有执行权限
4. 检查文件路径是否正确

### 网络问题
1. 检查防火墙设置
2. 确认端口未被占用
3. 验证服务配置
4. 检查DNS解析

### 权限问题
1. 确认用户有足够权限
2. 检查文件所有者
3. 验证目录权限
4. 确认服务用户权限

## 📞 技术支持

如果一键检查工具发现问题但无法自动修复，请：

1. 保存生成的诊断报告
2. 记录具体的错误信息
3. 提供系统环境信息
4. 联系技术支持团队

## 🔄 更新日志

- v1.0.0: 初始版本，支持基础检查功能
- v1.1.0: 添加系统资源检查
- v1.2.0: 添加权限检查和修复建议
- v1.3.0: 优化报告格式和错误处理
