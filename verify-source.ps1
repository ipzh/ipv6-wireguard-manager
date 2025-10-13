# IPv6 WireGuard Manager - 源代码验证脚本
Write-Host "🔍 验证源代码完整性..." -ForegroundColor Green

# 检查关键文件是否存在
function Check-File {
    param($FilePath)
    if (Test-Path $FilePath) {
        Write-Host "✅ $FilePath 存在" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $FilePath 缺失" -ForegroundColor Red
        return $false
    }
}

Write-Host "📋 检查关键文件..." -ForegroundColor Yellow

# 检查后端核心文件
$coreFiles = @(
    "backend/app/main.py",
    "backend/app/core/config.py",
    "backend/app/core/database.py",
    "backend/app/core/security.py",
    "backend/app/api/api_v1/api.py"
)

foreach ($file in $coreFiles) {
    Check-File $file
}

# 检查API端点文件
$endpointFiles = @(
    "backend/app/api/api_v1/endpoints/auth.py",
    "backend/app/api/api_v1/endpoints/users.py",
    "backend/app/api/api_v1/endpoints/status.py",
    "backend/app/api/api_v1/endpoints/wireguard.py",
    "backend/app/api/api_v1/endpoints/network.py",
    "backend/app/api/api_v1/endpoints/monitoring.py",
    "backend/app/api/api_v1/endpoints/logs.py",
    "backend/app/api/api_v1/endpoints/websocket.py",
    "backend/app/api/api_v1/endpoints/system.py",
    "backend/app/api/api_v1/endpoints/bgp.py",
    "backend/app/api/api_v1/endpoints/ipv6.py",
    "backend/app/api/api_v1/endpoints/bgp_sessions.py",
    "backend/app/api/api_v1/endpoints/ipv6_pools.py"
)

foreach ($file in $endpointFiles) {
    Check-File $file
}

# 检查服务文件
$serviceFiles = @(
    "backend/app/services/user_service.py",
    "backend/app/services/wireguard_service.py",
    "backend/app/services/network_service.py",
    "backend/app/services/monitoring_service.py",
    "backend/app/services/bgp_service.py",
    "backend/app/services/ipv6_service.py"
)

foreach ($file in $serviceFiles) {
    Check-File $file
}

# 检查模型文件
$modelFiles = @(
    "backend/app/models/user.py",
    "backend/app/models/wireguard.py",
    "backend/app/models/network.py",
    "backend/app/models/monitoring.py",
    "backend/app/models/bgp.py",
    "backend/app/models/ipv6.py"
)

foreach ($file in $modelFiles) {
    Check-File $file
}

# 检查模式文件
$schemaFiles = @(
    "backend/app/schemas/user.py",
    "backend/app/schemas/wireguard.py",
    "backend/app/schemas/network.py",
    "backend/app/schemas/monitoring.py",
    "backend/app/schemas/bgp.py",
    "backend/app/schemas/ipv6.py"
)

foreach ($file in $schemaFiles) {
    Check-File $file
}

Write-Host ""
Write-Host "🔧 检查源代码内容..." -ForegroundColor Yellow

# 检查关键文件内容
function Check-FileContent {
    param($FilePath, $SearchText, $Description)
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        if ($content -match $SearchText) {
            Write-Host "✅ $Description" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $Description" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "❌ 文件不存在: $FilePath" -ForegroundColor Red
        return $false
    }
}

# 检查auth.py内容
Check-FileContent "backend/app/api/api_v1/endpoints/auth.py" "async def login" "auth.py包含login函数"

# 检查users.py内容
Check-FileContent "backend/app/api/api_v1/endpoints/users.py" "async def get_users" "users.py包含get_users函数"

# 检查main.py内容
Check-FileContent "backend/app/main.py" "app.include_router" "main.py包含API路由"

# 检查config.py内容
Check-FileContent "backend/app/core/config.py" "DATABASE_URL" "config.py包含数据库配置"

# 检查database.py内容
Check-FileContent "backend/app/core/database.py" "create_async_engine" "database.py包含异步引擎"

# 检查security.py内容
Check-FileContent "backend/app/core/security.py" "create_access_token" "security.py包含令牌创建函数"

Write-Host ""
Write-Host "📋 生成验证报告..." -ForegroundColor Yellow

# 生成验证报告
$reportContent = @"
IPv6 WireGuard Manager - 源代码验证报告
生成时间: $(Get-Date)

文件检查结果:
"@

# 添加文件检查结果
foreach ($file in $coreFiles + $endpointFiles + $serviceFiles + $modelFiles + $schemaFiles) {
    if (Test-Path $file) {
        $reportContent += "`n✅ $file - 存在"
    } else {
        $reportContent += "`n❌ $file - 缺失"
    }
}

$reportContent += @"

内容检查结果:
- auth.py login函数: $(if (Check-FileContent "backend/app/api/api_v1/endpoints/auth.py" "async def login" "") { "✅ 存在" } else { "❌ 缺失" })
- users.py get_users函数: $(if (Check-FileContent "backend/app/api/api_v1/endpoints/users.py" "async def get_users" "") { "✅ 存在" } else { "❌ 缺失" })
- main.py API路由: $(if (Check-FileContent "backend/app/main.py" "app.include_router" "") { "✅ 存在" } else { "❌ 缺失" })
- config.py 数据库配置: $(if (Check-FileContent "backend/app/core/config.py" "DATABASE_URL" "") { "✅ 存在" } else { "❌ 缺失" })
- database.py 异步引擎: $(if (Check-FileContent "backend/app/core/database.py" "create_async_engine" "") { "✅ 存在" } else { "❌ 缺失" })
- security.py 令牌函数: $(if (Check-FileContent "backend/app/core/security.py" "create_access_token" "") { "✅ 存在" } else { "❌ 缺失" })

修复建议:
1. 确保所有文件都存在
2. 检查文件内容完整性
3. 验证导入语句
4. 测试Python语法
5. 运行安装脚本重新部署

下一步操作:
1. 在Linux服务器上运行: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/install.sh | bash
2. 检查后端服务状态
3. 测试API端点响应
4. 验证用户认证功能
"@

$reportContent | Out-File -FilePath "source-verification-report.txt" -Encoding UTF8

Write-Host "✅ 源代码验证完成！" -ForegroundColor Green
Write-Host "📄 验证报告已保存到: source-verification-report.txt" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 下一步操作:" -ForegroundColor Yellow
Write-Host "1. 在Linux服务器上运行安装脚本" -ForegroundColor White
Write-Host "2. 检查后端服务状态" -ForegroundColor White
Write-Host "3. 测试API端点响应" -ForegroundColor White
Write-Host "4. 验证用户认证功能" -ForegroundColor White
