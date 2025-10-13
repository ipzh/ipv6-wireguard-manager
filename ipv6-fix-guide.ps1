# IPv6 WireGuard Manager - IPv6访问修复指导
Write-Host "🔧 IPv6 WireGuard Manager - IPv6访问修复指导" -ForegroundColor Green
Write-Host ""

Write-Host "📊 当前环境检查..." -ForegroundColor Yellow
Write-Host "操作系统: $([System.Environment]::OSVersion.VersionString)"
Write-Host "PowerShell版本: $($PSVersionTable.PSVersion)"
Write-Host ""

# 检查IPv6支持
Write-Host "🌐 IPv6支持检查..." -ForegroundColor Yellow
try {
    $ipv6Interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue
    if ($ipv6Interfaces) {
        Write-Host "✅ 检测到IPv6接口:" -ForegroundColor Green
        $ipv6Interfaces | ForEach-Object {
            Write-Host "  接口: $($_.InterfaceAlias) - IPv6: $($_.IPAddress)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ 未检测到IPv6接口" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ IPv6检查失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 检查IPv6连接
Write-Host "🔗 IPv6连接测试..." -ForegroundColor Yellow
try {
    $ipv6Test = Test-NetConnection -ComputerName "ipv6.google.com" -Port 80 -InformationLevel Quiet
    if ($ipv6Test) {
        Write-Host "✅ IPv6连接正常" -ForegroundColor Green
    } else {
        Write-Host "❌ IPv6连接失败" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ IPv6连接测试失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🐧 Linux服务器修复指导" -ForegroundColor Yellow
Write-Host "请在您的Linux服务器上运行以下命令:"
Write-Host ""

Write-Host "1. 下载并运行IPv6修复脚本:" -ForegroundColor Cyan
Write-Host "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-ipv6-access.sh | bash" -ForegroundColor White
Write-Host ""

Write-Host "2. 手动检查IPv6地址:" -ForegroundColor Cyan
Write-Host "ip -6 addr show | grep inet6" -ForegroundColor White
Write-Host ""

Write-Host "3. 检查Nginx配置:" -ForegroundColor Cyan
Write-Host "grep -E 'listen.*\[::\]' /etc/nginx/sites-available/ipv6-wireguard-manager" -ForegroundColor White
Write-Host ""

Write-Host "4. 重启Nginx:" -ForegroundColor Cyan
Write-Host "sudo systemctl restart nginx" -ForegroundColor White
Write-Host ""

Write-Host "5. 检查防火墙:" -ForegroundColor Cyan
Write-Host "sudo ufw allow 80/tcp" -ForegroundColor White
Write-Host ""

Write-Host "🔧 常见问题解决方案:" -ForegroundColor Yellow
Write-Host ""

Write-Host "问题1: IPv6地址未分配" -ForegroundColor Green
Write-Host "解决: 联系云服务商启用IPv6支持" -ForegroundColor White
Write-Host ""

Write-Host "问题2: Nginx未监听IPv6" -ForegroundColor Green
Write-Host "解决: 在配置文件中添加 'listen [::]:80;'" -ForegroundColor White
Write-Host ""

Write-Host "问题3: 防火墙阻止IPv6" -ForegroundColor Green
Write-Host "解决: 配置防火墙允许IPv6流量" -ForegroundColor White
Write-Host ""

Write-Host "问题4: 系统IPv6支持问题" -ForegroundColor Green
Write-Host "解决: 启用IPv6转发和内核支持" -ForegroundColor White
Write-Host ""

Write-Host "📋 快速修复命令:" -ForegroundColor Yellow
Write-Host "在Linux服务器上依次执行:" -ForegroundColor White
Write-Host ""
Write-Host "# 1. 检查IPv6地址" -ForegroundColor Cyan
Write-Host "ip -6 addr show" -ForegroundColor White
Write-Host ""
Write-Host "# 2. 修复Nginx配置" -ForegroundColor Cyan
Write-Host "sudo sed -i 's/listen 80;/listen 80;\n    listen [::]:80;/' /etc/nginx/sites-available/ipv6-wireguard-manager" -ForegroundColor White
Write-Host ""
Write-Host "# 3. 重启服务" -ForegroundColor Cyan
Write-Host "sudo systemctl restart nginx" -ForegroundColor White
Write-Host ""
Write-Host "# 4. 测试IPv6访问" -ForegroundColor Cyan
Write-Host "curl -6 -I http://[YOUR_IPV6_ADDRESS]" -ForegroundColor White
Write-Host ""

Write-Host "✅ 修复指导完成！" -ForegroundColor Green
Write-Host "请按照上述步骤在Linux服务器上修复IPv6访问问题" -ForegroundColor White
