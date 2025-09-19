#!/bin/bash

# 防火墙配置模块
# 支持UFW、firewalld、nftables和iptables

# 检测防火墙类型
detect_firewall_type() {
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
        echo "firewalld"
    elif command -v nft >/dev/null 2>&1; then
        echo "nftables"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables"
    else
        echo "none"
    fi
}

# UFW防火墙配置
configure_ufw() {
    local wg_port="$1"
    local ssh_port="${2:-22}"
    
    log "INFO" "Configuring UFW firewall..."
    
    # 重置UFW规则
    ufw --force reset
    
    # 设置默认策略
    ufw default deny incoming
    ufw default allow outgoing
    
    # 允许SSH
    ufw allow "$ssh_port"/tcp comment 'SSH'
    
    # 允许WireGuard
    ufw allow "$wg_port"/udp comment 'WireGuard'
    
    # 允许回环接口
    ufw allow in on lo
    ufw allow out on lo
    
    # 启用UFW
    ufw --force enable
    
    log "INFO" "UFW firewall configured successfully"
}

# Firewalld防火墙配置
configure_firewalld() {
    local wg_port="$1"
    local ssh_port="${2:-22}"
    
    log "INFO" "Configuring Firewalld firewall..."
    
    # 启动并启用firewalld
    systemctl enable firewalld
    systemctl start firewalld
    
    # 添加WireGuard端口
    firewall-cmd --permanent --add-port="$wg_port"/udp
    firewall-cmd --permanent --add-service=ssh
    
    # 允许WireGuard接口
    firewall-cmd --permanent --add-interface=wg0
    firewall-cmd --permanent --zone=trusted --add-interface=wg0
    
    # 允许转发
    firewall-cmd --permanent --add-masquerade
    
    # 重新加载配置
    firewall-cmd --reload
    
    log "INFO" "Firewalld firewall configured successfully"
}

# nftables防火墙配置
configure_nftables() {
    local wg_port="$1"
    local ssh_port="${2:-22}"
    
    log "INFO" "Configuring nftables firewall..."
    
    # 创建nftables配置
    cat > /etc/nftables.conf << EOF
#!/usr/sbin/nft -f

# 清空现有规则
flush ruleset

# 定义表
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        # 允许回环接口
        iif lo accept
        
        # 允许已建立的连接
        ct state established,related accept
        
        # 允许SSH
        tcp dport $ssh_port accept
        
        # 允许WireGuard
        udp dport $wg_port accept
        
        # 允许ICMP
        icmp type echo-request accept
        icmpv6 type echo-request accept
    }
    
    chain forward {
        type filter hook forward priority 0; policy drop;
        
        # 允许已建立的连接
        ct state established,related accept
        
        # 允许WireGuard接口转发
        iif wg0 accept
        oif wg0 accept
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}

# NAT表
table inet nat {
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        
        # WireGuard接口NAT
        oifname "eth0" masquerade
    }
}
EOF

    # 应用配置
    nft -f /etc/nftables.conf
    
    # 启用nftables服务
    systemctl enable nftables
    systemctl start nftables
    
    log "INFO" "nftables firewall configured successfully"
}

# iptables防火墙配置
configure_iptables() {
    local wg_port="$1"
    local ssh_port="${2:-22}"
    local interface="${3:-eth0}"
    
    log "INFO" "Configuring iptables firewall..."
    
    # 清空现有规则
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    iptables -t nat -X
    iptables -t mangle -X
    
    # 设置默认策略
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # 允许回环接口
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # 允许已建立的连接
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # 允许SSH
    iptables -A INPUT -p tcp --dport "$ssh_port" -j ACCEPT
    
    # 允许WireGuard
    iptables -A INPUT -p udp --dport "$wg_port" -j ACCEPT
    
    # 允许ICMP
    iptables -A INPUT -p icmp -j ACCEPT
    
    # WireGuard转发规则
    iptables -A FORWARD -i wg0 -j ACCEPT
    iptables -A FORWARD -o wg0 -j ACCEPT
    
    # NAT规则
    iptables -t nat -A POSTROUTING -o "$interface" -j MASQUERADE
    
    # IPv6规则
    ip6tables -F
    ip6tables -P INPUT DROP
    ip6tables -P FORWARD DROP
    ip6tables -P OUTPUT ACCEPT
    
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A OUTPUT -o lo -j ACCEPT
    ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A INPUT -p udp --dport "$wg_port" -j ACCEPT
    ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
    ip6tables -A FORWARD -i wg0 -j ACCEPT
    ip6tables -A FORWARD -o wg0 -j ACCEPT
    
    # 保存规则
    save_iptables_rules
    
    log "INFO" "iptables firewall configured successfully"
}

# 保存iptables规则
save_iptables_rules() {
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            if command -v iptables-save >/dev/null 2>&1; then
                iptables-save > /etc/iptables/rules.v4
                ip6tables-save > /etc/iptables/rules.v6
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v iptables-save >/dev/null 2>&1; then
                iptables-save > /etc/sysconfig/iptables
                ip6tables-save > /etc/sysconfig/ip6tables
            fi
            ;;
    esac
}

# 恢复iptables规则
restore_iptables_rules() {
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            if [[ -f /etc/iptables/rules.v4 ]]; then
                iptables-restore < /etc/iptables/rules.v4
            fi
            if [[ -f /etc/iptables/rules.v6 ]]; then
                ip6tables-restore < /etc/iptables/rules.v6
            fi
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if [[ -f /etc/sysconfig/iptables ]]; then
                iptables-restore < /etc/sysconfig/iptables
            fi
            if [[ -f /etc/sysconfig/ip6tables ]]; then
                ip6tables-restore < /etc/sysconfig/ip6tables
            fi
            ;;
    esac
}

# 添加防火墙规则
add_firewall_rule() {
    local firewall_type="$1"
    local rule_type="$2"  # port, service, interface
    local rule_value="$3"
    local protocol="${4:-tcp}"
    
    case "$firewall_type" in
        "ufw")
            case "$rule_type" in
                "port")
                    ufw allow "$rule_value"/"$protocol"
                    ;;
                "service")
                    ufw allow "$rule_value"
                    ;;
            esac
            ;;
        "firewalld")
            case "$rule_type" in
                "port")
                    firewall-cmd --permanent --add-port="$rule_value"/"$protocol"
                    ;;
                "service")
                    firewall-cmd --permanent --add-service="$rule_value"
                    ;;
            esac
            firewall-cmd --reload
            ;;
        "nftables")
            # nftables规则添加需要手动编辑配置文件
            log "WARN" "nftables rules must be added manually to /etc/nftables.conf"
            ;;
        "iptables")
            case "$rule_type" in
                "port")
                    iptables -A INPUT -p "$protocol" --dport "$rule_value" -j ACCEPT
                    ;;
            esac
            save_iptables_rules
            ;;
    esac
    
    log "INFO" "Firewall rule added: $rule_type $rule_value"
}

# 删除防火墙规则
remove_firewall_rule() {
    local firewall_type="$1"
    local rule_type="$2"
    local rule_value="$3"
    local protocol="${4:-tcp}"
    
    case "$firewall_type" in
        "ufw")
            case "$rule_type" in
                "port")
                    ufw delete allow "$rule_value"/"$protocol"
                    ;;
                "service")
                    ufw delete allow "$rule_value"
                    ;;
            esac
            ;;
        "firewalld")
            case "$rule_type" in
                "port")
                    firewall-cmd --permanent --remove-port="$rule_value"/"$protocol"
                    ;;
                "service")
                    firewall-cmd --permanent --remove-service="$rule_value"
                    ;;
            esac
            firewall-cmd --reload
            ;;
        "iptables")
            case "$rule_type" in
                "port")
                    iptables -D INPUT -p "$protocol" --dport "$rule_value" -j ACCEPT
                    ;;
            esac
            save_iptables_rules
            ;;
    esac
    
    log "INFO" "Firewall rule removed: $rule_type $rule_value"
}

# 显示防火墙状态
show_firewall_status() {
    local firewall_type="$1"
    
    case "$firewall_type" in
        "ufw")
            echo "=== UFW Status ==="
            ufw status verbose
            ;;
        "firewalld")
            echo "=== Firewalld Status ==="
            firewall-cmd --state
            echo
            firewall-cmd --list-all
            ;;
        "nftables")
            echo "=== nftables Status ==="
            nft list ruleset
            ;;
        "iptables")
            echo "=== iptables Status ==="
            iptables -L -n -v
            echo
            echo "=== ip6tables Status ==="
            ip6tables -L -n -v
            ;;
    esac
}

# 测试防火墙规则
test_firewall_rules() {
    local firewall_type="$1"
    local test_port="$2"
    
    case "$firewall_type" in
        "ufw")
            if ufw status | grep -q "$test_port"; then
                echo "Port $test_port is allowed in UFW"
                return 0
            else
                echo "Port $test_port is not allowed in UFW"
                return 1
            fi
            ;;
        "firewalld")
            if firewall-cmd --query-port="$test_port"/tcp; then
                echo "Port $test_port is allowed in Firewalld"
                return 0
            else
                echo "Port $test_port is not allowed in Firewalld"
                return 1
            fi
            ;;
        "iptables")
            if iptables -C INPUT -p tcp --dport "$test_port" -j ACCEPT 2>/dev/null; then
                echo "Port $test_port is allowed in iptables"
                return 0
            else
                echo "Port $test_port is not allowed in iptables"
                return 1
            fi
            ;;
    esac
}

# 备份防火墙配置
backup_firewall_config() {
    local backup_dir="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local firewall_type="$2"
    
    mkdir -p "$backup_dir"
    
    case "$firewall_type" in
        "ufw")
            ufw status > "$backup_dir/ufw_status_$timestamp.txt"
            ;;
        "firewalld")
            firewall-cmd --list-all > "$backup_dir/firewalld_config_$timestamp.txt"
            ;;
        "nftables")
            if [[ -f /etc/nftables.conf ]]; then
                cp /etc/nftables.conf "$backup_dir/nftables_$timestamp.conf"
            fi
            ;;
        "iptables")
            if command -v iptables-save >/dev/null 2>&1; then
                iptables-save > "$backup_dir/iptables_$timestamp.rules"
                ip6tables-save > "$backup_dir/ip6tables_$timestamp.rules"
            fi
            ;;
    esac
    
    echo "Firewall configuration backed up to: $backup_dir"
}

# 恢复防火墙配置
restore_firewall_config() {
    local backup_dir="$1"
    local timestamp="$2"
    local firewall_type="$3"
    
    case "$firewall_type" in
        "ufw")
            if [[ -f "$backup_dir/ufw_status_$timestamp.txt" ]]; then
                log "WARN" "UFW configuration must be restored manually"
            fi
            ;;
        "firewalld")
            if [[ -f "$backup_dir/firewalld_config_$timestamp.txt" ]]; then
                log "WARN" "Firewalld configuration must be restored manually"
            fi
            ;;
        "nftables")
            if [[ -f "$backup_dir/nftables_$timestamp.conf" ]]; then
                cp "$backup_dir/nftables_$timestamp.conf" /etc/nftables.conf
                nft -f /etc/nftables.conf
                echo "nftables configuration restored"
            fi
            ;;
        "iptables")
            if [[ -f "$backup_dir/iptables_$timestamp.rules" ]]; then
                iptables-restore < "$backup_dir/iptables_$timestamp.rules"
                echo "iptables configuration restored"
            fi
            if [[ -f "$backup_dir/ip6tables_$timestamp.rules" ]]; then
                ip6tables-restore < "$backup_dir/ip6tables_$timestamp.rules"
                echo "ip6tables configuration restored"
            fi
            ;;
    esac
}

# 禁用防火墙
disable_firewall() {
    local firewall_type="$1"
    
    case "$firewall_type" in
        "ufw")
            ufw --force disable
            ;;
        "firewalld")
            systemctl stop firewalld
            systemctl disable firewalld
            ;;
        "nftables")
            systemctl stop nftables
            systemctl disable nftables
            ;;
        "iptables")
            # 清空iptables规则
            iptables -F
            iptables -t nat -F
            iptables -t mangle -F
            iptables -P INPUT ACCEPT
            iptables -P FORWARD ACCEPT
            iptables -P OUTPUT ACCEPT
            ip6tables -F
            ip6tables -P INPUT ACCEPT
            ip6tables -P FORWARD ACCEPT
            ip6tables -P OUTPUT ACCEPT
            ;;
    esac
    
    log "INFO" "Firewall disabled: $firewall_type"
}

# 启用防火墙
enable_firewall() {
    local firewall_type="$1"
    
    case "$firewall_type" in
        "ufw")
            ufw --force enable
            ;;
        "firewalld")
            systemctl enable firewalld
            systemctl start firewalld
            ;;
        "nftables")
            systemctl enable nftables
            systemctl start nftables
            ;;
        "iptables")
            restore_iptables_rules
            ;;
    esac
    
    log "INFO" "Firewall enabled: $firewall_type"
}
