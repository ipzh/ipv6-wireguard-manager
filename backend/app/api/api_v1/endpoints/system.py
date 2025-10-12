"""
系统管理API接口
"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
import subprocess
import os
import shutil
import json
from datetime import datetime

from ..dependencies import get_current_user
from ...models.user import User

router = APIRouter()

class SystemInfo(BaseModel):
    version: str
    install_date: str
    backend_status: str
    database_status: str
    nginx_status: str
    uptime: str

class SystemAction(BaseModel):
    action: str  # 'uninstall' or 'reinstall'
    confirm_text: str

class SystemLog(BaseModel):
    timestamp: str
    message: str
    level: str  # 'info', 'warning', 'error'

class BackupInfo(BaseModel):
    name: str
    size: str
    created_at: str
    description: str

@router.get("/info", response_model=SystemInfo)
async def get_system_info(current_user: User = Depends(get_current_user)):
    """获取系统信息"""
    try:
        # 检查服务状态
        backend_status = "运行中"
        database_status = "正常"
        nginx_status = "运行中"
        
        try:
            # 检查后端服务
            result = subprocess.run(
                ["systemctl", "is-active", "ipv6-wireguard-manager"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode != 0:
                backend_status = "异常"
        except:
            backend_status = "未知"
        
        try:
            # 检查数据库
            result = subprocess.run(
                ["systemctl", "is-active", "postgresql"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode != 0:
                database_status = "异常"
        except:
            database_status = "未知"
        
        try:
            # 检查Nginx
            result = subprocess.run(
                ["systemctl", "is-active", "nginx"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode != 0:
                nginx_status = "异常"
        except:
            nginx_status = "未知"
        
        # 获取系统运行时间
        try:
            result = subprocess.run(
                ["uptime", "-p"],
                capture_output=True, text=True, timeout=5
            )
            uptime = result.stdout.strip() if result.returncode == 0 else "未知"
        except:
            uptime = "未知"
        
        return SystemInfo(
            version="v1.0.0",
            install_date="2024-10-12",
            backend_status=backend_status,
            database_status=database_status,
            nginx_status=nginx_status,
            uptime=uptime
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取系统信息失败: {str(e)}")

@router.post("/action")
async def execute_system_action(
    action_data: SystemAction,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """执行系统操作（卸载或重新安装）"""
    
    # 验证确认文本
    required_text = "UNINSTALL" if action_data.action == "uninstall" else "REINSTALL"
    if action_data.confirm_text != required_text:
        raise HTTPException(status_code=400, detail=f"确认文本错误，请输入: {required_text}")
    
    # 只有管理员可以执行系统操作
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="只有管理员可以执行系统操作")
    
    try:
        if action_data.action == "uninstall":
            # 执行卸载操作
            background_tasks.add_task(uninstall_system)
            return {"message": "系统卸载已开始", "status": "started"}
        elif action_data.action == "reinstall":
            # 执行重新安装操作
            background_tasks.add_task(reinstall_system)
            return {"message": "系统重新安装已开始", "status": "started"}
        else:
            raise HTTPException(status_code=400, detail="无效的操作类型")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"执行系统操作失败: {str(e)}")

@router.get("/logs", response_model=List[SystemLog])
async def get_system_logs(
    limit: int = 50,
    current_user: User = Depends(get_current_user)
):
    """获取系统日志"""
    try:
        logs = []
        
        # 获取系统日志
        try:
            result = subprocess.run(
                ["journalctl", "-u", "ipv6-wireguard-manager", "-n", str(limit), "--no-pager"],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                for line in result.stdout.strip().split('\n'):
                    if line.strip():
                        logs.append(SystemLog(
                            timestamp=datetime.now().isoformat(),
                            message=line.strip(),
                            level="info"
                        ))
        except:
            pass
        
        return logs
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取系统日志失败: {str(e)}")

@router.get("/backups", response_model=List[BackupInfo])
async def get_backups(current_user: User = Depends(get_current_user)):
    """获取备份列表"""
    try:
        backups = []
        backup_dir = "/opt/ipv6-wireguard-manager/backups"
        
        if os.path.exists(backup_dir):
            for file in os.listdir(backup_dir):
                if file.endswith('.tar.gz'):
                    file_path = os.path.join(backup_dir, file)
                    stat = os.stat(file_path)
                    size = format_file_size(stat.st_size)
                    created_at = datetime.fromtimestamp(stat.st_ctime).strftime("%Y-%m-%d %H:%M:%S")
                    
                    backups.append(BackupInfo(
                        name=file,
                        size=size,
                        created_at=created_at,
                        description=f"系统备份 - {file}"
                    ))
        
        return sorted(backups, key=lambda x: x.created_at, reverse=True)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取备份列表失败: {str(e)}")

@router.post("/backup")
async def create_backup(
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    """创建系统备份"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="只有管理员可以创建备份")
    
    try:
        background_tasks.add_task(create_system_backup)
        return {"message": "备份创建已开始", "status": "started"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建备份失败: {str(e)}")

def uninstall_system():
    """卸载系统"""
    try:
        # 停止服务
        subprocess.run(["systemctl", "stop", "ipv6-wireguard-manager"], check=True)
        subprocess.run(["systemctl", "stop", "nginx"], check=True)
        
        # 禁用服务
        subprocess.run(["systemctl", "disable", "ipv6-wireguard-manager"], check=True)
        
        # 删除应用文件
        app_dir = "/opt/ipv6-wireguard-manager"
        if os.path.exists(app_dir):
            shutil.rmtree(app_dir)
        
        # 删除systemd服务文件
        service_file = "/etc/systemd/system/ipv6-wireguard-manager.service"
        if os.path.exists(service_file):
            os.remove(service_file)
        
        # 重新加载systemd
        subprocess.run(["systemctl", "daemon-reload"], check=True)
        
        # 记录卸载日志
        with open("/tmp/ipv6wg-uninstall.log", "w") as f:
            f.write(f"系统卸载完成: {datetime.now().isoformat()}\n")
            
    except Exception as e:
        # 记录错误日志
        with open("/tmp/ipv6wg-uninstall-error.log", "w") as f:
            f.write(f"卸载失败: {str(e)}\n")

def reinstall_system():
    """重新安装系统"""
    try:
        # 创建备份
        create_system_backup()
        
        # 停止服务
        subprocess.run(["systemctl", "stop", "ipv6-wireguard-manager"], check=True)
        
        # 下载最新版本
        subprocess.run([
            "curl", "-fsSL", 
            "https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install-robust.sh"
        ], check=True)
        
        # 执行重新安装
        subprocess.run([
            "bash", "/tmp/install-robust.sh", "native"
        ], check=True)
        
        # 记录重新安装日志
        with open("/tmp/ipv6wg-reinstall.log", "w") as f:
            f.write(f"系统重新安装完成: {datetime.now().isoformat()}\n")
            
    except Exception as e:
        # 记录错误日志
        with open("/tmp/ipv6wg-reinstall-error.log", "w") as f:
            f.write(f"重新安装失败: {str(e)}\n")

def create_system_backup():
    """创建系统备份"""
    try:
        backup_dir = "/opt/ipv6-wireguard-manager/backups"
        os.makedirs(backup_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"{backup_dir}/backup_{timestamp}.tar.gz"
        
        # 创建备份
        subprocess.run([
            "tar", "-czf", backup_file,
            "-C", "/opt/ipv6-wireguard-manager",
            "backend", "frontend", "config"
        ], check=True)
        
        # 记录备份日志
        with open("/tmp/ipv6wg-backup.log", "w") as f:
            f.write(f"备份创建完成: {backup_file}\n")
            
    except Exception as e:
        # 记录错误日志
        with open("/tmp/ipv6wg-backup-error.log", "w") as f:
            f.write(f"备份创建失败: {str(e)}\n")

def format_file_size(size_bytes):
    """格式化文件大小"""
    if size_bytes == 0:
        return "0B"
    
    size_names = ["B", "KB", "MB", "GB", "TB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024.0
        i += 1
    
    return f"{size_bytes:.1f}{size_names[i]}"
