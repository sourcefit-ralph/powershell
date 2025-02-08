# Define variables
$softwareName = "NetBird"
$githubRepo = "netbirdio/netbird"
$installerPath = "$env:TEMP\NetBird-latest.msi"

# Function to get the installed version of NetBird
function Get-InstalledVersion {
    try {
        $installedVersion = (Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $softwareName }).Version
        return $installedVersion
    } catch {
        Write-Host "NetBird is not installed."
        return $null
    }
}

# Function to get the latest version from GitHub releases
function Get-LatestVersion {
    try {
        $releasesUrl = "https://api.github.com/repos/$githubRepo/releases/latest"
        $response = Invoke-RestMethod -Uri $releasesUrl -UseBasicParsing
        $latestVersion = $response.tag_name -replace '^v', '' # Remove 'v' prefix if present
        return $latestVersion
    } catch {
        Write-Host "Failed to fetch the latest version from GitHub."
        return $null
    }
}

# Function to download and install the latest version using .msi
function Install-NetBird {
    param (
        [string]$downloadUrl
    )
    try {
        Write-Host "Downloading the latest .msi version of NetBird..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

        Write-Host "Installing the latest version of NetBird using .msi..."
        # Use msiexec.exe to install the .msi file silently
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait

        Write-Host "NetBird has been successfully updated using the .msi installer."
    } catch {
        Write-Host "Failed to download or install NetBird."
    } finally {
        # Clean up the downloaded installer
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

# Main script logic
Write-Host "Checking for NetBird updates..."

# Get the installed version
$installedVersion = Get-InstalledVersion
if (-not $installedVersion) {
    Write-Host "NetBird is not installed. Installing the latest version using .msi..."
    $latestVersion = Get-LatestVersion
    if ($latestVersion) {
        $downloadUrl = "https://github.com/$githubRepo/releases/download/v$latestVersion/NetBird-$latestVersion-x86_64.msi"
        Install-NetBird -downloadUrl $downloadUrl
    }
    exit
}

Write-Host "Installed version: $installedVersion"

# Get the latest version
$latestVersion = Get-LatestVersion
if (-not $latestVersion) {
    Write-Host "Unable to determine the latest version. Exiting."
    exit
}

Write-Host "Latest version: $latestVersion"

# Compare versions
if ([version]$installedVersion -lt [version]$latestVersion) {
    Write-Host "A new version of NetBird is available. Updating using .msi..."
    $downloadUrl = "https://github.com/$githubRepo/releases/download/v$latestVersion/NetBird-$latestVersion-x86_64.msi"
    Install-NetBird -downloadUrl $downloadUrl
} else {
    Write-Host "NetBird is already up-to-date."
}
