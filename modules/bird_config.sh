#!/bin/bash

# BIRD BGP配置模块
# 用于配置和管理BIRD BGP路由服务
# 支持BIRD 2.x和3.x版本兼容性
# 版本: 1.13

# 加载公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# 全局变量
BIRD_VERSION=""
BIRD_MAJOR_VERSION=""
BIRD_CONFIG_TEMPLATE=""

# BGP配置参数
BGP_ROUTER_ID=""
BGP_AS_NUMBER=""
BGP_NEIGHBORS=""
BGP_PASSWORDS=""
BGP_UPSTREAM_ASN=""
BGP_MULTIHOP=""
BGP_IPV6_PREFIXES=""

# 检测BIRD版本
detect_bird_version() {
    log "INFO" "Detecting BIRD version..."
    
    if command -v bird >/dev/null 2>&1; then
        # 尝试获取BIRD版本信息
        local version_output=$(bird --version 2>&1 || echo "")
        
        if [[ "$version_output" =~ BIRD[[:space:]]+([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
            BIRD_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            BIRD_MAJOR_VERSION="${BASH_REMATCH[1]}"
            log "INFO" "Detected BIRD version: $BIRD_VERSION"
        elif [[ "$version_output" =~ BIRD[[:space:]]+([0-9]+)\.([0-9]+) ]]; then
            BIRD_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
            BIRD_MAJOR_VERSION="${BASH_REMATCH[1]}"
            log "INFO" "Detected BIRD version: $BIRD_VERSION"
        else
            # 尝试从包管理器获取版本信息
            if command -v dpkg >/dev/null 2>&1; then
                local dpkg_version=$(dpkg -l | grep -E '^ii[[:space:]]+bird[0-9]*' | awk '{print $3}' | head -1)
                if [[ -n "$dpkg_version" ]]; then
                    BIRD_VERSION="$dpkg_version"
                    BIRD_MAJOR_VERSION=$(echo "$dpkg_version" | cut -d'.' -f1)
                    log "INFO" "Detected BIRD version from dpkg: $BIRD_VERSION"
                fi
            elif command -v rpm >/dev/null 2>&1; then
                local rpm_version=$(rpm -q bird 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
                if [[ -n "$rpm_version" ]]; then
                    BIRD_VERSION="$rpm_version"
                    BIRD_MAJOR_VERSION=$(echo "$rpm_version" | cut -d'.' -f1)
                    log "INFO" "Detected BIRD version from rpm: $BIRD_VERSION"
                fi
            fi
        fi
        
        # 如果仍然无法检测版本，尝试从可执行文件路径推断
        if [[ -z "$BIRD_VERSION" ]]; then
            if command -v bird2 >/dev/null 2>&1; then
                BIRD_MAJOR_VERSION="2"
                BIRD_VERSION="2.x"
                log "INFO" "Detected BIRD 2.x from bird2 command"
            elif command -v bird6 >/dev/null 2>&1; then
                BIRD_MAJOR_VERSION="1"
                BIRD_VERSION="1.x"
                log "WARN" "Detected BIRD 1.x (legacy version)"
            else
                BIRD_MAJOR_VERSION="2"
                BIRD_VERSION="2.x"
                log "WARN" "Could not detect BIRD version, assuming 2.x"
            fi
        fi
    else
        log "ERROR" "BIRD is not installed or not in PATH"
        return 1
    fi
    
    # 设置配置模板
    case "$BIRD_MAJOR_VERSION" in
        "1")
            BIRD_CONFIG_TEMPLATE="bird_v1"
            log "WARN" "BIRD 1.x is legacy and may not be fully supported"
            ;;
        "2")
            BIRD_CONFIG_TEMPLATE="bird_v2"
            log "INFO" "Using BIRD 2.x configuration template"
            ;;
        "3")
            BIRD_CONFIG_TEMPLATE="bird_v3"
            log "INFO" "Using BIRD 3.x configuration template"
            ;;
        *)
            BIRD_CONFIG_TEMPLATE="bird_v2"
            log "WARN" "Unknown BIRD version, using 2.x template"
            ;;
    esac
    
    return 0
}

# 交互式BGP配置
interactive_bgp_config() {
    echo -e "${CYAN}=== BGP配置设置 ===${NC}"
    
    # 路由器ID配置
    echo
    echo -e "${YELLOW}1. 路由器ID配置${NC}"
    local default_router_id=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    if [[ -z "$default_router_id" ]]; then
        default_router_id="10.0.0.1"
    fi
    
    while true; do
        read -p "请输入路由器ID (默认: $default_router_id): " router_id
        router_id="${router_id:-$default_router_id}"
        
        if [[ "$router_id" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            BGP_ROUTER_ID="$router_id"
            echo -e "${GREEN}✓${NC} 路由器ID设置为: $router_id"
            break
        else
            echo -e "${RED}错误: 请输入有效的IPv4地址作为路由器ID${NC}"
        fi
    done
    
    # AS号配置
    echo
    echo -e "${YELLOW}2. AS号配置${NC}"
    local default_as="65001"
    
    while true; do
        read -p "请输入AS号 (默认: $default_as): " as_number
        as_number="${as_number:-$default_as}"
        
        # 清理输入，只保留数字
        as_number=$(echo "$as_number" | tr -d '[:alpha:][:punct:][:space:]')
        
        if [[ "$as_number" =~ ^[0-9]+$ ]] && [[ "$as_number" -ge 1 ]] && [[ "$as_number" -le 4294967295 ]]; then
            BGP_AS_NUMBER="$as_number"
            echo -e "${GREEN}✓${NC} AS号设置为: $as_number"
            break
        else
            echo -e "${RED}错误: 请输入有效的AS号 (1-4294967295)${NC}"
        fi
    done
    
    # 上游ASN配置
    echo
    echo -e "${YELLOW}3. 上游ASN配置${NC}"
    local default_upstream_as="65000"
    
    while true; do
        read -p "请输入上游ASN (默认: $default_upstream_as): " upstream_as
        upstream_as="${upstream_as:-$default_upstream_as}"
        
        # 清理输入，只保留数字
        upstream_as=$(echo "$upstream_as" | tr -d '[:alpha:][:punct:][:space:]')
        
        if [[ "$upstream_as" =~ ^[0-9]+$ ]] && [[ "$upstream_as" -ge 1 ]] && [[ "$upstream_as" -le 4294967295 ]]; then
            BGP_UPSTREAM_ASN="$upstream_as"
            echo -e "${GREEN}✓${NC} 上游ASN设置为: $upstream_as"
            break
        else
            echo -e "${RED}错误: 请输入有效的上游ASN (1-4294967295)${NC}"
        fi
    done
    
    # BGP邻居配置
    echo
    echo -e "${YELLOW}4. BGP邻居配置${NC}"
    echo "请输入BGP邻居信息 (格式: 名称,IP地址,AS号,密码,描述)"
    echo "示例: upstream1,2001:db8::1,65000,password123,主要上游"
    echo "留空结束输入"
    
    local neighbors=()
    local neighbor_count=0
    
    while true; do
        read -p "邻居 $((neighbor_count + 1)): " neighbor_input
        
        if [[ -z "$neighbor_input" ]]; then
            break
        fi
        
        # 解析邻居信息
        IFS=',' read -ra neighbor_parts <<< "$neighbor_input"
        if [[ ${#neighbor_parts[@]} -ge 3 ]]; then
            local name="${neighbor_parts[0]}"
            local ip="${neighbor_parts[1]}"
            local as="${neighbor_parts[2]}"
            local password="${neighbor_parts[3]:-}"
            local description="${neighbor_parts[4]:-}"
            
            # 验证IP地址
            if [[ "$ip" =~ ^[0-9a-fA-F:]+$ ]] || [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                # 验证AS号
                local clean_as=$(echo "$as" | tr -d '[:alpha:][:punct:][:space:]')
                if [[ "$clean_as" =~ ^[0-9]+$ ]] && [[ "$clean_as" -ge 1 ]] && [[ "$clean_as" -le 4294967295 ]]; then
                    neighbors+=("$name,$ip,$clean_as,$password,$description")
                    neighbor_count=$((neighbor_count + 1))
                    echo -e "${GREEN}✓${NC} 邻居 $name 添加成功"
                else
                    echo -e "${RED}错误: 无效的AS号: $as${NC}"
                fi
            else
                echo -e "${RED}错误: 无效的IP地址: $ip${NC}"
            fi
        else
            echo -e "${RED}错误: 格式不正确，需要至少包含: 名称,IP地址,AS号${NC}"
        fi
    done
    
    BGP_NEIGHBORS=$(IFS='|'; echo "${neighbors[*]}")
    echo -e "${GREEN}✓${NC} 共添加 $neighbor_count 个BGP邻居"
    
    # Multihop配置
    echo
    echo -e "${YELLOW}5. Multihop配置${NC}"
    echo "是否启用BGP multihop? (用于非直连的BGP邻居)"
    read -p "启用multihop? (y/N): " enable_multihop
    
    if [[ "${enable_multihop,,}" == "y" ]]; then
        BGP_MULTIHOP="yes"
        echo -e "${GREEN}✓${NC} 已启用BGP multihop"
    else
        BGP_MULTIHOP="no"
        echo -e "${GREEN}✓${NC} 未启用BGP multihop"
    fi
    
    # IPv6前缀配置
    echo
    echo -e "${YELLOW}6. IPv6前缀配置${NC}"
    local default_prefix="2001:db8::/48"
    
    while true; do
        read -p "请输入要宣告的IPv6前缀 (默认: $default_prefix): " ipv6_prefix
        ipv6_prefix="${ipv6_prefix:-$default_prefix}"
        
        if [[ "$ipv6_prefix" =~ ^[0-9a-fA-F:]+/[0-9]{1,3}$ ]]; then
            BGP_IPV6_PREFIXES="$ipv6_prefix"
            echo -e "${GREEN}✓${NC} IPv6前缀设置为: $ipv6_prefix"
            break
        else
            echo -e "${RED}错误: 请输入有效的IPv6前缀 (格式: 2001:db8::/48)${NC}"
        fi
    done
    
    echo
    echo -e "${GREEN}=== BGP配置完成 ===${NC}"
    echo "路由器ID: $BGP_ROUTER_ID"
    echo "AS号: $BGP_AS_NUMBER"
    echo "上游ASN: $BGP_UPSTREAM_ASN"
    echo "邻居数量: $neighbor_count"
    echo "Multihop: $BGP_MULTIHOP"
    echo "IPv6前缀: $BGP_IPV6_PREFIXES"
}

# 获取BIRD可执行文件路径
get_bird_executable() {
    if [[ "$BIRD_MAJOR_VERSION" == "2" ]] && command -v bird2 >/dev/null 2>&1; then
        echo "bird2"
    elif [[ "$BIRD_MAJOR_VERSION" == "3" ]] && command -v bird >/dev/null 2>&1; then
        echo "bird"
    elif command -v bird >/dev/null 2>&1; then
        echo "bird"
    elif command -v bird2 >/dev/null 2>&1; then
        echo "bird2"
    else
        echo "bird"
    fi
}

# 获取BIRD控制命令路径
get_bird_control() {
    local bird_cmd=$(get_bird_executable)
    case "$bird_cmd" in
        "bird2")
            echo "birdc2"
            ;;
        "bird6")
            echo "birdc6"
            ;;
        "bird")
            echo "birdc"
            ;;
        *)
            echo "birdc"
            ;;
    esac
}

# 创建BIRD主配置文件
create_bird_config() {
    local config_file="$1"
    local router_id="$2"
    local as_number="$3"
    local ipv6_prefixes="$4"
    
    # 检测BIRD版本
    if ! detect_bird_version; then
        log "ERROR" "Failed to detect BIRD version"
        return 1
    fi
    
    log "INFO" "Creating BIRD configuration for version $BIRD_VERSION"
    
    # 根据版本生成不同的配置
    case "$BIRD_CONFIG_TEMPLATE" in
        "bird_v2")
            create_bird_v2_config "$config_file" "$router_id" "$as_number" "$ipv6_prefixes"
            ;;
        "bird_v3")
            create_bird_v3_config "$config_file" "$router_id" "$as_number" "$ipv6_prefixes"
            ;;
        "bird_v1")
            create_bird_v1_config "$config_file" "$router_id" "$as_number" "$ipv6_prefixes"
            ;;
        *)
            log "WARN" "Unknown BIRD version template, using v2"
            create_bird_v2_config "$config_file" "$router_id" "$as_number" "$ipv6_prefixes"
            ;;
    esac
    
    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "BIRD configuration created: $config_file"
}

# 创建BIRD 2.x配置
create_bird_v2_config() {
    local config_file="$1"
    local router_id="${2:-$BGP_ROUTER_ID}"
    local as_number="${3:-$BGP_AS_NUMBER}"
    local ipv6_prefixes="${4:-$BGP_IPV6_PREFIXES}"
    
    cat > "$config_file" << EOF
# BIRD 2.x BGP Configuration for IPv6 WireGuard
# Generated by IPv6 WireGuard Manager
# Router ID: $router_id
# AS Number: $as_number
# BIRD Version: 2.x

# 路由器ID
router id $router_id;

# 设备协议
protocol device {
    scan time 10;
}

# 内核协议 - 处理路由表
protocol kernel {
    ipv6 {
        import all;
        export all;
    };
    learn;
    scan time 20;
}

# 直连协议 - 处理直连网络
protocol direct {
    ipv6;
    interface "wg0";
}

# BGP协议配置
protocol bgp {
    local as $as_number;
    
    # BGP邻居配置
EOF

    # 添加BGP邻居配置
    if [[ -n "$BGP_NEIGHBORS" ]]; then
        IFS='|' read -ra neighbors <<< "$BGP_NEIGHBORS"
        for neighbor in "${neighbors[@]}"; do
            if [[ -n "$neighbor" ]]; then
                IFS=',' read -ra parts <<< "$neighbor"
                local name="${parts[0]}"
                local ip="${parts[1]}"
                local as="${parts[2]}"
                local password="${parts[3]}"
                local description="${parts[4]}"
                
                cat >> "$config_file" << EOF
    # $description
    neighbor $ip as $as;
EOF
                
                # 添加密码配置（如果提供）
                if [[ -n "$password" ]]; then
                    cat >> "$config_file" << EOF
    password "$password";
EOF
                fi
                
                # 添加multihop配置（如果启用）
                if [[ "$BGP_MULTIHOP" == "yes" ]]; then
                    cat >> "$config_file" << EOF
    multihop;
EOF
                fi
            fi
        done
    else
        cat >> "$config_file" << EOF
    # 请根据实际情况配置BGP邻居
    # neighbor 2001:db8::1 as 65000;
EOF
    fi
    
    cat >> "$config_file" << EOF
    
    ipv6 {
        import filter bgp_import;
        export filter bgp_export;
    };
    
    # 连接参数
    connect retry time 30;
    hold time 180;
    keepalive time 60;
}

# 静态路由配置
protocol static {
    ipv6;
    
    # 宣告IPv6前缀
EOF

    # 添加IPv6前缀配置
    if [[ -n "$ipv6_prefixes" ]]; then
        IFS=',' read -ra prefixes <<< "$ipv6_prefixes"
        for prefix in "${prefixes[@]}"; do
            if [[ -n "$prefix" ]]; then
                # 计算下一跳地址
                local network=$(echo "$prefix" | cut -d'/' -f1)
                local next_hop="${network%::*}::1"
                cat >> "$config_file" << EOF
    route $prefix via $next_hop;
EOF
            fi
        done
    else
        cat >> "$config_file" << EOF
    # 请根据实际情况配置IPv6前缀
    # route 2001:db8::/48 via 2001:db8::1;
EOF
    fi
    
    cat >> "$config_file" << EOF
}

# 过滤规则
filter bgp_import {
    # 接受所有路由
    accept;
}

filter bgp_export {
    # 导出所有路由
    accept;
}

# 日志配置 (BIRD 2.x 语法)
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log "/var/log/bird/bird.log" { info, remote, warning, error, auth, fatal, bug };
EOF

    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "BIRD 2.x configuration created: $config_file"
}

# 创建BIRD 3.x配置
create_bird_v3_config() {
    local config_file="$1"
    local router_id="$2"
    local as_number="$3"
    local ipv6_prefixes="$4"
    
    cat > "$config_file" << EOF
# BIRD 3.x BGP Configuration for IPv6 WireGuard
# Generated by IPv6 WireGuard Manager
# Router ID: $router_id
# AS Number: $as_number
# BIRD Version: 3.x

# 路由器ID
router id $router_id;

# 设备协议
protocol device {
    scan time 10;
}

# 内核协议 - 处理路由表
protocol kernel {
    ipv6 {
        import all;
        export all;
    };
    learn;
    scan time 20;
}

# 直连协议 - 处理直连网络
protocol direct {
    ipv6;
    interface "wg0";
}

# BGP协议配置
protocol bgp {
    local as $as_number;
    
    # 这里需要根据实际的上游BGP邻居配置
    # neighbor 2001:db8::1 as 65000;
    
    ipv6 {
        import all;
        export all;
    };
    
    # 连接参数
    connect retry time 30;
    connect retry time 60;
    hold time 180;
    keepalive time 60;
}

# 静态路由配置
protocol static {
    ipv6;
    
    # 宣告IPv6前缀
EOF

    # 添加IPv6前缀
    IFS=',' read -ra PREFIXES <<< "$ipv6_prefixes"
    for prefix in "${PREFIXES[@]}"; do
        # 提取网络地址和前缀长度
        local network=$(echo "$prefix" | cut -d'/' -f1)
        local prefix_len=$(echo "$prefix" | cut -d'/' -f2)
        
        # 计算下一跳地址（通常是WireGuard接口的第一个地址）
        local next_hop="${network%::*}::1"
        
        cat >> "$config_file" << EOF
    route $prefix via $next_hop;
EOF
    done

    cat >> "$config_file" << EOF
}

# 过滤规则
filter bgp_import {
    # 接受所有路由
    accept;
}

filter bgp_export {
    # 导出所有路由
    accept;
}

# 日志配置 (BIRD 3.x 语法)
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log "/var/log/bird/bird.log" { info, remote, warning, error, auth, fatal, bug };
EOF

    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "BIRD 3.x configuration created: $config_file"
}

# 创建BIRD 1.x配置 (兼容性)
create_bird_v1_config() {
    local config_file="$1"
    local router_id="$2"
    local as_number="$3"
    local ipv6_prefixes="$4"
    
    cat > "$config_file" << EOF
# BIRD 1.x BGP Configuration for IPv6 WireGuard
# Generated by IPv6 WireGuard Manager
# Router ID: $router_id
# AS Number: $as_number
# BIRD Version: 1.x (Legacy)

# 路由器ID
router id $router_id;

# 设备协议
protocol device {
    scan time 10;
}

# 内核协议 - 处理路由表
protocol kernel {
    ipv6 {
        import all;
        export all;
    };
    learn;
    scan time 20;
}

# 直连协议 - 处理直连网络
protocol direct {
    ipv6;
    interface "wg0";
}

# BGP协议配置
protocol bgp {
    local as $as_number;
    
    # 这里需要根据实际的上游BGP邻居配置
    # neighbor 2001:db8::1 as 65000;
    
    ipv6 {
        import all;
        export all;
    };
    
    # 连接参数
    connect retry time 30;
    connect retry time 60;
    hold time 180;
    keepalive time 60;
}

# 静态路由配置
protocol static {
    ipv6;
    
    # 宣告IPv6前缀
EOF

    # 添加IPv6前缀
    IFS=',' read -ra PREFIXES <<< "$ipv6_prefixes"
    for prefix in "${PREFIXES[@]}"; do
        # 提取网络地址和前缀长度
        local network=$(echo "$prefix" | cut -d'/' -f1)
        local prefix_len=$(echo "$prefix" | cut -d'/' -f2)
        
        # 计算下一跳地址（通常是WireGuard接口的第一个地址）
        local next_hop="${network%::*}::1"
        
        cat >> "$config_file" << EOF
    route $prefix via $next_hop;
EOF
    done

    cat >> "$config_file" << EOF
}

# 过滤规则
filter bgp_import {
    # 接受所有路由
    accept;
}

filter bgp_export {
    # 导出所有路由
    accept;
}

# 日志配置 (BIRD 1.x 语法)
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log "/var/log/bird/bird.log" { info, remote, warning, error, auth, fatal, bug };
EOF

    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "BIRD 1.x configuration created: $config_file"
}

# 创建BIRD客户端配置
create_bird_client_config() {
    local config_file="$1"
    local client_name="$2"
    local client_as="$3"
    local client_ipv6="$4"
    local ipv6_prefix="$5"
    
    cat > "$config_file" << EOF
# BIRD Client Configuration for $client_name
# Generated by IPv6 WireGuard Manager

protocol bgp $client_name {
    local as $AS_NUMBER;
    neighbor $client_ipv6 as $client_as;
    
    ipv6 {
        import filter bgp_import;
        export filter bgp_export;
    };
    
    # 连接参数
    connect retry time 30;
    hold time 180;
    keepalive time 60;
    
    # 路由策略
    import limit 1000 action block;
    export limit 1000 action block;
}
EOF

    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "BIRD client configuration created: $config_file"
}

# 配置BGP邻居
configure_bgp_neighbor() {
    local config_file="$1"
    local neighbor_ip="$2"
    local neighbor_as="$3"
    local neighbor_name="${4:-neighbor}"
    
    # 检查邻居是否已存在
    if grep -q "neighbor $neighbor_ip as $neighbor_as" "$config_file"; then
        echo "BGP neighbor $neighbor_ip already configured"
        return 0
    fi
    
    # 添加邻居配置
    cat >> "$config_file" << EOF

# BGP Neighbor: $neighbor_name
protocol bgp $neighbor_name {
    local as $AS_NUMBER;
    neighbor $neighbor_ip as $neighbor_as;
    
    ipv6 {
        import filter bgp_import;
        export filter bgp_export;
    };
    
    # 连接参数
    connect retry time 30;
    hold time 180;
    keepalive time 60;
}
EOF

    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "BGP neighbor $neighbor_name configured"
}

# 添加IPv6前缀宣告
add_ipv6_prefix() {
    local config_file="$1"
    local prefix="$2"
    local next_hop="${3:-}"
    
    # 如果没有指定下一跳，使用默认值
    if [[ -z "$next_hop" ]]; then
        local network=$(echo "$prefix" | cut -d'/' -f1)
        next_hop="${network%::*}::1"
    fi
    
    # 检查前缀是否已存在
    if grep -q "route $prefix via" "$config_file"; then
        echo "IPv6 prefix $prefix already configured"
        return 0
    fi
    
    # 在静态路由部分添加前缀
    sed -i "/^protocol static {/,/^}/ s/^}/    route $prefix via $next_hop;\n}/" "$config_file"
    
    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "IPv6 prefix $prefix added to BIRD configuration"
}

# 移除IPv6前缀宣告
remove_ipv6_prefix() {
    local config_file="$1"
    local prefix="$2"
    
    # 移除指定的前缀
    sed -i "/route $prefix via/d" "$config_file"
    
    # 设置配置文件权限
    chown bird:bird "$config_file"
    chmod 644 "$config_file"
    
    echo "IPv6 prefix $prefix removed from BIRD configuration"
}

# 配置BIRD用户和权限
configure_bird_permissions() {
    log "INFO" "Configuring BIRD user and permissions..."
    
    # 创建bird用户和组（如果不存在）
    if ! id "bird" >/dev/null 2>&1; then
        useradd -r -s /bin/false -d /var/lib/bird -c "BIRD BGP daemon" bird
        log "INFO" "Created bird user"
    fi
    
    if ! getent group "bird" >/dev/null 2>&1; then
        groupadd -r bird
        log "INFO" "Created bird group"
    fi
    
    # 确保bird用户在bird组中
    usermod -a -G bird bird
    
    # 创建BIRD相关目录
    mkdir -p /etc/bird
    mkdir -p /var/lib/bird
    mkdir -p /var/log/bird
    mkdir -p /var/run/bird
    
    # 设置目录权限
    chown -R bird:bird /etc/bird
    chown -R bird:bird /var/lib/bird
    chown -R bird:bird /var/log/bird
    chown -R bird:bird /var/run/bird
    
    # 设置目录权限
    chmod 755 /etc/bird
    chmod 755 /var/lib/bird
    chmod 755 /var/log/bird
    chmod 755 /var/run/bird
    
    # 设置配置文件权限
    if [[ -f /etc/bird/bird.conf ]]; then
        chown bird:bird /etc/bird/bird.conf
        chmod 644 /etc/bird/bird.conf
    fi
    
    # 创建BIRD配置子目录
    mkdir -p /etc/bird/bird.conf.d
    chown bird:bird /etc/bird/bird.conf.d
    chmod 755 /etc/bird/bird.conf.d
    
    log "INFO" "BIRD permissions configured successfully"
}

# 创建BIRD systemd服务文件
create_bird_systemd_service() {
    log "INFO" "Creating BIRD systemd service file..."
    
    # 检测BIRD版本
    if ! detect_bird_version; then
        log "ERROR" "Failed to detect BIRD version for systemd service"
        return 1
    fi
    
    local bird_executable=$(get_bird_executable)
    local bird_control=$(get_bird_control)
    
    cat > /etc/systemd/system/bird.service << EOF
[Unit]
Description=BIRD Internet Routing Daemon (Version $BIRD_VERSION)
Documentation=man:bird(8)
After=network.target
Wants=network.target

[Service]
Type=notify
User=bird
Group=bird
ExecStart=/usr/sbin/$bird_executable -f -u bird -g bird -c /etc/bird/bird.conf
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
Restart=on-failure
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=10

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/bird /var/log/bird /var/run/bird
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Network settings
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true

# Capabilities
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_SYS_ADMIN

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload
    
    log "INFO" "BIRD systemd service file created for version $BIRD_VERSION"
}

# 启动BIRD服务
start_bird_service() {
    # 首先配置权限
    configure_bird_permissions
    
    # 创建systemd服务文件
    create_bird_systemd_service
    
    # 启动服务
    systemctl enable bird 2>/dev/null || true
    systemctl start bird 2>/dev/null || true
    
    if systemctl is-active bird >/dev/null 2>&1; then
        echo "BIRD service started successfully"
        return 0
    else
        echo "Failed to start BIRD service - continuing installation"
        log "WARN" "BIRD service failed to start, but installation will continue"
        return 0  # 返回0表示继续安装，不阻止其他组件安装
    fi
}

# 停止BIRD服务
stop_bird_service() {
    systemctl stop bird
    systemctl disable bird
    
    echo "BIRD service stopped"
}

# 重启BIRD服务
restart_bird_service() {
    systemctl restart bird 2>/dev/null || true
    
    if systemctl is-active bird >/dev/null 2>&1; then
        echo "BIRD service restarted successfully"
        return 0
    else
        echo "Failed to restart BIRD service - continuing operation"
        log "WARN" "BIRD service failed to restart, but operation will continue"
        return 0  # 返回0表示继续操作，不阻止其他功能
    fi
}

# 重新加载BIRD配置
reload_bird_config() {
    if systemctl is-active bird >/dev/null 2>&1; then
        local bird_control=$(get_bird_control)
        if command -v "$bird_control" >/dev/null 2>&1; then
            "$bird_control" configure
            echo "BIRD configuration reloaded"
        else
            echo "BIRD control utility not found"
            return 1
        fi
    else
        echo "BIRD service is not running"
        return 1
    fi
}

# 获取BIRD状态
get_bird_status() {
    if systemctl is-active bird >/dev/null 2>&1; then
        echo "active"
    else
        echo "inactive"
    fi
}

# 显示BIRD路由表
show_bird_routes() {
    local bird_control=$(get_bird_control)
    if command -v "$bird_control" >/dev/null 2>&1; then
        echo "=== BIRD IPv6 Routes ==="
        "$bird_control" show route protocol static
        echo
        echo "=== BGP Routes ==="
        "$bird_control" show route protocol bgp
    else
        echo "BIRD control utility not found"
    fi
}

# 显示BGP邻居状态
show_bgp_neighbors() {
    local bird_control=$(get_bird_control)
    if command -v "$bird_control" >/dev/null 2>&1; then
        echo "=== BGP Neighbors ==="
        "$bird_control" show protocols all bgp
    else
        echo "BIRD control utility not found"
    fi
}

# 显示BIRD统计信息
show_bird_stats() {
    local bird_control=$(get_bird_control)
    if command -v "$bird_control" >/dev/null 2>&1; then
        echo "=== BIRD Statistics ==="
        "$bird_control" show status
        echo
        "$bird_control" show protocols
    else
        echo "BIRD control utility not found"
    fi
}

# 测试BIRD配置
test_bird_config() {
    local config_file="$1"
    local bird_control=$(get_bird_control)
    
    if command -v "$bird_control" >/dev/null 2>&1; then
        if "$bird_control" -c "$config_file" configure; then
            echo "BIRD configuration test passed"
            return 0
        else
            echo "BIRD configuration test failed"
            return 1
        fi
    else
        echo "BIRD control utility not found"
        return 1
    fi
}

# 备份BIRD配置
backup_bird_config() {
    local backup_dir="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    # 备份BIRD配置文件
    if [[ -f /etc/bird/bird.conf ]]; then
        cp /etc/bird/bird.conf "$backup_dir/bird_$timestamp.conf"
    fi
    
    # 备份BIRD客户端配置
    if [[ -d /etc/bird/clients ]]; then
        cp -r /etc/bird/clients "$backup_dir/bird_clients_$timestamp"
    fi
    
    echo "BIRD configuration backed up to: $backup_dir"
}

# 恢复BIRD配置
restore_bird_config() {
    local backup_dir="$1"
    local timestamp="$2"
    
    if [[ -f "$backup_dir/bird_$timestamp.conf" ]]; then
        cp "$backup_dir/bird_$timestamp.conf" /etc/bird/bird.conf
        echo "BIRD configuration restored from: $backup_dir/bird_$timestamp.conf"
    else
        echo "Backup not found: $backup_dir/bird_$timestamp.conf"
        return 1
    fi
}

# 生成BIRD监控脚本
generate_bird_monitor_script() {
    local script_file="$1"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash

# BIRD BGP监控脚本
# 用于监控BIRD服务状态和BGP连接

set -euo pipefail

# 配置
LOG_FILE="/var/log/bird-monitor.log"
ALERT_EMAIL="admin@example.com"
CHECK_INTERVAL=60

# 日志函数
log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# 获取BIRD控制命令路径
get_bird_control() {
    if command -v birdc2 >/dev/null 2>&1; then
        echo "birdc2"
    elif command -v birdc6 >/dev/null 2>&1; then
        echo "birdc6"
    elif command -v birdc >/dev/null 2>&1; then
        echo "birdc"
    else
        echo "birdc"
    fi
}

# 检查BIRD服务状态
check_bird_service() {
    if systemctl is-active bird >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查BGP邻居状态
check_bgp_neighbors() {
    local failed_neighbors=()
    
    local bird_control=$(get_bird_control)
    if command -v "$bird_control" >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^BGP[[:space:]]+([^[:space:]]+)[[:space:]]+ ]]; then
                local neighbor="${BASH_REMATCH[1]}"
                if [[ "$line" =~ Established ]]; then
                    log "BGP neighbor $neighbor is established"
                else
                    log "WARNING: BGP neighbor $neighbor is not established"
                    failed_neighbors+=("$neighbor")
                fi
            fi
        done < <("$bird_control" show protocols all bgp)
    fi
    
    echo "${failed_neighbors[@]}"
}

# 发送告警邮件
send_alert() {
    local subject="$1"
    local message="$2"
    
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
    fi
    
    log "ALERT: $subject - $message"
}

# 主监控循环
main() {
    log "BIRD monitoring started"
    
    while true; do
        # 检查BIRD服务
        if ! check_bird_service; then
            send_alert "BIRD Service Down" "BIRD service is not running"
            systemctl start bird
        fi
        
        # 检查BGP邻居
        local failed_neighbors=($(check_bgp_neighbors))
        if [[ ${#failed_neighbors[@]} -gt 0 ]]; then
            send_alert "BGP Neighbors Down" "Failed neighbors: ${failed_neighbors[*]}"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# 运行监控
main "$@"
EOF

    chmod +x "$script_file"
    echo "BIRD monitor script generated: $script_file"
}

# 配置BIRD日志
configure_bird_logging() {
    local log_level="${1:-info}"
    local log_file="${2:-/var/log/bird.log}"
    
    # 创建日志配置
    cat > /etc/bird/bird.conf.d/logging.conf << EOF
# BIRD日志配置
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
log "$log_file" { $log_level, trace, info, remote, warning, error, auth, fatal, bug };
EOF

    # 设置配置文件权限
    chown bird:bird /etc/bird/bird.conf.d/logging.conf
    chmod 644 /etc/bird/bird.conf.d/logging.conf
    
    # 确保日志文件目录存在且权限正确
    mkdir -p "$(dirname "$log_file")"
    chown bird:bird "$(dirname "$log_file")"
    chmod 755 "$(dirname "$log_file")"
    
    echo "BIRD logging configured: $log_file (level: $log_level)"
}

# =============================================================================
# BIRD错误诊断和修复功能
# =============================================================================

# 诊断BIRD安装问题
diagnose_bird_installation() {
    echo -e "${CYAN}=== BIRD安装诊断 ===${NC}"
    
    local issues_found=0
    
    # 检查BIRD是否已安装
    echo -e "${YELLOW}1. 检查BIRD安装状态...${NC}"
    if command -v bird >/dev/null 2>&1 || command -v bird2 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} BIRD已安装"
        
        # 显示BIRD版本信息
        if command -v bird >/dev/null 2>&1; then
            local version=$(bird --version 2>&1 | head -1)
            echo "   版本: $version"
        elif command -v bird2 >/dev/null 2>&1; then
            local version=$(bird2 --version 2>&1 | head -1)
            echo "   版本: $version"
        fi
    else
        echo -e "${RED}✗${NC} BIRD未安装"
        issues_found=$((issues_found + 1))
        
        # 提供安装建议
        echo -e "${YELLOW}   建议修复:${NC}"
        case "$OS_TYPE" in
            "ubuntu"|"debian")
                echo "   sudo apt update && sudo apt install -y bird2"
                ;;
            "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
                if command -v dnf >/dev/null 2>&1; then
                    echo "   sudo dnf install -y bird2"
                else
                    echo "   sudo yum install -y bird2"
                fi
                ;;
            "arch")
                echo "   sudo pacman -S bird2"
                ;;
        esac
    fi
    
    # 检查BIRD控制工具
    echo -e "${YELLOW}2. 检查BIRD控制工具...${NC}"
    if command -v birdc >/dev/null 2>&1 || command -v birdc2 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} BIRD控制工具已安装"
    else
        echo -e "${RED}✗${NC} BIRD控制工具未安装"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 重新安装BIRD包"
    fi
    
    # 检查BIRD用户和组
    echo -e "${YELLOW}3. 检查BIRD用户和组...${NC}"
    if id "bird" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} BIRD用户存在"
    else
        echo -e "${RED}✗${NC} BIRD用户不存在"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} sudo useradd -r -s /bin/false -d /var/lib/bird bird"
    fi
    
    if getent group "bird" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} BIRD组存在"
    else
        echo -e "${RED}✗${NC} BIRD组不存在"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} sudo groupadd -r bird"
    fi
    
    # 检查BIRD目录权限
    echo -e "${YELLOW}4. 检查BIRD目录权限...${NC}"
    local bird_dirs=("/etc/bird" "/var/lib/bird" "/var/log/bird" "/var/run/bird")
    for dir in "${bird_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local owner=$(stat -c '%U:%G' "$dir" 2>/dev/null || echo "unknown")
            if [[ "$owner" == "bird:bird" ]]; then
                echo -e "${GREEN}✓${NC} $dir 权限正确 ($owner)"
            else
                echo -e "${RED}✗${NC} $dir 权限错误 ($owner)"
                issues_found=$((issues_found + 1))
                echo -e "${YELLOW}   建议修复:${NC} sudo chown -R bird:bird $dir"
            fi
        else
            echo -e "${RED}✗${NC} $dir 目录不存在"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} sudo mkdir -p $dir && sudo chown bird:bird $dir"
        fi
    done
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ BIRD安装诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ BIRD安装诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# 诊断BIRD配置问题
diagnose_bird_configuration() {
    echo -e "${CYAN}=== BIRD配置诊断 ===${NC}"
    
    local issues_found=0
    local config_file="/etc/bird/bird.conf"
    
    # 检查配置文件是否存在
    echo -e "${YELLOW}1. 检查BIRD配置文件...${NC}"
    if [[ -f "$config_file" ]]; then
        echo -e "${GREEN}✓${NC} 配置文件存在: $config_file"
        
        # 检查配置文件权限
        local owner=$(stat -c '%U:%G' "$config_file" 2>/dev/null || echo "unknown")
        if [[ "$owner" == "bird:bird" ]]; then
            echo -e "${GREEN}✓${NC} 配置文件权限正确 ($owner)"
        else
            echo -e "${RED}✗${NC} 配置文件权限错误 ($owner)"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} sudo chown bird:bird $config_file"
        fi
        
        # 检查配置文件语法
        echo -e "${YELLOW}2. 检查配置文件语法...${NC}"
        local bird_control=$(get_bird_control)
        if command -v "$bird_control" >/dev/null 2>&1; then
            # BIRD 2.x 使用 configure 命令，BIRD 1.x 使用 -c 选项
            if [[ "$bird_control" == "birdc2" ]]; then
                if "$bird_control" configure 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 配置文件语法正确"
                else
                    echo -e "${RED}✗${NC} 配置文件语法错误"
                    issues_found=$((issues_found + 1))
                    show_bird_config_errors
                fi
            else
                if "$bird_control" -c "$config_file" configure 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 配置文件语法正确"
                else
                    echo -e "${RED}✗${NC} 配置文件语法错误"
                    issues_found=$((issues_found + 1))
                    show_bird_config_errors
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} 无法检查语法（BIRD控制工具不可用）"
        fi
        
        # 检查配置文件内容
        echo -e "${YELLOW}3. 检查配置文件内容...${NC}"
        
        # 检查路由器ID
        if grep -q "router id" "$config_file"; then
            local router_id=$(grep "router id" "$config_file" | head -1 | awk '{print $3}' | tr -d ';')
            echo -e "${GREEN}✓${NC} 路由器ID已配置: $router_id"
        else
            echo -e "${RED}✗${NC} 路由器ID未配置"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} 在配置文件中添加 'router id <IP地址>;'"
        fi
        
        # 检查BGP协议配置
        if grep -q "protocol bgp" "$config_file"; then
            echo -e "${GREEN}✓${NC} BGP协议已配置"
        else
            echo -e "${YELLOW}⚠${NC} BGP协议未配置（可选）"
        fi
        
        # 检查IPv6支持
        if grep -q "ipv6" "$config_file"; then
            echo -e "${GREEN}✓${NC} IPv6支持已配置"
        else
            echo -e "${RED}✗${NC} IPv6支持未配置"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} 在协议配置中添加IPv6支持"
        fi
        
    else
        echo -e "${RED}✗${NC} 配置文件不存在: $config_file"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 创建BIRD配置文件"
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ BIRD配置诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ BIRD配置诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# 诊断BIRD服务问题
diagnose_bird_service() {
    echo -e "${CYAN}=== BIRD服务诊断 ===${NC}"
    
    local issues_found=0
    
    # 检查systemd服务文件
    echo -e "${YELLOW}1. 检查systemd服务文件...${NC}"
    if [[ -f /etc/systemd/system/bird.service ]]; then
        echo -e "${GREEN}✓${NC} systemd服务文件存在"
        
        # 检查服务文件内容
        if grep -q "ExecStart.*bird" /etc/systemd/system/bird.service; then
            echo -e "${GREEN}✓${NC} 服务文件配置正确"
        else
            echo -e "${RED}✗${NC} 服务文件配置错误"
            issues_found=$((issues_found + 1))
            echo -e "${YELLOW}   建议修复:${NC} 重新创建systemd服务文件"
        fi
    else
        echo -e "${RED}✗${NC} systemd服务文件不存在"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 创建systemd服务文件"
    fi
    
    # 检查服务状态
    echo -e "${YELLOW}2. 检查BIRD服务状态...${NC}"
    if systemctl is-active bird >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} BIRD服务正在运行"
        
        # 检查服务是否启用
        if systemctl is-enabled bird >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} BIRD服务已启用"
        else
            echo -e "${YELLOW}⚠${NC} BIRD服务未启用"
            echo -e "${YELLOW}   建议修复:${NC} sudo systemctl enable bird"
        fi
    else
        echo -e "${RED}✗${NC} BIRD服务未运行"
        issues_found=$((issues_found + 1))
        
        # 检查服务失败原因
        echo -e "${YELLOW}3. 检查服务失败原因...${NC}"
        local service_status=$(systemctl status bird --no-pager -l 2>&1)
        echo "服务状态:"
        echo "$service_status" | head -20
        
        # 检查journal日志
        echo -e "${YELLOW}4. 检查系统日志...${NC}"
        local journal_logs=$(journalctl -u bird --no-pager -l --since "5 minutes ago" 2>&1)
        if [[ -n "$journal_logs" ]]; then
            echo "最近的日志:"
            echo "$journal_logs" | tail -10
        else
            echo "没有找到相关日志"
        fi
        
        # 提供修复建议
        echo -e "${YELLOW}   建议修复:${NC}"
        echo "   1. sudo systemctl start bird"
        echo "   2. sudo journalctl -u bird -f  # 查看实时日志"
        echo "   3. 检查配置文件语法: sudo birdc configure"
    fi
    
    # 检查端口占用
    echo -e "${YELLOW}5. 检查端口占用...${NC}"
    local bird_processes=$(ps aux | grep -E '[b]ird[^c]' | wc -l)
    if [[ $bird_processes -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} 发现 $bird_processes 个BIRD进程"
        ps aux | grep -E '[b]ird[^c]' | head -5
    else
        echo -e "${RED}✗${NC} 没有发现BIRD进程"
        issues_found=$((issues_found + 1))
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ BIRD服务诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ BIRD服务诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# 诊断BIRD网络连接问题
diagnose_bird_network() {
    echo -e "${CYAN}=== BIRD网络诊断 ===${NC}"
    
    local issues_found=0
    
    # 检查网络接口
    echo -e "${YELLOW}1. 检查网络接口...${NC}"
    if ip link show wg0 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} WireGuard接口 wg0 存在"
        
        # 检查接口状态
        local wg_status=$(ip link show wg0 | grep -o "state [A-Z]*")
        echo "   状态: $wg_status"
        
        # 检查IPv6地址
        local wg_ipv6=$(ip -6 addr show wg0 | grep inet6 | head -1)
        if [[ -n "$wg_ipv6" ]]; then
            echo -e "${GREEN}✓${NC} WireGuard接口有IPv6地址"
            echo "   $wg_ipv6"
        else
            echo -e "${RED}✗${NC} WireGuard接口没有IPv6地址"
            issues_found=$((issues_found + 1))
        fi
    else
        echo -e "${RED}✗${NC} WireGuard接口 wg0 不存在"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} 确保WireGuard已正确配置"
    fi
    
    # 检查IPv6转发
    echo -e "${YELLOW}2. 检查IPv6转发...${NC}"
    local ipv6_forward=$(cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || echo "0")
    if [[ "$ipv6_forward" == "1" ]]; then
        echo -e "${GREEN}✓${NC} IPv6转发已启用"
    else
        echo -e "${RED}✗${NC} IPv6转发未启用"
        issues_found=$((issues_found + 1))
        echo -e "${YELLOW}   建议修复:${NC} echo 1 | sudo tee /proc/sys/net/ipv6/conf/all/forwarding"
    fi
    
    # 检查BGP邻居连接
    echo -e "${YELLOW}3. 检查BGP邻居连接...${NC}"
    local bird_control=$(get_bird_control)
    if command -v "$bird_control" >/dev/null 2>&1 && systemctl is-active bird >/dev/null 2>&1; then
        local bgp_protocols=$("$bird_control" show protocols all bgp 2>/dev/null || echo "")
        if [[ -n "$bgp_protocols" ]]; then
            echo -e "${GREEN}✓${NC} BGP协议已配置"
            echo "$bgp_protocols" | head -10
            
            # 检查邻居状态
            if echo "$bgp_protocols" | grep -q "Established"; then
                echo -e "${GREEN}✓${NC} 有BGP邻居已建立连接"
            else
                echo -e "${YELLOW}⚠${NC} 没有BGP邻居建立连接"
                echo -e "${YELLOW}   建议检查:${NC} BGP邻居配置和网络连通性"
            fi
        else
            echo -e "${YELLOW}⚠${NC} 没有配置BGP协议"
        fi
    else
        echo -e "${YELLOW}⚠${NC} 无法检查BGP状态（BIRD服务未运行）"
    fi
    
    # 检查路由表
    echo -e "${YELLOW}4. 检查路由表...${NC}"
    local ipv6_routes=$(ip -6 route show | wc -l)
    if [[ $ipv6_routes -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} 发现 $ipv6_routes 条IPv6路由"
        
        # 显示BIRD管理的路由
        if command -v "$bird_control" >/dev/null 2>&1 && systemctl is-active bird >/dev/null 2>&1; then
            local bird_routes=$("$bird_control" show route 2>/dev/null | wc -l)
            if [[ $bird_routes -gt 0 ]]; then
                echo -e "${GREEN}✓${NC} BIRD管理 $bird_routes 条路由"
            else
                echo -e "${YELLOW}⚠${NC} BIRD没有管理任何路由"
            fi
        fi
    else
        echo -e "${RED}✗${NC} 没有IPv6路由"
        issues_found=$((issues_found + 1))
    fi
    
    # 总结
    echo
    if [[ $issues_found -eq 0 ]]; then
        echo -e "${GREEN}✓ BIRD网络诊断完成，未发现问题${NC}"
    else
        echo -e "${RED}✗ BIRD网络诊断完成，发现 $issues_found 个问题${NC}"
        echo -e "${YELLOW}请按照上述建议修复问题后重试${NC}"
    fi
    
    return $issues_found
}

# 显示BIRD配置错误详情
show_bird_config_errors() {
    echo -e "${YELLOW}=== BIRD配置错误详情 ===${NC}"
    
    local config_file="/etc/bird/bird.conf"
    local bird_control=$(get_bird_control)
    
    if command -v "$bird_control" >/dev/null 2>&1; then
        echo "配置文件语法检查结果:"
        # BIRD 2.x 使用 configure 命令，BIRD 1.x 使用 -c 选项
        if [[ "$bird_control" == "birdc2" ]]; then
            "$bird_control" configure 2>&1 | head -20
        else
            "$bird_control" -c "$config_file" configure 2>&1 | head -20
        fi
        
        echo
        echo -e "${YELLOW}常见配置错误及修复方法:${NC}"
        echo "1. 语法错误: 检查分号、大括号、引号是否匹配"
        echo "2. 路由器ID错误: 确保使用有效的IPv4地址"
        echo "3. AS号错误: 确保使用有效的AS号（1-4294967295）"
        echo "4. 邻居配置错误: 检查邻居IP地址和AS号"
        echo "5. 协议配置错误: 确保协议名称和参数正确"
        
        echo
        echo -e "${YELLOW}建议修复步骤:${NC}"
        echo "1. 备份当前配置: sudo cp $config_file $config_file.backup"
        echo "2. 检查配置文件语法: sudo $bird_control configure"
        echo "3. 查看详细错误: sudo $bird_control configure 2>&1 | less"
        echo "4. 修复错误后重新加载: sudo $bird_control configure"
    else
        echo -e "${RED}无法检查配置错误：BIRD控制工具不可用${NC}"
    fi
}

# 综合BIRD诊断
diagnose_bird_comprehensive() {
    echo -e "${CYAN}=== BIRD综合诊断 ===${NC}"
    echo "开始全面诊断BIRD安装、配置和服务状态..."
    echo
    
    local total_issues=0
    
    # 安装诊断
    diagnose_bird_installation
    total_issues=$((total_issues + $?))
    echo
    
    # 配置诊断
    diagnose_bird_configuration
    total_issues=$((total_issues + $?))
    echo
    
    # 服务诊断
    diagnose_bird_service
    total_issues=$((total_issues + $?))
    echo
    
    # 网络诊断
    diagnose_bird_network
    total_issues=$((total_issues + $?))
    echo
    
    # 总结报告
    echo -e "${CYAN}=== 诊断总结 ===${NC}"
    if [[ $total_issues -eq 0 ]]; then
        echo -e "${GREEN}✓ BIRD综合诊断完成，未发现任何问题${NC}"
        echo -e "${GREEN}BIRD服务运行正常，可以正常使用BGP功能${NC}"
    else
        echo -e "${RED}✗ BIRD综合诊断完成，总共发现 $total_issues 个问题${NC}"
        echo -e "${YELLOW}请按照上述诊断结果修复问题后重试${NC}"
        
        echo
        echo -e "${YELLOW}快速修复建议:${NC}"
        echo "1. 如果BIRD未安装: 运行安装脚本重新安装"
        echo "2. 如果配置错误: 检查配置文件语法并修复"
        echo "3. 如果服务启动失败: 查看系统日志并修复权限问题"
        echo "4. 如果网络问题: 检查WireGuard配置和IPv6转发"
    fi
    
    return $total_issues
}

# 自动修复BIRD常见问题
auto_fix_bird_issues() {
    echo -e "${CYAN}=== BIRD自动修复 ===${NC}"
    
    local fixes_applied=0
    
    # 修复权限问题
    echo -e "${YELLOW}1. 修复BIRD权限问题...${NC}"
    if configure_bird_permissions; then
        echo -e "${GREEN}✓${NC} BIRD权限已修复"
        fixes_applied=$((fixes_applied + 1))
    else
        echo -e "${RED}✗${NC} BIRD权限修复失败"
    fi
    
    # 修复systemd服务文件
    echo -e "${YELLOW}2. 修复systemd服务文件...${NC}"
    if create_bird_systemd_service; then
        echo -e "${GREEN}✓${NC} systemd服务文件已修复"
        fixes_applied=$((fixes_applied + 1))
    else
        echo -e "${RED}✗${NC} systemd服务文件修复失败"
    fi
    
    # 启用IPv6转发
    echo -e "${YELLOW}3. 启用IPv6转发...${NC}"
    if echo 1 | tee /proc/sys/net/ipv6/conf/all/forwarding >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} IPv6转发已启用"
        fixes_applied=$((fixes_applied + 1))
    else
        echo -e "${RED}✗${NC} IPv6转发启用失败"
    fi
    
    # 尝试启动BIRD服务
    echo -e "${YELLOW}4. 尝试启动BIRD服务...${NC}"
    if systemctl start bird 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIRD服务启动成功"
        fixes_applied=$((fixes_applied + 1))
    else
        echo -e "${YELLOW}⚠${NC} BIRD服务启动失败，请检查配置"
    fi
    
    # 总结
    echo
    echo -e "${CYAN}=== 修复总结 ===${NC}"
    echo "已应用 $fixes_applied 个修复"
    
    if [[ $fixes_applied -gt 0 ]]; then
        echo -e "${GREEN}建议重新运行诊断以确认问题已解决${NC}"
    else
        echo -e "${YELLOW}没有应用任何修复，可能需要手动干预${NC}"
    fi
    
    return $fixes_applied
}
