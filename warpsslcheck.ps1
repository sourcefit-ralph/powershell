# Define the thumbprint of the desired certificate
$thumbprint = "EE26C1D60ED73706FDC42D10A20E642F0C3DA2BE"
 
# Check if the certificate exists in the Trusted Root Certification Authorities store
$cert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $thumbprint }
 
if ($cert) {
    # Certificate is installed
    Write-Host "The certificate with thumbprint $thumbprint is already installed." -ForegroundColor Green
    Write-Host "Subject: $($cert.Subject)"
    Write-Host "Expiration Date: $($cert.NotAfter)"
    $sslStatus = "Yes"
    $sslMessage = "Certificate already installed."
    $sslExpirationDate = $cert.NotAfter
    $sslName = $cert.Subject
    $installationDateTime = "N/A"
} else {
    # Certificate not found (installation logic removed)
    Write-Host "The certificate with thumbprint $thumbprint is not installed." -ForegroundColor Yellow
    $sslStatus = "No"
    $sslMessage = "Certificate not installed."
    $sslExpirationDate = "N/A"
    $sslName = "N/A"
    $installationDateTime = "N/A"
}
