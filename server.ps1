$port = 8080
$folder = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "Servidor web activo en $prefix"
    Write-Host "Directorio: $folder"
} catch {
    $port = 8000
    $prefix = "http://localhost:$port/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Write-Host "Servidor web activo en $prefix"
    Write-Host "Directorio: $folder"
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webp" = "image/webp"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($rawPath)) {
            $rawPath = "index.html"
        }

        $relativePath = [System.Uri]::UnescapeDataString($rawPath)
        $filePath = Join-Path $folder $relativePath

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            if ($mimeTypes.ContainsKey($ext)) {
                $response.ContentType = $mimeTypes[$ext]
            } else {
                $response.ContentType = "application/octet-stream"
            }

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFoundBytes = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1>")
            $response.ContentType = "text/html; charset=utf-8"
            $response.ContentLength64 = $notFoundBytes.Length
            $response.OutputStream.Write($notFoundBytes, 0, $notFoundBytes.Length)
        }
        $response.OutputStream.Close()
    } catch {
    }
}
