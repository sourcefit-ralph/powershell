<#
.SYNOPSIS
Checks Cloudflare Warp connection status with colored output and symbols.
#>

# ANSI color codes
$ConnectedColor = "Green"
$DisconnectedColor = "Red"
$ErrorColor = "Yellow"
$StatusSymbol = @{
    Connected = "✅"
    Disconnected = "❌"
}

# Technique 1: Check warp-cli status
try {
    $cliOutput = & warp-cli status 2>&1 | Out-String
    
    if ($cliOutput -match "Status update: Connected") {
        Write-Host "$($StatusSymbol.Connected) Cloudflare Warp is Connected " -ForegroundColor $ConnectedColor -NoNewline
        Write-Host "(via warp-cli)" -ForegroundColor Gray
        exit 0
    }
    elseif ($cliOutput -match "Status update: Disconnected") {
        Write-Host "$($StatusSymbol.Disconnected) Cloudflare Warp is Disconnected " -ForegroundColor $DisconnectedColor -NoNewline
        Write-Host "(via warp-cli)" -ForegroundColor Gray
        exit 1
    }
}
catch {
    # Fall through to Technique 2 if warp-cli check fails
}

# Technique 2: Check connectivity trace
try {
    $traceResponse = Invoke-RestMethod -Uri "https://connectivity.cloudflareclient.com/cdn-cgi/trace" -ErrorAction Stop
    $warpStatus = ($traceResponse -split "`n" | Where-Object { $_ -match '^warp=' }) -split '=' | Select-Object -Last 1
    
    if ($warpStatus -eq 'on') {
        Write-Host "$($StatusSymbol.Connected) Cloudflare Warp is Connected " -ForegroundColor $ConnectedColor -NoNewline
        Write-Host "(via connectivity trace)" -ForegroundColor Gray
        exit 0
    }
    else {
        Write-Host "$($StatusSymbol.Disconnected) Cloudflare Warp is Disconnected " -ForegroundColor $DisconnectedColor -NoNewline
        Write-Host "(via connectivity trace)" -ForegroundColor Gray
        exit 1
    }
}
catch {
    Write-Host "$($StatusSymbol.Disconnected) Error checking connectivity trace: " -ForegroundColor $ErrorColor -NoNewline
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 2
}
