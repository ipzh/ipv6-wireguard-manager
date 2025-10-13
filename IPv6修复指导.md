# IPv6 WireGuard Manager - IPv6访问修复指导

## 🔧 问题诊断

IPv6访问显示空白页面，这通常是由以下原因造成的：

### 1. IPv6地址检测问题
- 安装脚本可能没有正确检测到IPv6地址
- 显示的IPv6地址格式不正确

### 2. Nginx配置问题
- Nginx可能没有正确配置IPv6监听
- 缺少 `listen [::]:80;` 配置

### 3. 防火墙问题
- IPv6流量可能被防火墙阻止
- 需要配置IPv6防火墙规则

## 🚀 修复方案

### 方案1: 自动修复（推荐）

在您的Linux服务器上运行以下命令：

```bash
# 下载并运行IPv6修复脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-ipv6-access.sh | bash
```

### 方案2: 手动修复

#### 步骤1: 检查IPv6地址
```bash
# 检查IPv6地址
ip -6 addr show | grep inet6

# 获取全局IPv6地址
ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1
```

#### 步骤2: 修复Nginx配置
```bash
# 编辑Nginx配置文件
sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager

# 确保包含以下配置：
server {
    listen 80;
    listen [::]:80;  # 这行很重要！
    server_name _;
    
    # 前端静态文件
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 步骤3: 测试并重启Nginx
```bash
# 测试配置文件
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

#### 步骤4: 配置防火墙
```bash
# 允许IPv6流量
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 重新加载防火墙
sudo ufw --force reload
```

#### 步骤5: 测试IPv6访问
```bash
# 获取IPv6地址
IPV6_ADDR=$(ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1)

# 测试IPv6访问
curl -6 -I http://[$IPV6_ADDR]

# 测试前端页面
curl -6 -s http://[$IPV6_ADDR] | head -20
```

## 🔍 常见问题解决

### 问题1: 未检测到IPv6地址
**原因**: 服务器可能没有分配IPv6地址
**解决**: 
- 联系云服务商启用IPv6支持
- 检查网络配置

### 问题2: Nginx配置错误
**原因**: 缺少IPv6监听配置
**解决**: 添加 `listen [::]:80;` 配置

### 问题3: 防火墙阻止
**原因**: IPv6流量被阻止
**解决**: 配置防火墙允许IPv6流量

### 问题4: 系统IPv6支持问题
**原因**: IPv6转发未启用
**解决**: 
```bash
# 启用IPv6转发
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
sysctl -p
```

## 📋 快速修复命令

如果您想快速修复，可以运行以下命令：

```bash
# 一键修复IPv6访问问题
sudo sed -i 's/listen 80;/listen 80;\n    listen [::]:80;/' /etc/nginx/sites-available/ipv6-wireguard-manager
sudo nginx -t && sudo systemctl restart nginx
sudo ufw allow 80/tcp
sudo ufw --force reload

# 获取正确的IPv6地址
IPV6_ADDR=$(ip -6 addr show | grep -E 'inet6.*global' | awk '{print $2}' | cut -d'/' -f1 | head -1)
echo "IPv6访问地址: http://[$IPV6_ADDR]"
```

## 🎯 验证修复结果

修复完成后，您应该能够：

1. ✅ 通过IPv6地址正常访问前端界面
2. ✅ 看到完整的页面内容（不再是空白页）
3. ✅ 通过IPv6访问API文档
4. ✅ 所有功能正常工作

## 📞 获取帮助

如果修复后仍有问题，请：

1. 检查服务器IPv6地址分配情况
2. 验证网络提供商IPv6支持
3. 查看Nginx错误日志：`sudo tail -f /var/log/nginx/error.log`
4. 提交Issue到项目仓库

---

**注意**: 此修复方案专为Linux服务器环境设计。
