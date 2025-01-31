# Continuous Ping Test Script with Timestamp, Color Coding, Latency, Packet Loss, and Summaries

# Prompt user for target destination
$target = Read-Host "Enter the target destination (IP or hostname) [default: google.com]"
if ([string]::IsNullOrWhiteSpace($target)) {
    $target = "google.com"
}

Write-Host "Starting continuous ping test to $target..." -ForegroundColor Cyan

# Initialize counters
$totalPings = 0
$successCount = 0
$failureCount = 0
$summaryInterval = 10
$totalLatency = 0
$latencyList = @()

try {
    while ($true) {
        # Perform ping using native ping command
        $pingOutput = ping $target -n 1 | Select-String "Reply from" -Context 0, 0
        
        # Get timestamp
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if ($pingOutput) {
            # Extract latency from the ping output
            if ($pingOutput -match 'time=(\d+)ms') {
                $latency = [int]$matches[1]
                Write-Host "[$timestamp] Ping to $target succeeded. Latency: ${latency}ms" -ForegroundColor Green
                $successCount++
                $totalLatency += $latency
                $latencyList += $latency
            } else {
                Write-Host "[$timestamp] Ping to $target succeeded, but could not parse latency." -ForegroundColor Yellow
                $successCount++
            }
        } else {
            Write-Host "[$timestamp] Ping to $target failed." -ForegroundColor Red
            $failureCount++
        }

        # Increment total pings
        $totalPings++

        # Calculate packet loss percentage
        $packetLossPercentage = if ($totalPings -gt 0) { [math]::Round(($failureCount / $totalPings) * 100, 2) } else { 0 }

        # Summarize every 10 responses
        if ($totalPings % $summaryInterval -eq 0) {
            $averageLatency = if ($successCount -gt 0) { [math]::Round($totalLatency / $successCount, 2) } else { 0 }
            Write-Host "`n--- Summary after $totalPings pings ---" -ForegroundColor Yellow
            Write-Host "Successful pings: $successCount" -ForegroundColor Green
            Write-Host "Failed pings: $failureCount" -ForegroundColor Red
            Write-Host "Packet loss: ${packetLossPercentage}%" -ForegroundColor Magenta
            Write-Host "Average latency: ${averageLatency}ms" -ForegroundColor Cyan
            Write-Host "--------------------------------------`n" -ForegroundColor Yellow
        }

        # Wait for a second before the next ping
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
} finally {
    # Final summary
    $finalAverageLatency = if ($successCount -gt 0) { [math]::Round($totalLatency / $successCount, 2) } else { 0 }
    $finalPacketLossPercentage = if ($totalPings -gt 0) { [math]::Round(($failureCount / $totalPings) * 100, 2) } else { 0 }
    Write-Host "`n--- Final Summary ---" -ForegroundColor Magenta
    Write-Host "Total pings: $totalPings" -ForegroundColor Cyan
    Write-Host "Successful pings: $successCount" -ForegroundColor Green
    Write-Host "Failed pings: $failureCount" -ForegroundColor Red
    Write-Host "Packet loss: ${finalPacketLossPercentage}%" -ForegroundColor Magenta
    Write-Host "Average latency: ${finalAverageLatency}ms" -ForegroundColor Cyan
    Write-Host "Latency details (last 10): $($latencyList[-10..-1] -join ', ')ms" -ForegroundColor Yellow
    Write-Host "---------------------`n" -ForegroundColor Magenta
}
