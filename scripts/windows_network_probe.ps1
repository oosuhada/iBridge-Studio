param(
  [string]$MacHost
)
if (-not $MacHost) { Write-Host "Usage: .\windows_network_probe.ps1 -MacHost <ip>"; exit 1 }
Test-Connection -Count 20 $MacHost | Tee-Object -FilePath "logs\ping_$MacHost.txt"
Write-Host "If iperf3 is installed, run: iperf3 -c $MacHost -t 30"
