# IPv6 WireGuard Manager 调试模式安装脚本

本文档介绍如何使用调试模式安装脚本来记录和解决安装过程中的所有问题。

## 脚本说明

### 1. Windows版本调试脚本
- **文件**: `install-debug.bat`
- **用途**: 在Windows系统上运行，详细记录安装过程中的所有问题
- **功能**:
  - 检查系统环境（Python、Node.js、Git）
  - 检查代码状态
  - 安装后端依赖
  - 安装前端依赖
  - 配置数据库
  - 构建前端
  - 测试后端启动
  - 生成详细的问题报告

### 2. Linux版本调试脚本
- **文件**: `install-debug.sh`
- **用途**: 在Linux系统上运行，详细记录安装过程中的所有问题
- **功能**: 与Windows版本相同，但针对Linux环境优化

### 3. VPS专用调试脚本
- **文件**: `vps-debug-install.sh`
- **用途**: 专门针对远程VPS部署过程中的问题进行调试
- **特殊功能**:
  - 检查schemas导入问题（IPv6PrefixPool、IPv6Allocation等）
  - 检查系统服务配置
  - 检查数据库连接
  - 检查代码同步状态
  - 生成针对VPS环境的修复建议

## 使用方法

### Windows系统
```cmd
# 在项目根目录运行
install-debug.bat
```

### Linux系统（本地开发环境）
```bash
# 给脚本执行权限
chmod +x install-debug.sh

# 运行脚本
./install-debug.sh
```

### 远程VPS部署调试
```bash
# 给脚本执行权限
chmod +x vps-debug-install.sh

# 运行VPS专用调试脚本
./vps-debug-install.sh
```

## 输出文件

脚本运行后会生成以下文件：

1. **日志文件**: `/tmp/ipv6-wireguard-install-debug.log`（Linux）或 `%TEMP%\ipv6-wireguard-install-debug.log`（Windows）
2. **问题报告**: `installation-report-YYYYMMDD-HHMMSS.txt`
3. **VPS调试报告**: `vps-debug-report-YYYYMMDD-HHMMSS.txt`

## 调试流程

### 1. 环境检查
- 检查Python、Node.js、Git版本
- 检查操作系统环境
- 验证依赖工具是否可用

### 2. 代码检查
- 检查Git仓库状态
- 验证关键文件是否存在
- 检查代码同步状态

### 3. 依赖安装
- 安装Python虚拟环境
- 安装后端依赖包
- 安装前端npm包
- 验证关键包导入

### 4. 配置检查
- 检查数据库连接
- 验证schemas导入
- 检查系统服务配置

### 5. 启动测试
- 测试后端应用导入
- 检查API路由
- 验证快速启动

### 6. 报告生成
- 汇总所有错误和警告
- 提供修复建议
- 生成详细报告

## 常见问题修复

### schemas导入错误
如果遇到类似 `ImportError: cannot import name 'IPv6PrefixPool'` 的错误：

1. 确保代码是最新版本：
```bash
git pull origin main
```

2. 检查 `backend/app/schemas/ipv6.py` 文件是否包含正确的类定义

### 数据库连接错误
1. 检查数据库服务是否运行
2. 验证 `backend/app/core/config.py` 中的数据库配置
3. 检查数据库用户权限

### 系统服务配置错误
1. 检查 `/etc/systemd/system/ipv6-wireguard-manager.service` 文件
2. 验证工作目录和执行命令配置
3. 重新加载systemd配置：
```bash
sudo systemctl daemon-reload
```

## 远程VPS部署建议

### 1. 首次部署
```bash
# 1. 克隆代码
sudo mkdir -p /opt/ipv6-wireguard-manager
sudo chown $USER:$USER /opt/ipv6-wireguard-manager
cd /opt/ipv6-wireguard-manager
git clone https://github.com/your-repo/ipv6-wireguard-manager.git .

# 2. 运行调试脚本
chmod +x vps-debug-install.sh
./vps-debug-install.sh

# 3. 根据报告修复问题
# 4. 启动服务
sudo systemctl start ipv6-wireguard-manager
sudo systemctl enable ipv6-wireguard-manager
```

### 2. 问题排查
如果服务启动失败：

1. 查看服务状态：
```bash
sudo systemctl status ipv6-wireguard-manager
```

2. 查看服务日志：
```bash
sudo journalctl -u ipv6-wireguard-manager -f
```

3. 手动测试启动：
```bash
cd /opt/ipv6-wireguard-manager/backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## 脚本特点

### 详细日志记录
- 记录所有命令执行和输出
- 分类显示信息、警告、错误
- 保留完整的调试信息

### 智能错误检测
- 自动检测常见安装问题
- 提供具体的修复建议
- 分类统计错误和警告数量

### 跨平台支持
- Windows和Linux双版本
- 自动适应不同环境
- 统一的输出格式

### 问题报告生成
- 自动生成详细的问题报告
- 包含修复步骤和建议
- 便于一次性解决所有问题

## 注意事项

1. **权限要求**: 部分操作需要sudo权限
2. **网络连接**: 确保有稳定的网络连接下载依赖
3. **磁盘空间**: 确保有足够的磁盘空间安装依赖
4. **时间消耗**: 完整调试可能需要较长时间
5. **安全考虑**: 在生产环境运行前请先测试

## 故障排除

如果脚本运行失败：

1. 检查日志文件了解详细错误
2. 确保所有依赖工具已正确安装
3. 验证网络连接是否正常
4. 检查文件权限是否正确
5. 查看系统资源是否充足

## 贡献指南

如需改进调试脚本：

1. 添加新的检查项目
2. 改进错误检测逻辑
3. 优化报告生成格式
4. 增加更多平台支持

---

通过使用这些调试脚本，您可以系统地记录和解决IPv6 WireGuard Manager安装过程中的所有问题，实现一次性修复所有问题的目标。