@echo off
echo #!/bin/bash > install.sh
echo. >> install.sh
echo # IPv6 WireGuard Manager One-Click Installation Script >> install.sh
echo # Fixed for non-interactive mode (curl ^| bash) >> install.sh
echo. >> install.sh
echo set -e >> install.sh
echo. >> install.sh
echo # Color definitions >> install.sh
echo RED='\033[0;31m' >> install.sh
echo GREEN='\033[0;32m' >> install.sh
echo YELLOW='\033[1;33m' >> install.sh
echo BLUE='\033[0;34m' >> install.sh
echo NC='\033[0m' >> install.sh
echo. >> install.sh
echo # Logging functions >> install.sh
echo log_info^(^) { >> install.sh
echo     echo -e "${BLUE}[INFO]${NC} $1" >> install.sh
echo } >> install.sh
echo. >> install.sh
echo log_success^(^) { >> install.sh
echo     echo -e "${GREEN}[SUCCESS]${NC} $1" >> install.sh
echo } >> install.sh
echo. >> install.sh
echo log_warning^(^) { >> install.sh
echo     echo -e "${YELLOW}[WARNING]${NC} $1" >> install.sh
echo } >> install.sh
echo. >> install.sh
echo log_error^(^) { >> install.sh
echo     echo -e "${RED}[ERROR]${NC} $1" >> install.sh
echo } >> install.sh
echo. >> install.sh
echo echo "==================================" >> install.sh
echo echo "IPv6 WireGuard Manager Installation" >> install.sh
echo echo "==================================" >> install.sh
echo. >> install.sh
echo # Check root privileges >> install.sh
echo if [ "$EUID" -ne 0 ]; then >> install.sh
echo     log_error "Please run this script as root" >> install.sh
echo     exit 1 >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo # Detect system environment >> install.sh
echo log_info "Detecting system environment..." >> install.sh
echo. >> install.sh
echo # Detect operating system >> install.sh
echo if [ -f /etc/os-release ]; then >> install.sh
echo     . /etc/os-release >> install.sh
echo     OS_NAME="$NAME" >> install.sh
echo     OS_VERSION="$VERSION_ID" >> install.sh
echo else >> install.sh
echo     OS_NAME="Unknown" >> install.sh
echo     OS_VERSION="Unknown" >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo # Detect memory >> install.sh
echo TOTAL_MEM=$(free -m ^| awk 'NR==2{printf "%.0f", $2}') >> install.sh
echo. >> install.sh
echo # Detect WSL >> install.sh
echo if grep -q Microsoft /proc/version 2>/dev/null; then >> install.sh
echo     IS_WSL=true >> install.sh
echo else >> install.sh
echo     IS_WSL=false >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo log_info "System information:" >> install.sh
echo echo "  OS: $OS_NAME $OS_VERSION" >> install.sh
echo echo "  Memory: ${TOTAL_MEM}MB" >> install.sh
echo echo "  WSL: $IS_WSL" >> install.sh
echo echo "" >> install.sh
echo. >> install.sh
echo # Smart installation type selection >> install.sh
echo log_info "Smart installation type selection..." >> install.sh
echo. >> install.sh
echo if [ "$TOTAL_MEM" -lt 1024 ]; then >> install.sh
echo     INSTALL_TYPE="low-memory" >> install.sh
echo     log_warning "Memory less than 1GB, selecting low-memory installation" >> install.sh
echo elif [ "$IS_WSL" = true ]; then >> install.sh
echo     INSTALL_TYPE="native" >> install.sh
echo     log_info "WSL environment detected, selecting native installation" >> install.sh
echo elif [ "$TOTAL_MEM" -lt 2048 ]; then >> install.sh
echo     INSTALL_TYPE="native" >> install.sh
echo     log_info "Low memory, selecting native installation (better performance)" >> install.sh
echo else >> install.sh
echo     INSTALL_TYPE="docker" >> install.sh
echo     log_info "Sufficient memory, selecting Docker installation (environment isolation)" >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo log_info "Auto-selected: $INSTALL_TYPE" >> install.sh
echo echo "" >> install.sh
echo. >> install.sh
echo # Project information >> install.sh
echo REPO_URL="https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.zip" >> install.sh
echo INSTALL_DIR="ipv6-wireguard-manager" >> install.sh
echo PROJECT_DIR="$(pwd)/$INSTALL_DIR" >> install.sh
echo. >> install.sh
echo # Download project >> install.sh
echo log_info "Downloading project..." >> install.sh
echo. >> install.sh
echo if [ -d "$INSTALL_DIR" ]; then >> install.sh
echo     log_info "Cleaning old project directory..." >> install.sh
echo     rm -rf "$INSTALL_DIR" >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo # Download project >> install.sh
echo if command -v wget >/dev/null 2>&1; then >> install.sh
echo     log_info "Using wget to download project..." >> install.sh
echo     wget -q "$REPO_URL" -O project.zip >> install.sh
echo elif command -v curl >/dev/null 2>&1; then >> install.sh
echo     log_info "Using curl to download project..." >> install.sh
echo     curl -fsSL "$REPO_URL" -o project.zip >> install.sh
echo else >> install.sh
echo     log_error "wget or curl is required to download the project" >> install.sh
echo     exit 1 >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo # Extract project >> install.sh
echo unzip -q project.zip >> install.sh
echo rm project.zip >> install.sh
echo. >> install.sh
echo # Rename directory >> install.sh
echo if [ -d "ipv6-wireguard-manager-main" ]; then >> install.sh
echo     mv ipv6-wireguard-manager-main "$INSTALL_DIR" >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo log_success "Project download completed" >> install.sh
echo. >> install.sh
echo # Execute installation >> install.sh
echo log_info "Executing installation..." >> install.sh
echo. >> install.sh
echo if [ -f "$PROJECT_DIR/install-complete.sh" ]; then >> install.sh
echo     chmod +x "$PROJECT_DIR/install-complete.sh" >> install.sh
echo     "$PROJECT_DIR/install-complete.sh" "$INSTALL_TYPE" >> install.sh
echo else >> install.sh
echo     log_error "Installation script not found" >> install.sh
echo     exit 1 >> install.sh
echo fi >> install.sh
echo. >> install.sh
echo # Show installation result >> install.sh
echo echo "" >> install.sh
echo echo "==================================" >> install.sh
echo echo "Installation Completed!" >> install.sh
echo echo "==================================" >> install.sh
echo echo "" >> install.sh
echo. >> install.sh
echo log_info "Service access addresses:" >> install.sh
echo echo "  Frontend: http://$(hostname -I ^| awk '{print $1}')" >> install.sh
echo echo "  Backend API: http://127.0.0.1:8000" >> install.sh
echo echo "  API Docs: http://127.0.0.1:8000/docs" >> install.sh
echo echo "" >> install.sh
echo. >> install.sh
echo log_info "Default login credentials:" >> install.sh
echo echo "  Username: admin" >> install.sh
echo echo "  Password: admin123" >> install.sh
echo echo "" >> install.sh
echo. >> install.sh
echo log_success "Installation completed! Please access the frontend to get started." >> install.sh
