# 统一日志函数脚本
# 移除重复的日志函数定义，统一使用 common_functions.sh 中的版本

Write-Host "开始统一日志函数..." -ForegroundColor Green

# 需要处理的文件列表（排除 common_functions.sh 本身）
$files = @(
    "ipv6-wireguard-manager.sh",
    "scripts/automated-testing.sh",
    "install.sh",
    "uninstall.sh",
    "scripts/deploy.sh",
    "tests/comprehensive_test_suite.sh",
    "tests/windows_compatibility_test_suite.sh",
    "modules/security_functions.sh",
    "modules/security_audit_monitoring.sh",
    "modules/resource_monitoring.sh",
    "modules/oauth_authentication.sh",
    "modules/update_management.sh",
    "modules/unified_error_handling.sh",
    "modules/client_auto_install.sh",
    "modules/module_preloading.sh"
)

# 日志函数模式
$logFunctions = @(
    "log_debug",
    "log_info", 
    "log_warn",
    "log_error",
    "log_success",
    "log_fatal"
)

# 颜色变量模式
$colorVariables = @(
    "RED=",
    "GREEN=",
    "YELLOW=",
    "BLUE=",
    "PURPLE=",
    "CYAN=",
    "WHITE=",
    "NC="
)

# 处理每个文件
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "处理文件: $file" -ForegroundColor Yellow
        
        # 创建备份
        Copy-Item $file "${file}.backup"
        
        # 读取文件内容
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # 移除重复的日志函数定义
        foreach ($func in $logFunctions) {
            # 使用正则表达式移除函数定义
            $pattern = "(?s)^${func}\(\)\s*\{[^}]*\}"
            $content = $content -replace $pattern, ""
        }
        
        # 移除重复的颜色变量定义
        foreach ($color in $colorVariables) {
            # 移除颜色变量定义行
            $pattern = "^${color}.*\\033.*$"
            $content = $content -replace $pattern, ""
        }
        
        # 确保文件导入了 common_functions.sh
        if ($content -notmatch "source.*common_functions\.sh") {
            # 在文件开头添加导入语句
            $importStatement = @"
# 导入公共函数库
if [[ -f "`${SCRIPT_DIR:-`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)}/modules/common_functions.sh" ]]; then
    source "`${SCRIPT_DIR:-`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)}/modules/common_functions.sh"
fi

"@
            $content = $importStatement + $content
        }
        
        # 写回文件
        Set-Content $file -Value $content -Encoding UTF8
        
        Write-Host "✓ 已处理: $file" -ForegroundColor Green
    } else {
        Write-Host "⚠ 文件不存在: $file" -ForegroundColor Red
    }
}

Write-Host "日志函数统一完成！" -ForegroundColor Green

# 验证结果
Write-Host "验证统一结果..." -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        $duplicateLogs = (Select-String -Path $file -Pattern "^log_[a-z_]*\(\)\s*\{").Count
        $duplicateColors = (Select-String -Path $file -Pattern "^[A-Z_]*=.*\\033").Count
        
        if ($duplicateLogs -gt 0 -or $duplicateColors -gt 0) {
            Write-Host "⚠ $file 仍有重复定义: 日志函数($duplicateLogs), 颜色变量($duplicateColors)" -ForegroundColor Red
        } else {
            Write-Host "✓ $file 已清理完成" -ForegroundColor Green
        }
    }
}

Write-Host "统一验证完成！" -ForegroundColor Green
