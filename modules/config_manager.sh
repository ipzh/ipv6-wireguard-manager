#!/bin/bash

# 配置管理模块
# 提供统一的配置读取、验证、缓存、更新、版本控制和YAML格式支持

# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# ================================================================
# 配置管理变量 - 统一使用IPV6WGM_前缀
# ================================================================

# 配置缓存
declare -A IPV6WGM_CONFIG_CACHE
declare -g IPV6WGM_CONFIG_CACHE_INITIALIZED=false

# 配置文件路径
declare -g IPV6WGM_MAIN_CONFIG="${IPV6WGM_CONFIG_FILE:-${IPV6WGM_CONFIG_DIR}/manager.conf}"
declare -g IPV6WGM_CONFIG_BACKUP_DIR="${IPV6WGM_CONFIG_BACKUP_DIR:-${IPV6WGM_CONFIG_DIR}/backups}"

# 添加配置管理相关目录
declare -g IPV6WGM_CONFIG_MANAGEMENT_DIR="${IPV6WGM_CONFIG_DIR}/management"
declare -g IPV6WGM_YAML_CONFIG_DIR="${IPV6WGM_CONFIG_MANAGEMENT_DIR}/yaml"
declare -g IPV6WGM_CONFIG_VALIDATION_DIR="${IPV6WGM_CONFIG_MANAGEMENT_DIR}/validation"
declare -g IPV6WGM_CONFIG_VERSION_DB="${IPV6WGM_CONFIG_MANAGEMENT_DIR}/versions.db"
declare -g IPV6WGM_CONFIG_TEMPLATES_DIR="${IPV6WGM_CONFIG_DIR}/templates"

# 配置缓存相关变量
declare -g IPV6WGM_CONFIG_CACHE_TTL=300  # 5分钟
declare -g IPV6WGM_CONFIG_CACHE_TIMESTAMP=0
declare -g IPV6WGM_CONFIG_LAST_MODIFIED=0

# 错误处理相关变量
declare -g IPV6WGM_CONFIG_ERROR_COUNT=0
declare -g IPV6WGM_CONFIG_WARNING_COUNT=0
declare -A IPV6WGM_CONFIG_ERRORS=()
declare -A IPV6WGM_CONFIG_WARNINGS=()

# ================================================================
# 配置管理核心函数
# ================================================================

# 初始化配置管理
init_config_manager() {
    ensure_variables
    log_info "初始化配置管理模块..."
    
    # 创建配置目录
    mkdir -p "$IPV6WGM_CONFIG_DIR" \
        "$IPV6WGM_CONFIG_BACKUP_DIR" \
        "$IPV6WGM_CONFIG_MANAGEMENT_DIR" \
        "$IPV6WGM_YAML_CONFIG_DIR" \
        "$IPV6WGM_CONFIG_VALIDATION_DIR" \
        "$IPV6WGM_CONFIG_TEMPLATES_DIR" 2>/dev/null || true
    
    # 检查配置文件是否存在
    if [[ ! -f "$IPV6WGM_MAIN_CONFIG" ]]; then
        log_warn "主配置文件不存在: $IPV6WGM_MAIN_CONFIG"
        create_default_config
    fi
    
    # 初始化版本数据库
    init_config_version_db
    
    # 创建YAML配置模板
    create_yaml_config_templates
    
    # 加载配置到缓存
    load_config_to_cache
    
    # 验证配置
    if ! validate_config; then
        log_error "配置验证失败"
        return 1
    fi
    
    IPV6WGM_CONFIG_CACHE_INITIALIZED=true
    log_success "配置管理模块初始化完成"
    return 0
}

# 初始化配置版本数据库
init_config_version_db() {
    if [[ ! -f "$IPV6WGM_CONFIG_VERSION_DB" ]]; then
        cat > "$IPV6WGM_CONFIG_VERSION_DB" << EOF
version|timestamp|config_type|file_path|checksum|description
EOF
        log_info "配置版本数据库已创建: $IPV6WGM_CONFIG_VERSION_DB"
    fi
}

# 创建默认配置文件
create_default_config() {
    log_info "创建默认配置文件..."
    
    cat > "$IPV6WGM_MAIN_CONFIG" << EOF
# IPv6 WireGuard Manager 配置文件
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

# 系统配置
SYSTEM_NAME="IPv6 WireGuard Manager"
SYSTEM_VERSION="1.0.0"
SYSTEM_ENVIRONMENT="production"
SYSTEM_DEBUG=false
SYSTEM_LOG_LEVEL="INFO"

# 网络配置
NETWORK_IPV6_PREFIX="2001:db8::/56"
NETWORK_IPV6_ALLOCATION_RANGE="/56"
NETWORK_IPV6_AUTO_ASSIGN=true
NETWORK_IPV4_NETWORK="10.0.0.0/24"
NETWORK_IPV4_AUTO_ASSIGN=true
NETWORK_DNS_PRIMARY="8.8.8.8"
NETWORK_DNS_SECONDARY="8.8.4.4"
NETWORK_DNS_IPV6_PRIMARY="2001:4860:4860::8888"
NETWORK_DNS_IPV6_SECONDARY="2001:4860:4860::8844"

# WireGuard配置
WIREGUARD_ENABLED=true
WIREGUARD_INTERFACE="wg0"
WIREGUARD_PORT=51820
WIREGUARD_PRIVATE_KEY=""
WIREGUARD_PUBLIC_KEY=""
WIREGUARD_ENDPOINT=""
WIREGUARD_PERSISTENT_KEEPALIVE=25
WIREGUARD_MTU=1420
WIREGUARD_ALLOWED_IPS="0.0.0.0/0,::/0"

# BIRD BGP配置
BIRD_ENABLED=true
BIRD_VERSION="auto"
BIRD_ROUTER_ID=""
BIRD_LOCAL_AS=65001
BIRD_NEIGHBORS=""
BIRD_POLICIES=""
BIRD_ROUTES=""

# 防火墙配置
FIREWALL_ENABLED=true
FIREWALL_TYPE="auto"
FIREWALL_RULES="22/tcp:ssh:allow,53/udp:dns:allow,80/tcp:http:allow,443/tcp:https:allow,51820/udp:wireguard:allow"

# Web管理界面配置
WEB_INTERFACE_ENABLED=true
WEB_INTERFACE_HOST="0.0.0.0"
WEB_INTERFACE_PORT=8080
WEB_INTERFACE_SSL_ENABLED=false
WEB_INTERFACE_SSL_CERT_FILE=""
WEB_INTERFACE_SSL_KEY_FILE=""
WEB_INTERFACE_AUTH_ENABLED=true
WEB_INTERFACE_AUTH_METHOD="basic"
WEB_INTERFACE_SESSION_TIMEOUT=3600
WEB_INTERFACE_SESSION_SECURE=false

# 监控配置
MONITORING_ENABLED=true
MONITORING_METRICS_ENABLED=true
MONITORING_METRICS_PORT=9090
MONITORING_METRICS_PATH="/metrics"
MONITORING_ALERTS_ENABLED=true
MONITORING_ALERTS_EMAIL_ENABLED=false
MONITORING_ALERTS_WEBHOOK_ENABLED=false

# 客户端管理配置
CLIENT_MANAGEMENT_AUTO_INSTALL_ENABLED=true
CLIENT_MANAGEMENT_AUTO_INSTALL_API_PORT=3000
CLIENT_MANAGEMENT_AUTO_INSTALL_TOKEN_EXPIRY=3600
CLIENT_MANAGEMENT_DATABASE_TYPE="sqlite"
CLIENT_MANAGEMENT_DATABASE_PATH="/var/lib/ipv6-wireguard-manager/clients.db"
CLIENT_MANAGEMENT_BACKUP_ENABLED=true
CLIENT_MANAGEMENT_BACKUP_INTERVAL=86400
CLIENT_MANAGEMENT_BACKUP_RETENTION=7

# 安全配置
SECURITY_KEY_ROTATION_ENABLED=true
SECURITY_KEY_ROTATION_INTERVAL=2592000
SECURITY_BIRD_USER="bird"
SECURITY_BIRD_GROUP="bird"
SECURITY_BIRD_HOME="/var/lib/bird"
SECURITY_AUDIT_ENABLED=true
SECURITY_AUDIT_LOG_FILE="/var/log/ipv6-wireguard-manager/audit.log"

# 更新配置
UPDATE_ENABLED=true
UPDATE_CHECK_INTERVAL=86400
UPDATE_AUTO_UPDATE=false
UPDATE_REPOSITORY_OWNER="ipzh"
UPDATE_REPOSITORY_NAME="ipv6-wireguard-manager"
UPDATE_REPOSITORY_BRANCH="main"
EOF
    
    log_success "默认配置文件已创建: $IPV6WGM_MAIN_CONFIG"
}

# 创建YAML配置模板
create_yaml_config_templates() {
    log_info "创建YAML配置模板..."
    
    # 创建主配置模板
    create_main_config_template
    
    # 创建WireGuard配置模板
    create_wireguard_config_template
    
    # 创建BIRD配置模板
    create_bird_config_template
    
    # 创建防火墙配置模板
    create_firewall_config_template
    
    # 创建客户端配置模板
    create_client_config_template
    
    # 创建监控配置模板
    create_monitoring_config_template
}

# 创建主配置模板
create_main_config_template() {
    cat > "${IPV6WGM_CONFIG_TEMPLATES_DIR}/main.yaml" << 'EOF'
# IPv6 WireGuard Manager 主配置文件
# 版本: 1.0.0
# 生成时间: ${TIMESTAMP}

# 系统配置
system:
  name: "IPv6 WireGuard Manager"
  version: "1.0.0"
  environment: "production"  # production, staging, development
  debug: false
  log_level: "INFO"  # DEBUG, INFO, WARN, ERROR

# 网络配置
network:
  ipv6:
    prefix: "2001:db8::/56"
    allocation_range: "/56"  # /56 to /72
    auto_assign: true
  ipv4:
    network: "10.0.0.0/24"
    auto_assign: true
  dns:
    primary: "8.8.8.8"
    secondary: "8.8.4.4"
    ipv6_primary: "2001:4860:4860::8888"
    ipv6_secondary: "2001:4860:4860::8844"

# WireGuard配置
wireguard:
  enabled: true
  interface: "wg0"
  port: 51820
  private_key: ""  # 自动生成
  public_key: ""   # 自动生成
  endpoint: ""     # 自动检测
  persistent_keepalive: 25
  mtu: 1420
  allowed_ips: ["0.0.0.0/0", "::/0"]

# BIRD BGP配置
bird:
  enabled: true
  version: "auto"  # auto, 1.x, 2.x, 3.x
  router_id: ""    # 自动生成
  local_as: 65001
  neighbors: []
  policies: []
  routes: []

# 防火墙配置
firewall:
  enabled: true
  type: "auto"  # auto, ufw, firewalld, nftables, iptables
  rules:
    - port: "22/tcp"
      service: "ssh"
      action: "allow"
    - port: "53/udp"
      service: "dns"
      action: "allow"
    - port: "80/tcp"
      service: "http"
      action: "allow"
    - port: "443/tcp"
      service: "https"
      action: "allow"
    - port: "51820/udp"
      service: "wireguard"
      action: "allow"

# Web管理界面配置
web_interface:
  enabled: true
  host: "0.0.0.0"
  port: 8080
  ssl:
    enabled: false
    cert_file: ""
    key_file: ""
  authentication:
    enabled: true
    method: "basic"  # basic, oauth, ldap
    users: []
  session:
    timeout: 3600  # 秒
    secure: false

# 监控配置
monitoring:
  enabled: true
  metrics:
    enabled: true
    port: 9090
    path: "/metrics"
  alerts:
    enabled: true
    email:
      enabled: false
      smtp_server: ""
      smtp_port: 587
      username: ""
      password: ""
      from: ""
      to: []
    webhook:
      enabled: false
      url: ""
      secret: ""

# 客户端管理配置
client_management:
  auto_install:
    enabled: true
    api_port: 3000
    token_expiry: 3600
  database:
    type: "sqlite"  # sqlite, mysql, postgresql
    path: "/var/lib/ipv6-wireguard-manager/clients.db"
  backup:
    enabled: true
    interval: 86400  # 秒
    retention: 7     # 天

# 安全配置
security:
  key_rotation:
    enabled: true
    interval: 2592000  # 30天
  permissions:
    bird_user: "bird"
    bird_group: "bird"
    bird_home: "/var/lib/bird"
  audit:
    enabled: true
    log_file: "/var/log/ipv6-wireguard-manager/audit.log"

# 更新配置
update:
  enabled: true
  check_interval: 86400  # 24小时
  auto_update: false
  repository:
    owner: "ipzh"
    name: "ipv6-wireguard-manager"
    branch: "main"
EOF
}

# 创建WireGuard配置模板
create_wireguard_config_template() {
    cat > "${IPV6WGM_CONFIG_TEMPLATES_DIR}/wireguard.yaml" << 'EOF'
# WireGuard配置模板
# 生成时间: ${TIMESTAMP}

# 服务器配置
server:
  interface: "wg0"
  private_key: ""  # 自动生成
  listen_port: 51820
  address: ["10.0.0.1/24", "2001:db8::1/64"]
  dns: ["8.8.8.8", "2001:4860:4860::8888"]
  mtu: 1420
  table: "auto"
  pre_up: []
  post_up: []
  pre_down: []
  post_down: []

# 客户端配置模板
client_template:
  private_key: ""  # 自动生成
  address: ""      # 自动分配
  dns: ["8.8.8.8", "2001:4860:4860::8888"]
  allowed_ips: ["0.0.0.0/0", "::/0"]
  persistent_keepalive: 25
  mtu: 1420

# 客户端列表
clients: []
EOF
}

# 创建BIRD配置模板
create_bird_config_template() {
    cat > "${IPV6WGM_CONFIG_TEMPLATES_DIR}/bird.yaml" << 'EOF'
# BIRD BGP配置模板
# 生成时间: ${TIMESTAMP}

# 全局配置
global:
  router_id: ""  # 自动生成
  local_as: 65001
  log_file: "/var/log/bird.log"
  log_level: "info"

# IPv4配置
ipv4:
  enabled: true
  table: "master4"
  import_filter: "default_import"
  export_filter: "default_export"

# IPv6配置
ipv6:
  enabled: true
  table: "master6"
  import_filter: "default_import6"
  export_filter: "default_export6"

# BGP邻居配置
neighbors: []

# 路由策略
policies:
  - name: "default_import"
    rules: []
  - name: "default_export"
    rules: []
  - name: "default_import6"
    rules: []
  - name: "default_export6"
    rules: []

# 路由配置
routes: []
EOF
}

# 创建防火墙配置模板
create_firewall_config_template() {
    cat > "${IPV6WGM_CONFIG_TEMPLATES_DIR}/firewall.yaml" << 'EOF'
# 防火墙配置模板
# 生成时间: ${TIMESTAMP}

# 防火墙类型
type: "auto"  # auto, ufw, firewalld, nftables, iptables

# 默认策略
default_policy:
  input: "DROP"
  forward: "ACCEPT"
  output: "ACCEPT"

# 规则列表
rules:
  # 必需端口
  - port: "22/tcp"
    service: "ssh"
    action: "allow"
    description: "SSH远程管理"
  - port: "53/udp"
    service: "dns"
    action: "allow"
    description: "DNS解析"
  - port: "80/tcp"
    service: "http"
    action: "allow"
    description: "HTTP服务"
  - port: "443/tcp"
    service: "https"
    action: "allow"
    description: "HTTPS服务"
  - port: "123/udp"
    service: "ntp"
    action: "allow"
    description: "NTP时间同步"
  
  # 功能端口
  - port: "51820/udp"
    service: "wireguard"
    action: "allow"
    description: "WireGuard VPN"
  - port: "179/tcp"
    service: "bgp"
    action: "allow"
    description: "BGP路由协议"
  - port: "8080/tcp"
    service: "web_management"
    action: "allow"
    description: "Web管理界面"
  - port: "8443/tcp"
    service: "web_management_ssl"
    action: "allow"
    description: "HTTPS Web管理界面"
  - port: "9090/tcp"
    service: "monitoring"
    action: "allow"
    description: "监控系统"
  - port: "3000/tcp"
    service: "api"
    action: "allow"
    description: "API服务"

# 自定义规则
custom_rules: []

# 黑名单
blacklist: []

# 白名单
whitelist: []
EOF
}

# 创建客户端配置模板
create_client_config_template() {
    cat > "${IPV6WGM_CONFIG_TEMPLATES_DIR}/client.yaml" << 'EOF'
# 客户端配置模板
# 生成时间: ${TIMESTAMP}

# 客户端信息
client:
  name: ""
  description: ""
  email: ""
  phone: ""
  organization: ""
  created_at: ""
  updated_at: ""
  status: "active"  # active, inactive, suspended

# 网络配置
network:
  ipv4_address: ""  # 自动分配
  ipv6_address: ""  # 自动分配
  allowed_ips: ["0.0.0.0/0", "::/0"]
  dns: ["8.8.8.8", "2001:4860:4860::8888"]
  mtu: 1420
  persistent_keepalive: 25

# 密钥配置
keys:
  private_key: ""  # 自动生成
  public_key: ""   # 自动生成
  preshared_key: "" # 可选

# 连接配置
connection:
  endpoint: ""  # 自动设置
  port: 51820
  protocol: "udp"

# 访问控制
access_control:
  allowed_networks: []
  blocked_networks: []
  time_restrictions: []
  bandwidth_limit: 0  # 0 = 无限制

# 监控配置
monitoring:
  enabled: true
  alert_on_disconnect: true
  alert_on_bandwidth_exceed: false
  alert_email: ""
EOF
}

# 创建监控配置模板
create_monitoring_config_template() {
    cat > "${IPV6WGM_CONFIG_TEMPLATES_DIR}/monitoring.yaml" << 'EOF'
# 监控配置模板
# 生成时间: ${TIMESTAMP}

# 监控服务配置
service:
  enabled: true
  port: 9090
  host: "0.0.0.0"
  path: "/metrics"

# 指标配置
metrics:
  system:
    enabled: true
    cpu: true
    memory: true
    disk: true
    network: true
  wireguard:
    enabled: true
    connections: true
    bandwidth: true
    latency: true
  bird:
    enabled: true
    bgp_sessions: true
    routes: true
    updates: true

# 告警配置
alerts:
  enabled: true
  rules:
    - name: "high_cpu_usage"
      condition: "cpu_usage > 80"
      duration: "5m"
      severity: "warning"
    - name: "high_memory_usage"
      condition: "memory_usage > 90"
      duration: "2m"
      severity: "critical"
    - name: "wireguard_disconnect"
      condition: "wireguard_connections == 0"
      duration: "1m"
      severity: "warning"
    - name: "bgp_session_down"
      condition: "bgp_sessions_down > 0"
      duration: "30s"
      severity: "critical"

# 通知配置
notifications:
  email:
    enabled: false
    smtp_server: ""
    smtp_port: 587
    username: ""
    password: ""
    from: ""
    to: []
  webhook:
    enabled: false
    url: ""
    secret: ""
  slack:
    enabled: false
    webhook_url: ""
    channel: ""

# 数据保留配置
retention:
  metrics: "30d"
  logs: "7d"
  alerts: "90d"
EOF
}

# ================================================================
# 配置缓存和性能优化函数
# ================================================================

# 加载配置到缓存
load_config_to_cache() {
    log_info "加载配置到缓存..."
    
    if [[ -f "$IPV6WGM_MAIN_CONFIG" ]]; then
        # 读取配置文件并存储到缓存
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            if [[ ! "$key" =~ ^[[:space:]]*# ]] && [[ -n "$key" ]]; then
                # 去除引号
                value=$(echo "$value" | sed 's/^"//;s/"$//')
                IPV6WGM_CONFIG_CACHE["$key"]="$value"
            fi
        done < "$IPV6WGM_MAIN_CONFIG"
        
        # 更新缓存时间戳
        IPV6WGM_CONFIG_CACHE_TIMESTAMP=$(date +%s)
        IPV6WGM_CONFIG_LAST_MODIFIED=$(stat -c %Y "$IPV6WGM_MAIN_CONFIG" 2>/dev/null || echo "0")
        
        log_success "配置已加载到缓存，共 ${#IPV6WGM_CONFIG_CACHE[@]} 项"
    else
        log_error "配置文件不存在: $IPV6WGM_MAIN_CONFIG"
        return 1
    fi
}

# 检查配置缓存是否有效
is_config_cache_valid() {
    local current_time=$(date +%s)
    local file_modified=$(stat -c %Y "$IPV6WGM_MAIN_CONFIG" 2>/dev/null || echo "0")
    
    # 检查缓存是否过期
    if [[ $((current_time - IPV6WGM_CONFIG_CACHE_TIMESTAMP)) -gt $IPV6WGM_CONFIG_CACHE_TTL ]]; then
        return 1
    fi
    
    # 检查文件是否被修改
    if [[ "$file_modified" != "$IPV6WGM_CONFIG_LAST_MODIFIED" ]]; then
        return 1
    fi
    
    return 0
}

# 更新缓存时间戳
update_cache_timestamp() {
    IPV6WGM_CONFIG_CACHE_TIMESTAMP=$(date +%s)
    IPV6WGM_CONFIG_LAST_MODIFIED=$(stat -c %Y "$IPV6WGM_MAIN_CONFIG" 2>/dev/null || echo "0")
}

# 清除配置缓存
clear_config_cache() {
    IPV6WGM_CONFIG_CACHE=()
    IPV6WGM_CONFIG_CACHE_INITIALIZED=false
    IPV6WGM_CONFIG_CACHE_TIMESTAMP=0
    IPV6WGM_CONFIG_LAST_MODIFIED=0
    log_info "配置缓存已清除"
}

# 缓存配置项
cache_config_item() {
    local key="$1"
    local value="$2"
    IPV6WGM_CONFIG_CACHE["$key"]="$value"
    update_cache_timestamp
}

# 获取缓存的配置项
get_cached_config_item() {
    local key="$1"
    local default_value="${2:-}"
    
    # 检查缓存是否有效
    if ! is_config_cache_valid; then
        load_config_to_cache
    fi
    
    # 从缓存获取值
    if [[ -n "${IPV6WGM_CONFIG_CACHE[$key]:-}" ]]; then
        echo "${IPV6WGM_CONFIG_CACHE[$key]}"
    else
        echo "$default_value"
    fi
}

# ================================================================
# 配置验证函数
# ================================================================

# 验证配置
validate_config() {
    local config_file="${1:-$IPV6WGM_MAIN_CONFIG}"
    local config_type="${2:-main}"
    
    log_info "验证配置文件: $config_file"
    
    # 检查文件是否存在
    if [[ ! -f "$config_file" ]]; then
        record_config_error "配置文件不存在: $config_file"
        return 1
    fi
    
    # 检查YAML语法（如果是YAML文件）
    if [[ "$config_file" == *.yaml ]] || [[ "$config_file" == *.yml ]]; then
        if ! validate_yaml_syntax "$config_file"; then
            record_config_error "YAML语法错误: $config_file"
            return 1
        fi
    fi
    
    # 根据配置类型进行特定验证
    case "$config_type" in
        "main")
            validate_main_config "$config_file"
            ;;
        "wireguard")
            validate_wireguard_config "$config_file"
            ;;
        "bird")
            validate_bird_config "$config_file"
            ;;
        "firewall")
            validate_firewall_config "$config_file"
            ;;
        "client")
            validate_client_config "$config_file"
            ;;
        "monitoring")
            validate_monitoring_config "$config_file"
            ;;
        *)
            log_warn "未知的配置类型: $config_type"
            ;;
    esac
    
    # 检查错误统计
    if [[ $IPV6WGM_CONFIG_ERROR_COUNT -gt 0 ]]; then
        log_error "配置验证失败，发现 $IPV6WGM_CONFIG_ERROR_COUNT 个错误"
        return 1
    fi
    
    log_success "配置验证通过"
    return 0
}

# 验证YAML语法
validate_yaml_syntax() {
    local config_file="$1"
    
    # 检查yq工具是否可用
    if command -v yq &> /dev/null; then
        if yq eval '.' "$config_file" > /dev/null 2>&1; then
            log_info "YAML语法验证通过: $config_file"
            return 0
        else
            record_config_error "YAML语法错误: $config_file"
            return 1
        fi
    else
        log_warn "yq工具未安装，跳过YAML语法验证"
        return 0
    fi
}

# 验证主配置
validate_main_config() {
    local config_file="$1"
    
    log_info "验证主配置: $config_file"
    
    # 检查必需的配置项
    local required_keys=(
        "SYSTEM_NAME"
        "SYSTEM_VERSION"
        "NETWORK_IPV6_PREFIX"
        "WIREGUARD_ENABLED"
        "BIRD_ENABLED"
        "FIREWALL_ENABLED"
    )
    
    for key in "${required_keys[@]}"; do
        if ! grep -q "^${key}=" "$config_file"; then
            record_config_error "缺少必需的配置项: $key"
        fi
    done
    
    # 验证网络配置
    if grep -q "^NETWORK_IPV6_PREFIX=" "$config_file"; then
        local prefix=$(grep "^NETWORK_IPV6_PREFIX=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        if ! validate_ipv6_prefix "$prefix"; then
            record_config_error "无效的IPv6前缀: $prefix"
        fi
    fi
    
    # 验证端口配置
    if grep -q "^WIREGUARD_PORT=" "$config_file"; then
        local port=$(grep "^WIREGUARD_PORT=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        if ! validate_port "$port"; then
            record_config_error "无效的端口号: $port"
        fi
    fi
    
    log_info "主配置验证完成"
}

# 验证WireGuard配置
validate_wireguard_config() {
    local config_file="$1"
    
    log_info "验证WireGuard配置: $config_file"
    
    # 这里添加WireGuard配置验证逻辑
    # 检查接口名称、端口、密钥格式等
    
    log_info "WireGuard配置验证完成"
}

# 验证BIRD配置
validate_bird_config() {
    local config_file="$1"
    
    log_info "验证BIRD配置: $config_file"
    
    # 这里添加BIRD配置验证逻辑
    # 检查BGP配置、邻居配置等
    
    log_info "BIRD配置验证完成"
}

# 验证防火墙配置
validate_firewall_config() {
    local config_file="$1"
    
    log_info "验证防火墙配置: $config_file"
    
    # 这里添加防火墙配置验证逻辑
    # 检查规则格式、端口配置等
    
    log_info "防火墙配置验证完成"
}

# 验证客户端配置
validate_client_config() {
    local config_file="$1"
    
    log_info "验证客户端配置: $config_file"
    
    # 这里添加客户端配置验证逻辑
    # 检查客户端信息、网络配置等
    
    log_info "客户端配置验证完成"
}

# 验证监控配置
validate_monitoring_config() {
    local config_file="$1"
    
    log_info "验证监控配置: $config_file"
    
    # 这里添加监控配置验证逻辑
    # 检查监控指标、告警规则等
    
    log_info "监控配置验证完成"
}

# ================================================================
# 辅助验证函数
# ================================================================

# 验证IPv6前缀
validate_ipv6_prefix() {
    local prefix="$1"
    
    # 检查IPv6前缀格式
    if [[ "$prefix" =~ ^[0-9a-fA-F:]+/[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# 验证端口号
validate_port() {
    local port="$1"
    
    # 检查端口号范围
    if [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}

# ================================================================
# 错误处理函数
# ================================================================

# 记录配置错误
record_config_error() {
    local error_msg="$1"
    IPV6WGM_CONFIG_ERROR_COUNT=$((IPV6WGM_CONFIG_ERROR_COUNT + 1))
    IPV6WGM_CONFIG_ERRORS["error_$IPV6WGM_CONFIG_ERROR_COUNT"]="$error_msg"
    log_error "$error_msg"
}

# 记录配置警告
record_config_warning() {
    local warning_msg="$1"
    IPV6WGM_CONFIG_WARNING_COUNT=$((IPV6WGM_CONFIG_WARNING_COUNT + 1))
    IPV6WGM_CONFIG_WARNINGS["warning_$IPV6WGM_CONFIG_WARNING_COUNT"]="$warning_msg"
    log_warn "$warning_msg"
}

# 获取配置错误统计
get_config_error_stats() {
    echo "错误数量: $IPV6WGM_CONFIG_ERROR_COUNT"
    echo "警告数量: $IPV6WGM_CONFIG_WARNING_COUNT"
    
    if [[ $IPV6WGM_CONFIG_ERROR_COUNT -gt 0 ]]; then
        echo "错误列表:"
        for key in "${!IPV6WGM_CONFIG_ERRORS[@]}"; do
            echo "  - ${IPV6WGM_CONFIG_ERRORS[$key]}"
        done
    fi
    
    if [[ $IPV6WGM_CONFIG_WARNING_COUNT -gt 0 ]]; then
        echo "警告列表:"
        for key in "${!IPV6WGM_CONFIG_WARNINGS[@]}"; do
            echo "  - ${IPV6WGM_CONFIG_WARNINGS[$key]}"
        done
    fi
}

# 清除配置错误
clear_config_errors() {
    IPV6WGM_CONFIG_ERROR_COUNT=0
    IPV6WGM_CONFIG_WARNING_COUNT=0
    IPV6WGM_CONFIG_ERRORS=()
    IPV6WGM_CONFIG_WARNINGS=()
    log_info "配置错误已清除"
}

# ================================================================
# 导出函数
# ================================================================

# 导出所有配置管理函数
export -f init_config_manager init_config_version_db create_default_config
export -f create_yaml_config_templates create_main_config_template create_wireguard_config_template
export -f create_bird_config_template create_firewall_config_template create_client_config_template
export -f create_monitoring_config_template load_config_to_cache is_config_cache_valid
export -f update_cache_timestamp clear_config_cache cache_config_item get_cached_config_item
export -f validate_config validate_yaml_syntax validate_main_config validate_wireguard_config
export -f validate_bird_config validate_firewall_config validate_client_config validate_monitoring_config
export -f validate_ipv6_prefix validate_port record_config_error record_config_warning
export -f get_config_error_stats clear_config_errors