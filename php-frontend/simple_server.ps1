# Simple PowerShell HTTP Server
$port = 8080
$url = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

try {
    $listener.Start()
    Write-Host "Server started at $url"
    Write-Host "Test page: ${url}test_api_path_builder.html"
    
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        if ($path -eq "/") {
            $path = "/test_api_path_builder.html"
        }
        
        $filePath = Join-Path (Get-Location) $path.Substring(1)
        
        if (Test-Path $filePath) {
            $content = Get-Content $filePath -Raw -Encoding UTF8
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            
            $response.ContentLength64 = $buffer.Length
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } else {
            $response.StatusCode = 404
            $content = "<h1>404 Not Found</h1>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "Error: $_"
} finally {
    $listener.Stop()
}