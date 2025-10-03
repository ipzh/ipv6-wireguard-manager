# IPv6 WireGuard Manager 自动提交脚本 (PowerShell版本)
# 监控文件变化并自动提交到Git仓库

param(
    [int]$Interval = 30,
    [switch]$Push,
    [switch]$NoPush,
    [string]$Prefix = "auto",
    [switch]$Once,
    [switch]$Status,
    [switch]$Help
)

# 配置
$script:AutoPush = $true
$script:WatchInterval = $Interval
$script:CommitPrefix = $Prefix

# 颜色函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Info { param([string]$Message) Write-ColorOutput "INFO: $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorOutput "SUCCESS: $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "WARN: $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "ERROR: $Message" "Red" }

# 检查Git仓库状态
function Test-GitRepository {
    try {
        git rev-parse --git-dir | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "当前目录不是Git仓库"
            exit 1
        }
        
        git remote get-url origin | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "未配置远程仓库origin"
            $script:AutoPush = $false
        }
    }
    catch {
        Write-Error "Git检查失败: $($_.Exception.Message)"
        exit 1
    }
}

# 生成提交信息
function New-CommitMessage {
    $changedFiles = (git diff --cached --name-only | Measure-Object).Count
    $deletedFiles = (git diff --cached --diff-filter=D --name-only | Measure-Object).Count
    $addedFiles = (git diff --cached --diff-filter=A --name-only | Measure-Object).Count
    $modifiedFiles = (git diff --cached --diff-filter=M --name-only | Measure-Object).Count
    
    $message = "$script:CommitPrefix`: 自动提交 - "
    
    if ($addedFiles -gt 0) { $message += "新增${addedFiles}个文件 " }
    if ($modifiedFiles -gt 0) { $message += "修改${modifiedFiles}个文件 " }
    if ($deletedFiles -gt 0) { $message += "删除${deletedFiles}个文件 " }
    
    $time = Get-Date -Format "HH:mm:ss"
    $message += "($time)"
    
    return $message
}

# 自动提交函数
function Invoke-AutoCommit {
    # 检查是否有变化
    git diff --quiet
    $workingTreeClean = ($LASTEXITCODE -eq 0)
    
    git diff --cached --quiet
    $stagingClean = ($LASTEXITCODE -eq 0)
    
    if ($workingTreeClean -and $stagingClean) {
        return $true
    }
    
    Write-Info "检测到文件变化，准备自动提交..."
    
    # 显示变化的文件
    $changedFiles = git status --porcelain
    if ($changedFiles) {
        Write-Info "变化的文件:"
        $changedFiles | ForEach-Object { Write-Host "  $_" }
    }
    
    # 添加所有变化到暂存区
    git add -A
    
    # 检查是否有暂存的变化
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Info "没有需要提交的变化"
        return $true
    }
    
    # 生成提交信息
    $commitMessage = New-CommitMessage
    
    # 提交变化
    git commit -m $commitMessage
    if ($LASTEXITCODE -eq 0) {
        Write-Success "自动提交成功: $commitMessage"
        
        # 自动推送到远程仓库
        if ($script:AutoPush) {
            Write-Info "推送到远程仓库..."
            $currentBranch = git branch --show-current
            git push origin $currentBranch 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "推送成功"
            } else {
                Write-Warning "推送失败，可能需要手动推送"
            }
        }
        return $true
    } else {
        Write-Error "提交失败"
        return $false
    }
}

# 监控循环
function Start-Monitoring {
    Write-Info "开始监控文件变化..."
    Write-Info "监控间隔: $script:WatchInterval 秒"
    Write-Info "自动推送: $script:AutoPush"
    Write-Info "按 Ctrl+C 停止监控"
    
    try {
        while ($true) {
            Invoke-AutoCommit | Out-Null
            Start-Sleep -Seconds $script:WatchInterval
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Info "监控已停止"
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host @"
IPv6 WireGuard Manager 自动提交脚本 (PowerShell版本)

用法: .\auto-commit.ps1 [参数]

参数:
  -Interval <秒数>        设置监控间隔（默认: 30秒）
  -Push                   启用自动推送到远程仓库
  -NoPush                 禁用自动推送
  -Prefix <前缀>          设置提交信息前缀（默认: auto）
  -Once                   只执行一次检查和提交
  -Status                 显示当前Git状态
  -Help                   显示帮助信息

示例:
  .\auto-commit.ps1                    # 使用默认设置开始监控
  .\auto-commit.ps1 -Interval 60 -Push # 60秒间隔，启用自动推送
  .\auto-commit.ps1 -Once              # 只执行一次提交
  .\auto-commit.ps1 -Status            # 显示Git状态
"@
}

# 显示Git状态
function Show-GitStatus {
    Write-Info "Git仓库状态:"
    git status --short
    
    Write-Info "最近的提交:"
    git log --oneline -5
    
    try {
        $remoteUrl = git remote get-url origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "远程仓库: $remoteUrl"
            $currentBranch = git branch --show-current
            Write-Info "当前分支: $currentBranch"
        }
    }
    catch {
        Write-Warning "无法获取远程仓库信息"
    }
}

# 主程序
function Main {
    Write-Info "IPv6 WireGuard Manager 自动提交脚本启动"
    
    # 处理参数
    if ($Help) {
        Show-Help
        return
    }
    
    if ($Push) { $script:AutoPush = $true }
    if ($NoPush) { $script:AutoPush = $false }
    
    # 检查Git仓库
    Test-GitRepository
    
    if ($Status) {
        Show-GitStatus
        return
    }
    
    if ($Once) {
        Invoke-AutoCommit
        return
    }
    
    # 开始监控
    Start-Monitoring
}

# 运行主程序
Main