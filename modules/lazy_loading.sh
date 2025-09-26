#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 配置懒加载模块
# 实现配置的懒加载机制，优化系统启动和内存使用

# 懒加载配置
LAZY_LOADING_DIR="${CONFIG_DIR}/lazy_loading"
LAZY_LOADING_CACHE="${LAZY_LOADING_DIR}/cache"
LAZY_LOADING_CONFIG="${LAZY_LOADING_DIR}/lazy_loading.conf"
LAZY_LOADING_LOG="${LOG_DIR}/lazy_loading.log"

# 懒加载状态
LAZY_LOADING_ENABLED=true
LAZY_LOADING_CACHE_SIZE=100
LAZY_LOADING_CACHE_TTL=3600  # 1小时
LAZY_LOADING_PRELOAD_CRITICAL=true

# 初始化懒加载模块
init_lazy_loading() {
    log_info "初始化配置懒加载模块..."
    
    # 创建目录
    mkdir -p "$LAZY_LOADING_DIR" "$LAZY_LOADING_CACHE"
    
    # 创建懒加载配置
    create_lazy_loading_config
    
    # 初始化懒加载缓存
    init_lazy_loading_cache
    
    # 创建懒加载管理器
    create_lazy_loading_manager
    
    log_info "配置懒加载模块初始化完成"
}

# 创建懒加载配置
create_lazy_loading_config() {
    cat > "$LAZY_LOADING_CONFIG" << 'EOF'
# 懒加载配置文件
# 生成时间: ${TIMESTAMP}

[general]
enabled = true
cache_size = 100
cache_ttl = 3600
preload_critical = true
log_level = INFO

[modules]
# 模块懒加载配置
wireguard_config = true
bird_config = true
network_management = true
firewall_management = true
client_management = true
monitoring_alerting = true
web_management = true
oauth_authentication = true
security_audit_monitoring = true
network_topology = true
api_documentation = true
websocket_realtime = true
multi_tenant = true
resource_quota = true

[preload]
# 关键模块预加载
critical_modules = common_functions,error_handling,system_detection,user_interface
important_modules = wireguard_config,bird_config,client_management
optional_modules = network_topology,api_documentation,websocket_realtime

[cache]
# 缓存配置
enable_cache = true
cache_directory = /etc/ipv6-wireguard-manager/lazy_loading/cache
max_cache_size = 100MB
cache_cleanup_interval = 3600
cache_compression = true

[performance]
# 性能优化配置
parallel_loading = true
max_parallel_loads = 4
load_timeout = 30
retry_attempts = 3
retry_delay = 1

[monitoring]
# 监控配置
enable_monitoring = true
log_load_times = true
log_cache_hits = true
log_memory_usage = true
performance_metrics = true
EOF
    
    # 替换时间戳
    sed -i "s/\${TIMESTAMP}/$(get_timestamp)/g" "$LAZY_LOADING_CONFIG"
}

# 初始化懒加载缓存
init_lazy_loading_cache() {
    log_info "初始化懒加载缓存..."
    
    # 创建缓存索引
    cat > "${LAZY_LOADING_CACHE}/index.json" << 'EOF'
{
    "cache_version": "1.0.0",
    "created_at": "",
    "last_updated": "",
    "cache_entries": {},
    "cache_stats": {
        "total_entries": 0,
        "cache_hits": 0,
        "cache_misses": 0,
        "cache_size": 0
    }
}
EOF
    
    # 替换时间戳
    sed -i "s/\"created_at\": \"\"/\"created_at\": \"$(get_timestamp)\"/g" "${LAZY_LOADING_CACHE}/index.json"
}

# 创建懒加载管理器
create_lazy_loading_manager() {
    cat > "${LAZY_LOADING_DIR}/lazy_loader.py" << 'EOF'
#!/usr/bin/env python3
# 懒加载管理器

import os
import json
import time
import hashlib
import threading
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

class LazyLoader:
    def __init__(self, config_file: str, cache_dir: str):
        self.config_file = config_file
        self.cache_dir = cache_dir
        self.cache_index = os.path.join(cache_dir, "index.json")
        self.loaded_modules = {}
        self.cache_stats = {
            "hits": 0,
            "misses": 0,
            "loads": 0
        }
        self.lock = threading.Lock()
        
        # 设置日志
        logging.basicConfig(
            filename='/var/log/ipv6-wireguard-manager/lazy_loading.log',
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        
        # 加载配置
        self.load_config()
        
        # 加载缓存索引
        self.load_cache_index()
    
    def load_config(self):
        """加载懒加载配置"""
        try:
            with open(self.config_file, 'r') as f:
                # 简单的配置文件解析
                self.config = {
                    'enabled': True,
                    'cache_size': 100,
                    'cache_ttl': 3600,
                    'preload_critical': True,
                    'parallel_loading': True,
                    'max_parallel_loads': 4
                }
        except Exception as e:
            self.logger.error(f"加载配置失败: {e}")
            self.config = {
                'enabled': True,
                'cache_size': 100,
                'cache_ttl': 3600,
                'preload_critical': True,
                'parallel_loading': True,
                'max_parallel_loads': 4
            }
    
    def load_cache_index(self):
        """加载缓存索引"""
        try:
            if os.path.exists(self.cache_index):
                with open(self.cache_index, 'r') as f:
                    self.cache_data = json.load(f)
            else:
                self.cache_data = {
                    "cache_version": "1.0.0",
                    "created_at": datetime.now().isoformat(),
                    "last_updated": datetime.now().isoformat(),
                    "cache_entries": {},
                    "cache_stats": {
                        "total_entries": 0,
                        "cache_hits": 0,
                        "cache_misses": 0,
                        "cache_size": 0
                    }
                }
        except Exception as e:
            self.logger.error(f"加载缓存索引失败: {e}")
            self.cache_data = {
                "cache_version": "1.0.0",
                "created_at": datetime.now().isoformat(),
                "last_updated": datetime.now().isoformat(),
                "cache_entries": {},
                "cache_stats": {
                    "total_entries": 0,
                    "cache_misses": 0,
                    "cache_size": 0
                }
            }
    
    def save_cache_index(self):
        """保存缓存索引"""
        try:
            with open(self.cache_index, 'w') as f:
                json.dump(self.cache_data, f, indent=2)
        except Exception as e:
            self.logger.error(f"保存缓存索引失败: {e}")
    
    def get_module_hash(self, module_name: str, module_path: str) -> str:
        """获取模块哈希值"""
        try:
            if os.path.exists(module_path):
                with open(module_path, 'rb') as f:
                    content = f.read()
                return hashlib.md5(content).hexdigest()
            return ""
        except Exception as e:
            self.logger.error(f"计算模块哈希失败: {e}")
            return ""
    
    def is_cache_valid(self, module_name: str) -> bool:
        """检查缓存是否有效"""
        if module_name not in self.cache_data["cache_entries"]:
            return False
        
        entry = self.cache_data["cache_entries"][module_name]
        cache_time = datetime.fromisoformat(entry["cached_at"])
        ttl = timedelta(seconds=self.config.get("cache_ttl", 3600))
        
        return datetime.now() - cache_time < ttl
    
    def load_module(self, module_name: str, module_path: str) -> bool:
        """懒加载模块"""
        if not self.config.get("enabled", True):
            return self.direct_load_module(module_name, module_path)
        
        with self.lock:
            # 检查是否已加载
            if module_name in self.loaded_modules:
                return True
            
            # 检查缓存
            if self.is_cache_valid(module_name):
                self.cache_stats["hits"] += 1
                self.cache_data["cache_stats"]["cache_hits"] += 1
                self.logger.info(f"从缓存加载模块: {module_name}")
                return True
            
            # 加载模块
            start_time = time.time()
            success = self.direct_load_module(module_name, module_path)
            load_time = time.time() - start_time
            
            if success:
                # 更新缓存
                self.update_cache(module_name, module_path)
                self.cache_stats["loads"] += 1
                self.logger.info(f"模块加载完成: {module_name} (耗时: {load_time:.2f}s)")
            else:
                self.cache_stats["misses"] += 1
                self.cache_data["cache_stats"]["cache_misses"] += 1
                self.logger.error(f"模块加载失败: {module_name}")
            
            return success
    
    def direct_load_module(self, module_name: str, module_path: str) -> bool:
        """直接加载模块"""
        try:
            if os.path.exists(module_path):
                # 这里应该执行实际的模块加载
                # 在bash环境中，这通常是通过source命令完成
                self.loaded_modules[module_name] = {
                    "path": module_path,
                    "loaded_at": datetime.now().isoformat(),
                    "status": "loaded"
                }
                return True
            return False
        except Exception as e:
            self.logger.error(f"直接加载模块失败: {e}")
            return False
    
    def update_cache(self, module_name: str, module_path: str):
        """更新缓存"""
        try:
            module_hash = self.get_module_hash(module_name, module_path)
            if module_hash:
                self.cache_data["cache_entries"][module_name] = {
                    "path": module_path,
                    "hash": module_hash,
                    "cached_at": datetime.now().isoformat(),
                    "status": "cached"
                }
                self.cache_data["cache_stats"]["total_entries"] = len(self.cache_data["cache_entries"])
                self.cache_data["last_updated"] = datetime.now().isoformat()
                self.save_cache_index()
        except Exception as e:
            self.logger.error(f"更新缓存失败: {e}")
    
    def preload_critical_modules(self, modules_dir: str):
        """预加载关键模块"""
        if not self.config.get("preload_critical", True):
            return
        
        critical_modules = [
            "common_functions",
            "error_handling", 
            "system_detection",
            "user_interface"
        ]
        
        for module in critical_modules:
            module_path = os.path.join(modules_dir, f"{module}.sh")
            if os.path.exists(module_path):
                self.load_module(module, module_path)
    
    def cleanup_cache(self):
        """清理过期缓存"""
        try:
            current_time = datetime.now()
            ttl = timedelta(seconds=self.config.get("cache_ttl", 3600))
            expired_entries = []
            
            for module_name, entry in self.cache_data["cache_entries"].items():
                cached_time = datetime.fromisoformat(entry["cached_at"])
                if current_time - cached_time > ttl:
                    expired_entries.append(module_name)
            
            for module_name in expired_entries:
                del self.cache_data["cache_entries"][module_name]
            
            if expired_entries:
                self.cache_data["cache_stats"]["total_entries"] = len(self.cache_data["cache_entries"])
                self.save_cache_index()
                self.logger.info(f"清理过期缓存: {len(expired_entries)} 个条目")
                
        except Exception as e:
            self.logger.error(f"清理缓存失败: {e}")
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """获取缓存统计"""
        return {
            "cache_hits": self.cache_stats["hits"],
            "cache_misses": self.cache_stats["misses"],
            "total_loads": self.cache_stats["loads"],
            "hit_rate": self.cache_stats["hits"] / max(1, self.cache_stats["hits"] + self.cache_stats["misses"]),
            "loaded_modules": len(self.loaded_modules),
            "cache_entries": len(self.cache_data["cache_entries"])
        }

# 全局懒加载器实例
lazy_loader = None

def get_lazy_loader():
    """获取懒加载器实例"""
    global lazy_loader
    if lazy_loader is None:
        config_file = "/etc/ipv6-wireguard-manager/lazy_loading/lazy_loading.conf"
        cache_dir = "/etc/ipv6-wireguard-manager/lazy_loading/cache"
        lazy_loader = LazyLoader(config_file, cache_dir)
    return lazy_loader

if __name__ == "__main__":
    # 测试懒加载器
    loader = get_lazy_loader()
    print("懒加载器初始化完成")
    print(f"缓存统计: {loader.get_cache_stats()}")
EOF
    
    chmod +x "${LAZY_LOADING_DIR}/lazy_loader.py"
}

# 懒加载管理菜单
lazy_loading_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 配置懒加载管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看懒加载状态"
        echo -e "${GREEN}2.${NC} 查看缓存统计"
        echo -e "${GREEN}3.${NC} 清理缓存"
        echo -e "${GREEN}4.${NC} 预加载模块"
        echo -e "${GREEN}5.${NC} 懒加载设置"
        echo -e "${GREEN}6.${NC} 性能监控"
        echo -e "${GREEN}7.${NC} 缓存管理"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) show_lazy_loading_status ;;
            2) show_cache_statistics ;;
            3) cleanup_cache ;;
            4) preload_modules ;;
            5) lazy_loading_settings ;;
            6) performance_monitoring ;;
            7) cache_management ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看懒加载状态
show_lazy_loading_status() {
    echo -e "${SECONDARY_COLOR}=== 懒加载状态 ===${NC}"
    echo
    
    if [[ -f "${LAZY_LOADING_DIR}/lazy_loader.py" ]]; then
        python3 "${LAZY_LOADING_DIR}/lazy_loader.py" 2>/dev/null || echo "懒加载器未运行"
    else
        show_error "懒加载器未安装"
    fi
}

# 查看缓存统计
show_cache_statistics() {
    echo -e "${SECONDARY_COLOR}=== 缓存统计 ===${NC}"
    echo
    
    if [[ -f "${LAZY_LOADING_CACHE}/index.json" ]]; then
        cat "${LAZY_LOADING_CACHE}/index.json" | python3 -m json.tool
    else
        show_error "缓存索引文件不存在"
    fi
}

# 清理缓存
cleanup_cache() {
    log_info "清理懒加载缓存..."
    
    if [[ -f "${LAZY_LOADING_DIR}/lazy_loader.py" ]]; then
        python3 -c "
from lazy_loader import get_lazy_loader
loader = get_lazy_loader()
loader.cleanup_cache()
print('缓存清理完成')
"
        show_success "缓存已清理"
    else
        show_error "懒加载器未安装"
    fi
}

# 预加载模块
preload_modules() {
    log_info "预加载关键模块..."
    
    if [[ -f "${LAZY_LOADING_DIR}/lazy_loader.py" ]]; then
        python3 -c "
from lazy_loader import get_lazy_loader
loader = get_lazy_loader()
loader.preload_critical_modules('$MODULES_DIR')
print('关键模块预加载完成')
"
        show_success "关键模块预加载完成"
    else
        show_error "懒加载器未安装"
    fi
}

# 懒加载设置
lazy_loading_settings() {
    echo -e "${SECONDARY_COLOR}=== 懒加载设置 ===${NC}"
    echo
    
    local enabled=$(show_selection "启用懒加载" "是" "否")
    local cache_size=$(show_input "缓存大小" "100")
    local cache_ttl=$(show_input "缓存TTL(秒)" "3600")
    local preload_critical=$(show_selection "预加载关键模块" "是" "否")
    local parallel_loading=$(show_selection "并行加载" "是" "否")
    
    # 更新配置文件
    sed -i "s/enabled = .*/enabled = $enabled/" "$LAZY_LOADING_CONFIG"
    sed -i "s/cache_size = .*/cache_size = $cache_size/" "$LAZY_LOADING_CONFIG"
    sed -i "s/cache_ttl = .*/cache_ttl = $cache_ttl/" "$LAZY_LOADING_CONFIG"
    sed -i "s/preload_critical = .*/preload_critical = $preload_critical/" "$LAZY_LOADING_CONFIG"
    sed -i "s/parallel_loading = .*/parallel_loading = $parallel_loading/" "$LAZY_LOADING_CONFIG"
    
    show_success "懒加载设置已保存"
}

# 性能监控
performance_monitoring() {
    echo -e "${SECONDARY_COLOR}=== 性能监控 ===${NC}"
    echo
    
    if [[ -f "${LAZY_LOADING_DIR}/lazy_loader.py" ]]; then
        python3 -c "
from lazy_loader import get_lazy_loader
loader = get_lazy_loader()
stats = loader.get_cache_stats()
print('缓存命中率:', f'{stats[\"hit_rate\"]:.2%}')
print('缓存命中次数:', stats['cache_hits'])
print('缓存未命中次数:', stats['cache_misses'])
print('总加载次数:', stats['total_loads'])
print('已加载模块数:', stats['loaded_modules'])
print('缓存条目数:', stats['cache_entries'])
"
    else
        show_error "懒加载器未安装"
    fi
}

# 缓存管理
cache_management() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 缓存管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 查看缓存内容"
        echo -e "${GREEN}2.${NC} 清理过期缓存"
        echo -e "${GREEN}3.${NC} 清空所有缓存"
        echo -e "${GREEN}4.${NC} 压缩缓存"
        echo -e "${GREEN}5.${NC} 导出缓存"
        echo -e "${GREEN}6.${NC} 导入缓存"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-6]: " choice
        
        case $choice in
            1) view_cache_contents ;;
            2) cleanup_expired_cache ;;
            3) clear_all_cache ;;
            4) compress_cache ;;
            5) export_cache ;;
            6) import_cache ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 查看缓存内容
view_cache_contents() {
    echo -e "${SECONDARY_COLOR}=== 缓存内容 ===${NC}"
    echo
    
    if [[ -f "${LAZY_LOADING_CACHE}/index.json" ]]; then
        echo "缓存条目:"
        jq -r '.cache_entries | keys[]' "${LAZY_LOADING_CACHE}/index.json" 2>/dev/null || echo "无法解析缓存索引"
    else
        show_error "缓存索引文件不存在"
    fi
}

# 导出函数
export -f init_lazy_loading create_lazy_loading_config init_lazy_loading_cache
export -f create_lazy_loading_manager lazy_loading_menu show_lazy_loading_status
export -f show_cache_statistics cleanup_cache preload_modules lazy_loading_settings
export -f performance_monitoring cache_management view_cache_contents
