# 安装脚本INFO_COLOR变量错误修复指南

## 🚨 问题描述

用户在运行安装脚本时遇到以下错误：
```
./install.sh: line 871: INFO_COLOR: unbound variable
```

## 🔍 问题原因

这个问题可能由以下原因造成：
1. **使用了旧版本的安装脚本** - 旧版本缺少INFO_COLOR变量定义
2. **网络缓存问题** - 下载的可能是缓存的旧版本
3. **脚本执行环境问题** - bash严格模式下的变量检查

## ✅ 解决方案

### 方案1: 使用最新版本（推荐）

```bash
# 下载最新版本的安装脚本
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh -o install_latest.sh

# 设置执行权限
chmod +x install_latest.sh

# 运行最新版本
sudo ./install_latest.sh
```

### 方案2: 一键修复脚本

```bash
# 运行修复脚本
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/fix_install_script.sh | bash
```

### 方案3: 手动修复

如果仍然遇到问题，可以手动修复：

```bash
# 下载安装脚本
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh -o install.sh

# 添加INFO_COLOR变量定义（如果缺失）
if ! grep -q "INFO_COLOR=" install.sh; then
    sed -i '/NC=.*No Color/a INFO_COLOR="\\033[0;36m"  # 信息颜色（青色）' install.sh
fi

# 运行修复后的脚本
chmod +x install.sh
sudo ./install.sh
```

## 🔧 技术修复详情

### 修复内容
1. **变量定义** - 在颜色定义部分添加INFO_COLOR
2. **安全检查** - 在函数中添加变量安全检查
3. **向后兼容** - 支持旧版本脚本

### 修复代码
```bash
# 在颜色定义部分添加
INFO_COLOR='\033[0;36m'  # 信息颜色（青色）

# 在show_install_methods函数中添加安全检查
INFO_COLOR="${INFO_COLOR:-$CYAN}"
```

## 📊 修复验证

### 检查修复是否成功
```bash
# 检查INFO_COLOR变量是否存在
grep -n "INFO_COLOR" install.sh

# 检查变量定义
grep -A2 -B2 "INFO_COLOR=" install.sh
```

### 预期结果
```bash
17:INFO_COLOR='\033[0;36m'  # 信息颜色（青色）
866:INFO_COLOR="${INFO_COLOR:-$CYAN}"
```

## 🎯 安装菜单显示

修复后，安装菜单应该正常显示：

```
=== 安装方法选择 ===

1. 快速安装 - 使用默认配置
2. 交互式安装 - 自定义配置
3. 仅下载文件 - 不安装
4. 显示安装帮助

0. 退出

请选择安装方法 [0-4]:
```

## 🚀 推荐安装命令

### 最新版本安装
```bash
# 一键安装（推荐）
curl -sSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh | bash

# 手动下载安装
wget https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 验证安装
```bash
# 检查安装是否成功
sudo systemctl status ipv6-wireguard-manager

# 运行主程序
sudo /opt/ipv6-wireguard-manager/ipv6-wireguard-manager.sh
```

## 📋 故障排除

### 常见问题
1. **权限问题** - 确保使用sudo运行
2. **网络问题** - 检查网络连接和防火墙设置
3. **依赖问题** - 确保系统已安装必要依赖

### 错误日志
```bash
# 查看详细错误信息
bash -x install.sh

# 检查系统日志
journalctl -u ipv6-wireguard-manager
```

## 🎉 总结

**INFO_COLOR变量错误已完全修复！**

- ✅ **变量定义** - INFO_COLOR变量已正确定义
- ✅ **安全检查** - 添加了变量安全检查机制
- ✅ **向后兼容** - 支持旧版本脚本
- ✅ **用户体验** - 安装菜单正常显示

**用户现在可以正常使用IPv6 WireGuard Manager安装脚本！** 🚀

## 📞 技术支持

如果仍然遇到问题，请：
1. 检查网络连接
2. 使用最新版本的安装脚本
3. 查看错误日志获取详细信息
4. 联系技术支持团队
