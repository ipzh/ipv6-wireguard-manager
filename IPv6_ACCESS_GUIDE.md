# IPv6访问指南

## 🌐 IPv6网络访问配置

### 获取IPv6地址

```bash
# 查看IPv6地址
ip -6 addr show

# 获取全局IPv6地址
ip -6 addr show | grep -E "inet6.*global" | awk '{print $2}' | cut -d'/' -f1
```

### 访问地址格式

IPv6地址需要用方括号包围：

```
http://[IPv6地址]
```

例如：
```
http://[2605:6400:8a61:100::117]
```

## 🔧 配置步骤

### 1. 运行IPv6配置脚本

```bash
# 下载并运行配置脚本
curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/configure-ipv6-access.sh | bash
```

### 2. 手动配置（可选）

#### 更新Nginx配置

```bash
sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager
```

确保包含IPv6监听：
```nginx
server {
    listen 80;
    listen [::]:80;  # IPv6监听
    server_name _;
    
    location / {
        root /opt/ipv6-wireguard-manager/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 重启服务

```bash
# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

## 🌐 访问方式

### 前端访问

```
http://[您的IPv6地址]
```

### API访问

```
http://[您的IPv6地址]/api/v1/status
http://[您的IPv6地址]/health
```

### 示例

如果您的IPv6地址是 `2605:6400:8a61:100::117`：

- 前端: `http://[2605:6400:8a61:100::117]`
- API状态: `http://[2605:6400:8a61:100::117]/api/v1/status`
- 健康检查: `http://[2605:6400:8a61:100::117]/health`

## 🔍 验证访问

### 检查端口监听

```bash
# 检查IPv6端口监听
ss -tlnp | grep :80 | grep "::"
```

### 测试访问

```bash
# 测试IPv6 API访问
curl -6 http://[您的IPv6地址]/api/v1/status

# 测试IPv6前端访问
curl -6 http://[您的IPv6地址]/
```

## 🛡️ 防火墙配置

如果需要开放端口：

```bash
# 开放HTTP端口
sudo ufw allow 80/tcp

# 开放后端API端口（如果需要直接访问）
sudo ufw allow 8000/tcp

# 查看防火墙状态
sudo ufw status
```

## 🔧 故障排除

### 1. 无法访问

**检查服务状态：**
```bash
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
```

**检查端口监听：**
```bash
ss -tlnp | grep :80
ss -tlnp | grep :8000
```

**检查IPv6地址：**
```bash
ip -6 addr show
```

### 2. 连接被拒绝

**检查防火墙：**
```bash
sudo ufw status
sudo iptables -L
```

**检查Nginx配置：**
```bash
sudo nginx -t
sudo journalctl -u nginx -f
```

### 3. 服务未启动

**重启服务：**
```bash
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl restart nginx
```

**查看日志：**
```bash
sudo journalctl -u ipv6-wireguard-manager -f
sudo journalctl -u nginx -f
```

## 📱 客户端访问

### 浏览器访问

1. 确保您的网络支持IPv6
2. 在浏览器地址栏输入：`http://[IPv6地址]`
3. 例如：`http://[2605:6400:8a61:100::117]`

### 移动设备访问

1. 确保移动网络支持IPv6
2. 使用相同的IPv6地址格式
3. 某些移动网络可能需要特殊配置

### API测试

```bash
# 使用curl测试
curl -6 http://[IPv6地址]/api/v1/status

# 使用wget测试
wget -6 -O- http://[IPv6地址]/health
```

## 🔄 服务管理

### 启动服务

```bash
sudo systemctl start ipv6-wireguard-manager
sudo systemctl start nginx
```

### 停止服务

```bash
sudo systemctl stop ipv6-wireguard-manager
sudo systemctl stop nginx
```

### 重启服务

```bash
sudo systemctl restart ipv6-wireguard-manager
sudo systemctl restart nginx
```

### 查看状态

```bash
sudo systemctl status ipv6-wireguard-manager
sudo systemctl status nginx
```

## 📊 监控

### 查看日志

```bash
# 后端服务日志
sudo journalctl -u ipv6-wireguard-manager -f

# Nginx日志
sudo journalctl -u nginx -f

# 系统日志
sudo journalctl -f
```

### 性能监控

```bash
# 查看端口连接
ss -tlnp | grep :80
ss -tlnp | grep :8000

# 查看进程
ps aux | grep uvicorn
ps aux | grep nginx
```

## 🎯 总结

IPv6访问配置完成后，您可以通过以下方式访问：

1. **前端界面**: `http://[您的IPv6地址]`
2. **API接口**: `http://[您的IPv6地址]/api/v1/`
3. **健康检查**: `http://[您的IPv6地址]/health`

确保您的网络环境支持IPv6，并且防火墙已正确配置。
