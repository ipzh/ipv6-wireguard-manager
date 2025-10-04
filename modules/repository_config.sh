#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 仓库配置模块
# 负责管理远程仓库地址和下载配置

# 默认仓库配置
DEFAULT_REPOSITORY_CONFIG=(
    "REPO_OWNER=ipzh"
    "REPO_NAME=ipv6-wireguard-manager"
    "REPO_BRANCH=main"
    "REPO_URL=https://github.com/ipzh/ipv6-wireguard-manager"
    "RAW_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main"
    "API_URL=https://api.github.com/repos/ipzh/ipv6-wireguard-manager"
    "RELEASES_URL=https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases"
    "LATEST_RELEASE_URL=https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases/latest"
    "DOWNLOAD_URL=https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.tar.gz"
    "INSTALL_SCRIPT_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh"
    "UNINSTALL_SCRIPT_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/uninstall.sh"
    "UPDATE_SCRIPT_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/update.sh"
)

# 仓库配置文件
REPOSITORY_CONFIG_FILE="${CONFIG_DIR}/repository.conf"

# 初始化仓库配置
init_repository_config() {
    log_info "初始化仓库配置..."
    
    # 创建配置目录
    mkdir -p "$CONFIG_DIR"
    
    # 创建仓库配置文件
    create_repository_config
    
    # 加载配置
    load_repository_config
    
    log_info "仓库配置初始化完成"
}

# 创建仓库配置文件
create_repository_config() {
    if [[ ! -f "$REPOSITORY_CONFIG_FILE" ]]; then
        cat > "$REPOSITORY_CONFIG_FILE" << EOF
# IPv6 WireGuard Manager 仓库配置文件
# 生成时间: $(get_timestamp "$@")

# 仓库基本信息
REPO_OWNER=ipzh
REPO_NAME=ipv6-wireguard-manager
REPO_BRANCH=main

# 仓库URL配置
REPO_URL=https://github.com/ipzh/ipv6-wireguard-manager
RAW_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main
API_URL=https://api.github.com/repos/ipzh/ipv6-wireguard-manager
RELEASES_URL=https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases
LATEST_RELEASE_URL=https://api.github.com/repos/ipzh/ipv6-wireguard-manager/releases/latest

# 下载URL配置
DOWNLOAD_URL=https://github.com/ipzh/ipv6-wireguard-manager/archive/refs/heads/main.tar.gz
INSTALL_SCRIPT_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh
UNINSTALL_SCRIPT_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/uninstall.sh
UPDATE_SCRIPT_URL=https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/update.sh

# 备用仓库配置（用于故障转移）
BACKUP_REPOSITORIES=(
    "https://github.com/ipzh/ipv6-wireguard-manager"
    "https://gitlab.com/ipzh/ipv6-wireguard-manager"
    "https://gitee.com/ipzh/ipv6-wireguard-manager"
)

# 镜像配置
MIRROR_SITES=(
    "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main"
    "https://cdn.jsdelivr.net/gh/ipzh/ipv6-wireguard-manager@main"
    "https://gitee.com/ipzh/ipv6-wireguard-manager/raw/main"
)

# 下载配置
DOWNLOAD_TIMEOUT=30
DOWNLOAD_RETRIES=3
DOWNLOAD_USER_AGENT="IPv6-WireGuard-Manager/1.0.0"
EOF
        log_info "仓库配置文件已创建: $REPOSITORY_CONFIG_FILE"
    fi
}

# 加载仓库配置
load_repository_config() {
    if [[ -f "$REPOSITORY_CONFIG_FILE" ]]; then
        source "$REPOSITORY_CONFIG_FILE"
        log_info "仓库配置已加载"
    else
        log_warn "仓库配置文件不存在，使用默认配置"
        load_default_repository_config
    fi
}

# 加载默认仓库配置
load_default_repository_config() {
    for config in "${DEFAULT_REPOSITORY_CONFIG[@]}"; do
        local key=$(echo "$config" | cut -d'=' -f1)
        local value=$(echo "$config" | cut -d'=' -f2-)
        declare "$key=$value"
        export "$key"
    done
    log_info "默认仓库配置已加载"
}

# 获取仓库URL
get_repository_url() {
    echo "$REPO_URL"
}

# 获取原始文件URL
get_raw_url() {
    local file_path="$1"
    echo "${RAW_URL}/${file_path}"
}

# 获取API URL
get_api_url() {
    echo "$API_URL"
}

# 获取最新发布URL
get_latest_release_url() {
    echo "$LATEST_RELEASE_URL"
}

# 获取下载URL
get_download_url() {
    local version="${1:-main}"
    if [[ "$version" == "main" ]] || [[ "$version" == "latest" ]]; then
        echo "$DOWNLOAD_URL"
    else
        echo "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/tags/v${version}.tar.gz"
    fi
}

# 获取安装脚本URL
get_install_script_url() {
    echo "$INSTALL_SCRIPT_URL"
}

# 获取卸载脚本URL
get_uninstall_script_url() {
    echo "$UNINSTALL_SCRIPT_URL"
}

# 获取更新脚本URL
get_update_script_url() {
    echo "$UPDATE_SCRIPT_URL"
}

# 下载文件
download_file() {
    local url="$1"
    local output_file="$2"
    local timeout="${3:-$DOWNLOAD_TIMEOUT}"
    local retries="${4:-$DOWNLOAD_RETRIES}"
    
    log_info "下载文件: $url"
    
    # 尝试使用curl
    if command -v curl &> /dev/null; then
        if curl -L --connect-timeout "$timeout" --retry "$retries" \
           -H "User-Agent: $DOWNLOAD_USER_AGENT" \
           -o "$output_file" "$url"; then
            log_info "文件下载成功: $output_file"
            return 0
        fi
    fi
    
    # 尝试使用wget
    if command -v wget &> /dev/null; then
        if wget --timeout="$timeout" --tries="$retries" \
           --user-agent="$DOWNLOAD_USER_AGENT" \
           -O "$output_file" "$url"; then
            log_info "文件下载成功: $output_file"
            return 0
        fi
    fi
    
    log_error "文件下载失败: $url"
    return 1
}

# 下载并执行脚本
download_and_execute() {
    local script_url="$1"
    local script_name="${2:-install.sh}"
    local temp_script="/tmp/${script_name}"
    
    log_info "下载并执行脚本: $script_url"
    
    # 下载脚本
    if download_file "$script_url" "$temp_script"; then
        # 设置执行权限
        chmod +x "$temp_script"
        
        # 执行脚本
        if bash "$temp_script" "$@"; then
            log_info "脚本执行成功"
            rm -f "$temp_script"
            return 0
        else
            log_error "脚本执行失败"
            rm -f "$temp_script"
            return 1
        fi
    else
        log_error "脚本下载失败"
        return 1
    fi
}

# 一键安装
one_click_install() {
    log_info "开始一键安装..."
    
    local install_url=$(get_install_script_url)
    
    echo "正在下载安装脚本..."
    if download_and_execute "$install_url" "install.sh"; then
        log_info "一键安装完成"
        return 0
    else
        log_error "一键安装失败"
        return 1
    fi
}

# 手动下载安装
manual_download_install() {
    log_info "开始手动下载安装..."
    
    local install_url=$(get_install_script_url)
    local install_script="install.sh"
    
    echo "正在下载安装脚本..."
    if download_file "$install_url" "$install_script"; then
        chmod +x "$install_script"
        echo "安装脚本下载完成: $install_script"
        echo "请运行: sudo ./$install_script"
        return 0
    else
        log_error "安装脚本下载失败"
        return 1
    fi
}

# 交互式安装
interactive_install() {
    log_info "开始交互式安装..."
    
    local install_url=$(get_install_script_url)
    local install_script="install.sh"
    
    echo "正在下载安装脚本..."
    if download_file "$install_url" "$install_script"; then
        chmod +x "$install_script"
        echo "安装脚本下载完成"
        echo "请运行: sudo ./$install_script"
        echo
        echo "安装选项:"
        echo "1. 快速安装 - 使用默认配置"
        echo "2. 交互式安装 - 自定义配置"
        echo "3. 仅下载文件 - 不安装"
        return 0
    else
        log_error "安装脚本下载失败"
        return 1
    fi
}

# 从源码安装
source_install() {
    log_info "开始从源码安装..."
    
    local repo_url=$(get_repository_url)
    local repo_name="${REPO_NAME}"
    
    echo "正在克隆仓库..."
    if git clone "$repo_url" "$repo_name"; then
        cd "$repo_name" || exit
        echo "仓库克隆完成"
        echo "请运行: sudo ./install.sh"
        return 0
    else
        log_error "仓库克隆失败"
        return 1
    fi
}

# 检查仓库连接
check_repository_connection() {
    local repo_url=$(get_repository_url)
    local api_url=$(get_api_url)
    
    log_info "检查仓库连接..."
    
    # 检查仓库URL
    if curl -s --head "$repo_url" | head -n 1 | grep -q "200 OK"; then
        log_info "仓库连接正常: $repo_url"
    else
        log_warn "仓库连接异常: $repo_url"
    fi
    
    # 检查API URL
    if curl -s --head "$api_url" | head -n 1 | grep -q "200 OK"; then
        log_info "API连接正常: $api_url"
    else
        log_warn "API连接异常: $api_url"
    fi
}

# 更新仓库配置
update_repository_config() {
    echo -e "${SECONDARY_COLOR}=== 更新仓库配置 ===${NC}"
    echo
    
    local config_type=$(show_selection "配置类型" "仓库信息" "URL配置" "镜像配置" "下载配置")
    
    case "$config_type" in
        "仓库信息")
            update_repository_info
            ;;
        "URL配置")
            update_url_config
            ;;
        "镜像配置")
            update_mirror_config
            ;;
        "下载配置")
            update_download_config
            ;;
    esac
}

# 更新仓库信息
update_repository_info() {
    echo "仓库信息配置:"
    echo "----------------------------------------"
    
    local new_owner=$(show_input "仓库所有者" "$REPO_OWNER")
    local new_name=$(show_input "仓库名称" "$REPO_NAME")
    local new_branch=$(show_input "默认分支" "$REPO_BRANCH")
    
    update_config_value "REPO_OWNER" "$new_owner"
    update_config_value "REPO_NAME" "$new_name"
    update_config_value "REPO_BRANCH" "$new_branch"
    
    # 更新相关URL
    update_config_value "REPO_URL" "https://github.com/${new_owner}/${new_name}"
    update_config_value "RAW_URL" "https://raw.githubusercontent.com/${new_owner}/${new_name}/${new_branch}"
    update_config_value "API_URL" "https://api.github.com/repos/${new_owner}/${new_name}"
    update_config_value "RELEASES_URL" "https://api.github.com/repos/${new_owner}/${new_name}/releases"
    update_config_value "LATEST_RELEASE_URL" "https://api.github.com/repos/${new_owner}/${new_name}/releases/latest"
    
    log_info "仓库信息已更新"
}

# 更新URL配置
update_url_config() {
    echo "URL配置:"
    echo "----------------------------------------"
    
    local new_repo_url=$(show_input "仓库URL" "$REPO_URL")
    local new_raw_url=$(show_input "原始文件URL" "$RAW_URL")
    local new_api_url=$(show_input "API URL" "$API_URL")
    
    update_config_value "REPO_URL" "$new_repo_url"
    update_config_value "RAW_URL" "$new_raw_url"
    update_config_value "API_URL" "$new_api_url"
    
    log_info "URL配置已更新"
}

# 更新镜像配置
update_mirror_config() {
    echo "镜像配置:"
    echo "----------------------------------------"
    
    echo "当前镜像站点:"
    for i in "${!MIRROR_SITES[@]}"; do
        echo "$((i+1)). ${MIRROR_SITES[$i]}"
    done
    
    local action=$(show_selection "操作" "添加镜像" "删除镜像" "测试镜像")
    
    case "$action" in
        "添加镜像")
            add_mirror_site
            ;;
        "删除镜像")
            remove_mirror_site
            ;;
        "测试镜像")
            test_mirror_sites
            ;;
    esac
}

# 添加镜像站点
add_mirror_site() {
    local new_mirror=$(show_input "新镜像站点URL" "")
    
    if [[ -n "$new_mirror" ]]; then
        MIRROR_SITES+=("$new_mirror")
        update_mirror_sites_config
        log_info "镜像站点已添加: $new_mirror"
    fi
}

# 删除镜像站点
remove_mirror_site() {
    echo "选择要删除的镜像站点:"
    for i in "${!MIRROR_SITES[@]}"; do
        echo "$((i+1)). ${MIRROR_SITES[$i]}"
    done
    
    local choice=$(show_input "选择序号" "")
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#MIRROR_SITES[@]} ]]; then
        unset MIRROR_SITES[$((choice-1))]
        MIRROR_SITES=("${MIRROR_SITES[@]}")
        update_mirror_sites_config
        log_info "镜像站点已删除"
    else
        show_error "无效的选择"
    fi
}

# 测试镜像站点
test_mirror_sites() {
    echo "测试镜像站点连接..."
    
    for mirror in "${MIRROR_SITES[@]}"; do
        echo "测试: $mirror"
        if curl -s --head "$mirror" | head -n 1 | grep -q "200 OK"; then
            echo "  ✓ 连接正常"
        else
            echo "  ✗ 连接失败"
        fi
    done
}

# 更新镜像站点配置
update_mirror_sites_config() {
    # 这里可以添加更新配置文件的逻辑
    log_info "镜像站点配置已更新"
}

# 更新下载配置
update_download_config() {
    echo "下载配置:"
    echo "----------------------------------------"
    
    local new_timeout=$(show_input "下载超时(秒)" "$DOWNLOAD_TIMEOUT")
    local new_retries=$(show_input "重试次数" "$DOWNLOAD_RETRIES")
    local new_user_agent=$(show_input "User-Agent" "$DOWNLOAD_USER_AGENT")
    
    update_config_value "DOWNLOAD_TIMEOUT" "$new_timeout"
    update_config_value "DOWNLOAD_RETRIES" "$new_retries"
    update_config_value "DOWNLOAD_USER_AGENT" "$new_user_agent"
    
    log_info "下载配置已更新"
}

# 更新配置值
update_config_value() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$REPOSITORY_CONFIG_FILE"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$REPOSITORY_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$REPOSITORY_CONFIG_FILE"
    fi
}

# 获取安装方法
get_install_methods() {
    echo "可用的安装方法:"
    echo "----------------------------------------"
    echo "1. 一键安装（推荐）"
    echo "   curl -sSL $(get_install_script_url) | bash"
    echo
    echo "2. 手动下载安装"
    echo "   wget $(get_install_script_url)"
    echo "   chmod +x install.sh"
    echo "   sudo ./install.sh"
    echo
    echo "3. 交互式安装"
    echo "   sudo ./install.sh"
    echo "   选择安装选项"
    echo
    echo "4. 从源码安装"
    echo "   git clone $(get_repository_url)"
    echo "   cd ipv6-wireguard-manager" || exit
    echo "   sudo ./install.sh"
}

# 显示安装帮助
show_install_help() {
    echo -e "${SECONDARY_COLOR}=== 安装帮助 ===${NC}"
    echo
    
    get_install_methods
    
    echo
    echo "安装选项:"
    echo "----------------------------------------"
    echo "1. 快速安装 - 使用默认配置"
    echo "2. 交互式安装 - 自定义配置"
    echo "3. 仅下载文件 - 不安装"
    echo
    echo "更多信息请访问: $(get_repository_url)"
}

# 导出函数
export -f init_repository_config create_repository_config load_repository_config
export -f get_repository_url get_raw_url get_api_url get_latest_release_url
export -f get_download_url get_install_script_url get_uninstall_script_url
export -f get_update_script_url download_file download_and_execute
export -f one_click_install manual_download_install interactive_install
export -f source_install check_repository_connection update_repository_config
export -f get_install_methods show_install_help
