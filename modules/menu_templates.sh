#!/bin/bash

# IPv6 WireGuard Manager 菜单模板库
# 版本: 1.13
# 提供统一的菜单显示和交互模板

# 加载公共函数
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common_functions.sh"
fi

# 标准菜单模板
show_standard_menu() {
    local title="$1"
    local options=("${@:2}")
    local max_option=$((${#options[@]} - 1))
    
    while true; do
        clear
        show_menu_header "$title"
        
        # 显示选项
        for i in "${!options[@]}"; do
            if [[ $i -eq 0 ]]; then
                show_menu_option "0" "${options[$i]}"
            else
                show_menu_option "$i" "${options[$i]}"
            fi
        done
        echo
        
        # 获取用户选择
        local choice=$(get_menu_choice "$max_option")
        
        # 验证选择
        if validate_menu_choice "$choice" "$max_option"; then
            echo "$choice"
            return 0
        else
            log "WARN" "Invalid choice, please try again"
            sleep 2
        fi
    done
}

# 确认对话框模板
show_confirm_dialog() {
    local message="$1"
    local default="${2:-n}"
    local title="${3:-确认操作}"
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "${YELLOW}$message${NC}"
        echo
        
        if confirm_action "$message" "$default"; then
            return 0
        else
            return 1
        fi
    done
}

# 输入对话框模板
show_input_dialog() {
    local prompt="$1"
    local default_value="${2:-}"
    local validation_func="${3:-}"
    local title="${4:-输入信息}"
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "${CYAN}$prompt${NC}"
        if [[ -n "$default_value" ]]; then
            echo -e "${GREEN}默认值: $default_value${NC}"
        fi
        echo
        
        read -p "请输入: " input_value
        input_value="${input_value:-$default_value}"
        
        if [[ -n "$validation_func" ]] && command -v "$validation_func" >/dev/null 2>&1; then
            if "$validation_func" "$input_value"; then
                echo "$input_value"
                return 0
            else
                log "WARN" "输入验证失败，请重新输入"
                sleep 2
            fi
        else
            echo "$input_value"
            return 0
        fi
    done
}

# 多选菜单模板
show_multi_select_menu() {
    local title="$1"
    local options=("${@:2}")
    local selected=()
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "${CYAN}请选择多个选项（用空格分隔数字，按回车确认）:${NC}"
        echo
        
        # 显示选项
        for i in "${!options[@]}"; do
            local marker=" "
            if [[ " ${selected[@]} " =~ " $i " ]]; then
                marker="✓"
            fi
            echo -e "  ${GREEN}[$marker] $i.${NC} ${options[$i]}"
        done
        echo
        echo -e "${YELLOW}已选择: ${selected[*]:-无}${NC}"
        echo
        
        read -p "请输入选择 (空格分隔，回车确认): " input
        
        if [[ -z "$input" ]]; then
            if [[ ${#selected[@]} -gt 0 ]]; then
                echo "${selected[@]}"
                return 0
            else
                log "WARN" "请至少选择一个选项"
                sleep 2
            fi
        else
            selected=()
            for choice in $input; do
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 0 ]] && [[ $choice -lt ${#options[@]} ]]; then
                    if [[ ! " ${selected[@]} " =~ " $choice " ]]; then
                        selected+=("$choice")
                    fi
                else
                    log "WARN" "无效选择: $choice"
                fi
            done
        fi
    done
}

# 进度显示模板
show_progress_dialog() {
    local title="$1"
    local total_steps="$2"
    local current_step=0
    
    clear
    show_menu_header "$title"
    
    while [[ $current_step -lt $total_steps ]]; do
        show_progress $current_step $total_steps "处理中"
        sleep 0.1
        ((current_step++))
    done
    
    show_progress $total_steps $total_steps "完成"
    echo
    echo -e "${GREEN}操作完成！${NC}"
    sleep 2
}

# 列表显示模板
show_list_dialog() {
    local title="$1"
    local items=("${@:2}")
    local page_size="${3:-10}"
    local current_page=0
    local total_pages=$(( (${#items[@]} + page_size - 1) / page_size ))
    
    while true; do
        clear
        show_menu_header "$title"
        
        # 计算当前页的项目
        local start_index=$((current_page * page_size))
        local end_index=$((start_index + page_size - 1))
        if [[ $end_index -ge ${#items[@]} ]]; then
            end_index=$((${#items[@]} - 1))
        fi
        
        # 显示当前页的项目
        for i in $(seq $start_index $end_index); do
            echo -e "  ${GREEN}$((i + 1)).${NC} ${items[$i]}"
        done
        
        echo
        echo -e "${CYAN}第 $((current_page + 1)) 页，共 $total_pages 页${NC}"
        echo -e "${YELLOW}总项目数: ${#items[@]}${NC}"
        echo
        
        # 显示导航选项
        echo -e "  ${GREEN}n.${NC} 下一页"
        echo -e "  ${GREEN}p.${NC} 上一页"
        echo -e "  ${GREEN}q.${NC} 退出"
        echo
        
        read -p "请选择操作: " choice
        
        case "$choice" in
            "n"|"next")
                if [[ $current_page -lt $((total_pages - 1)) ]]; then
                    ((current_page++))
                else
                    log "WARN" "已经是最后一页"
                    sleep 1
                fi
                ;;
            "p"|"prev")
                if [[ $current_page -gt 0 ]]; then
                    ((current_page--))
                else
                    log "WARN" "已经是第一页"
                    sleep 1
                fi
                ;;
            "q"|"quit")
                return 0
                ;;
            *)
                log "WARN" "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 表格显示模板
show_table_dialog() {
    local title="$1"
    local headers=("${@:2}")
    local data=("${@:$((${#headers[@]} + 2))}")
    local page_size="${3:-10}"
    local current_page=0
    local total_pages=$(( (${#data[@]} + page_size - 1) / page_size ))
    
    while true; do
        clear
        show_menu_header "$title"
        
        # 计算列宽
        local col_widths=()
        for i in "${!headers[@]}"; do
            col_widths[$i]=${#headers[$i]}
        done
        
        # 计算数据列宽
        for row in "${data[@]}"; do
            local IFS='|'
            local -a fields=($row)
            for i in "${!fields[@]}"; do
                if [[ $i -lt ${#headers[@]} ]]; then
                    local field_length=${#fields[$i]}
                    if [[ $field_length -gt ${col_widths[$i]} ]]; then
                        col_widths[$i]=$field_length
                    fi
                fi
            done
        done
        
        # 显示表头
        echo -e "${WHITE}┌"
        for i in "${!headers[@]}"; do
            printf "%-${col_widths[$i]}s" "${headers[$i]}"
            if [[ $i -lt $((${#headers[@]} - 1)) ]]; then
                echo -e "│"
            fi
        done
        echo -e "┐${NC}"
        
        # 显示分隔线
        echo -e "${WHITE}├"
        for i in "${!headers[@]}"; do
            printf "%*s" ${col_widths[$i]} "" | tr ' ' '-'
            if [[ $i -lt $((${#headers[@]} - 1)) ]]; then
                echo -e "┼"
            fi
        done
        echo -e "┤${NC}"
        
        # 计算当前页的数据
        local start_index=$((current_page * page_size))
        local end_index=$((start_index + page_size - 1))
        if [[ $end_index -ge ${#data[@]} ]]; then
            end_index=$((${#data[@]} - 1))
        fi
        
        # 显示数据行
        for i in $(seq $start_index $end_index); do
            local IFS='|'
            local -a fields=(${data[$i]})
            echo -e "${WHITE}│"
            for j in "${!fields[@]}"; do
                if [[ $j -lt ${#headers[@]} ]]; then
                    printf "%-${col_widths[$j]}s" "${fields[$j]}"
                    if [[ $j -lt $((${#headers[@]} - 1)) ]]; then
                        echo -e "│"
                    fi
                fi
            done
            echo -e "│${NC}"
        done
        
        # 显示表尾
        echo -e "${WHITE}└"
        for i in "${!headers[@]}"; do
            printf "%*s" ${col_widths[$i]} "" | tr ' ' '-'
            if [[ $i -lt $((${#headers[@]} - 1)) ]]; then
                echo -e "┴"
            fi
        done
        echo -e "┘${NC}"
        
        echo
        echo -e "${CYAN}第 $((current_page + 1)) 页，共 $total_pages 页${NC}"
        echo -e "${YELLOW}总行数: ${#data[@]}${NC}"
        echo
        
        # 显示导航选项
        echo -e "  ${GREEN}n.${NC} 下一页"
        echo -e "  ${GREEN}p.${NC} 上一页"
        echo -e "  ${GREEN}q.${NC} 退出"
        echo
        
        read -p "请选择操作: " choice
        
        case "$choice" in
            "n"|"next")
                if [[ $current_page -lt $((total_pages - 1)) ]]; then
                    ((current_page++))
                else
                    log "WARN" "已经是最后一页"
                    sleep 1
                fi
                ;;
            "p"|"prev")
                if [[ $current_page -gt 0 ]]; then
                    ((current_page--))
                else
                    log "WARN" "已经是第一页"
                    sleep 1
                fi
                ;;
            "q"|"quit")
                return 0
                ;;
            *)
                log "WARN" "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 搜索对话框模板
show_search_dialog() {
    local title="$1"
    local search_func="$2"
    local items=("${@:3}")
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "${CYAN}请输入搜索关键词（留空显示所有项目）:${NC}"
        echo
        
        read -p "搜索: " search_term
        
        if [[ -n "$search_term" ]]; then
            local results=()
            for item in "${items[@]}"; do
                if [[ "$item" =~ $search_term ]]; then
                    results+=("$item")
                fi
            done
            
            if [[ ${#results[@]} -eq 0 ]]; then
                echo -e "${YELLOW}未找到匹配的项目${NC}"
            else
                echo -e "${GREEN}找到 ${#results[@]} 个匹配项目:${NC}"
                for i in "${!results[@]}"; do
                    echo -e "  ${GREEN}$((i + 1)).${NC} ${results[$i]}"
                done
            fi
        else
            echo -e "${GREEN}所有项目:${NC}"
            for i in "${!items[@]}"; do
                echo -e "  ${GREEN}$((i + 1)).${NC} ${items[$i]}"
            done
        fi
        
        echo
        echo -e "  ${GREEN}s.${NC} 重新搜索"
        echo -e "  ${GREEN}q.${NC} 退出"
        echo
        
        read -p "请选择操作: " choice
        
        case "$choice" in
            "s"|"search")
                continue
                ;;
            "q"|"quit")
                return 0
                ;;
            *)
                log "WARN" "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 帮助对话框模板
show_help_dialog() {
    local title="$1"
    local help_text="$2"
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "$help_text"
        echo
        echo -e "  ${GREEN}q.${NC} 返回"
        echo
        
        read -p "请选择操作: " choice
        
        case "$choice" in
            "q"|"quit"|"return")
                return 0
                ;;
            *)
                log "WARN" "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 错误对话框模板
show_error_dialog() {
    local title="$1"
    local error_message="$2"
    local suggestions=("${@:3}")
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "${RED}错误: $error_message${NC}"
        echo
        
        if [[ ${#suggestions[@]} -gt 0 ]]; then
            echo -e "${YELLOW}建议解决方案:${NC}"
            for i in "${!suggestions[@]}"; do
                echo -e "  ${GREEN}$((i + 1)).${NC} ${suggestions[$i]}"
            done
            echo
        fi
        
        echo -e "  ${GREEN}r.${NC} 重试"
        echo -e "  ${GREEN}q.${NC} 返回"
        echo
        
        read -p "请选择操作: " choice
        
        case "$choice" in
            "r"|"retry")
                return 1
                ;;
            "q"|"quit"|"return")
                return 0
                ;;
            *)
                log "WARN" "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 成功对话框模板
show_success_dialog() {
    local title="$1"
    local success_message="$2"
    local next_actions=("${@:3}")
    
    while true; do
        clear
        show_menu_header "$title"
        echo -e "${GREEN}✓ $success_message${NC}"
        echo
        
        if [[ ${#next_actions[@]} -gt 0 ]]; then
            echo -e "${CYAN}下一步操作:${NC}"
            for i in "${!next_actions[@]}"; do
                echo -e "  ${GREEN}$((i + 1)).${NC} ${next_actions[$i]}"
            done
            echo
        fi
        
        echo -e "  ${GREEN}c.${NC} 继续"
        echo -e "  ${GREEN}q.${NC} 返回"
        echo
        
        read -p "请选择操作: " choice
        
        case "$choice" in
            "c"|"continue")
                return 1
                ;;
            "q"|"quit"|"return")
                return 0
                ;;
            *)
                log "WARN" "无效选择"
                sleep 1
                ;;
        esac
    done
}

# 加载菜单模板库
load_menu_templates() {
    # 此函数用于加载菜单模板库
    # 如果已经加载，则跳过
    if [[ -n "${MENU_TEMPLATES_LOADED:-}" ]]; then
        return 0
    fi
    
    # 标记为已加载
    export MENU_TEMPLATES_LOADED=1
    
    log "DEBUG" "Menu templates library loaded"
    return 0
}

# 自动加载菜单模板库
load_menu_templates
