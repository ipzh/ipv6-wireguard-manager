$content = Get-Content "install.sh" -Raw
$content = $content -replace "`r`n", "`n"
Set-Content "install.sh" -Value $content -NoNewline
