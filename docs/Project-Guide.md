# 项目详解与部署指南

本指南系统介绍 IPv6 WireGuard Manager 的架构、认证与安全、部署与运维、配置项以及开发与故障排查，帮助你在不同环境下快速、可靠地上线与维护系统。

## 概述

- 技术栈：后端 `FastAPI + Uvicorn + SQLAlchemy + Redis`，前端 `React + Vite + TypeScript + Ant Design`，实时通信 `WebSocket`。
- 部署方式：Docker Compose（推荐）与原生安装脚本，前端由 Nginx 提供静态资源和反向代理（含可选 HTTPS）。
- 功能域：用户与权限、WireGuard 节点与客户端管理、网络与防火墙配置、监控与日志、实时推送与仪表盘。

## 架构总览

- 后端（`backend/`）
  - 入口：`app/main.py` 初始化应用、中间件、启动/关闭事件。
  - 路由聚合：`app/api/api_v1/api.py` 将 `auth/users/wireguard/network/monitoring/logs/websocket` 子模块统一到 `/api/v1`。
  - 核心配置：`app/core` 下的 `config.py`（设置）、`database.py`（异步 DB 会话）、`security.py`（JWT 与鉴权依赖）。
  - 业务服务：`app/services/*` 封装 WireGuard 与网络、监控等核心逻辑。
  - 依赖与构建：`backend/Dockerfile` 多阶段镜像，`requirements*.txt` 管理依赖版本。

- 前端（`frontend/`）
  - 工程化：`Vite + React + TypeScript`，目录下分组件、页面、状态（Redux）、服务（REST/WebSocket）。
  - 路由与布局：`src/App.tsx` 路由、`ProtectedRoute` 访问控制、`AppLayout` 布局与导航。
  - 开发代理：`vite.config.ts` 在开发模式下代理 `/api` 与 `/ws` 到后端 `localhost:8000`。
  - 构建与部署：`frontend/Dockerfile` 构建静态产物，`frontend/nginx.conf` 提供静态站点与反向代理（HTTP/HTTPS）。

- 部署编排（`docker-compose.yml`）
  - 服务：`postgres`、`redis`、`backend`（FastAPI）、`frontend`（Nginx + 静态前端）。
  - 端口：后端 `8000`，前端 `80/443`（对外 `3000:80` 与 `443:443`）。
  - 网络：所有服务加入内部桥接网络 `ipv6wgm-network`，前端通过服务名 `backend` 反代到 API。

## 后端架构与安全

- 中间件与事件：
  - CORS、TrustedHost、请求耗时统计等中间件在 `main.py` 统一注册。
  - 启动/关闭事件管理数据库连接与资源。

- 路由与模块：
  - `auth`：登录、令牌签发与刷新、用户会话。
  - `users`：用户 CRUD 与角色权限（RBAC）。
  - `wireguard`：节点/客户端配置生成、二维码导出、状态查询。
  - `network`：网络接口、路由、防火墙规则与状态。
  - `monitoring`：系统资源与服务健康监控。
  - `logs`：系统与安全审计日志。
  - `websocket`：实时数据推送与订阅（路径前缀 `/api/v1/ws`）。

- 认证与鉴权：
  - 访问令牌（短时）与刷新令牌（长时），采用 JWT（`security.py`）。
  - REST：`Authorization: Bearer <token>` 注入，后端依赖如 `get_current_user_id` 进行鉴权。
  - WebSocket：握手时通过 `Authorization` 或查询参数携带令牌，服务端 `verify_token` 校验。

- 数据与缓存：
  - `DATABASE_URL` 指向 PostgreSQL；异步 `AsyncSession` 提升并发能力。
  - `REDIS_URL` 提供缓存/队列/会话辅助（如黑名单令牌、短期存储）。

## 前端架构与通信

- 路由与布局：
  - `App.tsx` 定义路由；`ProtectedRoute` 基于登录态保护受控页面；`AppLayout` 提供统一导航与主题。

- 状态与服务：
  - Redux Store：`@store` 下各 Slice（`auth/network/wireguard/monitoring`），统一在 `store/index.ts` 汇总。
  - REST 服务：`src/services/api.ts` 默认同源 `baseURL`（`window.location.origin`），也支持构建期 `VITE_API_URL`。
  - WebSocket：`src/services/websocket.ts` 与 `hooks/useWebSocket.ts` 构建 `ws(s)://<host>/ws/...`，在查询参数附带令牌与用户信息。

- 开发代理：
  - `vite.config.ts` 将 `/api` 与 `/ws` 代理到 `http://localhost:8000` 与 `ws://localhost:8000`，免去本地跨域问题。

## 接口与实时通信

- REST API
  - 基础路径：`/api/v1`，典型接口如 `auth/users/wireguard/network/monitoring/logs`。
  - 文档：后端启动后访问 `http://<host>:8000/docs`（Swagger）。

- WebSocket
  - 基础路径：`/api/v1/ws/...`，升级握手需 `Upgrade/Connection` 头（由 Nginx 代理正确设置）。
  - 生产建议使用同源 `wss://your-domain/ws/...`，避免浏览器混合内容与跨域。

## 配置与环境变量

- 后端（`docker-compose.yml` → `backend`）：
  - `DATABASE_URL=postgresql://ipv6wgm:password@postgres:5432/ipv6wgm`
  - `REDIS_URL=redis://redis:6379/0`
  - `SECRET_KEY=your-secret-key-here`（请替换为安全随机值）
  - `DEBUG=true`（生产请关闭或限制）

- 前端（构建期 → Vite）：
  - `VITE_API_URL`（示例：`https://your-domain/api`）
  - `VITE_WS_URL`（示例：`wss://your-domain/ws`）
  - 留空时采用同源逻辑（推荐生产通过 Nginx 反代统一同源）。

- Nginx（`frontend/nginx.conf`）：
  - `server { listen 80; }` 和可选 `server { listen 443 ssl http2; }`。
  - 前端静态资源缓存策略与安全响应头。
  - `/api/` 与 `/ws/` 反代到 `http://backend:8000`，并正确透传 `Authorization` 与升级头。

## 部署与运维

- Docker Compose（推荐）：
  - 启动：`docker compose up -d --build`
  - 查看：`docker compose ps`、`docker compose logs -f`
  - 停止：`docker compose down`

- 访问：
  - 前端：`http://<服务器IP>:3000` 或配置证书后 `https://<域名>`
  - 后端文档：`http://<服务器IP>:8000/docs`

- HTTPS 配置：
  - 证书路径默认挂载到容器 `/etc/nginx/certs`，在 `nginx.conf` 中配置 `ssl_certificate` 与 `ssl_certificate_key`。
  - 设置 `server_name your-domain` 并为生产建议开启 HSTS 与更严格安全头。

## 开发与本地调试

- 后端：
  - `cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload`

- 前端：
  - `cd frontend && npm install && npm run dev`
  - 通过 `vite.config.ts` 开发代理访问后端 `http://localhost:8000`。

## 验证与故障排查

- REST 验证：
  - 登录获取访问令牌与刷新令牌；访问受保护接口返回 `200`。
  - 若返回 `401`，检查前端是否触发刷新逻辑、后端 `SECRET_KEY` 与时间同步。

- WebSocket 验证：
  - 浏览器网络面板查看 `/ws/...` 握手是否 `101 Switching Protocols`。
  - 如为 HTTPS，确保前端使用 `wss://` 且证书有效。
  - Nginx 必须设置 `proxy_set_header Upgrade $http_upgrade;` 与 `proxy_set_header Connection "upgrade";`。

- Nginx/前端：
  - `docker compose logs frontend` 查看代理与证书错误。
  - 同源策略优先；避免在生产硬编码外部 `API/WS` URL。

## 安全与合规建议

- 令牌策略：
  - 刷新令牌轮换与登出失效；生产建议将刷新令牌改用 `HttpOnly` Cookie 并配合 CSRF 防护。
  - 访问令牌短时有效，后端校验签名与过期，必要时接入 Redis 黑名单。

- 响应安全头：
  - `X-Frame-Options/X-Content-Type-Options/X-XSS-Protection/Strict-Transport-Security` 按需启用。

## 常见问题（FAQ）

- 为什么前端在生产无需设置 `VITE_API_URL/VITE_WS_URL`？
  - 因为前端默认同源，通过 Nginx 将 `/api` 与 `/ws` 反代到后端服务，避免跨域与混合内容问题。

- WebSocket 连接失败？
  - 检查是否为 HTTPS 并使用 `wss://`，确认 Nginx 升级头设置，后端路径为 `/api/v1/ws/...`。

- 证书与域名如何配置？
  - 将证书挂载到 `./docker/certs`，在 `nginx.conf` 设置 `ssl_certificate/ssl_certificate_key` 与 `server_name your-domain`。

## 版本与变更摘要（近期）

- 前端默认地址改为同源，移除硬编码 `localhost:8000`。
- 新增 `frontend/nginx.conf`，支持 `/api/` 与 `/ws/` 反代及 HTTPS。
- `docker-compose.yml` 与 `frontend/Dockerfile` 支持 `VITE_API_URL/VITE_WS_URL` 构建变量（可留空走同源）。
- 加强 WebSocket 握手的代理与鉴权适配。

— 若需根据你的域名、证书路径或令牌策略定制，请联系维护者或提交 Issue。