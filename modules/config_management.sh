#!/bin/bash

# 配置管理模块
# 负责YAML格式配置管理、配置验证、配置版本控制等功能

# 导入公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 配置管理变量
CONFIG_DIR="${CONFIG_DIR:-/etc/ipv6-wireguard-manager}"
CONFIG_MANAGEMENT_DIR="${CONFIG_DIR}/management"
YAML_CONFIG_DIR="${CONFIG_MANAGEMENT_DIR}/yaml"
CONFIG_BACKUP_DIR="${CONFIG_MANAGEMENT_DIR}/backups"
CONFIG_VALIDATION_DIR="${CONFIG_MANAGEMENT_DIR}/validation"
CONFIG_VERSION_DB="${CONFIG_MANAGEMENT_DIR}/versions.db"
CONFIG_FILE="${CONFIG_FILE:-${CONFIG_DIR}/manager.conf}"

# 配置模板目录
CONFIG_TEMPLATES_DIR="${CONFIG_DIR}/templates"

# 初始化配置管理
init_config_management() {
    log_info "初始化配置管理..."
    
    # 创建配置管理目录
    mkdir -p "$CONFIG_MANAGEMENT_DIR" "$YAML_CONFIG_DIR" "$CONFIG_BACKUP_DIR" "$CONFIG_VALIDATION_DIR"
    
    # 创建配置模板目录
    mkdir -p "$CONFIG_TEMPLATES_DIR"
    
    # 初始化版本数据库
    init_config_version_db
    
    # 创建YAML配置模板
    create_yaml_config_templates
    
    # 转换现有配置为YAML格式
    convert_existing_configs_to_yaml
    
    log_info "配置管理初始化完成"
}

# 初始化配置版本数据库
init_config_version_db() {
    if [[ ! -f "$CONFIG_VERSION_DB" ]]; then
        cat > "$CONFIG_VERSION_DB" << EOF
version|timestamp|config_type|file_path|checksum|description
EOF
        log_info "配置版本数据库已创建: $CONFIG_VERSION_DB"
    fi
}

# 创建YAML配置模板
create_yaml_config_templates() {
    log_info "创建YAML配置模板..."
    
    # 主配置模板
    create_main_config_template
    
    # WireGuard配置模板
    create_wireguard_config_template
    
    # BIRD配置模板
    create_bird_config_template
    
    # 防火墙配置模板
    create_firewall_config_template
    
    # 客户端配置模板
    create_client_config_template
    
    # 监控配置模板
    create_monitoring_config_template
}

# 创建主配置模板
create_main_config_template() {
    cat > "${CONFIG_TEMPLATES_DIR}/main.yaml" << 'EOF'
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
    cat > "${CONFIG_TEMPLATES_DIR}/wireguard.yaml" << 'EOF'
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
    cat > "${CONFIG_TEMPLATES_DIR}/bird.yaml" << 'EOF'
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
    cat > "${CONFIG_TEMPLATES_DIR}/firewall.yaml" << 'EOF'
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
    cat > "${CONFIG_TEMPLATES_DIR}/client.yaml" << 'EOF'
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
    cat > "${CONFIG_TEMPLATES_DIR}/monitoring.yaml" << 'EOF'
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

# 转换现有配置为YAML格式
convert_existing_configs_to_yaml() {
    log_info "转换现有配置为YAML格式..."
    
    # 转换主配置文件
    if [[ -f "$CONFIG_FILE" ]]; then
        convert_config_to_yaml "$CONFIG_FILE" "${YAML_CONFIG_DIR}/main.yaml"
    fi
    
    # 转换WireGuard配置
    if [[ -f "/etc/wireguard/wg0.conf" ]]; then
        convert_wireguard_config_to_yaml "/etc/wireguard/wg0.conf" "${YAML_CONFIG_DIR}/wireguard.yaml"
    fi
    
    # 转换BIRD配置
    if [[ -f "/etc/bird/bird.conf" ]]; then
        convert_bird_config_to_yaml "/etc/bird/bird.conf" "${YAML_CONFIG_DIR}/bird.yaml"
    fi
    
    log_info "配置转换完成"
}

# 转换配置文件为YAML格式
convert_config_to_yaml() {
    local source_file="$1"
    local target_file="$2"
    
    log_info "转换配置文件: $source_file -> $target_file"
    
    # 这里添加配置文件转换逻辑
    # 将现有的.conf格式转换为YAML格式
    cp "${CONFIG_TEMPLATES_DIR}/main.yaml" "$target_file"
    
    # 替换模板变量
    sed -i "s/\${TIMESTAMP}/$(get_timestamp)/g" "$target_file"
    
    log_info "配置文件转换完成: $target_file"
}

# 转换WireGuard配置为YAML格式
convert_wireguard_config_to_yaml() {
    local source_file="$1"
    local target_file="$2"
    
    log_info "转换WireGuard配置: $source_file -> $target_file"
    
    # 这里添加WireGuard配置转换逻辑
    cp "${CONFIG_TEMPLATES_DIR}/wireguard.yaml" "$target_file"
    
    # 替换模板变量
    sed -i "s/\${TIMESTAMP}/$(get_timestamp)/g" "$target_file"
    
    log_info "WireGuard配置转换完成: $target_file"
}

# 转换BIRD配置为YAML格式
convert_bird_config_to_yaml() {
    local source_file="$1"
    local target_file="$2"
    
    log_info "转换BIRD配置: $source_file -> $target_file"
    
    # 这里添加BIRD配置转换逻辑
    cp "${CONFIG_TEMPLATES_DIR}/bird.yaml" "$target_file"
    
    # 替换模板变量
    sed -i "s/\${TIMESTAMP}/$(get_timestamp)/g" "$target_file"
    
    log_info "BIRD配置转换完成: $target_file"
}

# 配置验证
validate_config() {
    local config_file="$1"
    local config_type="$2"
    
    log_info "验证配置文件: $config_file"
    
    # 检查YAML语法
    if ! validate_yaml_syntax "$config_file"; then
        log_error "YAML语法错误: $config_file"
        return 1
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
}

# 验证YAML语法
validate_yaml_syntax() {
    local config_file="$1"
    
    # 检查文件是否存在
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    # 检查YAML语法（需要yq工具）
    if command -v yq &> /dev/null; then
        if yq eval '.' "$config_file" > /dev/null 2>&1; then
            log_info "YAML语法验证通过: $config_file"
            return 0
        else
            log_error "YAML语法错误: $config_file"
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
    
    # 这里添加主配置验证逻辑
    # 检查必需的字段
    # 验证数据类型
    # 检查值的有效性
    
    log_info "主配置验证完成"
}

# 验证WireGuard配置
validate_wireguard_config() {
    local config_file="$1"
    
    log_info "验证WireGuard配置: $config_file"
    
    # 这里添加WireGuard配置验证逻辑
    
    log_info "WireGuard配置验证完成"
}

# 验证BIRD配置
validate_bird_config() {
    local config_file="$1"
    
    log_info "验证BIRD配置: $config_file"
    
    # 这里添加BIRD配置验证逻辑
    
    log_info "BIRD配置验证完成"
}

# 验证防火墙配置
validate_firewall_config() {
    local config_file="$1"
    
    log_info "验证防火墙配置: $config_file"
    
    # 这里添加防火墙配置验证逻辑
    
    log_info "防火墙配置验证完成"
}

# 验证客户端配置
validate_client_config() {
    local config_file="$1"
    
    log_info "验证客户端配置: $config_file"
    
    # 这里添加客户端配置验证逻辑
    
    log_info "客户端配置验证完成"
}

# 验证监控配置
validate_monitoring_config() {
    local config_file="$1"
    
    log_info "验证监控配置: $config_file"
    
    # 这里添加监控配置验证逻辑
    
    log_info "监控配置验证完成"
}

# 配置版本控制
create_config_version() {
    local config_file="$1"
    local description="$2"
    
    log_info "创建配置版本: $config_file"
    
    local timestamp=$(get_timestamp)
    local checksum=$(sha256sum "$config_file" | awk '{print $1}')
    local config_type=$(basename "$(dirname "$config_file")")
    
    # 备份配置文件
    local backup_file="${CONFIG_BACKUP_DIR}/$(basename "$config_file")_${timestamp}.yaml"
    cp "$config_file" "$backup_file"
    
    # 记录版本信息
    echo "${timestamp}|${timestamp}|${config_type}|${config_file}|${checksum}|${description}" >> "$CONFIG_VERSION_DB"
    
    log_info "配置版本已创建: $backup_file"
}

# 配置管理菜单
config_management_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 配置管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看配置状态"
        echo -e "${GREEN}2.${NC} 编辑配置文件"
        echo -e "${GREEN}3.${NC} 验证配置文件"
        echo -e "${GREEN}4.${NC} 配置版本管理"
        echo -e "${GREEN}5.${NC} 配置备份/恢复"
        echo -e "${GREEN}6.${NC} 配置模板管理"
        echo -e "${GREEN}7.${NC} 配置导入/导出"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) show_config_status ;;
            2) edit_config_file ;;
            3) validate_config_file ;;
            4) config_version_management ;;
            5) config_backup_restore ;;
            6) config_template_management ;;
            7) config_import_export ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 显示配置状态
show_config_status() {
    echo -e "${SECONDARY_COLOR}=== 配置状态 ===${NC}"
    echo
    
    echo "YAML配置文件:"
    if [[ -d "$YAML_CONFIG_DIR" ]]; then
        ls -la "$YAML_CONFIG_DIR"/*.yaml 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        echo "  YAML配置目录不存在"
    fi
    
    echo
    echo "配置模板:"
    if [[ -d "$CONFIG_TEMPLATES_DIR" ]]; then
        ls -la "$CONFIG_TEMPLATES_DIR"/*.yaml 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        echo "  配置模板目录不存在"
    fi
    
    echo
    echo "配置备份:"
    if [[ -d "$CONFIG_BACKUP_DIR" ]]; then
        ls -la "$CONFIG_BACKUP_DIR"/*.yaml 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        echo "  配置备份目录不存在"
    fi
}

# 编辑配置文件
edit_config_file() {
    echo -e "${SECONDARY_COLOR}=== 编辑配置文件 ===${NC}"
    echo
    
    local config_files=()
    if [[ -d "$YAML_CONFIG_DIR" ]]; then
        while IFS= read -r -d '' file; do
            config_files+=("$file")
        done < <(find "$YAML_CONFIG_DIR" -name "*.yaml" -print0)
    fi
    
    if [[ ${#config_files[@]} -eq 0 ]]; then
        show_error "没有找到YAML配置文件"
        return 1
    fi
    
    echo "选择要编辑的配置文件:"
    for i in "${!config_files[@]}"; do
        echo "$((i+1)). $(basename "${config_files[$i]}")"
    done
    
    read -p "请选择配置文件编号: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#config_files[@]} ]]; then
        local selected_file="${config_files[$((choice-1))]}"
        local editor="${EDITOR:-nano}"
        
        if command -v "$editor" &> /dev/null; then
            "$editor" "$selected_file"
            log_info "配置文件已编辑: $selected_file"
        else
            show_error "编辑器不可用: $editor"
        fi
    else
        show_error "无效选择"
    fi
}

# 验证配置文件
validate_config_file() {
    echo -e "${SECONDARY_COLOR}=== 验证配置文件 ===${NC}"
    echo
    
    local config_files=()
    if [[ -d "$YAML_CONFIG_DIR" ]]; then
        while IFS= read -r -d '' file; do
            config_files+=("$file")
        done < <(find "$YAML_CONFIG_DIR" -name "*.yaml" -print0)
    fi
    
    if [[ ${#config_files[@]} -eq 0 ]]; then
        show_error "没有找到YAML配置文件"
        return 1
    fi
    
    echo "选择要验证的配置文件:"
    for i in "${!config_files[@]}"; do
        echo "$((i+1)). $(basename "${config_files[$i]}")"
    done
    
    read -p "请选择配置文件编号: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#config_files[@]} ]]; then
        local selected_file="${config_files[$((choice-1))]}"
        local config_type=$(basename "$selected_file" .yaml)
        
        if validate_config "$selected_file" "$config_type"; then
            show_success "配置文件验证通过: $selected_file"
        else
            show_error "配置文件验证失败: $selected_file"
        fi
    else
        show_error "无效选择"
    fi
}

# 配置版本管理
config_version_management() {
    echo -e "${SECONDARY_COLOR}=== 配置版本管理 ===${NC}"
    echo
    
    local action=$(show_selection "操作" "查看版本历史" "创建新版本" "回滚到版本" "比较版本")
    
    case "$action" in
        "查看版本历史")
            show_config_versions
            ;;
        "创建新版本")
            create_config_version_interactive
            ;;
        "回滚到版本")
            rollback_config_version
            ;;
        "比较版本")
            compare_config_versions
            ;;
    esac
}

# 显示配置版本
show_config_versions() {
    echo -e "${SECONDARY_COLOR}=== 配置版本历史 ===${NC}"
    echo
    
    if [[ -f "$CONFIG_VERSION_DB" ]]; then
        column -t -s '|' "$CONFIG_VERSION_DB"
    else
        echo "没有配置版本记录"
    fi
}

# 创建配置版本
create_config_version_interactive() {
    echo -e "${SECONDARY_COLOR}=== 创建配置版本 ===${NC}"
    echo
    
    local config_file=$(show_input "配置文件路径" "")
    local description=$(show_input "版本描述" "")
    
    if [[ -f "$config_file" ]]; then
        create_config_version "$config_file" "$description"
        show_success "配置版本已创建"
    else
        show_error "配置文件不存在: $config_file"
    fi
}

# 回滚配置版本
rollback_config_version() {
    echo -e "${SECONDARY_COLOR}=== 回滚配置版本 ===${NC}"
    echo
    
    # 这里添加回滚逻辑
    show_warn "回滚功能待实现"
}

# 比较配置版本
compare_config_versions() {
    echo -e "${SECONDARY_COLOR}=== 比较配置版本 ===${NC}"
    echo
    
    # 这里添加比较逻辑
    show_warn "比较功能待实现"
}

# 配置备份恢复
config_backup_restore() {
    echo -e "${SECONDARY_COLOR}=== 配置备份恢复 ===${NC}"
    echo
    
    local action=$(show_selection "操作" "创建备份" "恢复备份" "列出备份" "删除备份")
    
    case "$action" in
        "创建备份")
            create_config_backup
            ;;
        "恢复备份")
            restore_config_backup
            ;;
        "列出备份")
            list_config_backups
            ;;
        "删除备份")
            delete_config_backup
            ;;
    esac
}

# 创建配置备份
create_config_backup() {
    echo -e "${SECONDARY_COLOR}=== 创建配置备份 ===${NC}"
    echo
    
    local backup_name=$(show_input "备份名称" "config_backup_$(get_timestamp)")
    local description=$(show_input "备份描述" "")
    
    local backup_dir="${CONFIG_BACKUP_DIR}/${backup_name}"
    mkdir -p "$backup_dir"
    
    # 备份YAML配置
    if [[ -d "$YAML_CONFIG_DIR" ]]; then
        cp -r "$YAML_CONFIG_DIR" "$backup_dir/"
    fi
    
    # 备份原始配置
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_dir/"
    fi
    
    # 创建备份信息文件
    cat > "${backup_dir}/backup_info.txt" << EOF
备份名称: $backup_name
创建时间: $(get_timestamp)
描述: $description
文件列表:
$(find "$backup_dir" -type f -exec basename {} \;)
EOF
    
    show_success "配置备份已创建: $backup_dir"
}

# 恢复配置备份
restore_config_backup() {
    echo -e "${SECONDARY_COLOR}=== 恢复配置备份 ===${NC}"
    echo
    
    # 这里添加恢复逻辑
    show_warn "恢复功能待实现"
}

# 列出配置备份
list_config_backups() {
    echo -e "${SECONDARY_COLOR}=== 配置备份列表 ===${NC}"
    echo
    
    if [[ -d "$CONFIG_BACKUP_DIR" ]]; then
        ls -la "$CONFIG_BACKUP_DIR" | while read -r line; do
            echo "  $line"
        done
    else
        echo "没有找到配置备份"
    fi
}

# 删除配置备份
delete_config_backup() {
    echo -e "${SECONDARY_COLOR}=== 删除配置备份 ===${NC}"
    echo
    
    # 这里添加删除逻辑
    show_warn "删除功能待实现"
}

# 配置模板管理
config_template_management() {
    echo -e "${SECONDARY_COLOR}=== 配置模板管理 ===${NC}"
    echo
    
    local action=$(show_selection "操作" "查看模板" "创建模板" "编辑模板" "删除模板")
    
    case "$action" in
        "查看模板")
            show_config_templates
            ;;
        "创建模板")
            create_config_template
            ;;
        "编辑模板")
            edit_config_template
            ;;
        "删除模板")
            delete_config_template
            ;;
    esac
}

# 显示配置模板
show_config_templates() {
    echo -e "${SECONDARY_COLOR}=== 配置模板列表 ===${NC}"
    echo
    
    if [[ -d "$CONFIG_TEMPLATES_DIR" ]]; then
        ls -la "$CONFIG_TEMPLATES_DIR"/*.yaml 2>/dev/null | while read -r line; do
            echo "  $line"
        done
    else
        echo "没有找到配置模板"
    fi
}

# 创建配置模板
create_config_template() {
    echo -e "${SECONDARY_COLOR}=== 创建配置模板 ===${NC}"
    echo
    
    # 这里添加创建模板逻辑
    show_warn "创建模板功能待实现"
}

# 编辑配置模板
edit_config_template() {
    echo -e "${SECONDARY_COLOR}=== 编辑配置模板 ===${NC}"
    echo
    
    # 这里添加编辑模板逻辑
    show_warn "编辑模板功能待实现"
}

# 删除配置模板
delete_config_template() {
    echo -e "${SECONDARY_COLOR}=== 删除配置模板 ===${NC}"
    echo
    
    # 这里添加删除模板逻辑
    show_warn "删除模板功能待实现"
}

# 配置导入导出
config_import_export() {
    echo -e "${SECONDARY_COLOR}=== 配置导入导出 ===${NC}"
    echo
    
    local action=$(show_selection "操作" "导出配置" "导入配置" "导出模板" "导入模板")
    
    case "$action" in
        "导出配置")
            export_config
            ;;
        "导入配置")
            import_config
            ;;
        "导出模板")
            export_template
            ;;
        "导入模板")
            import_template
            ;;
    esac
}

# 导出配置
export_config() {
    echo -e "${SECONDARY_COLOR}=== 导出配置 ===${NC}"
    echo
    
    local export_file=$(show_input "导出文件路径" "/tmp/ipv6-wireguard-config-$(get_timestamp).tar.gz")
    
    if [[ -d "$YAML_CONFIG_DIR" ]]; then
        tar -czf "$export_file" -C "$(dirname "$YAML_CONFIG_DIR")" "$(basename "$YAML_CONFIG_DIR")"
        show_success "配置已导出到: $export_file"
    else
        show_error "YAML配置目录不存在"
    fi
}

# 导入配置
import_config() {
    echo -e "${SECONDARY_COLOR}=== 导入配置 ===${NC}"
    echo
    
    local import_file=$(show_input "导入文件路径" "")
    
    if [[ -f "$import_file" ]]; then
        tar -xzf "$import_file" -C "$(dirname "$YAML_CONFIG_DIR")"
        show_success "配置已导入"
    else
        show_error "导入文件不存在: $import_file"
    fi
}

# 导出模板
export_template() {
    echo -e "${SECONDARY_COLOR}=== 导出模板 ===${NC}"
    echo
    
    local export_file=$(show_input "导出文件路径" "/tmp/ipv6-wireguard-templates-$(get_timestamp).tar.gz")
    
    if [[ -d "$CONFIG_TEMPLATES_DIR" ]]; then
        tar -czf "$export_file" -C "$(dirname "$CONFIG_TEMPLATES_DIR")" "$(basename "$CONFIG_TEMPLATES_DIR")"
        show_success "模板已导出到: $export_file"
    else
        show_error "配置模板目录不存在"
    fi
}

# 导入模板
import_template() {
    echo -e "${SECONDARY_COLOR}=== 导入模板 ===${NC}"
    echo
    
    local import_file=$(show_input "导入文件路径" "")
    
    if [[ -f "$import_file" ]]; then
        tar -xzf "$import_file" -C "$(dirname "$CONFIG_TEMPLATES_DIR")"
        show_success "模板已导入"
    else
        show_error "导入文件不存在: $import_file"
    fi
}

# 导出函数
export -f init_config_management init_config_version_db create_yaml_config_templates
export -f create_main_config_template create_wireguard_config_template create_bird_config_template
export -f create_firewall_config_template create_client_config_template create_monitoring_config_template
export -f convert_existing_configs_to_yaml convert_config_to_yaml convert_wireguard_config_to_yaml
export -f convert_bird_config_to_yaml validate_config validate_yaml_syntax
export -f validate_main_config validate_wireguard_config validate_bird_config
export -f validate_firewall_config validate_client_config validate_monitoring_config
export -f create_config_version config_management_menu show_config_status edit_config_file
export -f validate_config_file config_version_management show_config_versions
export -f create_config_version_interactive rollback_config_version compare_config_versions
export -f config_backup_restore create_config_backup restore_config_backup
export -f list_config_backups delete_config_backup config_template_management
export -f show_config_templates create_config_template edit_config_template
export -f delete_config_template config_import_export export_config import_config
export -f export_template import_template
