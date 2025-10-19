@echo off
REM IPv6 WireGuard Manager API服務修復腳本 (Windows版本)
REM 修復 circular import 錯誤和 IPv6 連接問題

setlocal enabledelayedexpansion

REM 配置參數
set INSTALL_DIR=%INSTALL_DIR%
if "%INSTALL_DIR%"=="" set INSTALL_DIR=D:\ipv6-wireguard
set API_PORT=%API_PORT%
if "%API_PORT%"=="" set API_PORT=8000
set SERVICE_NAME=ipv6-wireguard-manager

echo ====================================
echo IPv6 WireGuard Manager API服務修復
echo ====================================
echo.

echo [INFO] 檢查修復腳本...
if not exist "%INSTALL_DIR%\scripts\fix_api_service.sh" (
    echo [ERROR] 修復腳本不存在: %INSTALL_DIR%\scripts\fix_api_service.sh
    echo [INFO] 請確保在正確的目錄中運行此腳本
    pause
    exit /b 1
)

echo [INFO] 修復腳本已準備就緒
echo [INFO] 安裝目錄: %INSTALL_DIR%
echo [INFO] API端口: %API_PORT%
echo.

echo [INFO] 請在Linux系統中運行以下命令來修復API服務:
echo.
echo sudo %INSTALL_DIR%/scripts/fix_api_service.sh
echo.
echo 或者手動執行以下步驟:
echo.
echo 1. 停止API服務:
echo    sudo systemctl stop %SERVICE_NAME%
echo.
echo 2. 更新systemd服務配置:
echo    sudo nano /etc/systemd/system/%SERVICE_NAME%.service
echo    將 --host :: 改為 --host 0.0.0.0
echo.
echo 3. 重新加載systemd配置:
echo    sudo systemctl daemon-reload
echo.
echo 4. 啟動API服務:
echo    sudo systemctl start %SERVICE_NAME%
echo.
echo 5. 檢查服務狀態:
echo    sudo systemctl status %SERVICE_NAME%
echo.
echo 6. 運行檢查腳本:
echo    sudo %INSTALL_DIR%/scripts/check_api_service.sh
echo.

echo [SUCCESS] 修復說明已顯示完成
echo [INFO] 請按照上述步驟在Linux系統中修復API服務
pause
