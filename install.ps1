# IPv6 WireGuard Manager PowerShell 一键安装脚本
# 支持Windows PowerShell和PowerShell Core

param(
    [switch]$Force,
    [string]$InstallPath = ".\ipv6-wireguard-manager"
)

# 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 项目信息
$PROJECT_NAME = "IPv6 WireGuard Manager"
$REPO_URL = "https://github.com/ipzh/ipv6-wireguard-manager.git"

# 颜色函数
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    Clear-Host
    Write-ColorMessage "==================================" "Cyan"
    Write-ColorMessage "$PROJECT_NAME PowerShell 一键安装" "Cyan"
    Write-ColorMessage "==================================" "Cyan"
    Write-Host ""
    Write-ColorMessage "本脚本将自动下载并安装 $PROJECT_NAME" "Yellow"
    Write-ColorMessage "支持 Windows PowerShell 5.1+ 和 PowerShell Core 6+" "Yellow"
    Write-Host ""
}

# 检查系统要求
function Test-Requirements {
    Write-ColorMessage "🔍 检查系统要求..." "Yellow"
    
    # 检查PowerShell版本
    $PSVersion = $PSVersionTable.PSVersion
    Write-ColorMessage "✅ PowerShell 版本: $($PSVersion.ToString())" "Green"
    
    # 检查Git
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ Git 已安装: $gitVersion" "Green"
        } else {
            throw "Git not found"
        }
    } catch {
        Write-ColorMessage "❌ Git 未安装" "Red"
        Write-ColorMessage "请先安装 Git: https://git-scm.com/downloads" "Yellow"
        exit 1
    }
    
    # 检查Docker
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ Docker 已安装: $dockerVersion" "Green"
        } else {
            throw "Docker not found"
        }
    } catch {
        Write-ColorMessage "❌ Docker 未安装" "Red"
        Write-ColorMessage "请先安装 Docker Desktop: https://docs.docker.com/desktop/windows/install/" "Yellow"
        exit 1
    }
    
    # 检查Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ Docker Compose 已安装: $composeVersion" "Green"
        } else {
            throw "Docker Compose not found"
        }
    } catch {
        Write-ColorMessage "❌ Docker Compose 未安装" "Red"
        Write-ColorMessage "请先安装 Docker Compose" "Yellow"
        exit 1
    }
    
    # 检查Docker服务状态
    try {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ Docker 服务运行正常" "Green"
        } else {
            throw "Docker service not running"
        }
    } catch {
        Write-ColorMessage "❌ Docker 服务未运行" "Red"
        Write-ColorMessage "请启动 Docker Desktop" "Yellow"
        exit 1
    }
    
    Write-ColorMessage "✅ 系统要求检查通过" "Green"
}

# 克隆项目
function Install-Project {
    Write-ColorMessage "📥 下载项目..." "Yellow"
    
    # 检查目标目录
    if (Test-Path $InstallPath) {
        if ($Force) {
            Write-ColorMessage "⚠️  删除现有目录: $InstallPath" "Yellow"
            Remove-Item -Path $InstallPath -Recurse -Force
        } else {
            Write-ColorMessage "⚠️  目录 $InstallPath 已存在" "Yellow"
            $choice = Read-Host "是否删除现有目录并重新安装? (y/N)"
            if ($choice -eq "y" -or $choice -eq "Y") {
                Remove-Item -Path $InstallPath -Recurse -Force
            } else {
                Write-ColorMessage "使用现有目录" "Yellow"
                return
            }
        }
    }
    
    # 克隆项目
    try {
        git clone $REPO_URL $InstallPath
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ 项目下载成功" "Green"
        } else {
            throw "Git clone failed"
        }
    } catch {
        Write-ColorMessage "❌ 下载项目失败" "Red"
        Write-ColorMessage "请检查网络连接和GitHub访问" "Yellow"
        exit 1
    }
    
    # 切换到项目目录
    Set-Location $InstallPath
}

# 设置环境
function Set-Environment {
    Write-ColorMessage "🔐 设置环境..." "Yellow"
    
    # 创建必要目录
    $directories = @("data\postgres", "data\redis", "logs", "uploads", "backups")
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # 配置环境文件
    if (Test-Path "backend\env.example") {
        if (-not (Test-Path "backend\.env")) {
            Copy-Item "backend\env.example" "backend\.env"
            Write-ColorMessage "✅ 环境配置文件已创建" "Green"
        }
        
        # 生成随机密码
        $SECRET_KEY = -join ((1..32) | ForEach {Get-Random -InputObject @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9')})
        $DB_PASSWORD = -join ((1..32) | ForEach {Get-Random -InputObject @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9')})
        
        # 更新配置文件
        $envContent = Get-Content "backend\.env" -Raw
        $envContent = $envContent -replace "your-super-secret-key-for-jwt", $SECRET_KEY
        $envContent = $envContent -replace "ipv6wgm", $DB_PASSWORD
        Set-Content "backend\.env" $envContent
        
        Write-ColorMessage "✅ 环境配置已更新" "Green"
        Write-ColorMessage "🔑 数据库密码: $DB_PASSWORD" "Yellow"
        Write-ColorMessage "🔑 JWT密钥: $SECRET_KEY" "Yellow"
    }
}

# 启动服务
function Start-Services {
    Write-ColorMessage "🚀 启动服务..." "Yellow"
    
    try {
        docker-compose up -d
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ 服务启动成功" "Green"
        } else {
            throw "Docker compose failed"
        }
    } catch {
        Write-ColorMessage "❌ 启动服务失败" "Red"
        Write-ColorMessage "请检查Docker配置和端口占用" "Yellow"
        exit 1
    }
    
    # 等待服务启动
    Write-ColorMessage "⏳ 等待服务启动..." "Yellow"
    Start-Sleep -Seconds 20
    
    # 检查服务状态
    docker-compose ps
}

# 初始化数据库
function Initialize-Database {
    Write-ColorMessage "🗄️  初始化数据库..." "Yellow"
    Start-Sleep -Seconds 10
    
    try {
        docker-compose exec -T backend python -c "import asyncio; from app.core.init_db import init_db; asyncio.run(init_db())" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "✅ 数据库初始化成功" "Green"
        } else {
            Write-ColorMessage "⚠️  数据库初始化可能失败，请手动检查" "Yellow"
        }
    } catch {
        Write-ColorMessage "⚠️  数据库初始化可能失败，请手动检查" "Yellow"
    }
}

# 验证安装
function Test-Installation {
    Write-ColorMessage "🔍 验证安装..." "Yellow"
    
    $allHealthy = $true
    
    # 检查后端服务
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000" -TimeoutSec 5 -UseBasicParsing 2>$null
        if ($response.StatusCode -eq 200) {
            Write-ColorMessage "✅ 后端服务正常" "Green"
        } else {
            Write-ColorMessage "❌ 后端服务异常" "Red"
            $allHealthy = $false
        }
    } catch {
        Write-ColorMessage "❌ 后端服务异常" "Red"
        $allHealthy = $false
    }
    
    # 检查前端服务
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing 2>$null
        if ($response.StatusCode -eq 200) {
            Write-ColorMessage "✅ 前端服务正常" "Green"
        } else {
            Write-ColorMessage "❌ 前端服务异常" "Red"
            $allHealthy = $false
        }
    } catch {
        Write-ColorMessage "❌ 前端服务异常" "Red"
        $allHealthy = $false
    }
    
    return $allHealthy
}

# 显示结果
function Show-Result {
    param([bool]$AllHealthy)
    
    Write-Host ""
    Write-ColorMessage "==================================" "Cyan"
    if ($AllHealthy) {
        Write-ColorMessage "🎉 安装完成！" "Green"
    } else {
        Write-ColorMessage "⚠️  安装完成，但部分服务可能存在问题" "Yellow"
    }
    Write-ColorMessage "==================================" "Cyan"
    Write-Host ""
    
    Write-ColorMessage "📋 访问信息：" "Cyan"
    Write-Host "   - 前端界面: http://localhost:3000"
    Write-Host "   - 后端API: http://localhost:8000"
    Write-Host "   - API文档: http://localhost:8000/docs"
    Write-Host ""
    
    Write-ColorMessage "🔑 默认登录信息：" "Cyan"
    Write-Host "   用户名: admin"
    Write-Host "   密码: admin123"
    Write-Host ""
    
    Write-ColorMessage "🛠️  管理命令：" "Cyan"
    Write-Host "   查看状态: docker-compose ps"
    Write-Host "   查看日志: docker-compose logs -f"
    Write-Host "   停止服务: docker-compose down"
    Write-Host "   重启服务: docker-compose restart"
    Write-Host ""
    
    Write-ColorMessage "⚠️  安全提醒：" "Yellow"
    Write-Host "   请在生产环境中修改默认密码"
    Write-Host "   配置文件位置: backend\.env"
    Write-Host ""
    
    Write-ColorMessage "📁 项目位置：" "Cyan"
    Write-Host "   $(Get-Location)"
    Write-Host ""
}

# 主函数
function Main {
    Write-Header
    
    # 检查系统要求
    Test-Requirements
    
    Write-Host ""
    $choice = Read-Host "按 Enter 键开始安装，或输入 'q' 取消"
    if ($choice -eq "q" -or $choice -eq "Q") {
        Write-ColorMessage "安装已取消" "Yellow"
        exit 0
    }
    Write-Host ""
    
    # 安装项目
    Install-Project
    
    # 设置环境
    Set-Environment
    
    # 启动服务
    Start-Services
    
    # 初始化数据库
    Initialize-Database
    
    # 验证安装
    $allHealthy = Test-Installation
    
    # 显示结果
    Show-Result $allHealthy
}

# 运行主函数
try {
    Main
} catch {
    Write-ColorMessage "❌ 安装过程中发生错误: $($_.Exception.Message)" "Red"
    exit 1
}
