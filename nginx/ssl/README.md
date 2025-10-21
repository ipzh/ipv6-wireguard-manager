# SSL 证书配置

此目录用于存放 SSL 证书文件。

## 需要的文件

- `cert.pem` - SSL 证书文件
- `key.pem` - SSL 私钥文件

## 生成自签名证书（仅用于开发）

```bash
# 生成私钥
openssl genrsa -out key.pem 2048

# 生成证书
openssl req -new -x509 -key key.pem -out cert.pem -days 365 -subj "/C=CN/ST=State/L=City/O=Organization/CN=localhost"
```

## 生产环境

请使用有效的 SSL 证书，可以通过 Let's Encrypt 或其他 CA 获取。
