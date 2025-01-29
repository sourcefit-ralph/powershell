<#
.SYNOPSIS
Checks Cloudflare Warp connection status with single exit point and improved key handling
#>

# ANSI color codes
$ConnectedColor = "Green"
$DisconnectedColor = "Red"
$ErrorColor = "Yellow"
$StatusSymbol = @{
    Connected = "✅"
    Disconnected = "❌"
}

$exitMessage = $null
$exitCode = 0

function Show-Exit {
    param($Message, $Color, $Code)
    
    Write-Host $Message -ForegroundColor $Color
    if ([Environment]::UserInteractive) {
        Write-Host "`nPress any key to exit..." -ForegroundColor Gray
        try {
            [System.Console]::ReadKey($true) | Out-Null
        }
        catch {
            # Fallback if ReadKey isn't supported
            Start-Sleep -Seconds 5
        }
    }
    exit $Code
}

try {
    # Technique 1: Check warp-cli status
    try {
        $cliOutput = & warp-cli status 2>&1 | Out-String
        
        if ($cliOutput -match "Status update: Connected") {
            $exitMessage = "$($StatusSymbol.Connected) Cloudflare Warp is Connected (via warp-cli)"
            $exitCode = 0
        }
        elseif ($cliOutput -match "Status update: Disconnected") {
            $exitMessage = "$($StatusSymbol.Disconnected) Cloudflare Warp is Disconnected (via warp-cli)"
            $exitCode = 1
        }
    }
    catch {
        # Fall through to Technique 2 if warp-cli check fails
    }

    if (-not $exitMessage) {
        # Technique 2: Check connectivity trace
        try {
            $traceResponse = Invoke-RestMethod -Uri "https://connectivity.cloudflareclient.com/cdn-cgi/trace" -ErrorAction Stop
            $warpStatus = ($traceResponse -split "`n" | Where-Object { $_ -match '^warp=' }) -split '=' | Select-Object -Last 1
            
            if ($warpStatus -eq 'on') {
                $exitMessage = "$($StatusSymbol.Connected) Cloudflare Warp is Connected (via connectivity trace)"
                $exitCode = 0
            }
            else {
                $exitMessage = "$($StatusSymbol.Disconnected) Cloudflare Warp is Disconnected (via connectivity trace)"
                $exitCode = 1
            }
        }
        catch {
            $exitMessage = "$($StatusSymbol.Disconnected) Error checking connectivity trace: $($_.Exception.Message)"
            $exitCode = 2
        }
    }
}
finally {
    if (-not $exitMessage) {
        $exitMessage = "$($StatusSymbol.Disconnected) Unknown connection state"
        $exitCode = 2
    }
    
    switch ($exitCode) {
        0 { Show-Exit -Message $exitMessage -Color $ConnectedColor -Code $exitCode }
        1 { Show-Exit -Message $exitMessage -Color $DisconnectedColor -Code $exitCode }
        default { Show-Exit -Message $exitMessage -Color $ErrorColor -Code $exitCode }
    }
}
