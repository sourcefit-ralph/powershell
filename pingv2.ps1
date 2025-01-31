# Continuous Ping Test Script with Timestamp, Color Coding, Latency, Packet Loss, and Web Dashboard

# Prompt user for primary target destination
$primaryTarget = Read-Host "Enter the primary target destination (IP or hostname) [default: google.com]"
if ([string]::IsNullOrWhiteSpace($primaryTarget)) {
    $primaryTarget = "google.com"
}

# Prompt user for secondary target destination
$secondaryTarget = Read-Host "Enter the secondary target destination (IP or hostname) [default: yahoo.com]"
if ([string]::IsNullOrWhiteSpace($secondaryTarget)) {
    $secondaryTarget = "yahoo.com"
}

Write-Host "Starting continuous ping test to primary target: $primaryTarget" -ForegroundColor Cyan
Write-Host "Secondary target: $secondaryTarget" -ForegroundColor Cyan

# Initialize counters and data structures
$totalPings = 0
$successCountPrimary = 0
$failureCountPrimary = 0
$successCountSecondary = 0
$failureCountSecondary = 0
$summaryInterval = 10
$totalLatencyPrimary = 0
$totalLatencySecondary = 0
$latencyListPrimary = @()
$latencyListSecondary = @()
$pingHistoryPrimary = @() # Stores timestamp, success/failure status, and latency for primary target
$pingHistorySecondary = @() # Stores timestamp, success/failure status, and latency for secondary target
$jsonFile = "$($primaryTarget.Replace('.', '_'))_$($secondaryTarget.Replace('.', '_'))_ping_data.json" # JSON file for web dashboard

try {
    while ($true) {
        # Perform ping for primary target
        $pingOutputPrimary = ping $primaryTarget -n 1 | Select-String "Reply from" -Context 0, 0
        
        # Get timestamp
        $timestamp = Get-Date
        $formattedTimestamp = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")

        # Determine if primary ping succeeded or failed
        if ($pingOutputPrimary) {
            # Extract latency from the ping output
            if ($pingOutputPrimary -match 'time=(\d+)ms') {
                $latencyPrimary = [int]$matches[1]
                $primaryStatus = "[$formattedTimestamp] Primary ($primaryTarget): Success, Latency=${latencyPrimary}ms"
                $successCountPrimary++
                $totalLatencyPrimary += $latencyPrimary
                $latencyListPrimary += $latencyPrimary
                $pingHistoryPrimary += @{ Timestamp = $timestamp; Success = $true; Latency = $latencyPrimary }
            } else {
                $primaryStatus = "[$formattedTimestamp] Primary ($primaryTarget): Success, Latency=Unknown"
                $successCountPrimary++
                $pingHistoryPrimary += @{ Timestamp = $timestamp; Success = $true; Latency = $null }
            }
        } else {
            $primaryStatus = "[$formattedTimestamp] Primary ($primaryTarget): Failed"
            $failureCountPrimary++
            $pingHistoryPrimary += @{ Timestamp = $timestamp; Success = $false; Latency = $null }
        }

        # Perform ping for secondary target
        $pingOutputSecondary = ping $secondaryTarget -n 1 | Select-String "Reply from" -Context 0, 0

        # Determine if secondary ping succeeded or failed
        if ($pingOutputSecondary) {
            # Extract latency from the ping output
            if ($pingOutputSecondary -match 'time=(\d+)ms') {
                $latencySecondary = [int]$matches[1]
                $secondaryStatus = "Secondary ($secondaryTarget): Success, Latency=${latencySecondary}ms"
                $successCountSecondary++
                $totalLatencySecondary += $latencySecondary
                $latencyListSecondary += $latencySecondary
                $pingHistorySecondary += @{ Timestamp = $timestamp; Success = $true; Latency = $latencySecondary }
            } else {
                $secondaryStatus = "Secondary ($secondaryTarget): Success, Latency=Unknown"
                $successCountSecondary++
                $pingHistorySecondary += @{ Timestamp = $timestamp; Success = $true; Latency = $null }
            }
        } else {
            $secondaryStatus = "Secondary ($secondaryTarget): Failed"
            $failureCountSecondary++
            $pingHistorySecondary += @{ Timestamp = $timestamp; Success = $false; Latency = $null }
        }

        # Combine primary and secondary statuses into one line
        Write-Host "$primaryStatus | $secondaryStatus" -ForegroundColor Green

        # Increment total pings
        $totalPings++

        # Calculate packet loss percentages for different time intervals (Primary)
        $currentTime = Get-Date
        $last1MinPrimary = $pingHistoryPrimary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 1 }
        $last5MinPrimary = $pingHistoryPrimary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 5 }
        $last10MinPrimary = $pingHistoryPrimary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 10 }
        $last30MinPrimary = $pingHistoryPrimary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 30 }
        $last60MinPrimary = $pingHistoryPrimary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 60 }

        # Calculate packet loss percentages for different time intervals (Secondary)
        $last1MinSecondary = $pingHistorySecondary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 1 }
        $last5MinSecondary = $pingHistorySecondary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 5 }
        $last10MinSecondary = $pingHistorySecondary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 10 }
        $last30MinSecondary = $pingHistorySecondary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 30 }
        $last60MinSecondary = $pingHistorySecondary | Where-Object { ($currentTime - $_.Timestamp).TotalMinutes -le 60 }

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

        # Primary Target Metrics
        $packetLoss1MinPrimary = Calculate-PacketLoss -data $last1MinPrimary
        $packetLoss5MinPrimary = Calculate-PacketLoss -data $last5MinPrimary
        $packetLoss10MinPrimary = Calculate-PacketLoss -data $last10MinPrimary
        $packetLoss30MinPrimary = Calculate-PacketLoss -data $last30MinPrimary
        $packetLoss60MinPrimary = Calculate-PacketLoss -data $last60MinPrimary
        $packetLossTotalPrimary = if ($totalPings -gt 0) { [math]::Round(($failureCountPrimary / $totalPings) * 100, 2) } else { 0 }

        $avgLatency1MinPrimary = Calculate-AverageLatency -data $last1MinPrimary
        $avgLatency5MinPrimary = Calculate-AverageLatency -data $last5MinPrimary
        $avgLatency10MinPrimary = Calculate-AverageLatency -data $last10MinPrimary
        $avgLatency30MinPrimary = Calculate-AverageLatency -data $last30MinPrimary
        $avgLatency60MinPrimary = Calculate-AverageLatency -data $last60MinPrimary
        $avgLatencyTotalPrimary = if ($successCountPrimary -gt 0) { [math]::Round($totalLatencyPrimary / $successCountPrimary, 2) } else { 0 }

        # Secondary Target Metrics
        $packetLoss1MinSecondary = Calculate-PacketLoss -data $last1MinSecondary
        $packetLoss5MinSecondary = Calculate-PacketLoss -data $last5MinSecondary
        $packetLoss10MinSecondary = Calculate-PacketLoss -data $last10MinSecondary
        $packetLoss30MinSecondary = Calculate-PacketLoss -data $last30MinSecondary
        $packetLoss60MinSecondary = Calculate-PacketLoss -data $last60MinSecondary
        $packetLossTotalSecondary = if ($totalPings -gt 0) { [math]::Round(($failureCountSecondary / $totalPings) * 100, 2) } else { 0 }

        $avgLatency1MinSecondary = Calculate-AverageLatency -data $last1MinSecondary
        $avgLatency5MinSecondary = Calculate-AverageLatency -data $last5MinSecondary
        $avgLatency10MinSecondary = Calculate-AverageLatency -data $last10MinSecondary
        $avgLatency30MinSecondary = Calculate-AverageLatency -data $last30MinSecondary
        $avgLatency60MinSecondary = Calculate-AverageLatency -data $last60MinSecondary
        $avgLatencyTotalSecondary = if ($successCountSecondary -gt 0) { [math]::Round($totalLatencySecondary / $successCountSecondary, 2) } else { 0 }

        # Create JSON object with current data
        $jsonData = @{
            PrimaryTarget = $primaryTarget
            SecondaryTarget = $secondaryTarget
            TotalPings = $totalPings
            Primary = @{
                SuccessCount = $successCountPrimary
                FailureCount = $failureCountPrimary
                PacketLoss = @{
                    "1Min" = $packetLoss1MinPrimary
                    "5Min" = $packetLoss5MinPrimary
                    "10Min" = $packetLoss10MinPrimary
                    "30Min" = $packetLoss30MinPrimary
                    "60Min" = $packetLoss60MinPrimary
                    "Total" = $packetLossTotalPrimary
                }
                AverageLatency = @{
                    "1Min" = $avgLatency1MinPrimary
                    "5Min" = $avgLatency5MinPrimary
                    "10Min" = $avgLatency10MinPrimary
                    "30Min" = $avgLatency30MinPrimary
                    "60Min" = $avgLatency60MinPrimary
                    "Total" = $avgLatencyTotalPrimary
                }
                Last10Latencies = $latencyListPrimary[-10..-1]
            }
            Secondary = @{
                SuccessCount = $successCountSecondary
                FailureCount = $failureCountSecondary
                PacketLoss = @{
                    "1Min" = $packetLoss1MinSecondary
                    "5Min" = $packetLoss5MinSecondary
                    "10Min" = $packetLoss10MinSecondary
                    "30Min" = $packetLoss30MinSecondary
                    "60Min" = $packetLoss60MinSecondary
                    "Total" = $packetLossTotalSecondary
                }
                AverageLatency = @{
                    "1Min" = $avgLatency1MinSecondary
                    "5Min" = $avgLatency5MinSecondary
                    "10Min" = $avgLatency10MinSecondary
                    "30Min" = $avgLatency30MinSecondary
                    "60Min" = $avgLatency60MinSecondary
                    "Total" = $avgLatencyTotalSecondary
                }
                Last10Latencies = $latencyListSecondary[-10..-1]
            }
        } | ConvertTo-Json

        # Write JSON data to file
        Set-Content -Path $jsonFile -Value $jsonData

        # Summarize every 10 responses
        if ($totalPings % $summaryInterval -eq 0) {
            Write-Host "`n--- Summary after $totalPings pings ---" -ForegroundColor Yellow
            
            # Header Row
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "Interval", "Primary (PL)", "Secondary (PL)", "Failed Pings", "Latency (ms)") -ForegroundColor Cyan
            
            # 1 Minute
            $failed1MinPrimary = @($last1MinPrimary | Where-Object { -not $_.Success }).Count
            $failed1MinSecondary = @($last1MinSecondary | Where-Object { -not $_.Success }).Count
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "1 Min", 
                "$packetLoss1MinPrimary%", "$packetLoss1MinSecondary%", 
                "$failed1MinPrimary / $failed1MinSecondary", 
                "$avgLatency1MinPrimary ms / $avgLatency1MinSecondary ms") -ForegroundColor Green

            # 5 Minutes
            $failed5MinPrimary = @($last5MinPrimary | Where-Object { -not $_.Success }).Count
            $failed5MinSecondary = @($last5MinSecondary | Where-Object { -not $_.Success }).Count
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "5 Min", 
                "$packetLoss5MinPrimary%", "$packetLoss5MinSecondary%", 
                "$failed5MinPrimary / $failed5MinSecondary", 
                "$avgLatency5MinPrimary ms / $avgLatency5MinSecondary ms") -ForegroundColor Green

            # 10 Minutes
            $failed10MinPrimary = @($last10MinPrimary | Where-Object { -not $_.Success }).Count
            $failed10MinSecondary = @($last10MinSecondary | Where-Object { -not $_.Success }).Count
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "10 Min", 
                "$packetLoss10MinPrimary%", "$packetLoss10MinSecondary%", 
                "$failed10MinPrimary / $failed10MinSecondary", 
                "$avgLatency10MinPrimary ms / $avgLatency10MinSecondary ms") -ForegroundColor Green

            # 30 Minutes
            $failed30MinPrimary = @($last30MinPrimary | Where-Object { -not $_.Success }).Count
            $failed30MinSecondary = @($last30MinSecondary | Where-Object { -not $_.Success }).Count
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "30 Min", 
                "$packetLoss30MinPrimary%", "$packetLoss30MinSecondary%", 
                "$failed30MinPrimary / $failed30MinSecondary", 
                "$avgLatency30MinPrimary ms / $avgLatency30MinSecondary ms") -ForegroundColor Green

            # 60 Minutes
            $failed60MinPrimary = @($last60MinPrimary | Where-Object { -not $_.Success }).Count
            $failed60MinSecondary = @($last60MinSecondary | Where-Object { -not $_.Success }).Count
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "60 Min", 
                "$packetLoss60MinPrimary%", "$packetLoss60MinSecondary%", 
                "$failed60MinPrimary / $failed60MinSecondary", 
                "$avgLatency60MinPrimary ms / $avgLatency60MinSecondary ms") -ForegroundColor Green

            # Total
            Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "Total", 
                "$packetLossTotalPrimary%", "$packetLossTotalSecondary%", 
                "$failureCountPrimary / $failureCountSecondary", 
                "$avgLatencyTotalPrimary ms / $avgLatencyTotalSecondary ms") -ForegroundColor Green

            Write-Host "--------------------------------------`n" -ForegroundColor Yellow
        }

        # Wait for a second before the next ping
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
} finally {
    # Final summary
    $finalPacketLossTotalPrimary = if ($totalPings -gt 0) { [math]::Round(($failureCountPrimary / $totalPings) * 100, 2) } else { 0 }
    $finalAvgLatencyTotalPrimary = if ($successCountPrimary -gt 0) { [math]::Round($totalLatencyPrimary / $successCountPrimary, 2) } else { 0 }
    $finalPacketLossTotalSecondary = if ($totalPings -gt 0) { [math]::Round(($failureCountSecondary / $totalPings) * 100, 2) } else { 0 }
    $finalAvgLatencyTotalSecondary = if ($successCountSecondary -gt 0) { [math]::Round($totalLatencySecondary / $successCountSecondary, 2) } else { 0 }

    Write-Host "`n--- Final Summary ---" -ForegroundColor Magenta
    
    # Header Row
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "Interval", "Primary (PL)", "Secondary (PL)", "Failed Pings", "Latency (ms)") -ForegroundColor Cyan

    # 1 Minute
    $failed1MinPrimary = @($last1MinPrimary | Where-Object { -not $_.Success }).Count
    $failed1MinSecondary = @($last1MinSecondary | Where-Object { -not $_.Success }).Count
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "1 Min", 
        "$packetLoss1MinPrimary%", "$packetLoss1MinSecondary%", 
        "$failed1MinPrimary / $failed1MinSecondary", 
        "$avgLatency1MinPrimary ms / $avgLatency1MinSecondary ms") -ForegroundColor Green
    # 5 Minutes
    $failed5MinPrimary = @($last5MinPrimary | Where-Object { -not $_.Success }).Count
    $failed5MinSecondary = @($last5MinSecondary | Where-Object { -not $_.Success }).Count
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "5 Min", 
        "$packetLoss5MinPrimary%", "$packetLoss5MinSecondary%", 
        "$failed5MinPrimary / $failed5MinSecondary", 
        "$avgLatency5MinPrimary ms / $avgLatency5MinSecondary ms") -ForegroundColor Green

    # 10 Minutes
    $failed10MinPrimary = @($last10MinPrimary | Where-Object { -not $_.Success }).Count
    $failed10MinSecondary = @($last10MinSecondary | Where-Object { -not $_.Success }).Count
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "10 Min", 
        "$packetLoss10MinPrimary%", "$packetLoss10MinSecondary%", 
        "$failed10MinPrimary / $failed10MinSecondary", 
        "$avgLatency10MinPrimary ms / $avgLatency10MinSecondary ms") -ForegroundColor Green

    # 30 Minutes
    $failed30MinPrimary = @($last30MinPrimary | Where-Object { -not $_.Success }).Count
    $failed30MinSecondary = @($last30MinSecondary | Where-Object { -not $_.Success }).Count
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "30 Min", 
        "$packetLoss30MinPrimary%", "$packetLoss30MinSecondary%", 
        "$failed30MinPrimary / $failed30MinSecondary", 
        "$avgLatency30MinPrimary ms / $avgLatency30MinSecondary ms") -ForegroundColor Green

    # 60 Minutes
    $failed60MinPrimary = @($last60MinPrimary | Where-Object { -not $_.Success }).Count
    $failed60MinSecondary = @($last60MinSecondary | Where-Object { -not $_.Success }).Count
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "60 Min", 
        "$packetLoss60MinPrimary%", "$packetLoss60MinSecondary%", 
        "$failed60MinPrimary / $failed60MinSecondary", 
        "$avgLatency60MinPrimary ms / $avgLatency60MinSecondary ms") -ForegroundColor Green

    # Total
    Write-Host ("{0,-15} {1,-15} {2,-15} {3,-15} {4,-15}" -f "Total", 
        "$finalPacketLossTotalPrimary%", "$finalPacketLossTotalSecondary%", 
        "$failureCountPrimary / $failureCountSecondary", 
        "$finalAvgLatencyTotalPrimary ms / $finalAvgLatencyTotalSecondary ms") -ForegroundColor Green

    Write-Host "---------------------`n" -ForegroundColor Magenta
    Write-Host "Web dashboard data written to $jsonFile" -ForegroundColor Cyan
}
