<#
.SYNOPSIS
Continuous ping monitor with latency tracking and stability indicators
#>

param(
    [string]$Target,
    [int]$Interval = 1,
    [int]$Timeout = 1,
    [string]$LogPath
)

# Prompt for target if not provided
if (-not $Target) {
    $Target = Read-Host -Prompt "Enter target hostname/IP (default: 8.8.8.8)"
    if ([string]::IsNullOrEmpty($Target)) { $Target = "8.8.8.8" }
}

# Initialize tracking
$startTime = Get-Date
$successCount = 0
$failCount = 0
$latencyHistory = @()
$stabilityWindow = 10  # Number of pings to consider for stability

# Header
Write-Host "`nPing Monitor - $Target" -ForegroundColor Cyan
Write-Host "Start Time: $($startTime.ToString('HH:mm:ss'))"
Write-Host "Ctrl+C to stop`n"

try {
    while ($true) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        
        try {
            $ping = Test-Connection -ComputerName $Target -Count 1 -TimeoutSeconds $Timeout -ErrorAction Stop
            $successCount++
            $latency = $ping.ResponseTime
            $latencyHistory += $latency
            
            # Keep only last 10 pings for stability calculation
            if ($latencyHistory.Count -gt $stabilityWindow) {
                $latencyHistory = $latencyHistory[-$stabilityWindow..-1]
            }
            
            # Stability calculation
            $averageLatency = [math]::Round(($latencyHistory | Measure-Object -Average).Average)
            $stabilityStatus = if ($averageLatency -lt 150 -and $latencyHistory.Count -eq $stabilityWindow) {
                "Stable" 
            } else { 
                "Calculating..." 
            }
            
            $message = "$timestamp [$($latency.ToString().PadLeft(4))ms] $Target - Status: $stabilityStatus"
            Write-Host $message -ForegroundColor Green
        }
        catch {
            $failCount++
            $message = "$timestamp [----ms] $Target - Status: Unstable"
            Write-Host $message -ForegroundColor Red
        }

        # Logging
        if ($LogPath) { 
            Add-Content -Path $LogPath -Value $message.Replace("ms] $Target - Status: ", "] ") 
        }

        # Detailed stats every 10 pings
        if (($successCount + $failCount) % 10 -eq 0) {
            $total = $successCount + $failCount
            $successRate = [math]::Round(($successCount / $total) * 100)
            $currentLatency = if ($latencyHistory.Count -gt 0) { 
                "Avg: {0}ms | Min: {1}ms | Max: {2}ms" -f (
                    [math]::Round(($latencyHistory | Measure-Object -Average).Average),
                    ($latencyHistory | Measure-Object -Minimum).Minimum,
                    ($latencyHistory | Measure-Object -Maximum).Maximum
                )
            } else { "N/A" }
            
            Write-Host ("`nLast 10 pings: " + $currentLatency) -ForegroundColor Yellow
            Write-Host ("Success Rate: {0}% | Total Attempts: {1}`n" -f $successRate, $total) -ForegroundColor Yellow
        }

        Start-Sleep -Seconds $Interval
    }
}
finally {
    # Final report
    $total = $successCount + $failCount
    $duration = (Get-Date) - $startTime
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"
    Write-Host "Total Pings: $total"
    Write-Host "Successful: $successCount"
    Write-Host "Failed: $failCount"
    if ($latencyHistory.Count -gt 0) {
        Write-Host "Average Latency: $([math]::Round(($latencyHistory | Measure-Object -Average).Average))ms"
    }
    if ($LogPath) { Write-Host "Log saved to: $LogPath" }
}
