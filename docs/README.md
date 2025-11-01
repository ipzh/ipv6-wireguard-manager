## 📋 欢迎

欢迎来到 IPv6 WireGuard Manager 文档中心。本页提供现有文档的导航，并汇总安装、运维与排障时常用的辅助脚本，帮助您快速找到所需内容。

## 📚 文档索引

| 文档 | 说明 |
|------|------|
| [项目概览](../README.md) | 项目的整体介绍、快速开始指引与功能总览 |
| [快速开始](QUICK_START.md) | 面向新用户的极速体验指南与常用操作示例 |
| [安装指南](INSTALLATION_GUIDE.md) | 详细的安装流程、环境准备与配置说明 |
| [部署指南](DEPLOYMENT_GUIDE.md) | 生产环境部署方案、服务管理与性能优化建议 |
| [API 参考](API_REFERENCE.md) | FastAPI 后端公开的接口说明与示例 |
| [安全特性](SECURITY_FEATURES.md) | 完整的安全特性说明和配置指南 |
| [故障排除指南](TROUBLESHOOTING_GUIDE.md) | 常见问题诊断与解决方案 |

> 文档会随着功能迭代持续更新，建议在升级或重新部署之前回顾上述文档获取最新信息。

## 🧰 常用支持脚本

| 脚本 | 作用 |
|------|------|
| `scripts/basic_check.sh` | 最小化系统巡检，快速确认核心服务和端口状态 |
| `scripts/verify_installation.sh` | 安装完成后的验证脚本，检查服务、端口、日志与系统资源 |
| `scripts/one_click_check.py` | 综合诊断工具，生成 JSON 报告并给出修复建议 |
| `scripts/check_docs_consistency.sh` | 对比安装脚本与文档内容，避免出现过时命令或默认密码 |

运行脚本前请确保具备相应的执行权限（`chmod +x`）；Python 脚本需要在具备依赖的虚拟环境或系统环境中执行。

## 🔐 安全与凭据

- 使用 `install.sh` 安装时，会自动生成 `.env` 文件和 `setup_credentials.txt`。文件中包含超级用户以及数据库账户的随机强密码，请务必妥善保管。
- 首次登录后台后，请立即修改超级用户密码，并根据需要调整 `.env` 中的密钥与安全相关配置。
- 防火墙与反向代理的示例配置可在部署指南中找到，并可结合自身安全策略进行强化。

## 🔄 文档维护与校验

为了保持文档与代码的一致性，建议在提交前执行以下检查：

```bash
python scripts/docs/check_consistency.py
```

脚本会检查安装说明、默认参数和禁用词（例如过时的默认密码），并输出修复建议。

## ❓ 反馈与支持

- 发现文档问题或需要新增内容？请提交 [GitHub Issues](https://github.com/ipzh/ipv6-wireguard-manager/issues)。
- 需要技术讨论或经验分享，可以前往 [GitHub Discussions](https://github.com/ipzh/ipv6-wireguard-manager/discussions)。
- 紧急问题可结合 `scripts/one_click_check.py` 生成的诊断报告，加速定位与解决。

感谢您使用 IPv6 WireGuard Manager，祝使用顺利！
