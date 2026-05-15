# iMac Setup Prep

Date: 2026-05-15

Scope: what can be prepared before physical access to the iMac, now that both
Windows and Mac-to-Mac routes are in scope.

## Current Remote State

Known from today's probes:

- iMac Tailscale address: `100.86.52.88`.
- Windows SSH port `22` is reachable, but the MacBook Pro SSH key is not
  authorized.
- iBridge receiver port `48320` is not listening yet.
- Live MBP -> iMac send/decode has not run because no receiver is active.

## What Can Be Done Remotely Now

These are safe preparatory steps if an RDP session or any existing authorized
remote shell is available:

1. Run `scripts/windows_imac_setup_inventory.ps1` on the Windows iMac.
2. Confirm whether Boot Camp Control Panel is installed and whether it sees a
   macOS startup volume.
3. Confirm whether the Windows disk still has an APFS/HFS macOS volume.
4. Add the MBP public SSH key to the Windows OpenSSH authorized keys file, if
   Windows OpenSSH is the intended remote path.
5. Build or copy the receiver binary and start it manually so port `48320`
   listens for a TCP smoke test.
6. Install or verify Tailscale on Windows and confirm whether the iMac is direct
   or relayed over DERP before treating latency as meaningful.

## What Should Wait For Physical Access

- Repartitioning, reinstalling macOS, deleting Windows partitions, changing EFI
  boot entries, or changing the default startup disk without a verified remote
  recovery path.
- Booting into macOS unless macOS remote login/screen sharing/Tailscale is
  already confirmed. If it boots into macOS with no remote access, the iMac can
  become unreachable until someone is physically present.
- Any Apple ID, FileVault, recovery, or installer workflow that might pause at a
  local UI prompt.

## Boot Camp Reality Check

Apple documents that Intel Macs with Boot Camp can choose the default operating
system from Windows Boot Camp Control Panel, and can also choose a startup
volume by holding Option during restart. Apple also notes Windows can restart
into macOS through the Boot Camp tray icon. See source ledger entries
`apple_bootcamp_startup_control_panel` and
`apple_bootcamp_restart_macos_windows`.

For the likely 2015 iMac family, Apple's iMac model page lists the official
newest compatible OS as:

- iMac Retina 5K, 27-inch, Late 2015: macOS Monterey.
- iMac Retina 4K, 21.5-inch, Late 2015: macOS Monterey.
- iMac 21.5-inch, Late 2015: macOS Monterey.
- iMac Retina 5K, 27-inch, Mid 2015: macOS Big Sur.

The exact iMac model identifier should be confirmed from Windows inventory or
physical macOS System Information before planning an OS install.

## Practical Tonight Checklist

When physically near the iMac:

1. Attach keyboard/mouse and make sure Option-key boot picker is available.
2. Check whether `Macintosh HD` or another macOS startup volume exists.
3. If macOS exists, boot it once, enable network access, enable Remote Login or
   Screen Sharing, sign in to Tailscale, and confirm the machine is reachable
   from MBP/MBA before relying on remote boot switching.
4. If macOS does not exist, make a full backup decision before installing. Do
   not start from remote-only assumptions.
5. If staying on Windows tonight, start the iBridge receiver and open port
   `48320` for the MBP forced-HEVC TCP smoke test.

## Suggested Remote Command

From a Windows PowerShell prompt on the iMac:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows_imac_setup_inventory.ps1
```

The script avoids printing key contents or environment secrets. It records
paths, service state, disks/volumes, listeners, Boot Camp files, and firmware
boot entries into a timestamped local folder.
