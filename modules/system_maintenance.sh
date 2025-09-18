#!/bin/bash

# 系统维护模块
# 提供系统状态检查、性能监控、日志管理、磁盘管理等功能

# 系统维护菜单
system_maintenance_menu() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    系统维护                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}系统维护选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 系统状态检查"
        echo -e "  ${GREEN}2.${NC} 性能监控"
        echo -e "  ${GREEN}3.${NC} 日志管理"
        echo -e "  ${GREEN}4.${NC} 磁盘空间管理"
        echo -e "  ${GREEN}5.${NC} 系统更新"
        echo -e "  ${GREEN}6.${NC} 进程管理"
        echo -e "  ${GREEN}7.${NC} 系统清理"
        echo -e "  ${GREEN}8.${NC} 安全扫描"
        echo -e "  ${GREEN}0.${NC} 返回主菜单"
        echo
        
        read -p "请选择操作 (0-8): " choice
        
        case "$choice" in
            "1")
                system_status_check
                ;;
            "2")
                performance_monitoring
                ;;
            "3")
                log_management
                ;;
            "4")
                disk_space_management
                ;;
            "5")
                system_update
                ;;
            "6")
                process_management
                ;;
            "7")
                system_cleanup
                ;;
            "8")
                security_scan
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 2
                ;;
        esac
    done
}

# 系统状态检查
system_status_check() {
    clear
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    系统状态检查                            ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # 系统信息
    echo -e "${CYAN}系统信息:${NC}"
    echo "  主机名: $(hostname)"
    echo "  操作系统: $OS_TYPE $OS_VERSION"
    echo "  架构: $ARCH"
    echo "  内核版本: $(uname -r)"
    echo "  运行时间: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//')"
    
    # 负载信息
    echo
    echo -e "${CYAN}系统负载:${NC}"
    uptime | awk -F'load average:' '{print "  " $2}'
    
    # 内存使用
    echo
    echo -e "${CYAN}内存使用:${NC}"
    free -h | while read line; do
        echo "  $line"
    done
    
    # 磁盘使用
    echo
    echo -e "${CYAN}磁盘使用:${NC}"
    df -h | grep -E "/$|/var|/etc|/tmp" | while read line; do
        echo "  $line"
    done
    
    # 网络接口状态
    echo
    echo -e "${CYAN}网络接口状态:${NC}"
    ip link show | grep -E "state UP|state DOWN" | while read line; do
        echo "  $line"
    done
    
    # 服务状态
    echo
    echo -e "${CYAN}关键服务状态:${NC}"
    local services=("wg-quick@wg0" "bird" "bird2" "firewalld" "ufw")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  $service: ${GREEN}运行中${NC}"
        else
            echo -e "  $service: ${RED}未运行${NC}"
        fi
    done
    
    echo
    read -p "按回车键继续..."
}

# 性能监控
performance_monitoring() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    性能监控                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}性能监控选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 实时监控"
        echo -e "  ${GREEN}2.${NC} CPU使用率"
        echo -e "  ${GREEN}3.${NC} 内存使用率"
        echo -e "  ${GREEN}4.${NC} 磁盘I/O"
        echo -e "  ${GREEN}5.${NC} 网络流量"
        echo -e "  ${GREEN}6.${NC} 进程资源使用"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-6): " choice
        
        case "$choice" in
            "1")
                real_time_monitoring
                ;;
            "2")
                cpu_usage_monitoring
                ;;
            "3")
                memory_usage_monitoring
                ;;
            "4")
                disk_io_monitoring
                ;;
            "5")
                network_traffic_monitoring
                ;;
            "6")
                process_resource_monitoring
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 实时监控
real_time_monitoring() {
    echo -e "${CYAN}实时系统监控 (按 Ctrl+C 退出):${NC}"
    echo
    
    if command -v htop >/dev/null 2>&1; then
        htop
    elif command -v top >/dev/null 2>&1; then
        top
    else
        echo -e "${RED}未找到监控工具${NC}"
    fi
}

# CPU使用率监控
cpu_usage_monitoring() {
    echo -e "${CYAN}CPU使用率监控:${NC}"
    echo
    
    # 使用top命令获取CPU使用率
    top -bn1 | grep "Cpu(s)" | while read line; do
        echo "  $line"
    done
    
    # 显示CPU核心数
    echo "  CPU核心数: $(nproc)"
    
    # 显示CPU信息
    if [[ -f /proc/cpuinfo ]]; then
        echo "  CPU型号: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 内存使用率监控
memory_usage_monitoring() {
    echo -e "${CYAN}内存使用率监控:${NC}"
    echo
    
    # 显示内存使用情况
    free -h | while read line; do
        echo "  $line"
    done
    
    # 显示内存详细信息
    echo
    echo -e "${CYAN}内存详细信息:${NC}"
    if [[ -f /proc/meminfo ]]; then
        grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree" /proc/meminfo | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 磁盘I/O监控
disk_io_monitoring() {
    echo -e "${CYAN}磁盘I/O监控:${NC}"
    echo
    
    if command -v iostat >/dev/null 2>&1; then
        iostat -x 1 3
    else
        echo -e "${YELLOW}iostat未安装，显示基本磁盘信息:${NC}"
        df -h | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 网络流量监控
network_traffic_monitoring() {
    echo -e "${CYAN}网络流量监控:${NC}"
    echo
    
    if command -v iftop >/dev/null 2>&1; then
        echo -e "${YELLOW}启动iftop网络流量监控 (按 q 退出):${NC}"
        iftop
    else
        echo -e "${YELLOW}iftop未安装，显示网络接口统计:${NC}"
        cat /proc/net/dev | head -2
        cat /proc/net/dev | grep -E "eth|ens|enp|wg" | while read line; do
            echo "  $line"
        done
    fi
    
    echo
    read -p "按回车键继续..."
}

# 进程资源使用监控
process_resource_monitoring() {
    echo -e "${CYAN}进程资源使用监控:${NC}"
    echo
    
    echo -e "${CYAN}CPU使用率最高的进程:${NC}"
    ps aux --sort=-%cpu | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}内存使用率最高的进程:${NC}"
    ps aux --sort=-%mem | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 日志管理
log_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    日志管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}日志管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看系统日志"
        echo -e "  ${GREEN}2.${NC} 查看应用日志"
        echo -e "  ${GREEN}3.${NC} 日志文件大小"
        echo -e "  ${GREEN}4.${NC} 清理日志文件"
        echo -e "  ${GREEN}5.${NC} 实时日志监控"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                view_system_logs
                ;;
            "2")
                view_application_logs
                ;;
            "3")
                check_log_sizes
                ;;
            "4")
                clean_log_files
                ;;
            "5")
                real_time_log_monitoring
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看系统日志
view_system_logs() {
    echo -e "${CYAN}系统日志 (最近50行):${NC}"
    journalctl -n 50 --no-pager
    echo
    read -p "按回车键继续..."
}

# 查看应用日志
view_application_logs() {
    echo -e "${CYAN}应用日志:${NC}"
    echo "1. WireGuard日志"
    echo "2. BIRD日志"
    echo "3. 防火墙日志"
    echo "4. 系统服务日志"
    read -p "请选择日志类型 (1-4): " log_type
    
    case "$log_type" in
        "1")
            journalctl -u wg-quick@wg0 -n 50 --no-pager
            ;;
        "2")
            if [[ -f /var/log/bird/bird.log ]]; then
                tail -50 /var/log/bird/bird.log
            else
                journalctl -u bird -n 50 --no-pager 2>/dev/null || journalctl -u bird2 -n 50 --no-pager 2>/dev/null
            fi
            ;;
        "3")
            journalctl -u firewalld -n 50 --no-pager 2>/dev/null || echo "无防火墙日志"
            ;;
        "4")
            journalctl -u systemd-networkd -n 50 --no-pager 2>/dev/null || echo "无网络服务日志"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo
    read -p "按回车键继续..."
}

# 检查日志文件大小
check_log_sizes() {
    echo -e "${CYAN}日志文件大小:${NC}"
    echo
    
    # 检查系统日志大小
    if [[ -d /var/log ]]; then
        echo -e "${CYAN}系统日志目录大小:${NC}"
        du -sh /var/log/* 2>/dev/null | sort -hr | head -10 | while read line; do
            echo "  $line"
        done
    fi
    
    # 检查journal日志大小
    echo
    echo -e "${CYAN}Journal日志大小:${NC}"
    journalctl --disk-usage 2>/dev/null || echo "  无法获取journal日志大小"
    
    echo
    read -p "按回车键继续..."
}

# 清理日志文件
clean_log_files() {
    echo -e "${CYAN}清理日志文件${NC}"
    echo "警告: 此操作将清理系统日志文件，请确认是否继续"
    read -p "确认清理日志文件? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        # 清理journal日志
        journalctl --vacuum-time=7d 2>/dev/null && echo -e "${GREEN}✓${NC} Journal日志已清理"
        
        # 清理旧日志文件
        find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} 旧日志文件已清理"
        
        # 清理临时文件
        find /tmp -type f -mtime +7 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} 临时文件已清理"
        
        echo -e "${GREEN}日志清理完成${NC}"
    else
        echo -e "${YELLOW}日志清理已取消${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 实时日志监控
real_time_log_monitoring() {
    echo -e "${CYAN}实时日志监控 (按 Ctrl+C 退出):${NC}"
    echo "1. 系统日志"
    echo "2. WireGuard日志"
    echo "3. BIRD日志"
    read -p "请选择监控类型 (1-3): " monitor_type
    
    case "$monitor_type" in
        "1")
            journalctl -f
            ;;
        "2")
            journalctl -u wg-quick@wg0 -f
            ;;
        "3")
            if [[ -f /var/log/bird/bird.log ]]; then
                tail -f /var/log/bird/bird.log
            else
                journalctl -u bird -f 2>/dev/null || journalctl -u bird2 -f 2>/dev/null
            fi
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
}

# 磁盘空间管理
disk_space_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    磁盘空间管理                            ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}磁盘空间管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看磁盘使用情况"
        echo -e "  ${GREEN}2.${NC} 查找大文件"
        echo -e "  ${GREEN}3.${NC} 清理临时文件"
        echo -e "  ${GREEN}4.${NC} 清理包缓存"
        echo -e "  ${GREEN}5.${NC} 清理日志文件"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_disk_usage
                ;;
            "2")
                find_large_files
                ;;
            "3")
                clean_temp_files
                ;;
            "4")
                clean_package_cache
                ;;
            "5")
                clean_log_files
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示磁盘使用情况
show_disk_usage() {
    echo -e "${CYAN}磁盘使用情况:${NC}"
    df -h | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}目录大小 (前10个最大的目录):${NC}"
    du -sh /* 2>/dev/null | sort -hr | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 查找大文件
find_large_files() {
    read -p "请输入要查找的目录 (默认: /): " search_dir
    search_dir="${search_dir:-/}"
    
    echo -e "${CYAN}在 $search_dir 中查找大于100MB的文件:${NC}"
    find "$search_dir" -type f -size +100M 2>/dev/null | head -20 | while read file; do
        size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  $size - $file"
    done
    
    echo
    read -p "按回车键继续..."
}

# 清理临时文件
clean_temp_files() {
    echo -e "${CYAN}清理临时文件${NC}"
    
    # 清理/tmp目录
    find /tmp -type f -mtime +7 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} /tmp目录已清理"
    
    # 清理/var/tmp目录
    find /var/tmp -type f -mtime +7 -delete 2>/dev/null && echo -e "${GREEN}✓${NC} /var/tmp目录已清理"
    
    # 清理用户临时目录
    find /home -name ".cache" -type d -exec find {} -type f -mtime +7 -delete \; 2>/dev/null && echo -e "${GREEN}✓${NC} 用户缓存已清理"
    
    echo -e "${GREEN}临时文件清理完成${NC}"
    read -p "按回车键继续..."
}

# 清理包缓存
clean_package_cache() {
    echo -e "${CYAN}清理包缓存${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt clean && echo -e "${GREEN}✓${NC} APT缓存已清理"
            apt autoremove -y && echo -e "${GREEN}✓${NC} 无用包已清理"
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf clean all && echo -e "${GREEN}✓${NC} DNF缓存已清理"
                dnf autoremove -y && echo -e "${GREEN}✓${NC} 无用包已清理"
            else
                yum clean all && echo -e "${GREEN}✓${NC} YUM缓存已清理"
            fi
            ;;
        "arch")
            pacman -Sc --noconfirm && echo -e "${GREEN}✓${NC} Pacman缓存已清理"
            ;;
    esac
    
    echo -e "${GREEN}包缓存清理完成${NC}"
    read -p "按回车键继续..."
}

# 系统更新
system_update() {
    echo -e "${CYAN}系统更新${NC}"
    echo "1. 检查更新"
    echo "2. 执行更新"
    echo "3. 仅安全更新"
    read -p "请选择操作 (1-3): " update_choice
    
    case "$update_choice" in
        "1")
            check_system_updates
            ;;
        "2")
            perform_system_update
            ;;
        "3")
            perform_security_update
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 检查系统更新
check_system_updates() {
    echo -e "${CYAN}检查系统更新...${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update >/dev/null 2>&1
            apt list --upgradable 2>/dev/null | grep -c "upgradable" | while read count; do
                echo "  可更新包数量: $count"
            done
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf check-update 2>/dev/null | grep -c "updates" | while read count; do
                    echo "  可更新包数量: $count"
                done
            else
                yum check-update 2>/dev/null | grep -c "updates" | while read count; do
                    echo "  可更新包数量: $count"
                done
            fi
            ;;
        "arch")
            pacman -Qu 2>/dev/null | wc -l | while read count; do
                echo "  可更新包数量: $count"
            done
            ;;
    esac
}

# 执行系统更新
perform_system_update() {
    echo -e "${CYAN}执行系统更新...${NC}"
    echo "警告: 此操作将更新系统包，可能需要重启"
    read -p "确认继续? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        case "$OS_TYPE" in
            "ubuntu"|"debian")
                apt update && apt upgrade -y
                ;;
            "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
                if command -v dnf >/dev/null 2>&1; then
                    dnf update -y
                else
                    yum update -y
                fi
                ;;
            "arch")
                pacman -Syu --noconfirm
                ;;
        esac
        echo -e "${GREEN}系统更新完成${NC}"
    else
        echo -e "${YELLOW}系统更新已取消${NC}"
    fi
}

# 执行安全更新
perform_security_update() {
    echo -e "${CYAN}执行安全更新...${NC}"
    
    case "$OS_TYPE" in
        "ubuntu"|"debian")
            apt update && apt upgrade -y -s | grep -i security
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf update --security -y
            else
                yum update --security -y
            fi
            ;;
        "arch")
            pacman -Syu --noconfirm
            ;;
    esac
    
    echo -e "${GREEN}安全更新完成${NC}"
}

# 进程管理
process_management() {
    while true; do
        clear
        echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║                    进程管理                                ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        
        echo -e "${YELLOW}进程管理选项:${NC}"
        echo -e "  ${GREEN}1.${NC} 查看运行进程"
        echo -e "  ${GREEN}2.${NC} 查找进程"
        echo -e "  ${GREEN}3.${NC} 终止进程"
        echo -e "  ${GREEN}4.${NC} 进程详细信息"
        echo -e "  ${GREEN}5.${NC} 进程资源使用"
        echo -e "  ${GREEN}0.${NC} 返回"
        echo
        
        read -p "请选择操作 (0-5): " choice
        
        case "$choice" in
            "1")
                show_running_processes
                ;;
            "2")
                find_process
                ;;
            "3")
                kill_process
                ;;
            "4")
                show_process_details
                ;;
            "5")
                show_process_resources
                ;;
            "0")
                return
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 查看运行进程
show_running_processes() {
    echo -e "${CYAN}运行中的进程 (前20个):${NC}"
    ps aux | head -1
    ps aux | tail -n +2 | head -20 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 查找进程
find_process() {
    read -p "请输入进程名称或关键词: " process_name
    
    if [[ -n "$process_name" ]]; then
        echo -e "${CYAN}查找包含 '$process_name' 的进程:${NC}"
        ps aux | grep -i "$process_name" | grep -v grep | while read line; do
            echo "  $line"
        done
    else
        echo -e "${RED}请输入有效的进程名称${NC}"
    fi
    
    echo
    read -p "按回车键继续..."
}

# 终止进程
kill_process() {
    read -p "请输入进程ID (PID): " pid
    
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "1. 正常终止 (SIGTERM)"
        echo "2. 强制终止 (SIGKILL)"
        read -p "请选择终止方式 (1-2): " kill_type
        
        case "$kill_type" in
            "1")
                if kill "$pid" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 进程 $pid 已正常终止"
                else
                    echo -e "${RED}✗${NC} 终止进程失败"
                fi
                ;;
            "2")
                if kill -9 "$pid" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} 进程 $pid 已强制终止"
                else
                    echo -e "${RED}✗${NC} 强制终止进程失败"
                fi
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    else
        echo -e "${RED}请输入有效的进程ID${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示进程详细信息
show_process_details() {
    read -p "请输入进程ID (PID): " pid
    
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo -e "${CYAN}进程 $pid 详细信息:${NC}"
        ps -p "$pid" -o pid,ppid,cmd,%cpu,%mem,etime,stat 2>/dev/null || echo -e "${RED}进程不存在${NC}"
    else
        echo -e "${RED}请输入有效的进程ID${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 显示进程资源使用
show_process_resources() {
    echo -e "${CYAN}进程资源使用情况:${NC}"
    echo
    
    echo -e "${CYAN}CPU使用率最高的进程:${NC}"
    ps aux --sort=-%cpu | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}内存使用率最高的进程:${NC}"
    ps aux --sort=-%mem | head -10 | while read line; do
        echo "  $line"
    done
    
    echo
    read -p "按回车键继续..."
}

# 系统清理
system_cleanup() {
    echo -e "${CYAN}系统清理${NC}"
    echo "此操作将清理系统中的临时文件、缓存和日志"
    read -p "确认执行系统清理? (y/N): " confirm
    
    if [[ "${confirm,,}" == "y" ]]; then
        # 清理临时文件
        clean_temp_files
        
        # 清理包缓存
        clean_package_cache
        
        # 清理日志文件
        clean_log_files
        
        # 清理用户缓存
        find /home -name ".cache" -type d -exec find {} -type f -mtime +7 -delete \; 2>/dev/null && echo -e "${GREEN}✓${NC} 用户缓存已清理"
        
        # 清理缩略图缓存
        find /home -name ".thumbnails" -type d -exec find {} -type f -mtime +7 -delete \; 2>/dev/null && echo -e "${GREEN}✓${NC} 缩略图缓存已清理"
        
        echo -e "${GREEN}系统清理完成${NC}"
    else
        echo -e "${YELLOW}系统清理已取消${NC}"
    fi
    
    read -p "按回车键继续..."
}

# 安全扫描
security_scan() {
    echo -e "${CYAN}安全扫描${NC}"
    echo "1. 检查开放端口"
    echo "2. 检查用户账户"
    echo "3. 检查文件权限"
    echo "4. 检查系统服务"
    read -p "请选择扫描类型 (1-4): " scan_type
    
    case "$scan_type" in
        "1")
            scan_open_ports
            ;;
        "2")
            check_user_accounts
            ;;
        "3")
            check_file_permissions
            ;;
        "4")
            check_system_services
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    read -p "按回车键继续..."
}

# 扫描开放端口
scan_open_ports() {
    echo -e "${CYAN}扫描开放端口:${NC}"
    
    if command -v nmap >/dev/null 2>&1; then
        nmap -sT -O localhost 2>/dev/null || echo -e "${RED}端口扫描失败${NC}"
    else
        echo -e "${YELLOW}nmap未安装，使用netstat显示监听端口:${NC}"
        netstat -tuln | grep LISTEN | while read line; do
            echo "  $line"
        done
    fi
}

# 检查用户账户
check_user_accounts() {
    echo -e "${CYAN}检查用户账户:${NC}"
    
    echo -e "${CYAN}系统用户:${NC}"
    awk -F: '$3 < 1000 {print "  " $1 ":" $3 ":" $7}' /etc/passwd | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}普通用户:${NC}"
    awk -F: '$3 >= 1000 {print "  " $1 ":" $3 ":" $7}' /etc/passwd | while read line; do
        echo "  $line"
    done
    
    echo
    echo -e "${CYAN}具有sudo权限的用户:${NC}"
    grep -E '^[^#]*sudo' /etc/group | cut -d: -f4 | tr ',' '\n' | while read user; do
        echo "  $user"
    done
}

# 检查文件权限
check_file_permissions() {
    echo -e "${CYAN}检查关键文件权限:${NC}"
    
    local critical_files=("/etc/passwd" "/etc/shadow" "/etc/group" "/etc/sudoers" "/etc/ssh/sshd_config")
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -c "%a %n" "$file" 2>/dev/null)
            echo "  $perms"
        fi
    done
}

# 检查系统服务
check_system_services() {
    echo -e "${CYAN}检查系统服务状态:${NC}"
    
    local services=("ssh" "sshd" "firewalld" "ufw" "fail2ban" "cron" "systemd-resolved")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "  $service: ${GREEN}运行中${NC}"
        else
            echo -e "  $service: ${RED}未运行${NC}"
        fi
    done
}

