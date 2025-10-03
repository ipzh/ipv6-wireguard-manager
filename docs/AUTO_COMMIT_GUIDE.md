# 自动提交功能使用指南

## 📋 概述

IPv6 WireGuard Manager 提供了自动提交功能，可以监控文件变化并自动提交到Git仓库，提高开发效率。

## 🚀 快速开始

### Linux/macOS 使用方法

```bash
# 基本使用 - 30秒间隔监控
./scripts/auto-commit.sh

# 自定义间隔 - 60秒监控，启用自动推送
./scripts/auto-commit.sh -i 60 -p

# 只执行一次提交
./scripts/auto-commit.sh --once

# 查看Git状态
./scripts/auto-commit.sh --status
```

### Windows PowerShell 使用方法

```powershell
# 基本使用 - 30秒间隔监控
.\scripts\auto-commit.ps1

# 自定义间隔 - 60秒监控，启用自动推送
.\scripts\auto-commit.ps1 -Interval 60 -Push

# 只执行一次提交
.\scripts\auto-commit.ps1 -Once

# 查看Git状态
.\scripts\auto-commit.ps1 -Status
```

## ⚙️ 配置选项

### Bash脚本参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-i, --interval` | 监控间隔（秒） | 30 |
| `-p, --push` | 启用自动推送 | false |
| `-n, --no-push` | 禁用自动推送 | - |
| `--prefix` | 提交信息前缀 | "auto" |
| `--once` | 只执行一次提交 | - |
| `--status` | 显示Git状态 | - |
| `-h, --help` | 显示帮助信息 | - |

### PowerShell脚本参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-Interval` | 监控间隔（秒） | 30 |
| `-Push` | 启用自动推送 | false |
| `-NoPush` | 禁用自动推送 | - |
| `-Prefix` | 提交信息前缀 | "auto" |
| `-Once` | 只执行一次提交 | - |
| `-Status` | 显示Git状态 | - |
| `-Help` | 显示帮助信息 | - |

## 🔧 功能特性

### 1. 智能文件监控
- 自动检测工作目录中的文件变化
- 支持新增、修改、删除文件的监控
- 忽略.gitignore中指定的文件

### 2. 自动提交信息生成
- 根据变化类型自动生成提交信息
- 包含变化文件数量统计
- 添加时间戳标识

**提交信息格式**:
```
auto: 自动提交 - 新增2个文件 修改3个文件 (14:30:25)
```

### 3. 可选自动推送
- 支持自动推送到远程仓库
- 自动检测当前分支
- 推送失败时给出警告提示

### 4. 安全检查
- 检查Git仓库有效性
- 验证远程仓库配置
- 提供详细的状态信息

## 📝 使用示例

### 开发环境监控

```bash
# 开发时持续监控，每30秒检查一次
./scripts/auto-commit.sh

# 输出示例:
# [INFO] 2024-01-15 14:30:00 - 开始监控文件变化...
# [INFO] 2024-01-15 14:30:00 - 监控间隔: 30秒
# [INFO] 2024-01-15 14:30:00 - 自动推送: false
# [SUCCESS] 2024-01-15 14:30:30 - 自动提交成功: auto: 自动提交 - 修改1个文件 (14:30:30)
```

### 生产环境部署

```bash
# 生产环境，启用自动推送，较长间隔
./scripts/auto-commit.sh -i 300 -p --prefix "deploy"

# 输出示例:
# [SUCCESS] 2024-01-15 14:35:00 - 自动提交成功: deploy: 自动提交 - 新增1个文件 (14:35:00)
# [INFO] 2024-01-15 14:35:01 - 推送到远程仓库...
# [SUCCESS] 2024-01-15 14:35:03 - 推送成功
```

### 一次性提交

```bash
# 手动触发一次提交
./scripts/auto-commit.sh --once

# 输出示例:
# [INFO] 2024-01-15 14:40:00 - 检测到文件变化，准备自动提交...
# [INFO] 2024-01-15 14:40:00 - 变化的文件:
#   M  README.md
#   A  new-feature.sh
# [SUCCESS] 2024-01-15 14:40:01 - 自动提交成功: auto: 自动提交 - 新增1个文件 修改1个文件 (14:40:01)
```

## 🛡️ 安全考虑

### 1. 敏感文件保护
- 自动遵循.gitignore规则
- 不会提交密钥、证书等敏感文件
- 支持自定义忽略规则

### 2. 提交质量控制
- 只在有实际变化时才提交
- 生成有意义的提交信息
- 避免空提交

### 3. 远程推送控制
- 默认不自动推送到远程仓库
- 需要显式启用自动推送
- 推送失败时不会中断监控

## 🔍 故障排除

### 常见问题

1. **"当前目录不是Git仓库"**
   ```bash
   # 确保在Git仓库根目录运行
   cd /path/to/your/git/repo
   ./scripts/auto-commit.sh
   ```

2. **"未配置远程仓库origin"**
   ```bash
   # 添加远程仓库
   git remote add origin https://github.com/username/repo.git
   ```

3. **推送失败**
   ```bash
   # 检查网络连接和认证
   git push origin main
   ```

4. **权限错误**
   ```bash
   # 给脚本执行权限
   chmod +x scripts/auto-commit.sh
   ```

### 调试模式

```bash
# 查看详细状态信息
./scripts/auto-commit.sh --status

# 输出示例:
# [INFO] Git仓库状态:
#  M README.md
#  A new-file.txt
# [INFO] 最近的提交:
# abc1234 auto: 自动提交 - 修改1个文件 (14:25:30)
# def5678 feat: 添加新功能
# [INFO] 远程仓库: https://github.com/username/repo.git
# [INFO] 当前分支: main
```

## 🎯 最佳实践

### 1. 开发阶段
- 使用较短的监控间隔（30-60秒）
- 禁用自动推送，手动控制推送时机
- 使用描述性的提交前缀

### 2. 测试阶段
- 使用中等监控间隔（2-5分钟）
- 可以启用自动推送到测试分支
- 添加测试相关的提交前缀

### 3. 生产阶段
- 使用较长的监控间隔（5-15分钟）
- 谨慎使用自动推送
- 使用生产相关的提交前缀

### 4. 团队协作
- 统一提交信息格式
- 避免在共享分支上使用自动推送
- 定期手动整理提交历史

## 📚 相关文档

- [Git基础使用](https://git-scm.com/doc)
- [项目结构说明](PROJECT_STRUCTURE.md)
- [CI/CD指南](docs/CI_CD.md)
- [测试指南](docs/TESTING.md)

## 🤝 贡献

如果您发现问题或有改进建议，请：

1. 提交Issue描述问题
2. 提供详细的错误信息
3. 建议改进方案
4. 提交Pull Request

## 📄 许可证

本功能遵循项目的开源许可证。