param(
  [string]$OutDir = "logs\env"
)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Out = Join-Path $OutDir "windows_env.txt"
"# Windows Environment" | Out-File $Out
Get-Date | Out-File $Out -Append
Get-ComputerInfo | Out-File $Out -Append
Get-CimInstance Win32_VideoController | Format-List * | Out-File $Out -Append
Get-NetAdapter | Format-Table | Out-File $Out -Append
powercfg /batteryreport /output (Join-Path $OutDir "battery-report.html") | Out-Null
Write-Host "Wrote $Out"
