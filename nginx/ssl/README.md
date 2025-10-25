# SSL证书配置说明

## 证书文件要求

将您的SSL证书文件放置在此目录下：

- `cert.pem` - SSL证书文件
- `key.pem` - SSL私钥文件

## 环境变量配置

在docker-compose.yml中设置以下环境变量：

```yaml
environment:
  - SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
  - SSL_KEY_PATH=/etc/nginx/ssl/key.pem
```

## 自动生成自签名证书（开发环境）

如果需要生成自签名证书用于开发测试：

```bash
# 生成私钥
openssl genrsa -out key.pem 2048

# 生成证书
openssl req -new -x509 -key key.pem -out cert.pem -days 365 -subj "/C=CN/ST=State/L=City/O=Organization/CN=localhost"
```

## 生产环境证书

生产环境请使用有效的SSL证书，推荐使用Let's Encrypt或其他受信任的CA机构颁发的证书。