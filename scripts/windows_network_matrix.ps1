param(
  [Parameter(Mandatory = $true)]
  [string]$Case,

  [Parameter(Mandatory = $true)]
  [string]$MacHost,

  [string]$TailscaleTarget = "",
  [int]$Duration = 20,
  [string]$RunRoot = ""
)

$ErrorActionPreference = "Continue"
$stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
if (-not $RunRoot) {
  $RunRoot = "benchmarks\runs\${stamp}_network_matrix"
}
$outDir = Join-Path $RunRoot $Case
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

@(
  "case=$Case"
  "mac_host=$MacHost"
  "duration_seconds=$Duration"
  "timestamp=$stamp"
  "computer=$env:COMPUTERNAME"
  "user=$env:USERNAME"
) | Tee-Object -FilePath (Join-Path $outDir "metadata.txt")

Get-NetAdapter | Format-List * | Out-File -Encoding utf8 (Join-Path $outDir "net_adapter.txt")
Get-NetIPAddress | Format-Table -AutoSize | Out-File -Encoding utf8 (Join-Path $outDir "net_ipaddress.txt")

Test-Connection -Count 100 $MacHost | Tee-Object -FilePath (Join-Path $outDir "ping_100.txt")

$iperf = Get-Command iperf3 -ErrorAction SilentlyContinue
if ($iperf) {
  & iperf3 -c $MacHost -t $Duration --json | Out-File -Encoding utf8 (Join-Path $outDir "iperf3_tcp_to_mac.json")
  & iperf3 -c $MacHost -t $Duration -R --json | Out-File -Encoding utf8 (Join-Path $outDir "iperf3_tcp_from_mac_reverse.json")
  foreach ($rate in @(30, 60, 120)) {
    & iperf3 -c $MacHost -u -b "${rate}M" -t $Duration --json | Out-File -Encoding utf8 (Join-Path $outDir "iperf3_udp_${rate}mbps.json")
  }
} else {
  "iperf3 not installed; install it on both machines before cable benchmarks." | Tee-Object -FilePath (Join-Path $outDir "iperf3_missing.txt")
}

if ($Case -eq "tailscale" -or $TailscaleTarget) {
  if (-not $TailscaleTarget) {
    $TailscaleTarget = $MacHost
  }
  $tailscale = Get-Command tailscale -ErrorAction SilentlyContinue
  if ($tailscale) {
    & tailscale status | Out-File -Encoding utf8 (Join-Path $outDir "tailscale_status.txt")
    & tailscale netcheck | Out-File -Encoding utf8 (Join-Path $outDir "tailscale_netcheck.txt")
    & tailscale ping --c 10 $TailscaleTarget | Out-File -Encoding utf8 (Join-Path $outDir "tailscale_ping.txt")
  } else {
    "tailscale CLI not found" | Tee-Object -FilePath (Join-Path $outDir "tailscale_missing.txt")
  }
}

@"
# Network Matrix Result: $Case

- Mac host: ``$MacHost``
- Duration: ``$Duration`` seconds
- Status: raw command artifacts captured; summarize min/avg/max/loss and iperf throughput after the physical path is confirmed.

## Required Notes

- Interface actually used:
- Physical path:
- Tailscale direct/relay status, if applicable:
- Link speed, if visible:
- Observed blockers:
"@ | Out-File -Encoding utf8 (Join-Path $outDir "summary.md")

Write-Host "Wrote $outDir"
