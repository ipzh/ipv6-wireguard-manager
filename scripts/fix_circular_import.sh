#!/bin/bash

# 修复循环导入问题的脚本
# 解决 backend/app/core/config_enhanced.py 和 path_config.py 之间的循环导入

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 备份原始文件
backup_files() {
    log_info "备份原始配置文件..."
    
    local backup_dir="/opt/ipv6-wireguard-manager/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    cp /opt/ipv6-wireguard-manager/backend/app/core/config_enhanced.py "$backup_dir/" || {
        log_error "无法备份 config_enhanced.py"
        exit 1
    }
    
    cp /opt/ipv6-wireguard-manager/backend/app/core/path_config.py "$backup_dir/" || {
        log_error "无法备份 path_config.py"
        exit 1
    }
    
    log_info "文件已备份到: $backup_dir"
}

# 修复循环导入问题
fix_circular_import() {
    log_info "修复循环导入问题..."
    
    # 修复 path_config.py - 移除对 config_enhanced 的导入
    log_info "修复 path_config.py..."
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 修改 path_config.py 文件
    cat > "$temp_file" << 'EOF'
"""
路径配置管理模块
支持环境变量覆盖和自定义路径
"""
from pathlib import Path
from typing import Optional, Dict, Any
import os
import logging

logger = logging.getLogger(__name__)

class PathConfig:
    """路径配置管理类，支持环境变量覆盖和自定义路径"""
    
    def __init__(self, install_dir: Optional[str] = None):
        # 基础安装目录，支持环境变量覆盖
        if install_dir:
            self.base_dir = Path(install_dir)
        else:
            self.base_dir = Path(os.getenv("INSTALL_DIR", "/opt/ipv6-wireguard-manager"))
        
        # 应用内部目录
        self.config_dir = self.base_dir / "config"
        self.data_dir = self.base_dir / "data"
        self.logs_dir = self.base_dir / "logs"
        self.temp_dir = self.base_dir / "temp"
        self.backups_dir = self.base_dir / "backups"
        self.cache_dir = self.base_dir / "cache"
        
        # 系统路径配置，支持环境变量覆盖
        self.wireguard_config_dir = Path(os.getenv("WIREGUARD_CONFIG_DIR", "/etc/wireguard"))
        self.wireguard_clients_dir = self.wireguard_config_dir / "clients"
        self.frontend_dir = Path(os.getenv("FRONTEND_DIR", "/var/www/html"))
        self.nginx_config_dir = Path(os.getenv("NGINX_CONFIG_DIR", "/etc/nginx/sites-available"))
        self.nginx_log_dir = Path(os.getenv("NGINX_LOG_DIR", "/var/log/nginx"))
        self.systemd_config_dir = Path(os.getenv("SYSTEMD_CONFIG_DIR", "/etc/systemd/system"))
        
        # 二进制文件目录
        self.bin_dir = Path(os.getenv("BIN_DIR", "/usr/local/bin"))
        
        # 确保目录存在
        self._ensure_directories()
        
        # 验证路径权限
        self._validate_paths()
    
    def _ensure_directories(self):
        """确保必要的目录存在"""
        directories = [
            self.base_dir, self.config_dir, self.data_dir, 
            self.logs_dir, self.temp_dir, self.backups_dir, self.cache_dir
        ]
        
        for directory in directories:
            try:
                directory.mkdir(parents=True, exist_ok=True)
                logger.debug(f"确保目录存在: {directory}")
            except PermissionError:
                logger.warning(f"无法创建目录 {directory}，权限不足")
            except Exception as e:
                logger.error(f"创建目录 {directory} 失败: {e}")
    
    def _validate_paths(self):
        """验证路径权限和可访问性"""
        critical_paths = [
            (self.wireguard_config_dir, "WireGuard配置目录"),
            (self.frontend_dir, "前端Web目录"),
            (self.nginx_config_dir, "Nginx配置目录"),
            (self.systemd_config_dir, "Systemd服务目录")
        ]
        
        for path, description in critical_paths:
            if not path.exists():
                logger.warning(f"{description}不存在: {path}")
            elif not os.access(path, os.R_OK):
                logger.warning(f"{description}不可读: {path}")
            elif not os.access(path, os.W_OK):
                logger.warning(f"{description}不可写: {path}")
            else:
                logger.debug(f"{description}验证通过: {path}")
    
    def get_path(self, path_name: str) -> Optional[Path]:
        """获取指定名称的路径"""
        return getattr(self, path_name, None)
    
    def update_path(self, path_name: str, new_path: str):
        """更新指定路径"""
        try:
            new_path_obj = Path(new_path)
            setattr(self, path_name, new_path_obj)
            
            # 如果是基础目录，重新创建相关目录
            if path_name == "base_dir":
                self._ensure_directories()
            
            logger.info(f"路径 {path_name} 已更新为: {new_path}")
        except Exception as e:
            logger.error(f"更新路径 {path_name} 失败: {e}")
            raise
    
    def get_relative_path(self, base_path_name: str, relative_path: str) -> Path:
        """获取相对于基础路径的路径"""
        base_path = self.get_path(base_path_name)
        if base_path is None:
            raise ValueError(f"基础路径 {base_path_name} 不存在")
        return base_path / relative_path
    
    def ensure_path_exists(self, path_name: str) -> bool:
        """确保指定路径存在"""
        path = self.get_path(path_name)
        if path is None:
            return False
        
        try:
            path.mkdir(parents=True, exist_ok=True)
            return True
        except Exception as e:
            logger.error(f"创建路径 {path} 失败: {e}")
            return False
    
    def check_path_permissions(self, path_name: str, required_perms: str = "rw") -> bool:
        """检查路径权限"""
        path = self.get_path(path_name)
        if path is None:
            return False
        
        if not path.exists():
            return False
        
        try:
            if "r" in required_perms and not os.access(path, os.R_OK):
                return False
            if "w" in required_perms and not os.access(path, os.W_OK):
                return False
            if "x" in required_perms and not os.access(path, os.X_OK):
                return False
            return True
        except Exception:
            return False
    
    def to_dict(self) -> Dict[str, Any]:
        """将路径配置转换为字典"""
        return {
            "base_dir": str(self.base_dir),
            "config_dir": str(self.config_dir),
            "data_dir": str(self.data_dir),
            "logs_dir": str(self.logs_dir),
            "temp_dir": str(self.temp_dir),
            "backups_dir": str(self.backups_dir),
            "cache_dir": str(self.cache_dir),
            "wireguard_config_dir": str(self.wireguard_config_dir),
            "wireguard_clients_dir": str(self.wireguard_clients_dir),
            "frontend_dir": str(self.frontend_dir),
            "nginx_config_dir": str(self.nginx_config_dir),
            "nginx_log_dir": str(self.nginx_log_dir),
            "systemd_config_dir": str(self.systemd_config_dir),
            "bin_dir": str(self.bin_dir)
        }
    
    def get_env_vars(self) -> Dict[str, str]:
        """获取所有环境变量配置"""
        env_vars = {}
        for key, value in os.environ.items():
            if key.endswith(('_DIR', '_PATH')) and any(
                path_key in key.lower() for path_key in 
                ['install', 'frontend', 'config', 'log', 'nginx', 'systemd', 'wireguard', 'bin']
            ):
                env_vars[key] = value
        return env_vars
    
    def validate_all_paths(self) -> Dict[str, Any]:
        """验证所有路径的状态"""
        validation_result = {
            "valid": True,
            "paths": {},
            "errors": [],
            "warnings": []
        }
        
        path_names = [
            "base_dir", "config_dir", "data_dir", "logs_dir", 
            "temp_dir", "backups_dir", "cache_dir",
            "wireguard_config_dir", "wireguard_clients_dir",
            "frontend_dir", "nginx_config_dir", "nginx_log_dir",
            "systemd_config_dir", "bin_dir"
        ]
        
        for path_name in path_names:
            path = self.get_path(path_name)
            if path is None:
                validation_result["errors"].append(f"路径 {path_name} 未定义")
                validation_result["valid"] = False
                continue
            
            path_info = {
                "path": str(path),
                "exists": path.exists(),
                "readable": os.access(path, os.R_OK) if path.exists() else False,
                "writable": os.access(path, os.W_OK) if path.exists() else False,
                "executable": os.access(path, os.X_OK) if path.exists() else False
            }
            
            validation_result["paths"][path_name] = path_info
            
            # 检查关键路径
            if path_name in ["wireguard_config_dir", "frontend_dir", "nginx_config_dir"]:
                if not path_info["exists"]:
                    validation_result["warnings"].append(f"关键路径 {path_name} 不存在: {path}")
                elif not path_info["readable"]:
                    validation_result["warnings"].append(f"关键路径 {path_name} 不可读: {path}")
                elif not path_info["writable"]:
                    validation_result["warnings"].append(f"关键路径 {path_name} 不可写: {path}")
        
        return validation_result

# 创建全局路径配置实例
path_config = PathConfig()

# 便捷函数
def get_path(path_name: str) -> Optional[Path]:
    """获取指定名称的路径（便捷函数）"""
    return path_config.get_path(path_name)

def update_path(path_name: str, new_path: str):
    """更新指定路径（便捷函数）"""
    path_config.update_path(path_name, new_path)

def ensure_path_exists(path_name: str) -> bool:
    """确保指定路径存在（便捷函数）"""
    return path_config.ensure_path_exists(path_name)

def validate_paths() -> Dict[str, Any]:
    """验证所有路径（便捷函数）"""
    return path_config.validate_all_paths()
EOF
    
    # 替换原文件
    mv "$temp_file" /opt/ipv6-wireguard-manager/backend/app/core/path_config.py || {
        log_error "无法更新 path_config.py"
        exit 1
    }
    
    # 修复 config_enhanced.py - 移除对 path_config 的直接导入
    log_info "修复 config_enhanced.py..."
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 获取 config_enhanced.py 的内容并修改
    sed 's/from \.path_config import path_config/# Removed direct import to avoid circular import/' \
        /opt/ipv6-wireguard-manager/backend/app/core/config_enhanced.py > "$temp_file"
    
    # 修改属性方法，使用延迟导入
    sed -i 's/return str(path_config.wireguard_config_dir)/from \.path_config import PathConfig\n        path_config = PathConfig(self.INSTALL_DIR)\n        return str(path_config.wireguard_config_dir)/' "$temp_file"
    sed -i 's/return str(path_config.wireguard_clients_dir)/from \.path_config import PathConfig\n        path_config = PathConfig(self.INSTALL_DIR)\n        return str(path_config.wireguard_clients_dir)/' "$temp_file"
    sed -i 's/return str(path_config.frontend_dir)/from \.path_config import PathConfig\n        path_config = PathConfig(self.INSTALL_DIR)\n        return str(path_config.frontend_dir)/' "$temp_file"
    
    # 替换原文件
    mv "$temp_file" /opt/ipv6-wireguard-manager/backend/app/core/config_enhanced.py || {
        log_error "无法更新 config_enhanced.py"
        exit 1
    }
    
    log_info "循环导入问题已修复"
}

# 重启服务
restart_service() {
    log_info "重启 IPv6 WireGuard Manager 服务..."
    
    systemctl restart ipv6-wireguard-manager || {
        log_error "无法重启服务"
        exit 1
    }
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if systemctl is-active --quiet ipv6-wireguard-manager; then
        log_info "服务已成功启动"
    else
        log_error "服务启动失败"
        exit 1
    fi
}

# 验证修复
verify_fix() {
    log_info "验证修复结果..."
    
    # 检查服务日志
    local log_output=$(journalctl -u ipv6-wireguard-manager --no-pager -n 20 2>/dev/null || echo "无法获取日志")
    
    if echo "$log_output" | grep -q "ImportError.*circular import"; then
        log_error "循环导入问题仍然存在"
        exit 1
    else
        log_info "循环导入问题已解决"
    fi
    
    # 检查API服务状态
    if /opt/ipv6-wireguard-manager/scripts/check_api_service.sh | grep -q "API服务 服务未运行"; then
        log_warn "API服务可能仍有问题，请检查日志"
    else
        log_info "API服务运行正常"
    fi
}

# 主函数
main() {
    log_info "开始修复循环导入问题..."
    
    check_root
    backup_files
    fix_circular_import
    restart_service
    verify_fix
    
    log_info "循环导入问题修复完成！"
}

# 执行主函数
main "$@"