# IPv6 WireGuard Manager - IPv6访问修复脚本 (Windows版本)
# 此脚本用于在Windows上诊断IPv6问题，并提供Linux服务器修复指导

Write-Host "🔧 IPv6 WireGuard Manager - IPv6访问修复诊断" -ForegroundColor Green
Write-Host ""

# 检查当前环境
Write-Host "📊 环境检查..." -ForegroundColor Yellow
Write-Host "操作系统: $([System.Environment]::OSVersion.VersionString)"
Write-Host "PowerShell版本: $($PSVersionTable.PSVersion)"
Write-Host ""

# 检查网络配置
Write-Host "🌐 网络配置检查..." -ForegroundColor Yellow

# 检查IPv6支持
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

# 生成Linux服务器修复命令
Write-Host "🐧 Linux服务器修复指导" -ForegroundColor Yellow
Write-Host "请在您的Linux服务器上运行以下命令来修复IPv6访问问题:"
Write-Host ""

Write-Host "# 1. 下载并运行IPv6修复脚本" -ForegroundColor Cyan
Write-Host "curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-ipv6-access.sh | bash" -ForegroundColor White
Write-Host ""

Write-Host "# 2. 或者手动执行以下步骤:" -ForegroundColor Cyan
Write-Host ""

Write-Host "# 检查IPv6地址" -ForegroundColor Green
Write-Host "ip -6 addr show | grep inet6" -ForegroundColor White
Write-Host ""

Write-Host "# 检查Nginx IPv6配置" -ForegroundColor Green
Write-Host "grep -E 'listen.*\[::\]' /etc/nginx/sites-available/ipv6-wireguard-manager" -ForegroundColor White
Write-Host ""

Write-Host "# 修复Nginx配置" -ForegroundColor Green
Write-Host "sudo nano /etc/nginx/sites-available/ipv6-wireguard-manager" -ForegroundColor White
Write-Host ""

Write-Host "# 确保包含以下配置:" -ForegroundColor Green
Write-Host "server {" -ForegroundColor White
Write-Host "    listen 80;" -ForegroundColor White
Write-Host "    listen [::]:80;" -ForegroundColor White
Write-Host "    # ... 其他配置" -ForegroundColor White
Write-Host "}" -ForegroundColor White
Write-Host ""

Write-Host "# 重启Nginx" -ForegroundColor Green
Write-Host "sudo systemctl restart nginx" -ForegroundColor White
Write-Host ""

Write-Host "# 检查防火墙" -ForegroundColor Green
Write-Host "sudo ufw status" -ForegroundColor White
Write-Host "sudo ufw allow 80/tcp" -ForegroundColor White
Write-Host ""

Write-Host "# 测试IPv6访问" -ForegroundColor Green
Write-Host "curl -6 -I http://[YOUR_IPV6_ADDRESS]" -ForegroundColor White
Write-Host ""

# 提供具体的修复建议
Write-Host "🔧 常见IPv6问题修复建议:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. IPv6地址检测问题:" -ForegroundColor Green
Write-Host "   - 确保服务器分配了IPv6地址" -ForegroundColor White
Write-Host "   - 检查网络提供商是否支持IPv6" -ForegroundColor White
Write-Host "   - 验证IPv6路由配置" -ForegroundColor White
Write-Host ""

Write-Host "2. Nginx配置问题:" -ForegroundColor Green
Write-Host "   - 确保listen [::]:80配置存在" -ForegroundColor White
Write-Host "   - 检查Nginx错误日志: sudo tail -f /var/log/nginx/error.log" -ForegroundColor White
Write-Host "   - 验证配置文件语法: sudo nginx -t" -ForegroundColor White
Write-Host ""

Write-Host "3. 防火墙问题:" -ForegroundColor Green
Write-Host "   - 确保IPv6流量被允许" -ForegroundColor White
Write-Host "   - 检查iptables IPv6规则" -ForegroundColor White
Write-Host "   - 验证云服务商安全组设置" -ForegroundColor White
Write-Host ""

Write-Host "4. 系统IPv6支持:" -ForegroundColor Green
Write-Host "   - 检查IPv6转发: cat /proc/sys/net/ipv6/conf/all/forwarding" -ForegroundColor White
Write-Host "   - 启用IPv6转发: echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf" -ForegroundColor White
Write-Host "   - 应用配置: sudo sysctl -p" -ForegroundColor White
Write-Host ""

Write-Host "5. DNS解析问题:" -ForegroundColor Green
Write-Host "   - 检查IPv6 DNS配置" -ForegroundColor White
Write-Host "   - 测试IPv6 DNS解析: nslookup -type=AAAA your-domain.com" -ForegroundColor White
Write-Host ""

# 生成诊断报告
Write-Host "📋 诊断报告生成..." -ForegroundColor Yellow
$reportFile = "ipv6-diagnosis-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

$report = @"
IPv6 WireGuard Manager - 诊断报告
生成时间: $(Get-Date)
操作系统: $([System.Environment]::OSVersion.VersionString)
PowerShell版本: $($PSVersionTable.PSVersion)

网络接口信息:
$((Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Get-NetIPAddress -AddressFamily IPv6 -ErrorAction SilentlyContinue | Out-String))

IPv6连接测试:
$((Test-NetConnection -ComputerName "ipv6.google.com" -Port 80 -InformationLevel Detailed | Out-String))

修复建议:
1. 在Linux服务器上运行: curl -fsSL https://raw.githubusercontent.com/ipzh/ipv6-wireguard-manager/main/fix-ipv6-access.sh | bash
2. 检查服务器IPv6地址分配
3. 验证Nginx IPv6配置
4. 检查防火墙IPv6规则
5. 确认系统IPv6支持

如需更多帮助，请查看项目文档或提交Issue。
"@

$report | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "✅ 诊断报告已保存到: $reportFile" -ForegroundColor Green

Write-Host ""
Write-Host "🎯 下一步操作:" -ForegroundColor Yellow
Write-Host "1. 在您的Linux服务器上运行IPv6修复脚本" -ForegroundColor White
Write-Host "2. 检查服务器IPv6地址分配情况" -ForegroundColor White
Write-Host "3. 验证Nginx和防火墙配置" -ForegroundColor White
Write-Host "4. 测试IPv6访问功能" -ForegroundColor White
Write-Host ""
Write-Host "✅ IPv6访问问题诊断完成！" -ForegroundColor Green
