#!/bin/bash

# IPv6 WireGuard Manager - Linux一键安装脚本
# 专为Linux服务器环境设计
# 修复了所有FastAPI依赖注入问题

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

# Auto-select installation type based on system memory
auto_select_install_type() {
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    
    if [ "$memory_mb" -lt 1024 ]; then
        echo "low-memory"
    elif [ "$memory_mb" -lt 2048 ]; then
        echo "native"
    else
        echo "docker"
    fi
}

# Show installation options
show_install_options() {
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    
    echo ""
    log_info "Installation Options:"
    echo "🐳 1. Docker Installation (Recommended for beginners)"
    echo "   - Pros: Environment isolation, easy management, one-click deployment"
    echo "   - Cons: Higher resource usage, slight performance loss"
    echo "   - Suitable: Test environments, development, scenarios with low performance requirements"
    echo "   - Memory requirement: 2GB+"
    echo ""
    echo "⚡ 2. Native Installation (Recommended for VPS)"
    echo "   - Pros: Optimal performance, minimal resource usage, fast startup"
    echo "   - Cons: Manual dependency management, relatively complex environment configuration"
    echo "   - Suitable: Production environments, VPS deployment, high-performance scenarios"
    echo "   - Memory requirement: 1GB+"
    echo ""
    echo "📊 Performance Comparison:"
    echo "   - Memory usage: Docker 2GB+ vs Native 1GB+"
    echo "   - Startup speed: Docker slower vs Native fast"
    echo "   - Performance: Docker good vs Native optimal"
    echo ""
    
    # Check if running in non-interactive mode
    if [ ! -t 0 ] || [ "$1" = "--auto" ]; then
        local auto_type=$(auto_select_install_type)
        log_info "Non-interactive mode detected, using auto-selection: $auto_type"
        echo "$auto_type"
        return
    fi
    
    echo -n "Please enter your choice (1 or 2): "
    read -r choice
    
    case $choice in
        1) echo "docker" ;;
        2) echo "native" ;;
        *) 
            log_warning "Invalid choice, using auto-selection"
            auto_select_install_type
            ;;
    esac
}

# Main installation function
main() {
    log_info "IPv6 WireGuard Manager Installation Script - Fixed Version"
    log_info "All FastAPI dependency injection issues have been resolved"
    echo ""
    
    # Check if running in non-interactive mode
    local install_type
    if [ ! -t 0 ] || [ "$1" = "--auto" ]; then
        install_type=$(auto_select_install_type)
        log_info "Non-interactive mode detected, auto-selecting: $install_type"
    else
        install_type=$(show_install_options)
    fi
    
    log_info "Selected installation type: $install_type"
    
    # Download and run the complete installation script
    log_info "Downloading complete installation script..."
    
    case $install_type in
        "docker")
            log_info "Starting Docker installation..."
            curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-complete.sh | bash -s docker
            ;;
        "native")
            log_info "Starting native installation..."
            curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-complete.sh | bash -s native
            ;;
        "low-memory")
            log_info "Starting low-memory installation..."
            curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-complete.sh | bash -s low-memory
            ;;
        *)
            log_error "Invalid installation type: $install_type"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"