<#
.SYNOPSIS
Performs continuous ping with timestamps and user prompt for target

.DESCRIPTION
Basic continuous ping with timestamp logging without diagnostic checks
#>

param(
    [string]$Target,
    [int]$Interval = 1,
    [int]$Timeout = 1,
    [string]$LogPath
)

# Prompt for target if not provided
if (-not $Target) {
    $Target = Read-Host -Prompt "Enter target hostname or IP address (press Enter for 8.8.8.8)"
    if ([string]::IsNullOrEmpty($Target)) { $Target = "8.8.8.8" }
}

# Initialize counters
$successCount = 0
$failCount = 0
$startTime = Get-Date

# Header
Write-Host "`nContinuous Ping Monitor" -ForegroundColor Cyan
Write-Host "Target: $Target"
Write-Host "Start Time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "Press Ctrl+C to stop...`n"

try {
    while ($true) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        
        try {
            $ping = Test-Connection -ComputerName $Target -Count 1 -TimeoutSeconds $Timeout -ErrorAction Stop
            $successCount++
            $message = "$timestamp [Success] $Target - Response: ${ping}ms"
            Write-Host $message -ForegroundColor Green
        }
        catch {
            $failCount++
            $message = "$timestamp [Failure] $Target - No response"
            Write-Host $message -ForegroundColor Red
        }

        if ($LogPath) { Add-Content -Path $LogPath -Value $message }

        # Show statistics every 10 attempts
        if (($successCount + $failCount) % 10 -eq 0) {
            $total = $successCount + $failCount
            $rate = if ($total -gt 0) { ($successCount / $total).ToString("P1") } else { "0%" }
            Write-Host ("`nAttempts: {0} | Success: {1} | Failures: {2} | Rate: {3}`n" -f 
                        $total, $successCount, $failCount, $rate) -ForegroundColor Yellow
        }

        Start-Sleep -Seconds $Interval
    }
}
finally {
    # Final report
    $total = $successCount + $failCount
    $rate = if ($total -gt 0) { ($successCount / $total).ToString("P1") } else { "0%" }
    $duration = (Get-Date) - $startTime
    
    Write-Host "`n=== Monitoring Summary ===" -ForegroundColor Cyan
    Write-Host "Target: $Target"
    Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"
    Write-Host "Total Attempts: $total"
    Write-Host "Success Rate: $rate"
    if ($LogPath) { Write-Host "Log saved to: $LogPath" }
}
