<#
.SYNOPSIS
    Install-EDOTCollector - Installs Elastic Distribution of OpenTelemetry (EDOT) Collector

.DESCRIPTION
    This script downloads and installs the Elastic EDOT Collector compatible with Elastic 8.19.
    Supports both Agent and Gateway deployment modes.
    Compatible with Windows Server 2012 R2 and later.

.PARAMETER Mode
    Deployment mode for the EDOT Collector. Valid values: 'Agent' or 'Gateway'
    - Agent: Collects telemetry directly from local applications
    - Gateway: Receives telemetry from other collectors/agents and forwards to Elastic

.PARAMETER ElasticEndpoint
    Elastic endpoint URL (e.g., https://your-cluster.es.region.cloud.es.io:443)

.PARAMETER ElasticApiKey
    API key for authenticating to Elastic

.EXAMPLE
    .\Install-EDOTCollector.ps1 -Mode Agent
    
.EXAMPLE
    .\Install-EDOTCollector.ps1 -Mode Gateway -ElasticEndpoint "https://my-cluster.es.us-east-1.aws.found.io:443" -ElasticApiKey "your-api-key"

.NOTES
    Name: Install-EDOTCollector
    Author: Lief08
    Version: 2.0
    Compatibility: Windows Server 2012 R2+, Elastic Platform 8.19
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Agent', 'Gateway')]
    [string]$Mode,
    
    [Parameter(Mandatory=$false)]
    [string]$ElasticEndpoint,
    
    [Parameter(Mandatory=$false)]
    [string]$ElasticApiKey
)

# Script configuration
$ErrorActionPreference = 'Stop'

# EDOT Collector download URL (Elastic 8.19)
$EDOTVersion = '8.19.0'
$EDOTCollectorUrl = "https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-$EDOTVersion-windows-x86_64.zip"

# Installation paths
$downloadPath = "$env:TEMP\elastic-agent-$EDOTVersion-windows-x86_64.zip"
$extractPath = "$env:TEMP\elastic-agent-extract"
$installDir = 'C:\Program Files\Elastic\EDOT-Collector'
$serviceName = 'elastic-edot-collector'
$configPath = Join-Path $installDir 'otel.yml'

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Elastic EDOT Collector Installation" -ForegroundColor Cyan
    Write-Host "Version: $EDOTVersion" -ForegroundColor Cyan
    Write-Host "Mode: $Mode" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Step 1: Download EDOT Collector
    Write-Host "[1/6] Downloading EDOT Collector from Elastic artifacts..." -ForegroundColor Yellow
    Write-Host "      URL: $EDOTCollectorUrl" -ForegroundColor Gray
    
    # Use .NET WebClient for Windows 2012 R2 compatibility
    $webClient = New-Object System.Net.WebClient
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $webClient.DownloadFile($EDOTCollectorUrl, $downloadPath)
    
    Write-Host "      Download complete: $downloadPath" -ForegroundColor Green
    Write-Host ""

    # Step 2: Create installation directory
    Write-Host "[2/6] Creating installation directory..." -ForegroundColor Yellow
    if (Test-Path $installDir) {
        Write-Host "      Removing existing installation..." -ForegroundColor Gray
        # Stop service if running
        $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($existingService -and $existingService.Status -eq 'Running') {
            Stop-Service -Name $serviceName -Force
            Start-Sleep -Seconds 2
        }
        Remove-Item $installDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "      Installation directory created: $installDir" -ForegroundColor Green
    Write-Host ""

    # Step 3: Extract the downloaded ZIP file
    Write-Host "[3/6] Extracting EDOT Collector package..." -ForegroundColor Yellow
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    
    # Use Shell.Application for Windows 2012 R2 compatibility
    $shell = New-Object -ComObject Shell.Application
    $zip = $shell.NameSpace($downloadPath)
    $destination = $shell.NameSpace($extractPath)
    $destination.CopyHere($zip.Items(), 16)
    
    # Find the extracted folder
    $extractedFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    
    # Copy contents to installation directory
    Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $installDir -Recurse -Force
    
    Write-Host "      Extraction complete" -ForegroundColor Green
    Write-Host ""

    # Step 4: Create EDOT Collector configuration based on mode
    Write-Host "[4/6] Creating EDOT Collector configuration ($Mode mode)..." -ForegroundColor Yellow
    
    if ($Mode -eq 'Agent') {
        # Agent mode configuration
        $configContent = @"
# Elastic Distribution of OpenTelemetry (EDOT) Collector Configuration
# Mode: Agent
# Compatible with Elastic 8.19

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: localhost:4317
      http:
        endpoint: localhost:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024

exporters:
  logging:
    loglevel: info
  # Configure your Elastic endpoint below
  # elasticsearch:
  #   endpoint: "https://your-elastic-endpoint:443"
  #   api_key: "your-api-key"
  #   data_stream:
  #     logs:
  #       dataset: otel-logs
  #     metrics:
  #       dataset: otel-metrics
  #     traces:
  #       dataset: otel-traces
  #   mode: otel

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
"@
    } else {
        # Gateway mode configuration
        $configContent = @"
# Elastic Distribution of OpenTelemetry (EDOT) Collector Configuration
# Mode: Gateway
# Compatible with Elastic 8.19

receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  resourcedetection:
    detectors: [env, system]
    timeout: 5s
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  logging:
    loglevel: info
"@

        # Add Elasticsearch exporter if endpoint and API key provided
        if ($ElasticEndpoint -and $ElasticApiKey) {
            $configContent += @"
  elasticsearch:
    endpoint: "$ElasticEndpoint"
    api_key: "$ElasticApiKey"
    data_stream:
      logs:
        dataset: otel-logs
      metrics:
        dataset: otel-metrics
      traces:
        dataset: otel-traces
    mode: otel
"@
            $exporters = "[elasticsearch, logging]"
        } else {
            $configContent += @"
  # elasticsearch:
  #   endpoint: "https://your-elastic-endpoint:443"
  #   api_key: "your-api-key"
  #   data_stream:
  #     logs:
  #       dataset: otel-logs
  #     metrics:
  #       dataset: otel-metrics
  #     traces:
  #       dataset: otel-traces
  #   mode: otel
"@
            $exporters = "[logging]"
        }

        $configContent += @"
service:
  pipelines:
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: $exporters
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: $exporters
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, resourcedetection]
      exporters: $exporters
"@
    }
    
    Set-Content -Path $configPath -Value $configContent -Encoding UTF8
    Write-Host "      Configuration file created: $configPath" -ForegroundColor Green
    if ($Mode -eq 'Gateway' -and (-not $ElasticEndpoint -or -not $ElasticApiKey)) {
        Write-Host "      NOTE: Update the configuration with your Elastic endpoint details" -ForegroundColor Magenta
    }
    Write-Host ""

    # Step 5: Install as Windows service
    Write-Host "[5/6] Configuring Windows service..." -ForegroundColor Yellow
    
    # Check if service already exists
    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "      Stopping existing service..." -ForegroundColor Gray
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Write-Host "      Removing existing service..." -ForegroundColor Gray
        $service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
        if ($service) {
            $service.Delete() | Out-Null
        }
        Start-Sleep -Seconds 2
    }
    
    # Locate the elastic-agent.exe binary
    $collectorExe = Get-ChildItem -Path $installDir -Filter "elastic-agent.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if (-not $collectorExe) {
        throw "Could not find elastic-agent.exe in $installDir"
    }
    
    $exePath = $collectorExe.FullName
    $serviceArgs = "otel --config `"$configPath`""
    
    # Create the service using sc.exe for Windows 2012 R2 compatibility
    $scResult = & sc.exe create $serviceName binPath= "`"$exePath`" $serviceArgs" start= auto DisplayName= "Elastic EDOT Collector ($Mode Mode)"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create service. Error: $scResult"
    }
    
    # Set service description
    & sc.exe description $serviceName "Elastic Distribution of OpenTelemetry Collector running in $Mode mode - Sends telemetry data to Elastic Observability"
    
    Write-Host "      Service '$serviceName' created successfully" -ForegroundColor Green
    Write-Host ""

    # Step 6: Start the service
    Write-Host "[6/6] Starting EDOT Collector service..." -ForegroundColor Yellow
    Start-Service -Name $serviceName
    Start-Sleep -Seconds 3
    
    $serviceStatus = Get-Service -Name $serviceName
    if ($serviceStatus.Status -eq 'Running') {
        Write-Host "      Service started successfully" -ForegroundColor Green
    } else {
        Write-Host "      Warning: Service is in '$($serviceStatus.Status)' state" -ForegroundColor Yellow
    }
    Write-Host ""

    # Cleanup temporary files
    Write-Host "Cleaning up temporary files..." -ForegroundColor Gray
    Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Service Name:    $serviceName" -ForegroundColor Cyan
    Write-Host "Deployment Mode: $Mode" -ForegroundColor Cyan
    Write-Host "Install Path:    $installDir" -ForegroundColor Cyan
    Write-Host "Config File:     $configPath" -ForegroundColor Cyan
    Write-Host "Service Status:  $($serviceStatus.Status)" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Mode -eq 'Gateway') {
        Write-Host "Gateway Mode Info:" -ForegroundColor Yellow
        Write-Host "- Listening on 0.0.0.0:4317 (gRPC) and 0.0.0.0:4318 (HTTP)" -ForegroundColor White
        Write-Host "- Ensure firewall allows inbound traffic on these ports" -ForegroundColor White
        Write-Host "" 
    }
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    if (-not $ElasticEndpoint -or -not $ElasticApiKey) {
        Write-Host "1. Edit the configuration file to add your Elastic endpoint" -ForegroundColor White
        Write-Host "   Config: $configPath" -ForegroundColor White
        Write-Host "2. Restart the service: Restart-Service $serviceName" -ForegroundColor White
    }
    Write-Host "3. Check service status: Get-Service $serviceName" -ForegroundColor White
    Write-Host "4. View service logs in Windows Event Viewer" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Installation Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    
    # Cleanup on failure
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    throw
}