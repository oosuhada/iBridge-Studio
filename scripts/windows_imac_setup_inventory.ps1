param(
    [string]$OutputRoot = "."
)

$ErrorActionPreference = "Continue"

function Write-Section {
    param([string]$Title)
    "`r`n===== $Title =====`r`n"
}

function Save-Command {
    param(
        [string]$Name,
        [scriptblock]$Command
    )

    $Path = Join-Path $ReportDir "$Name.txt"
    try {
        & $Command 2>&1 | Out-String -Width 240 | Set-Content -Path $Path -Encoding UTF8
    }
    catch {
        "ERROR: $($_.Exception.Message)" | Set-Content -Path $Path -Encoding UTF8
    }
}

function Get-PathLengthOrNull {
    param([string]$Path)

    if (Test-Path $Path) {
        return (Get-Item $Path).Length
    }

    return $null
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportDir = Join-Path $OutputRoot "ibridge-imac-prep-$Timestamp"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$Summary = New-Object System.Collections.Generic.List[string]
$Summary.Add("iBridge iMac setup inventory")
$Summary.Add("Generated: $(Get-Date -Format o)")
$Summary.Add("Computer: $env:COMPUTERNAME")
$Summary.Add("User: $env:USERNAME")
$Summary.Add("ReportDir: $ReportDir")

Save-Command "system" {
    Write-Section "Computer"
    Get-ComputerInfo | Select-Object `
        CsName, CsManufacturer, CsModel, CsSystemType, OsName, OsVersion, OsBuildNumber, WindowsProductName
    Write-Section "BIOS"
    Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion
}

Save-Command "network" {
    Write-Section "Adapters"
    Get-NetAdapter | Sort-Object Name | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress
    Write-Section "IP Addresses"
    Get-NetIPAddress | Sort-Object InterfaceAlias, AddressFamily | Select-Object InterfaceAlias, AddressFamily, IPAddress, PrefixLength
    Write-Section "Routes"
    Get-NetRoute -AddressFamily IPv4 | Sort-Object RouteMetric | Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric
}

Save-Command "tailscale" {
    $Tailscale = Get-Command tailscale.exe -ErrorAction SilentlyContinue
    if ($Tailscale) {
        Write-Section "tailscale status"
        tailscale status
        Write-Section "tailscale netcheck"
        tailscale netcheck
    }
    else {
        "tailscale.exe not found in PATH"
    }
}

Save-Command "ssh" {
    Write-Section "OpenSSH services"
    Get-Service sshd, ssh-agent -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType
    Write-Section "Authorized key path checks"
    $UserAuthorizedKeys = Join-Path $env:USERPROFILE ".ssh\authorized_keys"
    $AdminAuthorizedKeys = Join-Path $env:ProgramData "ssh\administrators_authorized_keys"
    foreach ($Path in @($UserAuthorizedKeys, $AdminAuthorizedKeys)) {
        [pscustomobject]@{
            Path = $Path
            Exists = Test-Path $Path
            Length = Get-PathLengthOrNull -Path $Path
        }
    }
    Write-Section "SSH listener"
    Get-NetTCPConnection -LocalPort 22 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State, OwningProcess
}

Save-Command "ports" {
    Write-Section "Important listeners"
    foreach ($Port in @(22, 3389, 48320, 5900, 5985, 5986)) {
        Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
            Select-Object @{Name="CheckedPort";Expression={$Port}}, LocalAddress, LocalPort, State, OwningProcess
    }
    Write-Section "Firewall rules mentioning iBridge, OpenSSH, Remote Desktop"
    Get-NetFirewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match "iBridge|OpenSSH|Remote Desktop|RDP" } |
        Select-Object DisplayName, Enabled, Direction, Action, Profile
}

Save-Command "disks-volumes" {
    Write-Section "Disks"
    Get-Disk | Sort-Object Number | Select-Object Number, FriendlyName, BusType, PartitionStyle, Size, OperationalStatus
    Write-Section "Partitions"
    Get-Partition | Sort-Object DiskNumber, PartitionNumber | Select-Object DiskNumber, PartitionNumber, DriveLetter, Type, GptType, Size
    Write-Section "Volumes"
    Get-Volume | Sort-Object DriveLetter, FileSystemLabel | Select-Object DriveLetter, FileSystemLabel, FileSystem, DriveType, HealthStatus, SizeRemaining, Size
}

Save-Command "bootcamp" {
    Write-Section "Boot Camp paths"
    $Paths = @(
        "C:\Program Files\Boot Camp",
        "C:\Program Files (x86)\Boot Camp",
        "C:\Windows\System32\AppleControlPanel.exe",
        "C:\Windows\System32\AppleOSSMgr.exe",
        "C:\Windows\System32\AppleKeyboardMgr.exe"
    )
    foreach ($Path in $Paths) {
        [pscustomobject]@{
            Path = $Path
            Exists = Test-Path $Path
        }
    }
    Write-Section "Apple services"
    Get-Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "Apple|BootCamp" -or $_.DisplayName -match "Apple|Boot Camp" } |
        Select-Object Name, DisplayName, Status, StartType
    Write-Section "Firmware boot entries"
    bcdedit /enum firmware
}

Save-Command "receiver" {
    Write-Section "iBridge receiver process/listener"
    Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -match "ibridge|receiver" } |
        Select-Object ProcessName, Id, Path
    Get-NetTCPConnection -LocalPort 48320 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State, OwningProcess
}

$Summary.Add("Files:")
Get-ChildItem $ReportDir -File | Sort-Object Name | ForEach-Object {
    $Summary.Add("- $($_.Name)")
}

$SummaryPath = Join-Path $ReportDir "SUMMARY.txt"
$Summary | Set-Content -Path $SummaryPath -Encoding UTF8

Write-Host "iBridge iMac inventory complete."
Write-Host "Report directory: $ReportDir"
Write-Host "Summary: $SummaryPath"
