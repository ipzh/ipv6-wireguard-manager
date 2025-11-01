# PowerShell安全头测试脚本
# 用于验证安全头不重复设置，配置正确

param(
    [string]$BaseUrl = "http://192.168.1.110",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# 测试结果计数
$script:Passed = 0
$script:Failed = 0
$script:Warnings = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [string]$Status,  # PASS, FAIL, WARN
        [string]$Message = ""
    )
    
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    
    Write-Host -NoNewline "$TestName ... "
    Write-Host -ForegroundColor $color $Status
    
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
    
    switch ($Status) {
        "PASS" { $script:Passed++ }
        "FAIL" { $script:Failed++ }
        "WARN" { $script:Warnings++ }
    }
}

function Test-SecurityHeader {
    param(
        [string]$HeaderName,
        [string[]]$ExpectedValues,
        [string]$Url = $BaseUrl
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -ErrorAction Stop
        
        # 检查响应头中是否存在该安全头
        $headerValue = $response.Headers[$HeaderName]
        
        if (-not $headerValue) {
            Write-TestResult -TestName "检查 $HeaderName" -Status "WARN" -Message "未设置"
            return $false
        }
        
        # 转换为字符串数组（如果有多值）
        if ($headerValue -is [string[]]) {
            $headerValue = $headerValue -join ", "
        }
        
        # 检查是否包含逗号（表示可能有重复值）
        if ($headerValue -match ",") {
            Write-TestResult -TestName "检查 $HeaderName" -Status "FAIL" -Message "发现重复值: $headerValue"
            return $false
        }
        
        # 检查是否为预期值
        $isValid = $false
        foreach ($expected in $ExpectedValues) {
            if ($headerValue -match [regex]::Escape($expected)) {
                $isValid = $true
                break
            }
        }
        
        if ($isValid) {
            if ($Verbose) {
                Write-TestResult -TestName "检查 $HeaderName" -Status "PASS" -Message "值: $headerValue"
            } else {
                Write-TestResult -TestName "检查 $HeaderName" -Status "PASS"
            }
            return $true
        } else {
            Write-TestResult -TestName "检查 $HeaderName" -Status "WARN" -Message "值: $headerValue (不在预期列表中)"
            return $false
        }
    } catch {
        Write-TestResult -TestName "检查 $HeaderName" -Status "FAIL" -Message "请求失败: $($_.Exception.Message)"
        return $false
    }
}

function Test-DuplicateHeaders {
    param([string]$Url = $BaseUrl)
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "测试1: 安全头重复检测"
    Write-Host "=========================================="
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -ErrorAction Stop
        
        $securityHeaders = @(
            "X-Frame-Options",
            "X-Content-Type-Options",
            "X-XSS-Protection",
            "Referrer-Policy"
        )
        
        foreach ($headerName in $securityHeaders) {
            if ($response.Headers.ContainsKey($headerName)) {
                $headerValue = $response.Headers[$headerName]
                
                # 转换为字符串数组
                if ($headerValue -is [string[]]) {
                    $headerValue = $headerValue -join ", "
                }
                
                # 检查是否包含逗号（重复值）
                if ($headerValue -match ",") {
                    Write-Host -ForegroundColor Red "❌ $headerName`: 发现重复值"
                    Write-Host "  值: $headerValue" -ForegroundColor Gray
                    $script:Failed++
                } else {
                    Write-Host -ForegroundColor Green "✅ $headerName`: 单一值"
                    if ($Verbose) {
                        Write-Host "  值: $headerValue" -ForegroundColor Gray
                    }
                }
            }
        }
    } catch {
        Write-Host -ForegroundColor Red "请求失败: $($_.Exception.Message)"
        $script:Failed++
    }
}

function Test-SpecificHeaders {
    param([string]$Url = $BaseUrl)
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "测试2: 安全头值验证"
    Write-Host "=========================================="
    
    Test-SecurityHeader -HeaderName "X-Frame-Options" -ExpectedValues @("DENY", "SAMEORIGIN") -Url $Url
    Test-SecurityHeader -HeaderName "X-Content-Type-Options" -ExpectedValues @("nosniff") -Url $Url
    Test-SecurityHeader -HeaderName "X-XSS-Protection" -ExpectedValues @("1; mode=block") -Url $Url
    Test-SecurityHeader -HeaderName "Referrer-Policy" -ExpectedValues @("strict-origin-when-cross-origin", "no-referrer-when-downgrade") -Url $Url
}

function Test-HealthEndpoints {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "测试3: 健康检查端点"
    Write-Host "=========================================="
    
    # 测试 /api/v1/health
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/health" -Method GET -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-TestResult -TestName "测试 /api/v1/health" -Status "PASS" -Message "HTTP $($response.StatusCode)"
        } else {
            Write-TestResult -TestName "测试 /api/v1/health" -Status "FAIL" -Message "HTTP $($response.StatusCode)"
        }
    } catch {
        Write-TestResult -TestName "测试 /api/v1/health" -Status "FAIL" -Message "请求失败: $($_.Exception.Message)"
    }
    
    # 测试 /health
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/health" -Method GET -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-TestResult -TestName "测试 /health" -Status "PASS" -Message "HTTP $($response.StatusCode)"
        } else {
            Write-TestResult -TestName "测试 /health" -Status "FAIL" -Message "HTTP $($response.StatusCode)"
        }
    } catch {
        Write-TestResult -TestName "测试 /health" -Status "FAIL" -Message "请求失败: $($_.Exception.Message)"
    }
}

# 主函数
function Main {
    Write-Host "=========================================="
    Write-Host "安全头测试脚本"
    Write-Host "=========================================="
    Write-Host "测试URL: $BaseUrl"
    Write-Host ""
    
    # 运行测试
    Test-DuplicateHeaders
    Test-SpecificHeaders
    Test-HealthEndpoints
    
    # 总结
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "测试总结"
    Write-Host "=========================================="
    Write-Host -ForegroundColor Green "通过: $script:Passed"
    Write-Host -ForegroundColor Yellow "警告: $script:Warnings"
    Write-Host -ForegroundColor Red "失败: $script:Failed"
    Write-Host ""
    
    if ($script:Failed -eq 0) {
        Write-Host -ForegroundColor Green "✅ 所有测试通过！"
        exit 0
    } else {
        Write-Host -ForegroundColor Red "❌ 部分测试失败，请检查配置"
        exit 1
    }
}

# 运行主函数
Main

