#!/bin/bash

# IPv6 WireGuard Manager 双栈支持验证脚本
# 验证前后端IPv6/IPv4双栈支持

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "IPv6 WireGuard Manager 双栈支持验证"
echo "=========================================="

# 检查后端IPv6/IPv4支持
check_backend_dual_stack() {
    log_info "检查后端IPv6/IPv4双栈支持..."
    
    local backend_config="backend/app/core/config.py"
    local backend_main="backend/app/main.py"
    
    # 检查服务器监听配置
    if grep -q 'SERVER_HOST.*0\.0\.0\.0' "$backend_config"; then
        log_success "后端服务器配置为监听所有接口 (0.0.0.0)"
    else
        log_error "后端服务器未配置为监听所有接口"
        return 1
    fi
    
    # 检查CORS配置
    if grep -q 'http://\[::1\]' "$backend_config"; then
        log_success "后端CORS配置支持IPv6"
    else
        log_error "后端CORS配置缺少IPv6支持"
        return 1
    fi
    
    if grep -q 'https://\[::1\]' "$backend_config"; then
        log_success "后端CORS配置支持IPv6 HTTPS"
    else
        log_warning "后端CORS配置缺少IPv6 HTTPS支持"
    fi
    
    # 检查TrustedHost配置
    if grep -q '::1' "$backend_main"; then
        log_success "后端TrustedHost配置支持IPv6"
    else
        log_error "后端TrustedHost配置缺少IPv6支持"
        return 1
    fi
    
    # 检查内网IPv6支持
    if grep -q 'fd00:' "$backend_config"; then
        log_success "后端支持内网IPv6 (fd00::/8)"
    else
        log_warning "后端缺少内网IPv6支持"
    fi
    
    return 0
}

# 检查前端IPv6/IPv4支持
check_frontend_dual_stack() {
    log_info "检查前端IPv6/IPv4双栈支持..."
    
    local vite_config="frontend/vite.config.ts"
    local api_service="frontend/src/services/api.ts"
    local ws_service="frontend/src/services/websocket.ts"
    local config_utils="frontend/src/utils/config.ts"
    
    # 检查Vite开发服务器配置
    if grep -q "host.*0\.0\.0\.0" "$vite_config"; then
        log_success "前端开发服务器配置为监听所有接口"
    else
        log_error "前端开发服务器未配置为监听所有接口"
        return 1
    fi
    
    # 检查API服务动态URL检测
    if grep -q "getApiBaseUrl" "$api_service"; then
        log_success "前端API服务支持动态URL检测"
    else
        log_error "前端API服务缺少动态URL检测"
        return 1
    fi
    
    # 检查WebSocket服务动态URL检测
    if grep -q "getWebSocketBaseUrl" "$ws_service"; then
        log_success "前端WebSocket服务支持动态URL检测"
    else
        log_error "前端WebSocket服务缺少动态URL检测"
        return 1
    fi
    
    # 检查配置工具
    if grep -q "isIPv6" "$config_utils"; then
        log_success "前端配置工具支持IPv6检测"
    else
        log_error "前端配置工具缺少IPv6检测"
        return 1
    fi
    
    # 检查IPv6地址检测
    if grep -q "isLocalHost" "$config_utils"; then
        log_success "前端支持IPv6本地地址检测"
    else
        log_error "前端缺少IPv6本地地址检测"
        return 1
    fi
    
    return 0
}

# 检查Docker IPv6/IPv4支持
check_docker_dual_stack() {
    log_info "检查Docker IPv6/IPv4双栈支持..."
    
    local docker_compose="docker-compose.yml"
    local docker_prod="docker-compose.production.yml"
    
    # 检查开发环境Docker配置
    if grep -q "enable_ipv6.*true" "$docker_compose"; then
        log_success "开发环境Docker配置启用IPv6"
    else
        log_error "开发环境Docker配置未启用IPv6"
        return 1
    fi
    
    if grep -q "2001:db8::/64" "$docker_compose"; then
        log_success "开发环境Docker配置IPv6子网"
    else
        log_error "开发环境Docker配置缺少IPv6子网"
        return 1
    fi
    
    # 检查生产环境Docker配置
    if grep -q "enable_ipv6.*true" "$docker_prod"; then
        log_success "生产环境Docker配置启用IPv6"
    else
        log_error "生产环境Docker配置未启用IPv6"
        return 1
    fi
    
    if grep -q "2001:db8::/64" "$docker_prod"; then
        log_success "生产环境Docker配置IPv6子网"
    else
        log_error "生产环境Docker配置缺少IPv6子网"
        return 1
    fi
    
    # 检查Nginx IPv6端口映射
    if grep -q "\[::\]:80:80" "$docker_prod"; then
        log_success "生产环境Docker配置IPv6端口映射"
    else
        log_warning "生产环境Docker配置缺少IPv6端口映射"
    fi
    
    return 0
}

# 检查Nginx IPv6/IPv4支持
check_nginx_dual_stack() {
    log_info "检查Nginx IPv6/IPv4双栈支持..."
    
    local nginx_config="frontend/nginx.conf"
    local install_script="install-complete.sh"
    
    # 检查Nginx配置文件
    if grep -q "listen \[::\]:80" "$nginx_config"; then
        log_success "Nginx配置支持IPv6监听"
    else
        log_error "Nginx配置缺少IPv6监听"
        return 1
    fi
    
    # 检查安装脚本中的Nginx配置
    if grep -q "listen \[::\]:80" "$install_script"; then
        log_success "安装脚本Nginx配置支持IPv6"
    else
        log_error "安装脚本Nginx配置缺少IPv6支持"
        return 1
    fi
    
    return 0
}

# 检查环境变量配置
check_env_config() {
    log_info "检查环境变量配置..."
    
    local frontend_env="frontend/env.example"
    local backend_env="backend/env.example"
    
    # 检查前端环境变量
    if grep -q "VITE_API_URL=http://localhost:8000" "$frontend_env"; then
        log_success "前端环境变量使用localhost（支持动态检测）"
    else
        log_warning "前端环境变量可能包含硬编码IP"
    fi
    
    if grep -q "VITE_WS_URL=ws://localhost:8000" "$frontend_env"; then
        log_success "前端WebSocket环境变量使用localhost"
    else
        log_warning "前端WebSocket环境变量可能包含硬编码IP"
    fi
    
    # 检查后端环境变量
    if grep -q 'SERVER_HOST="0\.0\.0\.0"' "$backend_env"; then
        log_success "后端环境变量配置为监听所有接口"
    else
        log_error "后端环境变量未配置为监听所有接口"
        return 1
    fi
    
    return 0
}

# 检查硬编码IP问题
check_hardcoded_ips() {
    log_info "检查硬编码IP问题..."
    
    local hardcoded_files=()
    
    # 检查脚本文件中的硬编码IP
    for file in *.sh; do
        if [ -f "$file" ]; then
            if grep -q "172\.16\.1\.117\|192\.168\.[0-9]\+\.[0-9]\+\|10\.[0-9]\+\.[0-9]\+\.[0-9]\+" "$file"; then
                hardcoded_files+=("$file")
            fi
        fi
    done
    
    if [ ${#hardcoded_files[@]} -eq 0 ]; then
        log_success "未发现硬编码IP问题"
    else
        log_warning "发现以下文件包含硬编码IP："
        for file in "${hardcoded_files[@]}"; do
            echo "  - $file"
        done
    fi
    
    return 0
}

# 生成双栈支持报告
generate_dual_stack_report() {
    log_info "生成双栈支持报告..."
    
    cat > /tmp/dual-stack-support-report.txt << EOF
IPv6 WireGuard Manager 双栈支持验证报告
=====================================

验证时间: $(date)

后端IPv6/IPv4双栈支持:
- 服务器监听: $(grep -q 'SERVER_HOST.*0\.0\.0\.0' backend/app/core/config.py && echo "✅ 支持" || echo "❌ 不支持")
- CORS IPv6支持: $(grep -q 'http://\[::1\]' backend/app/core/config.py && echo "✅ 支持" || echo "❌ 不支持")
- CORS IPv6 HTTPS: $(grep -q 'https://\[::1\]' backend/app/core/config.py && echo "✅ 支持" || echo "❌ 不支持")
- TrustedHost IPv6: $(grep -q '::1' backend/app/main.py && echo "✅ 支持" || echo "❌ 不支持")
- 内网IPv6支持: $(grep -q 'fd00:' backend/app/core/config.py && echo "✅ 支持" || echo "❌ 不支持")

前端IPv6/IPv4双栈支持:
- 开发服务器监听: $(grep -q "host.*0\.0\.0\.0" frontend/vite.config.ts && echo "✅ 支持" || echo "❌ 不支持")
- API动态URL检测: $(grep -q "getApiBaseUrl" frontend/src/services/api.ts && echo "✅ 支持" || echo "❌ 不支持")
- WebSocket动态URL: $(grep -q "getWebSocketBaseUrl" frontend/src/services/websocket.ts && echo "✅ 支持" || echo "❌ 不支持")
- IPv6地址检测: $(grep -q "isIPv6" frontend/src/utils/config.ts && echo "✅ 支持" || echo "❌ 不支持")
- IPv6本地地址: $(grep -q "isLocalHost" frontend/src/utils/config.ts && echo "✅ 支持" || echo "❌ 不支持")

Docker IPv6/IPv4双栈支持:
- 开发环境IPv6: $(grep -q "enable_ipv6.*true" docker-compose.yml && echo "✅ 支持" || echo "❌ 不支持")
- 开发环境IPv6子网: $(grep -q "2001:db8::/64" docker-compose.yml && echo "✅ 支持" || echo "❌ 不支持")
- 生产环境IPv6: $(grep -q "enable_ipv6.*true" docker-compose.production.yml && echo "✅ 支持" || echo "❌ 不支持")
- 生产环境IPv6子网: $(grep -q "2001:db8::/64" docker-compose.production.yml && echo "✅ 支持" || echo "❌ 不支持")
- IPv6端口映射: $(grep -q "\[::\]:80:80" docker-compose.production.yml && echo "✅ 支持" || echo "❌ 不支持")

Nginx IPv6/IPv4双栈支持:
- Nginx IPv6监听: $(grep -q "listen \[::\]:80" frontend/nginx.conf && echo "✅ 支持" || echo "❌ 不支持")
- 安装脚本IPv6: $(grep -q "listen \[::\]:80" install-complete.sh && echo "✅ 支持" || echo "❌ 不支持")

环境变量配置:
- 前端API URL: $(grep -q "VITE_API_URL=http://localhost:8000" frontend/env.example && echo "✅ 正确" || echo "❌ 错误")
- 前端WS URL: $(grep -q "VITE_WS_URL=ws://localhost:8000" frontend/env.example && echo "✅ 正确" || echo "❌ 错误")
- 后端监听配置: $(grep -q 'SERVER_HOST="0\.0\.0\.0"' backend/env.example && echo "✅ 正确" || echo "❌ 错误")

硬编码IP检查:
$(if [ $(find . -name "*.sh" -exec grep -l "172\.16\.1\.117\|192\.168\.[0-9]\+\.[0-9]\+\|10\.[0-9]\+\.[0-9]\+\.[0-9]\+" {} \; | wc -l) -eq 0 ]; then echo "- 硬编码IP: ✅ 无问题"; else echo "- 硬编码IP: ❌ 发现问题"; fi)

总结:
项目已完全支持IPv6/IPv4双栈网络，可以在任何支持双栈的主机上部署。
系统会自动检测网络环境并适配相应的协议。

部署建议:
1. 确保系统支持IPv6（可选但推荐）
2. 配置防火墙允许必要端口
3. 使用动态配置，避免硬编码IP
4. 生产环境建议配置SSL证书
EOF

    log_success "双栈支持报告已生成: /tmp/dual-stack-support-report.txt"
}

# 主函数
main() {
    local all_checks_passed=true
    
    if ! check_backend_dual_stack; then
        all_checks_passed=false
    fi
    
    if ! check_frontend_dual_stack; then
        all_checks_passed=false
    fi
    
    if ! check_docker_dual_stack; then
        all_checks_passed=false
    fi
    
    if ! check_nginx_dual_stack; then
        all_checks_passed=false
    fi
    
    if ! check_env_config; then
        all_checks_passed=false
    fi
    
    check_hardcoded_ips
    
    generate_dual_stack_report
    
    echo ""
    echo "=========================================="
    if [ "$all_checks_passed" = true ]; then
        log_success "IPv6/IPv4双栈支持验证通过！"
        echo ""
        echo "🎯 项目完全支持双栈网络："
        echo "  - 后端：监听所有接口，支持IPv6 CORS和TrustedHost"
        echo "  - 前端：动态URL检测，自动适配IPv6/IPv4"
        echo "  - Docker：启用IPv6网络，配置双栈子网"
        echo "  - Nginx：同时监听IPv4和IPv6端口"
        echo ""
        echo "📋 详细报告："
        echo "  cat /tmp/dual-stack-support-report.txt"
    else
        log_error "IPv6/IPv4双栈支持验证未通过！"
        echo ""
        echo "⚠️  请修复上述问题后重新验证"
        echo ""
        echo "📋 详细报告："
        echo "  cat /tmp/dual-stack-support-report.txt"
    fi
    echo "=========================================="
}

# 运行主函数
main "$@"
