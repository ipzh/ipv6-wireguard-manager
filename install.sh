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

# Parse command line arguments
parse_arguments() {
    local install_type=""
    local install_dir="/opt/ipv6-wireguard-manager"
    local port="80"
    local silent=false
    local performance=false
    local production=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            docker|native|low-memory)
                install_type="$1"
                shift
                ;;
            --dir)
                install_dir="$2"
                shift 2
                ;;
            --port)
                port="$2"
                shift 2
                ;;
            --silent)
                silent=true
                shift
                ;;
            --performance)
                performance=true
                shift
                ;;
            --production)
                production=true
                shift
                ;;
            --auto)
                silent=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # If no install type specified, auto-select
    if [ -z "$install_type" ]; then
        if [ "$silent" = true ] || [ ! -t 0 ]; then
            install_type=$(auto_select_install_type)
        else
            install_type=$(show_install_options)
        fi
    fi
    
    echo "$install_type|$install_dir|$port|$silent|$performance|$production"
}

# Show help information
show_help() {
    echo "IPv6 WireGuard Manager Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS] [INSTALL_TYPE]"
    echo ""
    echo "Install Types:"
    echo "  docker      Docker installation (recommended for beginners)"
    echo "  native      Native installation (recommended for VPS)"
    echo "  low-memory  Low memory installation (1GB+ RAM)"
    echo ""
    echo "Options:"
    echo "  --dir DIR       Installation directory (default: /opt/ipv6-wireguard-manager)"
    echo "  --port PORT     Web server port (default: 80)"
    echo "  --silent        Silent installation (no interaction)"
    echo "  --performance   Enable performance optimizations"
    echo "  --production    Production installation with monitoring"
    echo "  --auto          Auto-select installation type"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive installation"
    echo "  $0 docker                            # Docker installation"
    echo "  $0 --dir /opt/my-app --port 8080     # Custom directory and port"
    echo "  $0 --silent --performance            # Silent with optimizations"
    echo "  $0 --production native               # Production native installation"
}

# Main installation function
main() {
    log_info "IPv6 WireGuard Manager Installation Script - Enhanced Version"
    log_info "All FastAPI dependency injection issues have been resolved"
    echo ""
    
    # Parse arguments
    local args=$(parse_arguments "$@")
    IFS='|' read -r install_type install_dir port silent performance production <<< "$args"
    
    log_info "Installation configuration:"
    log_info "  Type: $install_type"
    log_info "  Directory: $install_dir"
    log_info "  Port: $port"
    log_info "  Silent: $silent"
    log_info "  Performance: $performance"
    log_info "  Production: $production"
    echo ""
    
    # Download and run the complete installation script
    log_info "Downloading complete installation script..."
    
    # Build arguments for install-complete.sh
    local complete_args="$install_type"
    [ "$install_dir" != "/opt/ipv6-wireguard-manager" ] && complete_args="$complete_args --dir $install_dir"
    [ "$port" != "80" ] && complete_args="$complete_args --port $port"
    [ "$silent" = true ] && complete_args="$complete_args --silent"
    [ "$performance" = true ] && complete_args="$complete_args --performance"
    [ "$production" = true ] && complete_args="$complete_args --production"
    
    case $install_type in
        "docker")
            log_info "Starting Docker installation..."
            curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-complete.sh | bash -s $complete_args
            ;;
        "native")
            log_info "Starting native installation..."
            curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-complete.sh | bash -s $complete_args
            ;;
        "low-memory")
            log_info "Starting low-memory installation..."
            curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-complete.sh | bash -s $complete_args
            ;;
        *)
            log_error "Invalid installation type: $install_type"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"