# IPv6 WireGuard 客户端一键安装脚本 (Windows PowerShell)
# 版本: 1.0.9
# 支持 Windows 10/11

param(
    [string]$ConfigFile = "",
    [string]$ClientName = "client",
    [switch]$Install = $false,
    [switch]$Start = $false,
    [switch]$Help = $false
)

# 颜色定义
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$White = "White"

# 脚本信息
$ScriptName = "IPv6 WireGuard 客户端安装器 (Windows)"
$ScriptVersion = "1.0.8"
$ScriptAuthor = "IPv6 WireGuard Manager Team"

# 配置变量
$ClientConfigDir = "$env:USERPROFILE\.config\wireguard"
$ClientLogDir = "$env:USERPROFILE\.local\log\wireguard"
$TempDir = "$env:TEMP\wireguard-client-$(Get-Random)"

# 日志函数
function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "ERROR" {
            Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor $Red
        }
        "WARN" {
            Write-Host "[$timestamp] [WARN] $Message" -ForegroundColor $Yellow
        }
        "INFO" {
            Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor $Green
        }
        "DEBUG" {
            Write-Host "[$timestamp] [DEBUG] $Message" -ForegroundColor $Blue
        }
        default {
            Write-Host "[$timestamp] [$Level] $Message"
        }
    }
}

# 错误处理函数
function Write-Error-Exit {
    param([string]$Message)
    Write-Log "ERROR" $Message
    Cleanup-TempFiles
    exit 1
}

# 清理临时文件
function Cleanup-TempFiles {
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "DEBUG" "Cleaned up temporary directory: $TempDir"
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host "IPv6 WireGuard 客户端安装器 (Windows)" -ForegroundColor $White
    Write-Host "版本: $ScriptVersion" -ForegroundColor $White
    Write-Host ""
    Write-Host "用法:" -ForegroundColor $Yellow
    Write-Host "  .\client-installer.ps1 [参数]" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "参数:" -ForegroundColor $Yellow
    Write-Host "  -ConfigFile <路径>    指定配置文件路径" -ForegroundColor $Cyan
    Write-Host "  -ClientName <名称>    指定客户端名称 (默认: client)" -ForegroundColor $Cyan
    Write-Host "  -Install              安装 WireGuard" -ForegroundColor $Cyan
    Write-Host "  -Start                启动客户端" -ForegroundColor $Cyan
    Write-Host "  -Help                 显示此帮助信息" -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "示例:" -ForegroundColor $Yellow
    Write-Host "  .\client-installer.ps1 -Install" -ForegroundColor $Cyan
    Write-Host "  .\client-installer.ps1 -ConfigFile 'C:\config\client.conf' -Start" -ForegroundColor $Cyan
}

# 显示欢迎信息
function Show-Welcome {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor $White
    Write-Host "║                IPv6 WireGuard 客户端安装器                  ║" -ForegroundColor $White
    Write-Host "║                    版本: $ScriptVersion                        ║" -ForegroundColor $White
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor $White
    Write-Host ""
    Write-Host "此脚本将帮助您安装和配置 WireGuard 客户端" -ForegroundColor $Cyan
    Write-Host "支持平台: Windows 10/11" -ForegroundColor $Cyan
    Write-Host ""
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查 WireGuard 是否已安装
function Test-WireGuardInstalled {
    try {
        $wireguardPath = Get-Command "wireguard.exe" -ErrorAction SilentlyContinue
        if ($wireguardPath) {
            Write-Log "INFO" "WireGuard 已安装: $($wireguardPath.Source)"
            return $true
        }
    }
    catch {
        Write-Log "INFO" "WireGuard 未安装"
        return $false
    }
    return $false
}

# 安装 WireGuard
function Install-WireGuard {
    Write-Log "INFO" "正在安装 WireGuard..."
    
    # 检查是否已安装
    if (Test-WireGuardInstalled) {
        Write-Log "INFO" "WireGuard 已安装，跳过安装步骤"
        return $true
    }
    
    # 下载 WireGuard 安装程序
    $downloadUrl = "https://download.wireguard.com/windows-client/wireguard-installer.exe"
    $installerPath = "$TempDir\wireguard-installer.exe"
    
    try {
        Write-Log "INFO" "正在下载 WireGuard 安装程序..."
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Log "INFO" "正在运行 WireGuard 安装程序..."
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        Write-Log "INFO" "WireGuard 安装完成"
        return $true
    }
    catch {
        Write-Log "ERROR" "WireGuard 安装失败: $($_.Exception.Message)"
        Write-Log "INFO" "请手动下载并安装 WireGuard: https://www.wireguard.com/install/"
        return $false
    }
}

# 创建客户端配置目录
function New-ClientDirectories {
    Write-Log "INFO" "创建客户端配置目录..."
    
    New-Item -ItemType Directory -Path $ClientConfigDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ClientLogDir -Force | Out-Null
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    Write-Log "INFO" "配置目录: $ClientConfigDir"
    Write-Log "INFO" "日志目录: $ClientLogDir"
}

# 交互式配置客户端
function New-InteractiveClientConfig {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host "                        客户端配置                          " -ForegroundColor $Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host ""
    
    # 获取服务器信息
    Write-Host "请输入服务器信息:" -ForegroundColor $Yellow
    $serverEndpoint = Read-Host "服务器地址 (IP 或域名)"
    $serverPort = Read-Host "服务器端口 [51820]"
    if ([string]::IsNullOrEmpty($serverPort)) { $serverPort = "51820" }
    
    # 获取客户端信息
    Write-Host ""
    Write-Host "请输入客户端信息:" -ForegroundColor $Yellow
    $clientName = Read-Host "客户端名称"
    $clientIPv4 = Read-Host "IPv4 地址 [10.0.0.2/32]"
    if ([string]::IsNullOrEmpty($clientIPv4)) { $clientIPv4 = "10.0.0.2/32" }
    $clientIPv6 = Read-Host "IPv6 地址 [2001:db8::2/64]"
    if ([string]::IsNullOrEmpty($clientIPv6)) { $clientIPv6 = "2001:db8::2/64" }
    
    # 获取密钥信息
    Write-Host ""
    Write-Host "请输入密钥信息:" -ForegroundColor $Yellow
    $clientPrivateKey = Read-Host "客户端私钥"
    $serverPublicKey = Read-Host "服务器公钥"
    
    # 生成客户端配置
    New-ClientConfig $clientName $serverEndpoint $serverPort $clientIPv4 $clientIPv6 $clientPrivateKey $serverPublicKey
}

# 生成客户端配置
function New-ClientConfig {
    param(
        [string]$ClientName,
        [string]$ServerEndpoint,
        [string]$ServerPort,
        [string]$ClientIPv4,
        [string]$ClientIPv6,
        [string]$ClientPrivateKey,
        [string]$ServerPublicKey
    )
    
    Write-Log "INFO" "生成客户端配置: $ClientName"
    
    $configContent = @"
[Interface]
PrivateKey = $ClientPrivateKey
Address = $ClientIPv4, $ClientIPv6
DNS = 8.8.8.8, 2001:4860:4860::8888

[Peer]
PublicKey = $ServerPublicKey
Endpoint = $ServerEndpoint`:$ServerPort
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
"@
    
    $configPath = "$ClientConfigDir\$ClientName.conf"
    $configContent | Out-File -FilePath $configPath -Encoding UTF8
    
    Write-Log "INFO" "客户端配置已生成: $configPath"
}

# 从文件导入配置
function Import-ConfigFromFile {
    param([string]$ConfigFilePath)
    
    if (-not (Test-Path $ConfigFilePath)) {
        Write-Log "ERROR" "配置文件不存在: $ConfigFilePath"
        return $false
    }
    
    $clientName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigFilePath)
    $configPath = "$ClientConfigDir\$clientName.conf"
    
    Copy-Item -Path $ConfigFilePath -Destination $configPath -Force
    
    Write-Log "INFO" "配置文件已导入: $configPath"
    return $true
}

# 启动 WireGuard 客户端
function Start-WireGuardClient {
    param([string]$ClientName)
    
    Write-Log "INFO" "启动 WireGuard 客户端: $ClientName"
    
    $configPath = "$ClientConfigDir\$ClientName.conf"
    
    if (-not (Test-Path $configPath)) {
        Write-Log "ERROR" "配置文件不存在: $configPath"
        return $false
    }
    
    try {
        # 使用 WireGuard 命令行工具启动
        $wireguardPath = Get-Command "wireguard.exe" -ErrorAction SilentlyContinue
        if ($wireguardPath) {
            Start-Process -FilePath $wireguardPath.Source -ArgumentList "/installtunnelservice", $configPath -Wait
            Write-Log "INFO" "WireGuard 客户端已启动"
            return $true
        }
        else {
            Write-Log "WARN" "WireGuard 命令行工具不可用，请使用图形界面启动"
            Write-Log "INFO" "配置文件位置: $configPath"
            return $false
        }
    }
    catch {
        Write-Log "ERROR" "启动 WireGuard 客户端失败: $($_.Exception.Message)"
        return $false
    }
}

# 显示客户端状态
function Show-ClientStatus {
    param([string]$ClientName)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host "                        客户端状态                          " -ForegroundColor $Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host ""
    
    $configPath = "$ClientConfigDir\$ClientName.conf"
    
    if (Test-Path $configPath) {
        Write-Host "配置文件: $configPath" -ForegroundColor $Yellow
        Write-Host "配置内容:" -ForegroundColor $Yellow
        Get-Content $configPath
    }
    else {
        Write-Host "配置文件不存在: $configPath" -ForegroundColor $Red
    }
}

# 主函数
function Main {
    # 设置清理函数
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup-TempFiles }
    
    # 显示帮助信息
    if ($Help) {
        Show-Help
        return
    }
    
    # 显示欢迎信息
    Show-Welcome
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-Log "WARN" "建议以管理员权限运行此脚本"
    }
    
    # 创建客户端目录
    New-ClientDirectories
    
    # 安装 WireGuard
    if ($Install) {
        if (-not (Install-WireGuard)) {
            Write-Error-Exit "WireGuard 安装失败"
        }
    }
    else {
        if (-not (Test-WireGuardInstalled)) {
            Write-Log "WARN" "WireGuard 未安装"
            $installChoice = Read-Host "是否现在安装 WireGuard? (y/N)"
            if ($installChoice -eq "y" -or $installChoice -eq "Y") {
                if (-not (Install-WireGuard)) {
                    Write-Error-Exit "WireGuard 安装失败"
                }
            }
            else {
                Write-Log "INFO" "请手动安装 WireGuard 后重新运行此脚本"
                return
            }
        }
    }
    
    # 配置客户端
    if (-not [string]::IsNullOrEmpty($ConfigFile)) {
        if (-not (Import-ConfigFromFile $ConfigFile)) {
            Write-Error-Exit "配置文件导入失败"
        }
    }
    else {
        New-InteractiveClientConfig
    }
    
    # 启动客户端
    if ($Start) {
        Start-WireGuardClient $ClientName
    }
    else {
        $startChoice = Read-Host "是否立即启动 WireGuard 客户端? (y/N)"
        if ($startChoice -eq "y" -or $startChoice -eq "Y") {
            Start-WireGuardClient $ClientName
        }
    }
    
    # 显示状态
    Show-ClientStatus $ClientName
    
    Write-Host ""
    Write-Log "INFO" "客户端安装完成!"
    Write-Host "配置文件位置: $ClientConfigDir\$ClientName.conf" -ForegroundColor $Green
    Write-Host "日志文件位置: $ClientLogDir" -ForegroundColor $Green
    Write-Host ""
    Write-Host "常用操作:" -ForegroundColor $Yellow
    Write-Host "  启动: 使用 WireGuard 图形界面导入配置文件" -ForegroundColor $Blue
    Write-Host "  停止: 在 WireGuard 图形界面中禁用隧道" -ForegroundColor $Blue
    Write-Host "  状态: 在 WireGuard 图形界面中查看连接状态" -ForegroundColor $Blue
}

# 脚本入口点
if ($MyInvocation.InvocationName -ne '.') {
    Main
}

