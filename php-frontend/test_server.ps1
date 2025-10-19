# PowerShell HTTP服务器脚本
$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "测试服务器运行在 http://localhost:$port"
    Write-Host "API路径构建器测试页面: http://localhost:$port/test_api_path_builder.html"
    Write-Host "按 Ctrl+C 停止服务器"

    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # 获取请求路径
        $path = $request.Url.LocalPath
        
        # 处理根路径
        if ($path -eq "/") {
            $path = "/test_api_path_builder.html"
        }
        
        # 构建文件路径
        $filePath = Join-Path (Get-Location) $path.Substring(1)
        
        # 检查文件是否存在
        if (Test-Path $filePath -PathType Leaf) {
            # 获取文件扩展名和MIME类型
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = "application/octet-stream"
            
            switch ($extension) {
                ".html" { $contentType = "text/html" }
                ".js" { $contentType = "text/javascript" }
                ".css" { $contentType = "text/css" }
                ".json" { $contentType = "application/json" }
                ".png" { $contentType = "image/png" }
                ".jpg" { $contentType = "image/jpeg" }
                ".gif" { $contentType = "image/gif" }
                ".svg" { $contentType = "image/svg+xml" }
            }
            
            # 读取文件内容
            $fileContent = [System.IO.File]::ReadAllBytes($filePath)
            
            # 设置响应头
            $response.ContentType = $contentType
            $response.ContentLength64 = $fileContent.Length
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Authorization")
            
            # 发送响应
            $response.OutputStream.Write($fileContent, 0, $fileContent.Length)
        } else {
            # 文件不存在
            $response.StatusCode = 404
            $response.ContentType = "text/html"
            $errorMessage = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1>")
            $response.ContentLength64 = $errorMessage.Length
            $response.OutputStream.Write($errorMessage, 0, $errorMessage.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    $listener.Stop()
}