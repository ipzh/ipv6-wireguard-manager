#!/bin/bash

# WireGuard配置文件修复脚本
# 修复配置文件中的中文注释和无效行

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] [$level] $message${NC}" >&2
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] [$level] $message${NC}" >&2
            ;;
        *)
            echo -e "[$timestamp] [$level] $message" >&2
            ;;
    esac
}

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    log "ERROR" "This script must be run as root."
    exit 1
fi

# 配置文件路径
CONFIG_FILE="/etc/wireguard/wg0.conf"
BACKUP_FILE="/etc/wireguard/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)"

log "INFO" "开始修复WireGuard配置文件..."

# 检查配置文件是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
    log "ERROR" "WireGuard配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 备份原配置文件
log "INFO" "备份原配置文件到: $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

# 显示当前配置文件内容
log "INFO" "当前配置文件内容:"
echo "----------------------------------------"
cat "$CONFIG_FILE"
echo "----------------------------------------"

# 创建临时文件
TEMP_FILE=$(mktemp)

# 清理配置文件
log "INFO" "清理配置文件中的无效行..."

# 只保留有效的WireGuard配置行
grep -E '^\[Interface\]|^\[Peer\]|^PrivateKey|^PublicKey|^Address|^ListenPort|^SaveConfig|^PostUp|^PostDown|^AllowedIPs|^Endpoint|^PersistentKeepalive|^PresharedKey|^# [A-Za-z]|^$' "$CONFIG_FILE" > "$TEMP_FILE"

# 检查清理后的文件
if [[ -s "$TEMP_FILE" ]]; then
    log "INFO" "清理后的配置文件内容:"
    echo "----------------------------------------"
    cat "$TEMP_FILE"
    echo "----------------------------------------"
    
    # 替换原配置文件
    mv "$TEMP_FILE" "$CONFIG_FILE"
    
    # 设置正确的权限
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    log "INFO" "配置文件已修复"
    
    # 验证配置文件语法
    log "INFO" "验证配置文件语法..."
    if wg-quick strip wg0 >/dev/null 2>&1; then
        log "INFO" "配置文件语法正确"
        
        # 尝试启动WireGuard服务
        log "INFO" "尝试启动WireGuard服务..."
        if systemctl start wg-quick@wg0.service; then
            log "INFO" "WireGuard服务启动成功"
            
            # 检查服务状态
            systemctl status wg-quick@wg0.service --no-pager
            
        else
            log "ERROR" "WireGuard服务启动失败"
            systemctl status wg-quick@wg0.service --no-pager
        fi
        
    else
        log "ERROR" "配置文件语法仍有问题"
        log "INFO" "语法检查结果:"
        wg-quick strip wg0 2>&1 || true
        
        # 恢复备份
        log "WARN" "恢复原配置文件..."
        mv "$BACKUP_FILE" "$CONFIG_FILE"
    fi
    
else
    log "ERROR" "清理后的配置文件为空，恢复原配置"
    mv "$BACKUP_FILE" "$CONFIG_FILE"
fi

# 清理临时文件
rm -f "$TEMP_FILE"

log "INFO" "修复完成"
