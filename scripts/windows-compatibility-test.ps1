# Windows兼容性测试脚本
# 在PowerShell中运行Windows兼容测试

Write-Host "=========================================="
Write-Host "  IPv6 WireGuard Manager Windows兼容性测试"
Write-Host "=========================================="

# 检查WSL环境
if ($env:WSL_DISTRO_NAME -or $env:WSLENV) {
    Write-Host "检测到WSL环境: $env:WSL_DISTRO_NAME" -ForegroundColor Green
} else {
    Write-Host "当前环境: Windows PowerShell" -ForegroundColor Yellow
}

# 检查必要工具
$tools = @("bash", "curl", "wget", "git")
$missing = @()

foreach ($tool in $tools) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        Write-Host "✓ $tool 已安装" -ForegroundColor Green
    } else {
        Write-Host "✗ $tool 未安装" -ForegroundColor Red
        $missing += $tool
    }
}

if ($missing.Count -gt 0) {
    Write-Host "缺少工具: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "请安装缺少的工具后重试" -ForegroundColor Yellow
} else {
    Write-Host "所有必要工具都已安装" -ForegroundColor Green
}

# 检查项目文件
$projectFiles = @(
    "ipv6-wireguard-manager.sh",
    "install.sh",
    "uninstall.sh",
    "modules/common_functions.sh"
)

Write-Host "`n检查项目文件..."
foreach ($file in $projectFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ $file 不存在" -ForegroundColor Red
    }
}

# 运行基础测试
Write-Host "`n运行基础测试..."
try {
    if (Test-Path "scripts/run_all_tests.sh") {
        bash scripts/run_all_tests.sh --syntax
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ 语法测试通过" -ForegroundColor Green
        } else {
            Write-Host "✗ 语法测试失败" -ForegroundColor Red
        }
    } else {
        Write-Host "测试脚本不存在" -ForegroundColor Yellow
    }
} catch {
    Write-Host "测试执行失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nWindows兼容性测试完成" -ForegroundColor Cyan

