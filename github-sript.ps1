# Cloudflare WARP Check Script with Loop
do {
    Clear-Host
    Write-Host "`n=== Cloudflare WARP Check ===" -ForegroundColor Cyan
    Write-Host "1. SSL Certificate Check" -ForegroundColor Yellow
    Write-Host "2. Connection Status Check" -ForegroundColor Green
    Write-Host "Q. Quit" -ForegroundColor Magenta

    $choice = Read-Host "`nChoose a check (1/2/Q)"

    switch -Wildcard ($choice) {
        1 {
            Write-Warning "Running SSL Certificate Check..."
            iex (irm https://link.sourcefit.info/warpsslcheck)
            Write-Host "[SSL Check Complete]" -ForegroundColor Cyan
        }
        2 {
            Write-Warning "Checking WARP Connection Status..."
            iex (https://link.sourcefit.info/warpstatuscheck)
            Write-Host "[Connection Check Complete]" -ForegroundColor Cyan
        }
        Q { break }
        default {
            Write-Host "Invalid choice! Please enter 1, 2, or Q." -ForegroundColor Red
        }
    }

    if ($choice -notin 'Q','q') {
        $repeat = Read-Host "`nRun another check? (Y/N)"
    }
} while ($repeat -eq 'Y' -or $repeat -eq 'y')

Write-Host "`nWARP Check session ended" -ForegroundColor Cyan
