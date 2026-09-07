$root = Split-Path -Parent $PSScriptRoot
$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$port/"

$mimeTypes = @{
    ".html" = "text/html"; ".htm" = "text/html"; ".css" = "text/css"; ".js" = "application/javascript"
    ".json" = "application/json"; ".png" = "image/png"; ".jpg" = "image/jpeg"; ".jpeg" = "image/jpeg"
    ".gif" = "image/gif"; ".svg" = "image/svg+xml"; ".ico" = "image/x-icon"; ".woff" = "font/woff"
    ".woff2" = "font/woff2"; ".txt" = "text/plain"; ".md" = "text/plain"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    try {
        $urlPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
        if ($urlPath -eq "/") { $urlPath = "/code.html" }
        $filePath = Join-Path $root ($urlPath.TrimStart("/"))
        $filePath = [System.IO.Path]::GetFullPath($filePath)
        if (-not $filePath.StartsWith([System.IO.Path]::GetFullPath($root))) {
            $response.StatusCode = 403
        } elseif (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = $mimeTypes[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
    } catch {
        $response.StatusCode = 500
    } finally {
        $response.OutputStream.Close()
    }
}
