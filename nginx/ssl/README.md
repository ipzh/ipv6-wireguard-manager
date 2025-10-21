# SSL 证书目录

本目录用于存放 SSL 证书文件（cert.pem 和 key.pem）。

默认反向代理配置未启用 443/SSL 监听，仅用于占位以满足 Docker Compose 挂载需求。
如需启用 HTTPS，请放置有效的证书并更新 nginx.conf 以监听 443 端口。
