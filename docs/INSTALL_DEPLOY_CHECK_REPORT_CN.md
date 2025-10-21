IPv6 WireGuard Manager 安装与部署全面检查报告（CN）

一、结论综述
- 原生安装（install.sh -> type=native/minimal）：脚本设计完整，具备系统检测、依赖安装、数据库初始化、服务创建、Nginx 与 PHP-FPM 配置、健康检查与自检等关键路径。按代码静态审计，在具备 root 权限且满足系统条件的真实环境中应能完成安装与启动。但存在一处高优先级配置问题：PHP 前端的 API 路由配置文件（config/api_paths.json）默认 base_url=“http://backend:8000”，仅适用于容器网络；原生安装应改为 http://127.0.0.1:{API_PORT}，否则前端控制器通过 ApiClient 直接拉取后端数据会失败（浏览器侧的 /api 代理没问题）。
- 容器化部署（docker-compose）：后端与数据库、Redis 服务的编排逻辑基本正确，但当前仓库缺少前端与 Nginx 所需的关键配置文件，导致 docker-compose 构建会被阻塞：
  1) 缺少文件：php-frontend/docker/nginx.conf、php-frontend/docker/supervisord.conf、php-frontend/nginx.production.conf
  2) 缺少文件：repo 根目录的 nginx/nginx.conf（compose 挂载该文件到 Nginx/APIGateway 容器）
  在未补齐上述文件前，前端镜像无法成功构建，Nginx 容器也无法启动，整套容器编排无法运行。
- 数据导入/初始化：后端在应用启动生命周期内会基于 SQLAlchemy 自动建表并初始化权限/角色、创建超级用户；docker/mysql/init.sql 虽存在，但标注“已弃用”，主要为兼容或演示用途。建议以应用自建表为准，或引入 Alembic 迁移流程以保证结构一致性与可演进性。

二、检查范围与方法
- 代码静态审计：install.sh、docker-compose*.yml、后端 FastAPI 启动流程、数据库初始化流程、PHP 前端路由与 API 客户端、Nginx 配置生成逻辑等。
- 运行性限制：当前环境不具备 root/systemd/Docker 能力，未实际执行 apt/systemctl/docker。报告基于脚本逻辑与配置的可行性分析与一致性检查，指出潜在阻塞点与修复建议。

三、install.sh 脚本检查
1) 脚本基本信息
- 支持安装类型：docker | native | minimal
- 支持多发行版（apt/yum/dnf/pacman/zypper/emerge/apk）依赖安装与差异化处理。
- 自动检测：OS、CPU、内存、磁盘、IPv6 支持、可用 PHP 版本；智能选择安装类型与端口规避冲突；自动生成强随机密钥与管理员密码。

2) 原生安装关键路径
- 系统依赖：Python3.11（回退系统 python3）、MySQL 或 MariaDB、Nginx、PHP-FPM、常用工具等。
- 数据库：
  - Debian12 优先 MariaDB；其他系尝试 MySQL8.0→默认 MySQL→MariaDB→MySQL5.7 多策略；创建数据库与本地/127.0.0.1 用户，授予权限，flush privileges。
  - 生成 .env，设置 DATABASE_URL=mysql://{user}:{pass}@127.0.0.1:{port}/{db}。
  - initialize_database：使用 aiomysql 异步引擎连接，建表并初始化权限与超级用户（admin）。
- 后端服务：
  - 创建 systemd 服务 ipv6-wireguard-manager，ExecStart=uvicorn backend.app.main:app --host :: --port {API_PORT}，WorkingDirectory 为安装目录，EnvironmentFile=$INSTALL_DIR/.env。
- PHP 前端与 Nginx：
  - 复制 php-frontend 至 FRONTEND_DIR（默认 /var/www/html）。
  - 自动寻找 PHP-FPM 服务名并启动（phpX.Y-fpm/php-fpm 等多候选，含直接启动兜底）。
  - 生成 Nginx 站点：
    - upstream backend_api 同时支持 [::1]:{API_PORT}（IPv6 有效时）与 127.0.0.1:{API_PORT}（IPv4 备份）
    - location /api/ 反代至 backend_api；location ~ \.php$ 走 PHP-FPM；listen {WEB_PORT} 与 listen [::]:{WEB_PORT}
  - 重载 Nginx，启用/链接 sites-enabled。
- 自检与提示：启动后运行环境检查与 API 健康检查脚本，打印访问地址与账户凭据。

3) 原生安装潜在问题与建议
- 高优先级：config/api_paths.json 的 api.base_url 默认为 http://backend:8000（用于容器内 DNS），在原生部署中应改为 http://127.0.0.1:{API_PORT}。否则 PHP 控制器（通过 ApiClientJWT + UnifiedAPIPathBuilder）服务器端拉取后端数据会报连接失败。建议在 install.sh 的 deploy_php_frontend 阶段按实际 API_PORT 动态改写 config/api_paths.json。
- 中优先级：Nginx server 块默认 listen [::]:{WEB_PORT}，若宿主机完全禁用 IPv6，个别系统可能对绑定 [::] 行为敏感。脚本已根据 IPv6 支持决定是否添加 upstream 的 IPv6，但 listen [::] 仍存在。建议在未检测到 IPv6 时只监听 IPv4，或保留当前配置但在文档中注明依赖。
- 一致性：文档/Compose 与原生默认 DB 用户名存在“ipv6wgm”和“ipv6-wireguard”两种写法。当前 install.sh 原生默认 DB_USER=ipv6-wireguard，而 Docker 使用 ipv6wgm。建议统一为 ipv6wgm 或在各处清晰区分。

四、容器化部署检查（docker-compose）
1) 架构概览
- backend: 基于 backend/Dockerfile 构建，uvicorn 启动 app.main:app，健康检查 /api/v1/health，挂载代码目录，依赖 mysql、redis。
- frontend: 基于 php-frontend/Dockerfile 构建，暴露 80/443，健康检查 /health，依赖 backend。
- mysql: MySQL 8.0，初始化数据卷与配置，附带 docker/mysql/init.sql（标注已弃用）。
- redis: 7-alpine，基础配置与健康检查。
- nginx（可选或 API 网关）：挂载 ./nginx/nginx.conf、./nginx/ssl，健康检查 /health。

2) 阻塞问题（必须修复）
- php-frontend 镜像构建缺少文件：
  - php-frontend/docker/nginx.conf（Dockerfile 第 18 行 COPY）
  - php-frontend/docker/supervisord.conf（Dockerfile 第 20 行 COPY）
  - php-frontend/nginx.production.conf（Dockerfile 第 19 行 COPY）
- docker-compose 对 Nginx 容器与前端容器均挂载 ./nginx/nginx.conf，但仓库不存在该文件；仅有 nginx/sites-available/.gitkeep 与 nginx/ssl/README.md。
- 未补齐前述文件之前，compose build 会失败（COPY 失败），或者容器启动失败（缺少配置）。

3) 其它建议
- 配置一致性：backend 的 DATABASE_URL 以 mysql://ipv6wgm:${MYSQL_ROOT_PASSWORD}@mysql:3306/ipv6wgm 传入，与 mysql 容器环境变量匹配，OK。建议不再依赖 docker/mysql/init.sql（与 ORM 模型可能不完全一致），改为仅依靠应用启动时的自动建表或正式引入 Alembic 迁移。
- IPv6 网络：compose 已开启 enable_ipv6 与 IPv6 子网，注意宿主 Docker 守护进程与内核 IPv6 配置是否开启，否则 IPv6 路由功能不可用。

五、数据导入/初始化
- 原生：initialize_database 使用 aiomysql 异步连接，调用 app.core.database.init_db() 自动建表，并调用 init_permissions_and_roles 初始化权限/角色，再创建超级用户（FIRST_SUPERUSER=admin，密码为自动生成强密码，保存在 .env 并在安装日志中输出）。
- 容器：后端镜像启动时同样在 lifespan 中执行 init_db 自动建表。docker/mysql/init.sql 仍会被执行，但已标注弃用，存在与模型演进不同步的风险。建议统一采用 ORM + 迁移脚本，避免双轨初始化。

六、服务运行与健康检查
- systemd 服务（原生）：
  - After/Wants 关联 mysql/mariadb，确保数据库先于后端；WorkingDirectory 与 PATH 指向 venv；EnvironmentFile 指向 .env；日志走 journal。
- 健康检查（原生与容器）：
  - 后端健康检查端点 /api/v1/health；前端容器 /health；Nginx 容器 /health；backend 容器健康检查配置已就绪。
- 安装后自检：install.sh 会执行 run_environment_check 与 scripts/check_api_service.sh（若不可用则生成简版），逐项检查端口、IPv4/IPv6 连通、健康端点与日志。

七、前端代码问题与建议
- 必须修复：缺少 php-frontend/docker/nginx.conf、php-frontend/docker/supervisord.conf、php-frontend/nginx.production.conf，阻断容器化构建。
- 原生环境 API 调用：controllers 通过 ApiClientJWT 使用 UnifiedAPIPathBuilder 读取 config/api_paths.json 的 base_url；该文件默认指向 http://backend:8000（容器网络），应在原生部署中改为 http://127.0.0.1:{API_PORT}。否则页面渲染时服务器端向后端取数会失败（而浏览器侧 /api 反代仍可用，表现为部分功能无数据）。
- 配置重复来源：
  - api_proxy.php 通过环境变量 API_BASE_URL 代理到后端，默认 http://localhost:8000/api/v1（原生 OK，容器化由 compose 传值 OK）。
  - UnifiedAPIPathBuilder 使用 config/api_paths.json 的 base_url（容器默认 OK，原生需改）。
  建议：在 install.sh 原生部署时同步改写 api_paths.json；容器化保持默认。
- PHP 扩展与版本：index.php 与 scripts/deploy.sh 均对 PHP8.1+ 与扩展进行校验，逻辑合理。

八、建议的修复与改进清单
- 必须修复（容器化无法运行的阻塞项）：
  - 补齐并提交以下文件：
    - ./nginx/nginx.conf（供 nginx 服务和微服务 api-gateway 使用）
    - ./php-frontend/docker/nginx.conf
    - ./php-frontend/docker/supervisord.conf
    - ./php-frontend/nginx.production.conf
  或者：修改 php-frontend/Dockerfile 与 docker-compose.yml，改为引用现有的 Nginx 配置路径。
- 高优先级（原生功能不一致）：
  - install.sh 在 deploy_php_frontend 之后，根据 API_PORT 动态改写 config/api_paths.json 的 api.base_url=http://127.0.0.1:{API_PORT}。
- 一致性与可运维性：
  - 统一 DB 用户命名（ipv6wgm vs ipv6-wireguard），建议统一到 ipv6wgm，并在 install.sh 与文档保持一致。
  - 建议引入 Alembic 迁移，逐步淘汰 docker/mysql/init.sql，避免 schema 偏差。
  - Nginx listen [::] 逻辑可依据 IPv6 检测决定是否写入，以避免极端环境的绑定失败。

九、验证建议（真实环境）
- 原生安装（Ubuntu/Debian 示例）：
  - sudo ./install.sh --type native --auto
  - 验证：
    - systemctl status ipv6-wireguard-manager（active）
    - curl -f http://127.0.0.1:{API_PORT}/api/v1/health（200）
    - 浏览器访问 http://服务器IP:{WEB_PORT}
    - 日志：journalctl -u ipv6-wireguard-manager -n 50
  - 如发现前端控制台或页面数据为空，检查并修正 config/api_paths.json 的 api.base_url。
- 容器化部署：
  - 补齐缺失的 Nginx/前端配置文件后：
    - docker-compose up -d --build
    - docker-compose ps（各服务 healthy）
    - curl -f http://localhost:{API_PORT}/api/v1/health（200）
    - 前端容器健康端点 http://localhost:{WEB_PORT}/health（200）

十、附：关键文件与位置
- 安装脚本：install.sh
- Docker 编排：docker-compose.yml、docker-compose.production.yml、docker-compose.low-memory.yml、docker-compose.microservices.yml
- 后端：backend/Dockerfile、backend/app/main.py、backend/app/core/database.py、backend/app/core/database_manager.py
- MySQL 初始化（弃用）：docker/mysql/init.sql
- 前端：php-frontend/（controllers、classes、includes、config）
- 缺失配置（需补齐）：
  - nginx/nginx.conf
  - php-frontend/docker/nginx.conf
  - php-frontend/docker/supervisord.conf
  - php-frontend/nginx.production.conf

报告版本：v1.0（基于仓库当前分支审计）
