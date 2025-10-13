# IPv6 WireGuard Manager - 源代码检查脚本
Write-Host "🔍 检查源代码完整性..." -ForegroundColor Green

# 检查关键文件
$files = @(
    "backend/app/main.py",
    "backend/app/core/config.py", 
    "backend/app/core/database.py",
    "backend/app/core/security.py",
    "backend/app/api/api_v1/api.py",
    "backend/app/api/api_v1/endpoints/auth.py",
    "backend/app/api/api_v1/endpoints/users.py",
    "backend/app/api/api_v1/endpoints/status.py",
    "backend/app/api/api_v1/endpoints/wireguard.py",
    "backend/app/services/user_service.py",
    "backend/app/models/user.py",
    "backend/app/schemas/user.py"
)

Write-Host "📋 检查关键文件..." -ForegroundColor Yellow

$missingFiles = @()
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

Write-Host ""
if ($missingFiles.Count -eq 0) {
    Write-Host "✅ 所有关键文件都存在！" -ForegroundColor Green
} else {
    Write-Host "❌ 发现 $($missingFiles.Count) 个缺失文件" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🔧 检查文件内容..." -ForegroundColor Yellow

# 检查auth.py
if (Test-Path "backend/app/api/api_v1/endpoints/auth.py") {
    $authContent = Get-Content "backend/app/api/api_v1/endpoints/auth.py" -Raw
    if ($authContent -match "async def login") {
        Write-Host "✅ auth.py 包含login函数" -ForegroundColor Green
    } else {
        Write-Host "❌ auth.py 缺少login函数" -ForegroundColor Red
    }
} else {
    Write-Host "❌ auth.py 文件不存在" -ForegroundColor Red
}

# 检查users.py
if (Test-Path "backend/app/api/api_v1/endpoints/users.py") {
    $usersContent = Get-Content "backend/app/api/api_v1/endpoints/users.py" -Raw
    if ($usersContent -match "async def get_users") {
        Write-Host "✅ users.py 包含get_users函数" -ForegroundColor Green
    } else {
        Write-Host "❌ users.py 缺少get_users函数" -ForegroundColor Red
    }
} else {
    Write-Host "❌ users.py 文件不存在" -ForegroundColor Red
}

# 检查main.py
if (Test-Path "backend/app/main.py") {
    $mainContent = Get-Content "backend/app/main.py" -Raw
    if ($mainContent -match "app.include_router") {
        Write-Host "✅ main.py 包含API路由" -ForegroundColor Green
    } else {
        Write-Host "❌ main.py 缺少API路由" -ForegroundColor Red
    }
} else {
    Write-Host "❌ main.py 文件不存在" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 生成检查报告..." -ForegroundColor Yellow

$report = @"
IPv6 WireGuard Manager - 源代码检查报告
生成时间: $(Get-Date)

文件检查结果:
"@

foreach ($file in $files) {
    if (Test-Path $file) {
        $report += "`n✅ $file - 存在"
    } else {
        $report += "`n❌ $file - 缺失"
    }
}

$report += @"

修复建议:
1. 确保所有文件都存在
2. 检查文件内容完整性
3. 验证导入语句
4. 在Linux服务器上重新部署

下一步操作:
1. 在Linux服务器上运行安装脚本
2. 检查后端服务状态
3. 测试API端点响应
"@

$report | Out-File -FilePath "source-check-report.txt" -Encoding UTF8

Write-Host "✅ 源代码检查完成！" -ForegroundColor Green
Write-Host "📄 检查报告已保存到: source-check-report.txt" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 建议操作:" -ForegroundColor Yellow
Write-Host "1. 在Linux服务器上运行: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash" -ForegroundColor White
Write-Host "2. 检查后端服务状态" -ForegroundColor White
Write-Host "3. 测试API端点响应" -ForegroundColor White
