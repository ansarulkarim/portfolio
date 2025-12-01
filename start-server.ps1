# Simple HTTP Server using PowerShell
$port = 8000
$url = "http://localhost:$port/"

Write-Host "Starting local server at $url" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Create HTTP listener
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add($url)
$http.Start()

# Open browser
Start-Process $url

Write-Host "Server is running. Listening on port $port..." -ForegroundColor Cyan

# Keep server running
while ($http.IsListening) {
    $context = $http.GetContext()
    $request = $context.Request
    $response = $context.Response
    
    # Get requested file path
    $path = $request.Url.LocalPath
    if ($path -eq "/") { $path = "/index.html" }
    
    $filePath = Join-Path $PSScriptRoot $path.TrimStart('/')
    
    Write-Host "Request: $path" -ForegroundColor Gray
    
    if (Test-Path $filePath -PathType Leaf) {
        # Determine content type
        $contentType = "text/html"
        switch ([System.IO.Path]::GetExtension($filePath)) {
            ".css" { $contentType = "text/css" }
            ".js" { $contentType = "application/javascript" }
            ".jpg" { $contentType = "image/jpeg" }
            ".jpeg" { $contentType = "image/jpeg" }
            ".png" { $contentType = "image/png" }
            ".gif" { $contentType = "image/gif" }
            ".svg" { $contentType = "image/svg+xml" }
            ".ico" { $contentType = "image/x-icon" }
        }
        
        # Read and serve file
        $content = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $content.Length
        $response.OutputStream.Write($content, 0, $content.Length)
    } else {
        # 404 Not Found
        $response.StatusCode = 404
        $html = "<h1>404 - File Not Found</h1><p>$path</p>"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    
    $response.Close()
}

$http.Stop()
