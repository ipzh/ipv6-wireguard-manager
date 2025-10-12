#!/bin/bash

# IPv6 WireGuard Manager One-Click Installation Script
# Fixed for non-interactive mode (curl | bash)

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "=================================="
echo "IPv6 WireGuard Manager Installation"
echo "=================================="

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root"
    exit 1
fi

# Detect system environment
log_info "Detecting system environment..."

# Detect operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$NAME"
    OS_VERSION="$VERSION_ID"
else
    OS_NAME="Unknown"
    OS_VERSION="Unknown"
fi

# Detect memory
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')

log_info "System information:"
echo "  OS: $OS_NAME $OS_VERSION"
echo "  Memory: ${TOTAL_MEM}MB"
echo ""

# Smart installation type selection
log_info "Smart installation type selection..."

# Check if running in non-interactive mode (curl | bash)
if [ ! -t 0 ]; then
    log_info "Non-interactive mode detected, using automatic selection"
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        INSTALL_TYPE="low-memory"
        log_warning "Memory less than 1GB, selecting low-memory installation"
    elif [ "$TOTAL_MEM" -lt 2048 ]; then
        INSTALL_TYPE="native"
        log_info "Low memory, selecting native installation (better performance)"
    else
        INSTALL_TYPE="docker"
        log_info "Sufficient memory, selecting Docker installation (environment isolation)"
    fi
    log_info "Auto-selected: $INSTALL_TYPE"
else
    # Interactive mode - show installation options
    echo "🎯 Installation Options:"
    echo "  1. Docker Installation - Environment isolation, easy management"
    echo "  2. Native Installation - Best performance, minimal resource usage"
    echo "  3. Low Memory Installation - Optimized for 1GB memory"
    echo "  4. VPS Installation - Optimized for VPS environments"
    echo "  5. Auto Selection - Smart selection based on system environment"
    echo ""
    
    # Show system recommendations
    echo "💡 System Recommendations:"
    if [ "$TOTAL_MEM" -lt 1024 ]; then
        echo "  Low Memory (<1GB): Recommended Low Memory Installation"
    elif [ "$TOTAL_MEM" -lt 2048 ]; then
        echo "  Medium Memory (<2GB): Recommended Native Installation"
    else
        echo "  High Memory (>=2GB): Recommended Docker Installation"
    fi
    echo ""
    
    # Get user choice
    while true; do
        echo -n "Please select installation type (1-5): "
        read -r choice
        
        case $choice in
            1)
                INSTALL_TYPE="docker"
                log_info "Selected: Docker Installation"
                break
                ;;
            2)
                INSTALL_TYPE="native"
                log_info "Selected: Native Installation"
                break
                ;;
            3)
                INSTALL_TYPE="low-memory"
                log_info "Selected: Low Memory Installation"
                break
                ;;
            4)
                INSTALL_TYPE="vps"
                log_info "Selected: VPS Installation"
                break
                ;;
            5|"")
                # Auto selection
                if [ "$TOTAL_MEM" -lt 1024 ]; then
                    INSTALL_TYPE="low-memory"
                    log_warning "Auto-selected: Low Memory Installation"
                elif [ "$TOTAL_MEM" -lt 2048 ]; then
                    INSTALL_TYPE="native"
                    log_info "Auto-selected: Native Installation"
                else
                    INSTALL_TYPE="docker"
                    log_info "Auto-selected: Docker Installation"
                fi
                break
                ;;
            *)
                log_error "Invalid selection. Please choose 1-5."
                ;;
        esac
    done
fi

echo ""

# Project information
REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.zip"
INSTALL_DIR="ipv6-wireguard-manager"
PROJECT_DIR="$(pwd)/$INSTALL_DIR"

# Download project
log_info "Downloading project..."

if [ -d "$INSTALL_DIR" ]; then
    log_info "Cleaning old project directory..."
    rm -rf "$INSTALL_DIR"
fi

# Download project
if command -v wget >/dev/null 2>&1; then
    log_info "Using wget to download project..."
    wget -q "$REPO_URL" -O project.zip
elif command -v curl >/dev/null 2>&1; then
    log_info "Using curl to download project..."
    curl -fsSL "$REPO_URL" -o project.zip
else
    log_error "wget or curl is required to download the project"
    exit 1
fi

# Extract project
unzip -q project.zip
rm project.zip

# Rename directory
if [ -d "ipv6-wireguard-manager-main" ]; then
    mv ipv6-wireguard-manager-main "$INSTALL_DIR"
fi

log_success "Project download completed"

# Execute installation
log_info "Executing installation..."

if [ -f "$PROJECT_DIR/install-complete.sh" ]; then
    chmod +x "$PROJECT_DIR/install-complete.sh"
    # Map VPS installation to native for now (can be customized later)
    if [ "$INSTALL_TYPE" = "vps" ]; then
        log_info "VPS installation mapped to native installation"
        "$PROJECT_DIR/install-complete.sh" "native"
    else
        "$PROJECT_DIR/install-complete.sh" "$INSTALL_TYPE"
    fi
else
    log_error "Installation script not found"
    exit 1
fi

# Show installation result
echo ""
echo "=================================="
echo "Installation Completed!"
echo "=================================="
echo ""

log_info "Service access addresses:"
echo "  Frontend: http://$(hostname -I | awk '{print $1}')"
echo "  Backend API: http://127.0.0.1:8000"
echo "  API Docs: http://127.0.0.1:8000/docs"
echo ""

log_info "Default login credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""

log_success "Installation completed! Please access the frontend to get started."
