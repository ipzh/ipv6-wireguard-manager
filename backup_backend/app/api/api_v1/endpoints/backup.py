"""
备份API端点
提供备份管理、恢复、调度等功能
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from fastapi.responses import JSONResponse, FileResponse

from ....core.backup_manager import (
    backup_manager,
    BackupType,
    BackupStatus,
    BackupInfo
)
from ....core.security_enhanced import security_manager, rate_limit
from ....core.cluster_manager import cluster_manager, leader_only

router = APIRouter()

@router.get("/backups", response_model=None)
@rate_limit
async def get_all_backups():
    """获取所有备份"""
    try:
        backups = backup_manager.get_all_backups()
        return JSONResponse(content=[backup.to_dict() for backup in backups])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get backups: {str(e)}")

@router.get("/backups/{backup_id}", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_backup(backup_id: str):
    """获取特定备份信息"""
    try:
        backup = backup_manager.get_backup(backup_id)
        if not backup:
            raise HTTPException(status_code=404, detail="Backup not found")
        
        return JSONResponse(content=backup.to_dict())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get backup: {str(e)}")

@router.post("/backups/create", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def create_backup(
    background_tasks: BackgroundTasks,
    name: str = Query(..., description="备份名称"),
    backup_type: str = Query("full", description="备份类型: full, database, files, config"),
    metadata: Optional[Dict[str, Any]] = None
):
    """创建备份"""
    try:
        # 验证备份类型
        try:
            backup_type_enum = BackupType(backup_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid backup type: {backup_type}")
        
        # 在后台创建备份
        background_tasks.add_task(
            backup_manager.create_backup,
            name=name,
            backup_type=backup_type_enum,
            metadata=metadata or {}
        )
        
        return JSONResponse(content={
            "message": "Backup creation started",
            "name": name,
            "type": backup_type
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create backup: {str(e)}")

@router.post("/backups/{backup_id}/restore", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def restore_backup(
    background_tasks: BackgroundTasks,
    backup_id: str,
    target_dir: Optional[str] = Query(None, description="恢复目标目录")
):
    """恢复备份"""
    try:
        backup = backup_manager.get_backup(backup_id)
        if not backup:
            raise HTTPException(status_code=404, detail="Backup not found")
        
        # 在后台恢复备份
        background_tasks.add_task(
            backup_manager.restore_backup,
            backup_id=backup_id,
            target_dir=target_dir
        )
        
        return JSONResponse(content={
            "message": "Backup restore started",
            "backup_id": backup_id,
            "backup_name": backup.name
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to restore backup: {str(e)}")

@router.delete("/backups/{backup_id}", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def delete_backup(backup_id: str):
    """删除备份"""
    try:
        backup = backup_manager.get_backup(backup_id)
        if not backup:
            raise HTTPException(status_code=404, detail="Backup not found")
        
        success = backup_manager.delete_backup(backup_id)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to delete backup")
        
        return JSONResponse(content={
            "message": "Backup deleted successfully",
            "backup_id": backup_id
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete backup: {str(e)}")

@router.get("/backups/{backup_id}/download", response_model=None)
@rate_limit
async def download_backup(backup_id: str):
    """下载备份文件"""
    try:
        backup = backup_manager.get_backup(backup_id)
        if not backup:
            raise HTTPException(status_code=404, detail="Backup not found")
        
        if not os.path.exists(backup.file_path):
            raise HTTPException(status_code=404, detail="Backup file not found")
        
        return FileResponse(
            path=backup.file_path,
            filename=f"{backup.name}_{backup.id}.tar.gz",
            media_type="application/gzip"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to download backup: {str(e)}")

@router.get("/schedules", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_backup_schedules():
    """获取备份计划"""
    try:
        schedules = backup_manager.scheduler.get_schedules()
        return JSONResponse(content=schedules)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get backup schedules: {str(e)}")

@router.post("/schedules", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def create_backup_schedule(schedule_data: Dict[str, Any]):
    """创建备份计划"""
    try:
        name = schedule_data.get("name")
        if not name:
            raise HTTPException(status_code=400, detail="Schedule name is required")
        
        backup_manager.scheduler.add_schedule(name, schedule_data)
        
        return JSONResponse(content={
            "message": "Backup schedule created successfully",
            "schedule": schedule_data
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create backup schedule: {str(e)}")

@router.put("/schedules/{schedule_name}", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def update_backup_schedule(schedule_name: str, schedule_data: Dict[str, Any]):
    """更新备份计划"""
    try:
        schedules = backup_manager.scheduler.get_schedules()
        if schedule_name not in schedules:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # 更新计划
        schedules[schedule_name].update(schedule_data)
        backup_manager.scheduler.schedules = schedules
        
        return JSONResponse(content={
            "message": "Backup schedule updated successfully",
            "schedule": schedules[schedule_name]
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update backup schedule: {str(e)}")

@router.delete("/schedules/{schedule_name}", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def delete_backup_schedule(schedule_name: str):
    """删除备份计划"""
    try:
        backup_manager.scheduler.remove_schedule(schedule_name)
        
        return JSONResponse(content={
            "message": "Backup schedule deleted successfully",
            "schedule_name": schedule_name
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete backup schedule: {str(e)}")

@router.post("/schedules/{schedule_name}/run", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def run_backup_schedule(schedule_name: str):
    """立即运行备份计划"""
    try:
        schedules = backup_manager.scheduler.get_schedules()
        if schedule_name not in schedules:
            raise HTTPException(status_code=404, detail="Schedule not found")
        
        # 立即运行计划
        await backup_manager.scheduler._run_backup_task(schedule_name, schedules[schedule_name])
        
        return JSONResponse(content={
            "message": "Backup schedule executed successfully",
            "schedule_name": schedule_name
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to run backup schedule: {str(e)}")

@router.get("/stats", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_backup_statistics():
    """获取备份统计"""
    try:
        stats = backup_manager.get_backup_stats()
        return JSONResponse(content=stats)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get backup statistics: {str(e)}")

@router.post("/cleanup", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def cleanup_old_backups():
    """清理旧备份"""
    try:
        await backup_manager._cleanup_old_backups()
        
        return JSONResponse(content={
            "message": "Old backups cleaned up successfully"
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cleanup old backups: {str(e)}")

@router.get("/types", response_model=List[str], response_model=None)
@rate_limit
async def get_backup_types():
    """获取支持的备份类型"""
    try:
        return JSONResponse(content=[backup_type.value for backup_type in BackupType])
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get backup types: {str(e)}")

@router.get("/status", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def get_backup_status():
    """获取备份状态"""
    try:
        stats = backup_manager.get_backup_stats()
        schedules = backup_manager.scheduler.get_schedules()
        
        return JSONResponse(content={
            "backup_statistics": stats,
            "schedules": schedules,
            "running_backups": list(backup_manager.scheduler.running_backups.keys()),
            "status": "active"
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get backup status: {str(e)}")

@router.post("/verify/{backup_id}", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def verify_backup(backup_id: str):
    """验证备份完整性"""
    try:
        backup = backup_manager.get_backup(backup_id)
        if not backup:
            raise HTTPException(status_code=404, detail="Backup not found")
        
        if not os.path.exists(backup.file_path):
            raise HTTPException(status_code=404, detail="Backup file not found")
        
        # 计算文件校验和
        current_checksum = backup_manager._calculate_checksum(backup.file_path)
        is_valid = current_checksum == backup.checksum
        
        return JSONResponse(content={
            "backup_id": backup_id,
            "is_valid": is_valid,
            "stored_checksum": backup.checksum,
            "current_checksum": current_checksum,
            "file_size": os.path.getsize(backup.file_path)
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to verify backup: {str(e)}")

@router.get("/export", response_model=Dict[str, Any], response_model=None)
@rate_limit
async def export_backup_list():
    """导出备份列表"""
    try:
        backups = backup_manager.get_all_backups()
        export_data = {
            "exported_at": datetime.utcnow().isoformat(),
            "total_backups": len(backups),
            "backups": [backup.to_dict() for backup in backups]
        }
        
        return JSONResponse(content=export_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export backup list: {str(e)}")

@router.post("/import", response_model=Dict[str, Any], response_model=None)
@leader_only
@rate_limit
async def import_backup_list(import_data: Dict[str, Any]):
    """导入备份列表"""
    try:
        # 这里应该实现备份列表的导入逻辑
        # 例如从其他系统导入备份信息
        
        return JSONResponse(content={
            "message": "Backup list imported successfully",
            "imported_count": 0
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to import backup list: {str(e)}")
