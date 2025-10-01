# 优化硬编码sleep调用的脚本
# 将硬编码的sleep时间替换为可配置的智能等待函数

Write-Host "开始优化硬编码sleep调用..." -ForegroundColor Green

# 需要处理的文件列表
$files = @(
    "ipv6-wireguard-manager.sh",
    "tests/comprehensive_test_suite.sh", 
    "uninstall.sh",
    "install_with_download.sh",
    "modules/user_interface.sh"
)

# 替换规则
$replacements = @{
    "sleep 0.1" = "smart_sleep `$IPV6WGM_SLEEP_SHORT"
    "sleep 0.5" = "smart_sleep `$IPV6WGM_SLEEP_UI"
    "sleep 1" = "smart_sleep `$IPV6WGM_SLEEP_MEDIUM"
    "sleep 2" = "smart_sleep `$IPV6WGM_SLEEP_LONG"
}

# 处理每个文件
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "处理文件: $file" -ForegroundColor Yellow
        
        # 创建备份
        Copy-Item $file "${file}.backup"
        
        # 读取文件内容
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # 应用替换规则
        foreach ($oldPattern in $replacements.Keys) {
            $newPattern = $replacements[$oldPattern]
            $content = $content -replace [regex]::Escape($oldPattern), $newPattern
        }
        
        # 写回文件
        Set-Content $file -Value $content -Encoding UTF8
        
        Write-Host "✓ 已处理: $file" -ForegroundColor Green
    } else {
        Write-Host "⚠ 文件不存在: $file" -ForegroundColor Red
    }
}

Write-Host "sleep调用优化完成！" -ForegroundColor Green

# 验证结果
Write-Host "验证优化结果..." -ForegroundColor Cyan
foreach ($file in $files) {
    if (Test-Path $file) {
        $hardcodedSleeps = (Select-String -Path $file -Pattern "sleep [0-9]").Count
        $smartSleeps = (Select-String -Path $file -Pattern "smart_sleep").Count
        
        if ($hardcodedSleeps -gt 0) {
            Write-Host "⚠ $file 仍有 $hardcodedSleeps 个硬编码sleep调用" -ForegroundColor Red
        } else {
            Write-Host "✓ $file 已优化完成 (使用 $smartSleeps 个smart_sleep调用)" -ForegroundColor Green
        }
    }
}

Write-Host "优化验证完成！" -ForegroundColor Green
