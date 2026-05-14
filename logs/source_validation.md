# Source Validation

## 2026-05-14 22:08 KST — Prompt 01

Prompt: `prompts/01_SOURCE_AND_ENV_VALIDATION.md`

Scope:
- Re-checked the highest-impact source claims for iBridge before product code.
- Used official Apple/Microsoft docs where possible and Astropad public docs for Luna benchmark claims.
- No proprietary reverse engineering, binary inspection, firmware analysis, or protocol sniffing instructions were added.

## Confirmed Claims

- iMac Retina 5K 27-inch Late 2015 has a 5120-by-2880 built-in display, four USB 3 ports, two Thunderbolt 2 ports, and Gigabit Ethernet. [내용 출처 : https://support.apple.com/en-us/112035]
- The iMac Late 2015 Thunderbolt 2 ports are documented as Mini DisplayPort output / adapter support, not as an input path for using the iMac panel directly from a MacBook. [내용 출처 : https://support.apple.com/en-us/112035]
- Apple documents IP communication between two Thunderbolt-equipped Macs over a Thunderbolt cable using Thunderbolt Bridge. This supports treating Thunderbolt as a data transport, not as a panel input. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]
- Apple documents the TB3-to-TB2 adapter as a Thunderbolt/Thunderbolt 2 adapter with up to 20Gbps Thunderbolt 2 data transfer, not as a Mini DisplayPort adapter. [내용 출처 : https://support.apple.com/en-us/111753]
- Apple explicitly says a Mac cannot be charged by connecting the TB3-to-TB2 adapter to an external Thunderbolt display or other Thunderbolt power-delivering device. [내용 출처 : https://support.apple.com/en-us/111753]
- Apple documents ScreenCaptureKit as the preferred high-performance API for capturing selected screen/app/window content into a Mac app. [내용 출처 : https://developer.apple.com/documentation/screencapturekit]
- Apple documents VideoToolbox as a low-level framework for hardware-accelerated video encoding and decoding, and has a WWDC session specifically about low-delay H.264 hardware encoding. [내용 출처 : https://developer.apple.com/documentation/videotoolbox] [내용 출처 : https://developer.apple.com/videos/play/wwdc2021/10158/]
- Microsoft documents Media Foundation H.264 decode as an MFT path with DXVA-related attributes, but the documented maximum resolution is 4096x2304. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]
- Microsoft documents Media Foundation H.265/HEVC decode as an MFT path for Annex B HEVC, also with a documented maximum resolution of 4096x2304. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-265---hevc-video-decoder]
- Luna's current public support page still documents USB-C Luna for 5K, Mac 5K at 45Hz, PC 5K at 30Hz, and 4K at 60Hz. [내용 출처 : https://support.astropad.com/en/articles/11835385-does-luna-display-support-4k-and-5k-retina-resolutions]
- Luna hardware is still documented as requiring direct connection to a compatible port; adapters/hubs/docks are not officially supported for the Luna unit itself. [내용 출처 : https://support.astropad.com/en/articles/11835378-can-i-plug-luna-display-into-an-adapter-or-hub]

## Uncertain Claims

- Whether the user's Windows-booted iMac exposes stable Thunderbolt networking to the MacBook through the Apple TB3-to-TB2 adapter is not confirmed by the Apple Mac-to-Mac Thunderbolt Bridge document, because that document is macOS-oriented.
- Whether the Late 2015 iMac's Windows GPU/driver can decode/render iBridge's target 5K60 compressed stream is not confirmed. Microsoft documents MFT capabilities, but actual 5K behavior depends on hardware, driver, codec, profile, and chosen decode path.
- Whether Media Foundation is enough for 5120x2880 HEVC/H.264 is uncertain because the official H.264 and HEVC decoder docs list 4096x2304 as maximum resolution. This does not prove 5K is impossible with other paths, but it means 5K decode must be measured.
- Whether iMac USB-A or TB2 can meaningfully slow MacBook Air battery drain is not confirmed. The TB3-to-TB2 adapter cannot be treated as a charging path by default.
- The Luna dongle role remains a clean-room hypothesis. Public docs prove the hardware unit is required and supports several data connection modes, but they do not prove its internal mechanism.

## Local Environment Snapshot

- Local machine: MacBook Air, MacBookAir10,1, Apple M1, 8 GB memory.
- Local OS: macOS 14.5 build 23F79.
- `scripts/mac_collect_env.sh logs/env` ran successfully and wrote `logs/env/macos_env.txt`.
- `logs/env/` is intentionally gitignored because the file may include machine/network details.

## Local Experiments Required

- Run `scripts/windows_collect_env.ps1` on the iMac Windows receiver and record GPU, OS build, display mode, DirectX, and codec availability.
- Run `scripts/mac_network_probe.sh <receiver-ip>` after the receiver IP is known.
- Measure direct Ethernet throughput/latency with `iperf3` if installed on both sides.
- Measure Thunderbolt path availability and throughput if the Apple TB3-to-TB2 adapter and TB2 cable are available.
- Create the Plan A theoretical bandwidth note before implementing receiver rendering: `benchmarks/theory/5k60_raw_bandwidth.md`.
- Build a synthetic Windows receiver benchmark before any claim that 5K60 rendering is practical.

## Result

The source base is good enough to proceed to environment validation and Plan A benchmark planning. The biggest newly emphasized risk is Windows Media Foundation's documented 4096x2304 decoder maximum, which makes 5120x2880 decode a test requirement rather than an assumed capability.
