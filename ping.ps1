# Continuous Ping Test Script with Timestamp, Color Coding, Latency, Packet Loss, and Summaries

# Prompt user for target destination
$target = Read-Host "Enter the target destination (IP or hostname) [default: google.com]"
if ([string]::IsNullOrWhiteSpace($target)) {
    $target = "google.com"
}

Write-Host "Starting continuous ping test to $target..." -ForegroundColor Cyan

# Initialize counters and data structures
$totalPings = 0
$successCount = 0
$failureCount = 0
$summaryInterval = 10
$totalLatency = 0
$latencyList = @()
$pingHistory = @() # Stores timestamp, success/failure status, and latency for each ping

try {
    while ($true) {
        # Perform ping using native ping command
        $pingOutput = ping $target -n 1 | Select-String "Reply from" -Context 0, 0
        
        # Get timestamp
        $timestamp = Get-Date
        $formattedTimestamp = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")

        # Determine if ping succeeded or failed
        if ($pingOutput) {
            # Extract latency from the ping output
            if ($pingOutput -match 'time=(\d+)ms') {
                $latency = [int]$matches[1]
                Write-Host "[$formattedTimestamp] Ping to $target succeeded. Latency: ${latency}ms" -ForegroundColor Green
                $successCount++
                $totalLatency += $latency
                $latencyList += $latency
                $pingHistory += @{ Timestamp = $timestamp; Success = $true; Latency = $latency }
            } else {
                Write-Host "[$formattedTimestamp] Ping to $target succeeded, but could not parse latency." -ForegroundColor Yellow
                $successCount++
                $pingHistory += @{ Timestamp = $timestamp; Success = $true; Latency = $null }
            }
        } else {
            Write-Host "[$formattedTimestamp] Ping to $target failed." -ForegroundColor Red
            $failureCount++
            $pingHistory += @{ Timestamp = $timestamp; Success = $false; Latency = $null }
        }

        # Increment total pings
        $totalPings++

        # Calculate packet loss percentages for different time intervals
        $currentTime = Get-Date
        $last1Min = $pingHistory | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 1 }
        $last5Min = $pingHistory | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 5 }
        $last10Min = $pingHistory | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 10 }
        $last30Min = $pingHistory | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 30 }
        $last60Min = $pingHistory | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 60 }

        # Function to calculate packet loss percentage
        function Calculate-PacketLoss {
            param (
                [Parameter(Mandatory = $true)]
                $data
            )
            $total = $data.Count
            $failed = ($data | Where-Object { -not $_.Success }).Count
            if ($total -gt 0) {
                return [math]::Round(($failed / $total) * 100, 2)
            } else {
                return 0
            }
        }

        # Function to calculate average latency
        function Calculate-AverageLatency {
            param (
                [Parameter(Mandatory = $true)]
                $data
            )
            $successfulPings = $data | Where-Object { $_.Success -and $_.Latency -ne $null }
            $totalLatency = ($successfulPings | Measure-Object -Property Latency -Sum).Sum
            $count = $successfulPings.Count
            if ($count -gt 0) {
                return [math]::Round($totalLatency / $count, 2)
            } else {
                return 0
            }
        }

        $packetLoss1Min = Calculate-PacketLoss -data $last1Min
        $packetLoss5Min = Calculate-PacketLoss -data $last5Min
        $packetLoss10Min = Calculate-PacketLoss -data $last10Min
        $packetLoss30Min = Calculate-PacketLoss -data $last30Min
        $packetLoss60Min = Calculate-PacketLoss -data $last60Min
        $packetLossTotal = if ($totalPings -gt 0) { [math]::Round(($failureCount / $totalPings) * 100, 2) } else { 0 }

        $avgLatency1Min = Calculate-AverageLatency -data $last1Min
        $avgLatency5Min = Calculate-AverageLatency -data $last5Min
        $avgLatency10Min = Calculate-AverageLatency -data $last10Min
        $avgLatency30Min = Calculate-AverageLatency -data $last30Min
        $avgLatency60Min = Calculate-AverageLatency -data $last60Min
        $avgLatencyTotal = if ($successCount -gt 0) { [math]::Round($totalLatency / $successCount, 2) } else { 0 }

        # Summarize every 10 responses
        if ($totalPings % $summaryInterval -eq 0) {
            Write-Host "`n--- Summary after $totalPings pings ---" -ForegroundColor Yellow
            Write-Host "Successful pings: $successCount" -ForegroundColor Green
            Write-Host "Failed pings: $failureCount" -ForegroundColor Red
            Write-Host "Packet loss (1 min): ${packetLoss1Min}%" -ForegroundColor Magenta
            Write-Host "Packet loss (5 min): ${packetLoss5Min}%" -ForegroundColor Magenta
            Write-Host "Packet loss (10 min): ${packetLoss10Min}%" -ForegroundColor Magenta
            Write-Host "Packet loss (30 min): ${packetLoss30Min}%" -ForegroundColor Magenta
            Write-Host "Packet loss (60 min): ${packetLoss60Min}%" -ForegroundColor Magenta
            Write-Host "Packet loss (total): ${packetLossTotal}%" -ForegroundColor Magenta
            Write-Host "Average latency (1 min): ${avgLatency1Min}ms" -ForegroundColor Cyan
            Write-Host "Average latency (5 min): ${avgLatency5Min}ms" -ForegroundColor Cyan
            Write-Host "Average latency (10 min): ${avgLatency10Min}ms" -ForegroundColor Cyan
            Write-Host "Average latency (30 min): ${avgLatency30Min}ms" -ForegroundColor Cyan
            Write-Host "Average latency (60 min): ${avgLatency60Min}ms" -ForegroundColor Cyan
            Write-Host "Average latency (total): ${avgLatencyTotal}ms" -ForegroundColor Cyan
            Write-Host "--------------------------------------`n" -ForegroundColor Yellow
        }

        # Wait for a second before the next ping
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
} finally {
    # Final summary
    $finalPacketLossTotal = if ($totalPings -gt 0) { [math]::Round(($failureCount / $totalPings) * 100, 2) } else { 0 }
    $finalAvgLatencyTotal = if ($successCount -gt 0) { [math]::Round($totalLatency / $successCount, 2) } else { 0 }
    Write-Host "`n--- Final Summary ---" -ForegroundColor Magenta
    Write-Host "Total pings: $totalPings" -ForegroundColor Cyan
    Write-Host "Successful pings: $successCount" -ForegroundColor Green
    Write-Host "Failed pings: $failureCount" -ForegroundColor Red
    Write-Host "Packet loss (1 min): ${packetLoss1Min}%" -ForegroundColor Magenta
    Write-Host "Packet loss (5 min): ${packetLoss5Min}%" -ForegroundColor Magenta
    Write-Host "Packet loss (10 min): ${packetLoss10Min}%" -ForegroundColor Magenta
    Write-Host "Packet loss (30 min): ${packetLoss30Min}%" -ForegroundColor Magenta
    Write-Host "Packet loss (60 min): ${packetLoss60Min}%" -ForegroundColor Magenta
    Write-Host "Packet loss (total): ${finalPacketLossTotal}%" -ForegroundColor Magenta
    Write-Host "Average latency (1 min): ${avgLatency1Min}ms" -ForegroundColor Cyan
    Write-Host "Average latency (5 min): ${avgLatency5Min}ms" -ForegroundColor Cyan
    Write-Host "Average latency (10 min): ${avgLatency10Min}ms" -ForegroundColor Cyan
    Write-Host "Average latency (30 min): ${avgLatency30Min}ms" -ForegroundColor Cyan
    Write-Host "Average latency (60 min): ${avgLatency60Min}ms" -ForegroundColor Cyan
    Write-Host "Average latency (total): ${finalAvgLatencyTotal}ms" -ForegroundColor Cyan
    Write-Host "Latency details (last 10): $($latencyList[-10..-1] -join ', ')ms" -ForegroundColor Yellow
    Write-Host "---------------------`n" -ForegroundColor Magenta
}
