# PowerShell Script to Install Elastic EDOT Collector

# Set the URL for the Elastic EDOT Collector package
$EDOTCollectorUrl = 'https://artifacts.elastic.co/downloads/beats/edot-collector/edot-collector-7.9.0-windows-x86.zip'

# Download the Elastic EDOT Collector package
$zipFilePath = 'C:\path\to\download\edot-collector.zip'
Invoke-WebRequest -Uri $EDOTCollectorUrl -OutFile $zipFilePath

# Create installation directory
$installDir = 'C:\Program Files\Elastic\EDOTCollector'
New-Item -ItemType Directory -Path $installDir -Force

# Extract the downloaded ZIP file
Write-Host 'Extracting the EDOT Collector...'
Expand-Archive -Path $zipFilePath -DestinationPath $installDir -Force

# Install the EDOT Collector as a Windows service
$edotServiceName = 'elastic-edot-collector'
$edotServiceExecutable = Join-Path $installDir 'edot-collector.exe'

# Check if the service exists and remove it if it does
if (Get-Service -Name $edotServiceName -ErrorAction SilentlyContinue) {
    Stop-Service -Name $edotServiceName -Force
    Remove-Service -Name $edotServiceName
}

# Create the new service
New-Service -Name $edotServiceName -Binary $edotServiceExecutable -DisplayName 'Elastic EDOT Collector' -StartupType Automatic

# Start the service
Start-Service -Name $edotServiceName

# Cleanup
Remove-Item $zipFilePath -Force

Write-Host 'Elastic EDOT Collector installed and started successfully.'