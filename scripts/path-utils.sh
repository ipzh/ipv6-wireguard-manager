#!/bin/bash

# 路径处理工具函数
# 用于解决安装脚本中的路径导航问题

# 获取项目根目录的绝对路径
get_project_root() {
    local install_dir="$1"
    local current_dir="$(pwd)"
    
    echo "🔍 查找项目根目录..."
    echo "   当前目录: $current_dir"
    echo "   查找目录: $install_dir"
    
    # 尝试多种可能的路径
    local possible_paths=(
        "$install_dir"
        "../$install_dir"
        "../../$install_dir"
        "../../../$install_dir"
        "/tmp/$install_dir"
        "/root/$install_dir"
        "/home/*/$install_dir"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -d "$path" ]; then
            local abs_path=$(realpath "$path" 2>/dev/null)
            if [ -n "$abs_path" ] && [ -d "$abs_path" ]; then
                echo "✅ 找到项目目录: $abs_path"
                echo "$abs_path"
                return 0
            fi
        fi
    done
    
    # 如果没找到，尝试在当前目录及其父目录中搜索
    local search_dir="$current_dir"
    for i in {1..5}; do
        if [ -d "$search_dir/$install_dir" ]; then
            local abs_path=$(realpath "$search_dir/$install_dir" 2>/dev/null)
            if [ -n "$abs_path" ] && [ -d "$abs_path" ]; then
                echo "✅ 在 $search_dir 中找到项目目录: $abs_path"
                echo "$abs_path"
                return 0
            fi
        fi
        search_dir="$(dirname "$search_dir")"
        if [ "$search_dir" = "/" ]; then
            break
        fi
    done
    
    echo "❌ 找不到项目目录: $install_dir"
    echo "📁 当前目录内容:"
    ls -la
    echo "📁 上级目录内容:"
    ls -la .. 2>/dev/null || echo "无法访问上级目录"
    return 1
}

# 安全切换到项目目录
safe_cd_to_project() {
    local install_dir="$1"
    local project_root
    
    project_root=$(get_project_root "$install_dir")
    if [ $? -eq 0 ]; then
        cd "$project_root"
        echo "✅ 切换到项目目录: $(pwd)"
        return 0
    else
        return 1
    fi
}

# 验证项目结构
validate_project_structure() {
    local project_root="$1"
    
    echo "🔍 验证项目结构..."
    
    if [ ! -d "$project_root" ]; then
        echo "❌ 项目根目录不存在: $project_root"
        return 1
    fi
    
    if [ ! -d "$project_root/backend" ]; then
        echo "❌ 后端目录不存在: $project_root/backend"
        echo "📁 项目目录内容:"
        ls -la "$project_root"
        return 1
    fi
    
    if [ ! -d "$project_root/frontend" ]; then
        echo "❌ 前端目录不存在: $project_root/frontend"
        echo "📁 项目目录内容:"
        ls -la "$project_root"
        return 1
    fi
    
    echo "✅ 项目结构验证通过"
    return 0
}

# 安全进入后端目录
safe_cd_to_backend() {
    local install_dir="$1"
    
    if safe_cd_to_project "$install_dir"; then
        if [ -d "backend" ]; then
            cd backend
            echo "✅ 进入后端目录: $(pwd)"
            return 0
        else
            echo "❌ 后端目录不存在"
            return 1
        fi
    else
        return 1
    fi
}

# 安全进入前端目录
safe_cd_to_frontend() {
    local install_dir="$1"
    
    if safe_cd_to_project "$install_dir"; then
        if [ -d "frontend" ]; then
            cd frontend
            echo "✅ 进入前端目录: $(pwd)"
            return 0
        else
            echo "❌ 前端目录不存在"
            return 1
        fi
    else
        return 1
    fi
}

# 显示调试信息
show_path_debug_info() {
    echo "🔍 路径调试信息:"
    echo "   当前用户: $(whoami)"
    echo "   当前目录: $(pwd)"
    echo "   主目录: $HOME"
    echo "   临时目录: /tmp"
    echo "   根目录: /"
    echo ""
}
