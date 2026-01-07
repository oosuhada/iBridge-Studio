# Source Ledger

This file stores plain-text source URLs in the user-requested format. Every technical claim added to docs should refer to one of these or add another entry.

| ID | Status | Claim | Source |
|---|---|---|---|
| apple_imac_2015_spec_en | confirmed | iMac Retina 5K 27-inch Late 2015 has a 5120-by-2880 display, four USB 3 ports, two Thunderbolt 2 ports with Mini DisplayPort output support, and 10/100/1000BASE-T Gigabit Ethernet. | [내용 출처 : https://support.apple.com/en-us/112035] |
| apple_imac_2015_spec_ko | reference | See related docs. | [내용 출처 : https://support.apple.com/ko-kr/112035] |
| apple_tb3_tb2_adapter | confirmed | Apple's TB3-to-TB2 adapter supports Thunderbolt/Thunderbolt 2 data transfer up to 20Gbps for Thunderbolt 2 devices, is not Mini DisplayPort-compatible, and does not let a Mac charge from a Thunderbolt power-delivering device through the adapter. | [내용 출처 : https://support.apple.com/en-us/111753] |
| apple_tb_bridge | confirmed | Apple documents IP communication between two Thunderbolt-equipped Macs over a Thunderbolt cable using Thunderbolt Bridge. | [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac] |
| apple_ethernet_two_macs | confirmed | Apple documents direct Ethernet networking between two Macs and notes USB Ethernet or Thunderbolt-to-Gigabit Ethernet adapters when a Mac lacks Ethernet. | [내용 출처 : https://support.apple.com/en-om/guide/mac-help/mchlp1413/mac] |
| apple_screen_capture_kit | confirmed | ScreenCaptureKit is Apple's framework for high-performance capture of selected display, app, and window content into app-provided streams. | [내용 출처 : https://developer.apple.com/documentation/screencapturekit] |
| apple_videotoolbox | confirmed | VideoToolbox provides low-level access to hardware-accelerated video encoding and decoding capabilities. | [내용 출처 : https://developer.apple.com/documentation/videotoolbox] |
| apple_vt_low_delay | confirmed | Apple documents low-delay H.264 hardware encoding with VideoToolbox for real-time use cases. | [내용 출처 : https://developer.apple.com/videos/play/wwdc2021/10158/] |
| apple_vt_low_latency_rate_control | confirmed | Apple documents `kVTVideoEncoderSpecification_EnableLowLatencyRateControl` as an encoder specification key that selects an encoder supporting low-latency operation and enables low-latency mode. | [내용 출처 : https://developer.apple.com/documentation/videotoolbox/kvtvideoencoderspecification_enablelowlatencyratecontrol] |
| apple_vt_low_latency_sample | confirmed | Apple's low-latency conferencing sample says to include `kVTVideoEncoderSpecification_EnableLowLatencyRateControl` in `videoEncoderSpecification` when creating a `VTCompressionSession`. | [내용 출처 : https://developer.apple.com/documentation/videotoolbox/encoding-video-for-low-latency-conferencing] |
| apple_vt_encoder_id | confirmed | Apple documents that encoder IDs can be obtained from `VTCopyVideoEncoderList` and passed in an encoder specification when creating a compression session. | [내용 출처 : https://developer.apple.com/documentation/videotoolbox/kvtvideoencoderspecification_encoderid] |
| apple_bonjour | reference | See related docs. | [내용 출처 : https://developer.apple.com/bonjour/] |
| apple_driverkit | reference | See related docs. | [내용 출처 : https://developer.apple.com/documentation/driverkit] |
| apple_power_adapter | reference | See related docs. | [내용 출처 : https://support.apple.com/en-us/109509] |
| astropad_luna_requirements | confirmed | Luna Display currently documents that its hardware unit is required for all connection types and that Windows 10 64-bit or later is supported as a primary device. | [내용 출처 : https://support.astropad.com/en/articles/11835375-what-are-the-system-requirements-for-luna-display] |
| astropad_luna_4k_5k | confirmed | Luna Display currently documents USB-C Luna as required for 5K resolutions, Mac support for 5K at 45Hz and 4K at 60Hz, and PC support for 5K at 30Hz and 4K at 60Hz. | [내용 출처 : https://support.astropad.com/en/articles/11835385-does-luna-display-support-4k-and-5k-retina-resolutions] |
| astropad_luna_hub | confirmed | Luna Display currently says the Luna hardware should be plugged directly into a compatible port; adapters may still be used for separate wired Ethernet/Thunderbolt connections. | [내용 출처 : https://support.astropad.com/en/articles/11835378-can-i-plug-luna-display-into-an-adapter-or-hub] |
| astropad_luna_51 | confirmed | Luna Display 5.1 publicly stated 5K at 30Hz on PC, 5K at 45Hz on Mac, and 4K at 60Hz on Mac and PC. | [내용 출처 : https://astropad.com/blog/luna-display-5-1/] |
| ms_desktop_dup | reference | See related docs. | [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/desktop-dup-api] |
| ms_h264_decoder | confirmed | Microsoft's Media Foundation H.264 decoder is an MFT, supports Baseline/Main/High up to level 5.1, exposes DXVA-related attributes, and lists 4096x2304 as the documented maximum resolution. | [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder] |
| ms_hevc_decoder | confirmed | Microsoft's Media Foundation H.265/HEVC decoder is an MFT for Annex B HEVC, supports Main/Main Still Picture/Main10 profiles, and lists 4096x2304 as the documented maximum resolution. | [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-265---hevc-video-decoder] |
| ms_mediafoundation_decode | reference | See related docs. | [내용 출처 : https://learn.microsoft.com/en-us/gaming/gdk/docs/gdk-dev/overviews/mediafoundation-decode] |
| tailscale_connection_types | confirmed | Tailscale documents direct connections as usually providing the lowest latency and highest throughput, while relayed connections are a fallback when direct connectivity is unavailable. | [내용 출처 : https://tailscale.com/docs/reference/connection-types] |
| tailscale_derp_routing_debug | confirmed | Tailscale documents `tailscale status`, `tailscale ping`, and `tailscale netcheck` as tools for inspecting direct vs DERP/relay behavior. | [내용 출처 : https://tailscale.com/docs/reference/troubleshooting/network-configuration/derp-routing] |
| ffmpeg_hwaccel | reference | See related docs. | [내용 출처 : https://trac.ffmpeg.org/wiki/HWAccelIntro] |
| sdl_intro | reference | See related docs. | [내용 출처 : https://wiki.libsdl.org/SDL2/Introduction] |
| freedisplay | reference | See related docs. | [내용 출처 : https://github.com/huberdf/FreeDisplay] |
| node_mac_virtual_display | reference | See related docs. | [내용 출처 : https://github.com/enfp-dev-studio/node-mac-virtual-display] |
| chromium_cgvirtualdisplay | reference | See related docs. | [내용 출처 : https://chromium.googlesource.com/chromium/src/+/d441ddf663e568fe8383d59a31e0dfacb9d9535b/ui/display/mac/test/virtual_display_mac_util.mm] |
| tripplite_usb_power | reference | See related docs. | [내용 출처 : https://tripplite.eaton.com/products/usb-charging] |
| thunderbolt_bus_power_sei | reference | See related docs. | [내용 출처 : https://global-sei.com/ewp/E/thunderbolt/] |
| intel_thunderbolt_brief_pdf | reference | See related docs. | [내용 출처 : https://www.intel.com/content/dam/doc/technology-brief/thunderbolt-technology-brief.pdf] |
| owc_tb_compat | reference | See related docs. | [내용 출처 : https://eshop.macsales.com/blog/96867-the-simple-guide-to-thunderbolt-forwards-and-backwards-compatibility/] |
| karpathy_skills | reference | See related docs. | [내용 출처 : https://github.com/forrestchang/andrej-karpathy-skills] |
| gstack | reference | See related docs. | [내용 출처 : https://github.com/garrytan/gstack] |
| sunshine_repo | reference | Sunshine is an open-source self-hosted game stream host for Moonlight with hardware-encoding backends, including macOS VideoToolbox paths worth studying for iBridge. | [내용 출처 : https://github.com/LizardByte/Sunshine] |
| moonlight_qt_repo | reference | Moonlight Qt is an open-source game streaming client with hardware-accelerated decode support across Windows, macOS, and Linux. | [내용 출처 : https://github.com/moonlight-stream/moonlight-qt] |
| obs_studio_repo | reference | OBS Studio includes macOS capture and VideoToolbox encoder implementations useful as mature capture/encode references. | [내용 출처 : https://github.com/obsproject/obs-studio] |
| transcoding_repo | reference | Transcoding is a Swift package for video encoding/decoding with Annex-B adapters and low-latency presets. | [내용 출처 : https://github.com/finnvoor/Transcoding] |
| apple_sck_sample_mirror | reference | CapturingScreenContentInMacOS mirrors Apple's ScreenCaptureKit sample for high-performance macOS screen capture. | [내용 출처 : https://github.com/Fidetro/CapturingScreenContentInMacOS] |
| videotoolbox_h265_sample | reference | VideoToolboxH265Encoder is a small Swift HEVC/H.264 VideoToolbox encoder sample. | [내용 출처 : https://github.com/zf3/VideoToolboxH265Encoder] |
| ffmpeg_repo | reference | FFmpeg includes VideoToolbox and codec bitstream handling code useful as a reference implementation. | [내용 출처 : https://github.com/FFmpeg/FFmpeg] |
| deskpad_repo | reference | DeskPad is an open-source macOS virtual monitor for screen sharing and uses virtual display concepts relevant to a Mac-Mac iBridge route. | [내용 출처 : https://github.com/Stengo/DeskPad] |
| freedisplay_repo | reference | FreeDisplay is an open-source macOS virtual display/display-management reference. | [내용 출처 : https://github.com/huberdf/FreeDisplay] |
| simpledisplay_repo | reference | SimpleDisplay is an open-source macOS display manager that creates virtual monitors using CGVirtualDisplay private API. | [내용 출처 : https://github.com/SamuelRioTz/SimpleDisplay] |
| node_mac_virtual_display_repo | reference | node-mac-virtual-display is an open-source native bridge for creating macOS virtual displays from Node/Electron contexts. | [내용 출처 : https://github.com/enfp-dev-studio/node-mac-virtual-display] |
| betterdisplay_repo | reference | BetterDisplay is an open-source macOS display/HiDPI/virtual-screen reference. | [내용 출처 : https://github.com/waydabber/BetterDisplay] |
| rustdesk_repo | reference | RustDesk is an open-source remote desktop application with macOS capture and hardware codec paths worth studying for Mac-Mac and cross-platform routes. | [내용 출처 : https://github.com/rustdesk/rustdesk] |
| deskreen_repo | reference | Deskreen is an open-source project that turns devices with a browser into secondary screens over WebRTC. | [내용 출처 : https://github.com/pavlobu/deskreen] |
| screencat_repo | reference | ScreenCat is an open-source screen sharing and remote collaboration project using WebRTC. | [내용 출처 : https://github.com/max-mapper/screencat] |
