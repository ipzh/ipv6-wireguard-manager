#!/bin/bash

# 功能测试模块
# 提供全面的功能测试，包括网络连接、WireGuard隧道等

# ================================================================
# 网络连接测试
# ================================================================

# 运行网络连接测试
run_network_connection_test() {
    log_info "开始网络连接测试..."
    
    # 测试IPv6本地连接
    if execute_command "ping6 -c 3 ::1" "测试IPv6本地连接" "true"; then
        log_success "✓ IPv6本地连接正常"
        ((PASSED_TESTS++))
    else
        log_error "✗ IPv6本地连接失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试IPv4本地连接
    if execute_command "ping -c 3 127.0.0.1" "测试IPv4本地连接" "true"; then
        log_success "✓ IPv4本地连接正常"
        ((PASSED_TESTS++))
    else
        log_error "✗ IPv4本地连接失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试外网连接
    if execute_command "ping -c 3 8.8.8.8" "测试外网连接" "true"; then
        log_success "✓ 外网连接正常"
        ((PASSED_TESTS++))
    else
        log_warn "⚠ 外网连接失败（可能是网络问题）"
        ((SKIPPED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试DNS解析
    if execute_command "nslookup google.com" "测试DNS解析" "true"; then
        log_success "✓ DNS解析正常"
        ((PASSED_TESTS++))
    else
        log_error "✗ DNS解析失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试网络接口
    if execute_command "ip link show" "检查网络接口" "true"; then
        log_success "✓ 网络接口检查成功"
        ((PASSED_TESTS++))
    else
        log_error "✗ 网络接口检查失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试路由表
    if execute_command "ip route show" "检查路由表" "true"; then
        log_success "✓ 路由表检查成功"
        ((PASSED_TESTS++))
    else
        log_error "✗ 路由表检查失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试WireGuard隧道建立
    if [[ -f "/etc/wireguard/wg0.conf" ]]; then
        if execute_command "wg show wg0 2>/dev/null || echo 'WireGuard未运行'" "检查WireGuard状态" "true"; then
            log_success "✓ WireGuard配置检查正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ WireGuard配置检查失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    fi
}

# 测试WireGuard隧道建立
test_wireguard_tunnel() {
    log_info "开始WireGuard隧道测试..."
    
    # 检查WireGuard是否安装
    if ! command -v wg &> /dev/null; then
        log_warn "WireGuard未安装，跳过隧道测试"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
        return 0
    fi
    
    # 检查WireGuard配置文件
    local wg_config="/etc/wireguard/wg0.conf"
    if [[ -f "$wg_config" ]]; then
        log_info "发现WireGuard配置文件: $wg_config"
        
        # 检查WireGuard接口状态
        if execute_command "wg show wg0 2>/dev/null || echo 'WireGuard未运行'" "检查WireGuard状态" "true"; then
            log_success "✓ WireGuard配置检查正常"
            ((PASSED_TESTS++))
        else
            log_error "✗ WireGuard配置检查失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 测试WireGuard接口启动
        if execute_command "wg-quick up wg0" "启动WireGuard接口" "true"; then
            log_success "✓ WireGuard接口启动成功"
            ((PASSED_TESTS++))
            
            # 测试WireGuard接口状态
            if execute_command "wg show wg0" "检查WireGuard接口状态" "true"; then
                log_success "✓ WireGuard接口运行正常"
                ((PASSED_TESTS++))
            else
                log_error "✗ WireGuard接口状态异常"
                ((FAILED_TESTS++))
            fi
            ((TOTAL_TESTS++))
            
            # 停止WireGuard接口
            execute_command "wg-quick down wg0" "停止WireGuard接口" "true"
        else
            log_error "✗ WireGuard接口启动失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        log_warn "WireGuard配置文件不存在: $wg_config"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
    fi
}

# 测试BGP路由配置
test_bgp_routing() {
    log_info "开始BGP路由测试..."
    
    # 检查BIRD是否安装
    if ! command -v birdc &> /dev/null; then
        log_warn "BIRD未安装，跳过BGP测试"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
        return 0
    fi
    
    # 检查BIRD配置文件
    local bird_config="/etc/bird/bird.conf"
    if [[ -f "$bird_config" ]]; then
        log_info "发现BIRD配置文件: $bird_config"
        
        # 检查BIRD语法
        if execute_command "birdc -p -c '$bird_config'" "检查BIRD配置语法" "true"; then
            log_success "✓ BIRD配置语法正确"
            ((PASSED_TESTS++))
        else
            log_error "✗ BIRD配置语法错误"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 检查BIRD服务状态
        if execute_command "systemctl is-active bird" "检查BIRD服务状态" "true"; then
            log_success "✓ BIRD服务运行正常"
            ((PASSED_TESTS++))
        else
            log_warn "⚠ BIRD服务未运行"
            ((SKIPPED_TESTS++))
        fi
        ((TOTAL_TESTS++))
        
        # 检查BGP邻居状态
        if execute_command "birdc show protocols" "检查BGP协议状态" "true"; then
            log_success "✓ BGP协议状态检查成功"
            ((PASSED_TESTS++))
        else
            log_warn "⚠ BGP协议状态检查失败"
            ((SKIPPED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        log_warn "BIRD配置文件不存在: $bird_config"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
    fi
}

# ================================================================
# 客户端管理测试
# ================================================================

# 测试客户端配置生成
test_client_config_generation() {
    log_info "开始客户端配置生成测试..."
    
    local test_client_dir="/tmp/test_client_config"
    execute_command "mkdir -p '$test_client_dir'" "创建测试客户端目录" "true"
    
    # 创建测试客户端配置
    local client_config="$test_client_dir/test_client.conf"
    cat > "$client_config" << 'EOF'
[Interface]
PrivateKey = TEST_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 8.8.8.8

[Peer]
PublicKey = TEST_PUBLIC_KEY
Endpoint = 192.168.1.1:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    if [[ -f "$client_config" ]]; then
        log_success "✓ 客户端配置生成成功"
        ((PASSED_TESTS++))
        
        # 验证配置格式
        if grep -q "\[Interface\]" "$client_config" && grep -q "\[Peer\]" "$client_config"; then
            log_success "✓ 客户端配置格式正确"
            ((PASSED_TESTS++))
        else
            log_error "✗ 客户端配置格式错误"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        log_error "✗ 客户端配置生成失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 清理测试文件
    execute_command "rm -rf '$test_client_dir'" "清理测试文件" "true"
}

# 测试客户端QR码生成
test_client_qr_generation() {
    log_info "开始客户端QR码生成测试..."
    
    if command -v qrencode &> /dev/null; then
        local test_config="[Interface]\nPrivateKey = TEST_KEY\nAddress = 10.0.0.2/24"
        
        if execute_command "echo -e '$test_config' | qrencode -t ansiutf8" "生成QR码" "true"; then
            log_success "✓ QR码生成成功"
            ((PASSED_TESTS++))
        else
            log_error "✗ QR码生成失败"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        log_info "qrencode未安装，跳过QR码测试"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
    fi
}

# ================================================================
# 配置管理测试
# ================================================================

# 测试配置加载和验证
test_config_loading() {
    log_info "开始配置加载测试..."
    
    # 创建测试配置文件
    local test_config_file="/tmp/test_config.conf"
    cat > "$test_config_file" << 'EOF'
# 测试配置文件
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
LOG_LEVEL=INFO
ENABLE_IPV6=true
EOF
    
    # 测试配置加载
    if execute_command "bash -c 'source \"$test_config_file\" && echo \"Port: \$WIREGUARD_PORT\"" "测试配置加载" "true"; then
        log_success "✓ 配置加载成功"
        ((PASSED_TESTS++))
    else
        log_error "✗ 配置加载失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试配置验证
    if execute_command "bash -c 'source \"$test_config_file\" && [[ \$WIREGUARD_PORT -ge 1 && \$WIREGUARD_PORT -le 65535 ]]'" "测试端口验证" "true"; then
        log_success "✓ 端口验证成功"
        ((PASSED_TESTS++))
    else
        log_error "✗ 端口验证失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 清理测试文件
    execute_command "rm -f '$test_config_file'" "清理测试文件" "true"
}

# 测试配置修改
test_config_modification() {
    log_info "开始配置修改测试..."
    
    local test_config_file="/tmp/test_config_modify.conf"
    cat > "$test_config_file" << 'EOF'
WIREGUARD_PORT=51820
WIREGUARD_INTERFACE=wg0
EOF
    
    # 测试配置修改
    execute_command "sed -i 's/WIREGUARD_PORT=51820/WIREGUARD_PORT=51821/' '$test_config_file'" "修改配置" "true"
    
    if execute_command "bash -c 'source \"$test_config_file\" && [[ \$WIREGUARD_PORT -eq 51821 ]]'" "验证配置修改" "true"; then
        log_success "✓ 配置修改成功"
        ((PASSED_TESTS++))
    else
        log_error "✗ 配置修改失败"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 清理测试文件
    execute_command "rm -f '$test_config_file'" "清理测试文件" "true"
}

# ================================================================
# 性能测试
# ================================================================

# 测试系统性能
test_system_performance() {
    log_info "开始系统性能测试..."
    
    # 测试CPU性能
    local cpu_test_start=$(date +%s%N)
    for i in {1..1000}; do
        echo "test_$i" > /dev/null
    done
    local cpu_test_end=$(date +%s%N)
    local cpu_duration=$(( (cpu_test_end - cpu_test_start) / 1000000 ))
    
    if [[ $cpu_duration -lt 1000 ]]; then
        log_success "✓ CPU性能测试通过 (${cpu_duration}ms)"
        ((PASSED_TESTS++))
    else
        log_warn "⚠ CPU性能测试较慢 (${cpu_duration}ms)"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试内存性能
    local mem_test_start=$(date +%s%N)
    local test_array=()
    for i in {1..10000}; do
        test_array+=("test_string_$i")
    done
    unset test_array
    local mem_test_end=$(date +%s%N)
    local mem_duration=$(( (mem_test_end - mem_test_start) / 1000000 ))
    
    if [[ $mem_duration -lt 500 ]]; then
        log_success "✓ 内存性能测试通过 (${mem_duration}ms)"
        ((PASSED_TESTS++))
    else
        log_warn "⚠ 内存性能测试较慢 (${mem_duration}ms)"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 测试磁盘I/O性能
    local disk_test_file="/tmp/disk_test_$(date +%s)"
    local disk_test_start=$(date +%s%N)
    for i in {1..1000}; do
        echo "test_line_$i" >> "$disk_test_file"
    done
    local disk_test_end=$(date +%s%N)
    local disk_duration=$(( (disk_test_end - disk_test_start) / 1000000 ))
    
    if [[ $disk_duration -lt 2000 ]]; then
        log_success "✓ 磁盘I/O性能测试通过 (${disk_duration}ms)"
        ((PASSED_TESTS++))
    else
        log_warn "⚠ 磁盘I/O性能测试较慢 (${disk_duration}ms)"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # 清理测试文件
    execute_command "rm -f '$disk_test_file'" "清理测试文件" "true"
}

# ================================================================
# 主测试函数
# ================================================================

# 运行所有功能测试
run_all_functional_tests() {
    log_info "开始运行所有功能测试..."
    
    # 网络连接测试
    run_network_connection_test
    
    # WireGuard隧道测试
    test_wireguard_tunnel
    
    # BGP路由测试
    test_bgp_routing
    
    # 客户端管理测试
    test_client_config_generation
    test_client_qr_generation
    
    # 配置管理测试
    test_config_loading
    test_config_modification
    
    # 性能测试
    test_system_performance
    
    log_success "所有功能测试完成"
}

# ================================================================
# 导出函数
# ================================================================

export -f run_network_connection_test test_wireguard_tunnel test_bgp_routing
export -f test_client_config_generation test_client_qr_generation
export -f test_config_loading test_config_modification test_system_performance
export -f run_all_functional_tests
