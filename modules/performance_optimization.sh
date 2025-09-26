#!/bin/bash
# 导入公共函数库
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"

# 确保日志相关变量已定义
LOG_DIR="${LOG_DIR:-/var/log/ipv6-wireguard-manager}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/manager.log}"
fi

# 性能优化模块
# 实现内存和CPU使用优化

# 性能优化配置
PERFORMANCE_OPTIMIZATION_DIR="${CONFIG_DIR}/performance_optimization"
PERFORMANCE_CONFIG="${PERFORMANCE_OPTIMIZATION_DIR}/performance.conf"
PERFORMANCE_MONITORING_DB="${PERFORMANCE_OPTIMIZATION_DIR}/performance.db"
PERFORMANCE_LOG="${LOG_DIR}/performance.log"

# 性能优化状态
PERFORMANCE_OPTIMIZATION_ENABLED=true
MEMORY_OPTIMIZATION=true
CPU_OPTIMIZATION=true
CACHE_OPTIMIZATION=true
PROCESS_OPTIMIZATION=true

# 初始化性能优化模块
init_performance_optimization() {
    log_info "初始化性能优化模块..."
    
    # 创建目录
    mkdir -p "$PERFORMANCE_OPTIMIZATION_DIR"
    
    # 创建性能配置
    create_performance_config
    
    # 初始化性能监控数据库
    init_performance_monitoring_db
    
    # 创建性能优化脚本
    create_performance_optimization_scripts
    
    # 启动性能监控
    start_performance_monitoring
    
    log_info "性能优化模块初始化完成"
}

# 创建性能配置
create_performance_config() {
    cat > "$PERFORMANCE_CONFIG" << 'EOF'
# 性能优化配置文件
# 生成时间: ${TIMESTAMP}

[memory]
# 内存优化配置
enable_memory_optimization = true
memory_threshold = 80
memory_cleanup_interval = 300
memory_compression = true
memory_pool_size = 100MB
memory_cache_size = 50MB

[cpu]
# CPU优化配置
enable_cpu_optimization = true
cpu_threshold = 80
cpu_affinity = true
cpu_priority = normal
cpu_governor = performance
cpu_scaling = true

[cache]
# 缓存优化配置
enable_cache_optimization = true
cache_size_limit = 200MB
cache_cleanup_interval = 600
cache_compression = true
cache_preloading = true
cache_eviction_policy = lru

[process]
# 进程优化配置
enable_process_optimization = true
max_processes = 100
process_priority = normal
process_affinity = auto
process_memory_limit = 512MB
process_cpu_limit = 50

[monitoring]
# 监控配置
enable_monitoring = true
monitoring_interval = 60
log_performance_metrics = true
alert_on_threshold = true
performance_reporting = true
metrics_retention_days = 30

[optimization]
# 优化策略配置
enable_lazy_loading = true
enable_connection_pooling = true
enable_query_optimization = true
enable_compression = true
enable_parallel_processing = true
max_parallel_tasks = 4

[alerts]
# 告警配置
memory_alert_threshold = 85
cpu_alert_threshold = 85
disk_alert_threshold = 90
process_alert_threshold = 100
alert_cooldown = 300
EOF
    
    # 替换时间戳
    sed -i "s/\${TIMESTAMP}/$(get_timestamp)/g" "$PERFORMANCE_CONFIG"
}

# 初始化性能监控数据库
init_performance_monitoring_db() {
    log_info "初始化性能监控数据库..."
    
    sqlite3 "$PERFORMANCE_MONITORING_DB" << EOF
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    metric_unit TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT DEFAULT 'system'
);

CREATE TABLE IF NOT EXISTS memory_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    total_memory INTEGER NOT NULL,
    used_memory INTEGER NOT NULL,
    free_memory INTEGER NOT NULL,
    cached_memory INTEGER NOT NULL,
    buffer_memory INTEGER NOT NULL,
    swap_total INTEGER NOT NULL,
    swap_used INTEGER NOT NULL,
    swap_free INTEGER NOT NULL,
    memory_percentage REAL NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cpu_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cpu_percentage REAL NOT NULL,
    load_average_1m REAL NOT NULL,
    load_average_5m REAL NOT NULL,
    load_average_15m REAL NOT NULL,
    cpu_cores INTEGER NOT NULL,
    cpu_frequency REAL,
    cpu_temperature REAL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS process_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    process_name TEXT NOT NULL,
    pid INTEGER NOT NULL,
    cpu_percentage REAL NOT NULL,
    memory_percentage REAL NOT NULL,
    memory_usage INTEGER NOT NULL,
    cpu_time REAL NOT NULL,
    status TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS performance_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    alert_type TEXT NOT NULL,
    alert_level TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    current_value REAL NOT NULL,
    threshold_value REAL NOT NULL,
    alert_message TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN DEFAULT FALSE,
    resolved BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS optimization_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type TEXT NOT NULL,
    action_name TEXT NOT NULL,
    action_description TEXT,
    target_metric TEXT NOT NULL,
    expected_improvement REAL,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT FALSE,
    performance_impact REAL
);
EOF
}

# 创建性能优化脚本
create_performance_optimization_scripts() {
    # 内存优化脚本
    cat > "${PERFORMANCE_OPTIMIZATION_DIR}/memory_optimizer.py" << 'EOF'
#!/usr/bin/env python3
# 内存优化脚本

import psutil
import gc
import os
import time
import sqlite3
import logging
from datetime import datetime

class MemoryOptimizer:
    def __init__(self, db_path):
        self.db_path = db_path
        self.logger = logging.getLogger(__name__)
        
    def get_memory_info(self):
        """获取内存信息"""
        memory = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        return {
            'total': memory.total,
            'used': memory.used,
            'free': memory.free,
            'cached': getattr(memory, 'cached', 0),
            'buffers': getattr(memory, 'buffers', 0),
            'swap_total': swap.total,
            'swap_used': swap.used,
            'swap_free': swap.free,
            'percentage': memory.percent
        }
    
    def optimize_memory(self):
        """优化内存使用"""
        try:
            # 强制垃圾回收
            gc.collect()
            
            # 清理系统缓存（需要root权限）
            if os.geteuid() == 0:
                os.system('sync && echo 3 > /proc/sys/vm/drop_caches')
            
            # 记录优化结果
            memory_info = self.get_memory_info()
            self.log_memory_usage(memory_info)
            
            return memory_info
            
        except Exception as e:
            self.logger.error(f"内存优化失败: {e}")
            return None
    
    def log_memory_usage(self, memory_info):
        """记录内存使用情况"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO memory_usage 
                (total_memory, used_memory, free_memory, cached_memory, 
                 buffer_memory, swap_total, swap_used, swap_free, memory_percentage)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                memory_info['total'], memory_info['used'], memory_info['free'],
                memory_info['cached'], memory_info['buffers'], memory_info['swap_total'],
                memory_info['swap_used'], memory_info['swap_free'], memory_info['percentage']
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"记录内存使用失败: {e}")
    
    def check_memory_threshold(self, threshold=80):
        """检查内存使用阈值"""
        memory_info = self.get_memory_info()
        if memory_info['percentage'] > threshold:
            self.create_memory_alert(memory_info['percentage'], threshold)
            return True
        return False
    
    def create_memory_alert(self, current_value, threshold):
        """创建内存告警"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO performance_alerts 
                (alert_type, alert_level, metric_name, current_value, 
                 threshold_value, alert_message)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                'memory', 'warning', 'memory_usage', current_value,
                threshold, f"内存使用率达到 {current_value:.1f}%"
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"创建内存告警失败: {e}")

if __name__ == "__main__":
    optimizer = MemoryOptimizer("/etc/ipv6-wireguard-manager/performance_optimization/performance.db")
    optimizer.optimize_memory()
    print("内存优化完成")
EOF
    
    # CPU优化脚本
    cat > "${PERFORMANCE_OPTIMIZATION_DIR}/cpu_optimizer.py" << 'EOF'
#!/usr/bin/env python3
# CPU优化脚本

import psutil
import os
import time
import sqlite3
import logging
from datetime import datetime

class CPUOptimizer:
    def __init__(self, db_path):
        self.db_path = db_path
        self.logger = logging.getLogger(__name__)
        
    def get_cpu_info(self):
        """获取CPU信息"""
        cpu_percent = psutil.cpu_percent(interval=1)
        load_avg = psutil.getloadavg()
        cpu_count = psutil.cpu_count()
        
        # 获取CPU频率
        cpu_freq = psutil.cpu_freq()
        cpu_frequency = cpu_freq.current if cpu_freq else None
        
        # 获取CPU温度（如果可用）
        cpu_temp = None
        try:
            temps = psutil.sensors_temperatures()
            if 'coretemp' in temps:
                cpu_temp = temps['coretemp'][0].current
        except:
            pass
        
        return {
            'percentage': cpu_percent,
            'load_1m': load_avg[0],
            'load_5m': load_avg[1],
            'load_15m': load_avg[2],
            'cores': cpu_count,
            'frequency': cpu_frequency,
            'temperature': cpu_temp
        }
    
    def optimize_cpu(self):
        """优化CPU使用"""
        try:
            # 设置CPU调度策略
            if os.geteuid() == 0:
                # 设置CPU性能模式
                os.system('echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor')
                
                # 设置进程优先级
                os.nice(-5)  # 提高进程优先级
            
            # 记录CPU信息
            cpu_info = self.get_cpu_info()
            self.log_cpu_usage(cpu_info)
            
            return cpu_info
            
        except Exception as e:
            self.logger.error(f"CPU优化失败: {e}")
            return None
    
    def log_cpu_usage(self, cpu_info):
        """记录CPU使用情况"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO cpu_usage 
                (cpu_percentage, load_average_1m, load_average_5m, load_average_15m,
                 cpu_cores, cpu_frequency, cpu_temperature)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                cpu_info['percentage'], cpu_info['load_1m'], cpu_info['load_5m'],
                cpu_info['load_15m'], cpu_info['cores'], cpu_info['frequency'],
                cpu_info['temperature']
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"记录CPU使用失败: {e}")
    
    def check_cpu_threshold(self, threshold=80):
        """检查CPU使用阈值"""
        cpu_info = self.get_cpu_info()
        if cpu_info['percentage'] > threshold:
            self.create_cpu_alert(cpu_info['percentage'], threshold)
            return True
        return False
    
    def create_cpu_alert(self, current_value, threshold):
        """创建CPU告警"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO performance_alerts 
                (alert_type, alert_level, metric_name, current_value, 
                 threshold_value, alert_message)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                'cpu', 'warning', 'cpu_usage', current_value,
                threshold, f"CPU使用率达到 {current_value:.1f}%"
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"创建CPU告警失败: {e}")

if __name__ == "__main__":
    optimizer = CPUOptimizer("/etc/ipv6-wireguard-manager/performance_optimization/performance.db")
    optimizer.optimize_cpu()
    print("CPU优化完成")
EOF
    
    # 进程优化脚本
    cat > "${PERFORMANCE_OPTIMIZATION_DIR}/process_optimizer.py" << 'EOF'
#!/usr/bin/env python3
# 进程优化脚本

import psutil
import os
import time
import sqlite3
import logging
from datetime import datetime

class ProcessOptimizer:
    def __init__(self, db_path):
        self.db_path = db_path
        self.logger = logging.getLogger(__name__)
        
    def get_process_info(self):
        """获取进程信息"""
        processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'memory_info', 'cpu_times', 'status']):
            try:
                proc_info = proc.info
                processes.append({
                    'name': proc_info['name'],
                    'pid': proc_info['pid'],
                    'cpu_percent': proc_info['cpu_percent'],
                    'memory_percent': proc_info['memory_percent'],
                    'memory_usage': proc_info['memory_info'].rss if proc_info['memory_info'] else 0,
                    'cpu_time': proc_info['cpu_times'].user + proc_info['cpu_times'].system if proc_info['cpu_times'] else 0,
                    'status': proc_info['status']
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        return processes
    
    def optimize_processes(self):
        """优化进程"""
        try:
            processes = self.get_process_info()
            
            # 按CPU使用率排序
            processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
            
            # 记录进程信息
            self.log_process_metrics(processes)
            
            # 优化高CPU使用率的进程
            for proc in processes[:10]:  # 只处理前10个高CPU使用率的进程
                if proc['cpu_percent'] > 50:  # 如果CPU使用率超过50%
                    self.optimize_process(proc)
            
            return processes
            
        except Exception as e:
            self.logger.error(f"进程优化失败: {e}")
            return []
    
    def optimize_process(self, proc_info):
        """优化单个进程"""
        try:
            pid = proc_info['pid']
            proc = psutil.Process(pid)
            
            # 设置进程优先级
            if os.geteuid() == 0:  # 需要root权限
                proc.nice(10)  # 降低进程优先级
            
            # 设置进程CPU亲和性
            if os.geteuid() == 0:
                proc.cpu_affinity([0])  # 绑定到第一个CPU核心
            
            self.logger.info(f"优化进程 {proc_info['name']} (PID: {pid})")
            
        except (psutil.NoSuchProcess, psutil.AccessDenied) as e:
            self.logger.warning(f"无法优化进程 {proc_info['name']}: {e}")
    
    def log_process_metrics(self, processes):
        """记录进程指标"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            for proc in processes:
                cursor.execute("""
                    INSERT INTO process_metrics 
                    (process_name, pid, cpu_percentage, memory_percentage, 
                     memory_usage, cpu_time, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    proc['name'], proc['pid'], proc['cpu_percent'],
                    proc['memory_percent'], proc['memory_usage'],
                    proc['cpu_time'], proc['status']
                ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"记录进程指标失败: {e}")
    
    def check_process_threshold(self, threshold=100):
        """检查进程数量阈值"""
        process_count = len(psutil.pids())
        if process_count > threshold:
            self.create_process_alert(process_count, threshold)
            return True
        return False
    
    def create_process_alert(self, current_value, threshold):
        """创建进程告警"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO performance_alerts 
                (alert_type, alert_level, metric_name, current_value, 
                 threshold_value, alert_message)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                'process', 'warning', 'process_count', current_value,
                threshold, f"进程数量达到 {current_value}"
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"创建进程告警失败: {e}")

if __name__ == "__main__":
    optimizer = ProcessOptimizer("/etc/ipv6-wireguard-manager/performance_optimization/performance.db")
    optimizer.optimize_processes()
    print("进程优化完成")
EOF
    
    # 性能监控脚本
    cat > "${PERFORMANCE_OPTIMIZATION_DIR}/performance_monitor.py" << 'EOF'
#!/usr/bin/env python3
# 性能监控脚本

import psutil
import time
import sqlite3
import logging
from datetime import datetime, timedelta

class PerformanceMonitor:
    def __init__(self, db_path):
        self.db_path = db_path
        self.logger = logging.getLogger(__name__)
        self.monitoring = True
        
    def start_monitoring(self):
        """开始性能监控"""
        self.logger.info("开始性能监控...")
        
        while self.monitoring:
            try:
                # 监控内存
                self.monitor_memory()
                
                # 监控CPU
                self.monitor_cpu()
                
                # 监控进程
                self.monitor_processes()
                
                # 监控磁盘
                self.monitor_disk()
                
                # 监控网络
                self.monitor_network()
                
                # 等待下次监控
                time.sleep(60)  # 每分钟监控一次
                
            except KeyboardInterrupt:
                self.logger.info("监控已停止")
                break
            except Exception as e:
                self.logger.error(f"监控错误: {e}")
                time.sleep(10)
    
    def monitor_memory(self):
        """监控内存使用"""
        try:
            memory = psutil.virtual_memory()
            swap = psutil.swap_memory()
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO memory_usage 
                (total_memory, used_memory, free_memory, cached_memory, 
                 buffer_memory, swap_total, swap_used, swap_free, memory_percentage)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                memory.total, memory.used, memory.free,
                getattr(memory, 'cached', 0), getattr(memory, 'buffers', 0),
                swap.total, swap.used, swap.free, memory.percent
            ))
            
            conn.commit()
            conn.close()
            
            # 检查内存告警
            if memory.percent > 85:
                self.create_alert('memory', 'critical', 'memory_usage', memory.percent, 85)
            
        except Exception as e:
            self.logger.error(f"内存监控失败: {e}")
    
    def monitor_cpu(self):
        """监控CPU使用"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            load_avg = psutil.getloadavg()
            cpu_count = psutil.cpu_count()
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO cpu_usage 
                (cpu_percentage, load_average_1m, load_average_5m, load_average_15m, cpu_cores)
                VALUES (?, ?, ?, ?, ?)
            """, (cpu_percent, load_avg[0], load_avg[1], load_avg[2], cpu_count))
            
            conn.commit()
            conn.close()
            
            # 检查CPU告警
            if cpu_percent > 85:
                self.create_alert('cpu', 'critical', 'cpu_usage', cpu_percent, 85)
            
        except Exception as e:
            self.logger.error(f"CPU监控失败: {e}")
    
    def monitor_processes(self):
        """监控进程"""
        try:
            process_count = len(psutil.pids())
            
            # 检查进程数量告警
            if process_count > 200:
                self.create_alert('process', 'warning', 'process_count', process_count, 200)
            
        except Exception as e:
            self.logger.error(f"进程监控失败: {e}")
    
    def monitor_disk(self):
        """监控磁盘使用"""
        try:
            disk_usage = psutil.disk_usage('/')
            disk_percent = (disk_usage.used / disk_usage.total) * 100
            
            # 检查磁盘告警
            if disk_percent > 90:
                self.create_alert('disk', 'critical', 'disk_usage', disk_percent, 90)
            
        except Exception as e:
            self.logger.error(f"磁盘监控失败: {e}")
    
    def monitor_network(self):
        """监控网络使用"""
        try:
            net_io = psutil.net_io_counters()
            # 这里可以添加网络监控逻辑
            pass
            
        except Exception as e:
            self.logger.error(f"网络监控失败: {e}")
    
    def create_alert(self, alert_type, level, metric_name, current_value, threshold):
        """创建告警"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO performance_alerts 
                (alert_type, alert_level, metric_name, current_value, 
                 threshold_value, alert_message)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                alert_type, level, metric_name, current_value,
                threshold, f"{metric_name} 达到 {current_value:.1f}%"
            ))
            
            conn.commit()
            conn.close()
            
            self.logger.warning(f"性能告警: {metric_name} = {current_value:.1f}%")
            
        except Exception as e:
            self.logger.error(f"创建告警失败: {e}")
    
    def stop_monitoring(self):
        """停止监控"""
        self.monitoring = False

if __name__ == "__main__":
    monitor = PerformanceMonitor("/etc/ipv6-wireguard-manager/performance_optimization/performance.db")
    monitor.start_monitoring()
EOF
    
    # 设置执行权限
    chmod +x "${PERFORMANCE_OPTIMIZATION_DIR}"/*.py
}

# 启动性能监控
start_performance_monitoring() {
    log_info "启动性能监控..."
    
    # 检查是否已在运行
    if pgrep -f "performance_monitor.py" > /dev/null; then
        show_warn "性能监控已在运行"
        return
    fi
    
    # 启动监控脚本
    nohup python3 "${PERFORMANCE_OPTIMIZATION_DIR}/performance_monitor.py" > "$PERFORMANCE_LOG" 2>&1 &
    
    # 保存PID
    echo $! > "${PERFORMANCE_OPTIMIZATION_DIR}/monitor.pid"
    
    show_success "性能监控已启动"
}

# 性能优化管理菜单
performance_optimization_menu() {
    while true; do
        clear
        show_banner
        
        echo -e "${SECONDARY_COLOR}=== 性能优化管理 ===${NC}"
        echo
        echo -e "${GREEN}1.${NC} 内存优化"
        echo -e "${GREEN}2.${NC} CPU优化"
        echo -e "${GREEN}3.${NC} 进程优化"
        echo -e "${GREEN}4.${NC} 性能监控"
        echo -e "${GREEN}5.${NC} 性能报告"
        echo -e "${GREEN}6.${NC} 优化设置"
        echo -e "${GREEN}7.${NC} 性能告警"
        echo
        echo -e "${INFO_COLOR}0.${NC} 返回"
        echo
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) memory_optimization ;;
            2) cpu_optimization ;;
            3) process_optimization ;;
            4) performance_monitoring ;;
            5) performance_report ;;
            6) optimization_settings ;;
            7) performance_alerts ;;
            0) return 0 ;;
            *) show_error "无效选择，请重新输入" ;;
        esac
        
        read -p "按回车键继续..."
    done
}

# 内存优化
memory_optimization() {
    log_info "执行内存优化..."
    
    if [[ -f "${PERFORMANCE_OPTIMIZATION_DIR}/memory_optimizer.py" ]]; then
        python3 "${PERFORMANCE_OPTIMIZATION_DIR}/memory_optimizer.py"
        show_success "内存优化完成"
    else
        show_error "内存优化脚本不存在"
    fi
}

# CPU优化
cpu_optimization() {
    log_info "执行CPU优化..."
    
    if [[ -f "${PERFORMANCE_OPTIMIZATION_DIR}/cpu_optimizer.py" ]]; then
        python3 "${PERFORMANCE_OPTIMIZATION_DIR}/cpu_optimizer.py"
        show_success "CPU优化完成"
    else
        show_error "CPU优化脚本不存在"
    fi
}

# 进程优化
process_optimization() {
    log_info "执行进程优化..."
    
    if [[ -f "${PERFORMANCE_OPTIMIZATION_DIR}/process_optimizer.py" ]]; then
        python3 "${PERFORMANCE_OPTIMIZATION_DIR}/process_optimizer.py"
        show_success "进程优化完成"
    else
        show_error "进程优化脚本不存在"
    fi
}

# 性能监控
performance_monitoring() {
    echo -e "${SECONDARY_COLOR}=== 性能监控 ===${NC}"
    echo
    
    echo "系统性能指标:"
    echo "内存使用率: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
    echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "磁盘使用率: $(df -h / | tail -1 | awk '{print $5}')"
    echo "负载平均值: $(uptime | awk -F'load average:' '{print $2}')"
    echo "进程数量: $(ps aux | wc -l)"
}

# 性能报告
performance_report() {
    echo -e "${SECONDARY_COLOR}=== 性能报告 ===${NC}"
    echo
    
    if [[ -f "$PERFORMANCE_MONITORING_DB" ]]; then
        echo "内存使用统计:"
        sqlite3 "$PERFORMANCE_MONITORING_DB" << EOF
.mode column
.headers on
SELECT 
    datetime(timestamp, 'localtime') as time,
    memory_percentage,
    used_memory/1024/1024/1024 as used_gb,
    free_memory/1024/1024/1024 as free_gb
FROM memory_usage 
ORDER BY timestamp DESC 
LIMIT 10;
EOF
        
        echo
        echo "CPU使用统计:"
        sqlite3 "$PERFORMANCE_MONITORING_DB" << EOF
.mode column
.headers on
SELECT 
    datetime(timestamp, 'localtime') as time,
    cpu_percentage,
    load_average_1m,
    load_average_5m,
    load_average_15m
FROM cpu_usage 
ORDER BY timestamp DESC 
LIMIT 10;
EOF
    else
        show_error "性能监控数据库不存在"
    fi
}

# 优化设置
optimization_settings() {
    echo -e "${SECONDARY_COLOR}=== 优化设置 ===${NC}"
    echo
    
    local memory_threshold=$(show_input "内存告警阈值(%)" "80")
    local cpu_threshold=$(show_input "CPU告警阈值(%)" "80")
    local disk_threshold=$(show_input "磁盘告警阈值(%)" "90")
    local process_threshold=$(show_input "进程告警阈值" "200")
    
    # 更新配置文件
    sed -i "s/memory_alert_threshold = .*/memory_alert_threshold = $memory_threshold/" "$PERFORMANCE_CONFIG"
    sed -i "s/cpu_alert_threshold = .*/cpu_alert_threshold = $cpu_threshold/" "$PERFORMANCE_CONFIG"
    sed -i "s/disk_alert_threshold = .*/disk_alert_threshold = $disk_threshold/" "$PERFORMANCE_CONFIG"
    sed -i "s/process_alert_threshold = .*/process_alert_threshold = $process_threshold/" "$PERFORMANCE_CONFIG"
    
    show_success "优化设置已保存"
}

# 性能告警
performance_alerts() {
    echo -e "${SECONDARY_COLOR}=== 性能告警 ===${NC}"
    echo
    
    if [[ -f "$PERFORMANCE_MONITORING_DB" ]]; then
        sqlite3 "$PERFORMANCE_MONITORING_DB" << EOF
.mode column
.headers on
SELECT 
    datetime(timestamp, 'localtime') as time,
    alert_type,
    alert_level,
    metric_name,
    current_value,
    threshold_value,
    alert_message,
    acknowledged,
    resolved
FROM performance_alerts 
ORDER BY timestamp DESC 
LIMIT 20;
EOF
    else
        show_error "性能监控数据库不存在"
    fi
}

# 导出函数
export -f init_performance_optimization create_performance_config init_performance_monitoring_db
export -f create_performance_optimization_scripts start_performance_monitoring
export -f performance_optimization_menu memory_optimization cpu_optimization
export -f process_optimization performance_monitoring performance_report
export -f optimization_settings performance_alerts
