# iBridge iMac 5K Second Display Development Guide v0.2

> 이 문서는 iBridge 소프트웨어 구현을 위한 제품/기술/검증 기준 문서다. v0.1의 내용과 사용자의 수정 요구를 반영해, “하네스 문서 작성”이 아니라 **실제 외부 디스플레이 활용 소프트웨어 제작**을 기준으로 재구성했다.

---

## 0. 핵심 요약

- 프로젝트명: **iBridge**
- 목표: 2015 27-inch Retina 5K iMac을 하드웨어 개조 없이 MacBook의 보조 디스플레이처럼 활용한다.
- 현재 iMac 상태: **Windows 부팅 상태**
- 1차 구현 경로: **macOS Primary → Windows Receiver**
- 2차 구현 경로: macOS Receiver / OCLP / AirPlay 비교 실험
- 첫 목표: **Plan A 5K 60Hz 무압축/저지연 가능성 정면 검증**
- 실패 시: Plan B 5K60 실사용급 → Plan C 60Hz scaled modes 순서로 하향한다.

---

## 1. 사용자 요구 정리

사용자는 2015 iMac 5K를 이미 20만 원에 구입했고, 상태가 좋기 때문에 하드웨어 개조로 내부 컴퓨터 기능을 제거하는 것을 망설이고 있다. 따라서 먼저 소프트웨어로 가능한 한 높은 품질의 보조 디스플레이화를 시도한다.

중요한 요구:

1. 5K 60Hz를 먼저 시도한다.
2. 60Hz 이하의 마우스 움직임은 사용성이 떨어진다고 느낀다.
3. 5K 60Hz가 불가능하면 60Hz 유지가 가능한 스케일링 모드를 찾는다.
4. iMac은 현재 Windows 상태이므로, macOS 재설치/OCLP가 꼭 필요한 근거가 없으면 Windows Receiver를 우선한다.
5. USB-C 허브 + LAN 또는 USB-C/TB ↔ iMac TB2 연결을 적극 활용한다.
6. iMac USB-A/TB2 전원 공급 가능성은 단정하지 말고 실험한다.
7. Luna Display는 현재 시장에서 가장 가까운 상용 구현이므로, 리버스엔지니어링 없이 공개 정보 기반으로 벤치마크/기술 가설을 분석한다.

---

## 2. 확정 사실과 검증 필요 항목

### 2.1 확정: iMac Late 2015 5K의 물리 포트

Apple 공식 스펙 기준으로 iMac Retina 5K 27-inch Late 2015는 5120×2880 Retina 5K 디스플레이, USB 3 포트 4개, Thunderbolt 2 포트 2개, Gigabit Ethernet을 제공한다. [내용 출처 : https://support.apple.com/en-us/112035]

### 2.2 확정: TB2는 패널 입력으로 취급하면 안 됨

공식 스펙에서 Thunderbolt 2는 Mini DisplayPort output과 외부 출력 어댑터 지원으로 설명된다. 즉 MacBook의 DisplayPort 신호를 iMac 내부 패널에 직접 입력하는 Target Display Mode 대체 경로가 아니다. [내용 출처 : https://support.apple.com/en-us/112035]

### 2.3 확정: Thunderbolt Bridge는 데이터 경로로 가능

Apple은 두 Mac을 Thunderbolt 케이블로 연결해 IP 통신할 수 있다고 설명한다. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

따라서 TB2는 `display input`이 아니라 `high-speed transport`로 다룬다.

### 2.4 정정: TB3-to-TB2 어댑터와 전원 공급

Apple TB3-to-TB2 어댑터가 MacBook 충전기 역할을 한다고 보면 안 된다. Apple은 해당 어댑터가 Thunderbolt/Thunderbolt 2 장치와 최대 20Gbps 데이터 전송을 지원한다고 설명하고, Thunderbolt Display는 어댑터를 통해 전원을 공급하지 않으므로 별도 전원이 필요하다고 설명한다. [내용 출처 : https://support.apple.com/en-us/111753]

하지만 이것은 “iMac TB2 포트가 전원 출력을 전혀 하지 않는다”는 의미와 다르다. Thunderbolt 1/2 bus power는 일부 주변기기 전원을 공급할 수 있다는 자료가 있다. [내용 출처 : https://global-sei.com/ewp/E/thunderbolt/]

검증 필요:

- iMac TB2 → Apple TB3-to-TB2 → MacBook USB-C 연결 시 MacBook 전원 상태가 변하는지
- 변한다면 충전 전력/방전 완화가 몇 W 수준인지
- Thunderbolt Bridge 데이터 전송과 전원 인식이 동시에 가능한지

### 2.5 확정에 가까움: USB-A 저전력 감지는 가능하지만 실사용 충전은 어려움

USB 3 기본 전력은 보통 5V 900mA, 약 4.5W 수준으로 정리된다. [내용 출처 : https://tripplite.eaton.com/products/usb-charging]

사용자 관찰상 iMac USB3.0 ↔ MacBook USB-C 연결 시 배터리 상태가 전원 연결로 바뀌는 것은 가능하다. 그러나 MacBook 작업 전력과 비교하면 실제 충전/유지에는 부족할 가능성이 높다.

---

## 3. Luna Display 분석: clean-room benchmark only

Luna Display는 이 시장에서 가장 가까운 상용 구현이다. 하지만 iBridge는 Luna를 복제하거나 분석해서 우회하지 않는다.

공개 정보로 확인되는 사실:

- Luna Mac-to-Mac은 Wi-Fi/Ethernet/USB/Thunderbolt 연결을 지원한다. [내용 출처 : https://support.astropad.com/en/articles/11835375-what-are-the-system-requirements-for-luna-display]
- 5K iMac을 Retina 해상도로 쓰려면 USB-C Luna Display가 필요하다고 안내한다. [내용 출처 : https://support.astropad.com/en/articles/11835385-does-luna-display-support-4k-and-5k-retina-resolutions]
- Luna 5.1은 Mac에서 5K @ 45Hz, 4K @ 60Hz를 명시했다. [내용 출처 : https://astropad.com/blog/luna-display-5-1/]
- Luna 하드웨어는 허브/어댑터/독에 꽂는 것을 공식 지원하지 않는다. [내용 출처 : https://support.astropad.com/en/articles/11835378-can-i-plug-luna-display-into-an-adapter-or-hub]

합리적 가설:

- Luna 동글은 실제 5K 프레임을 직접 송수신하는 고성능 영상 칩이라기보다, macOS에 외장 디스플레이 존재를 안정적으로 알리는 hardware token / display trigger / license key 성격이 강하다.
- 실제 프레임 데이터는 네트워크/USB/Thunderbolt 경로로 앱이 송수신한다.

금지:

- Luna 앱 바이너리 분석
- 동글 펌웨어 dump
- 프로토콜 sniffing 후 호환 구현
- 라이선스 우회

허용:

- 공개 문서 기반 벤치마크 목표 설정
- Luna의 공개 한계와 iBridge 결과 비교
- 동일 문제를 공개 API와 독립 설계로 해결

---

## 4. 화질 목표와 Downshift Ladder

### Plan A — 5K 60Hz 무압축/저지연

목표:

- 5120×2880
- 60Hz
- 무압축 또는 사실상 무손실
- 마우스/스크롤 지연 최소

단순 대역폭 계산:

```text
5120 × 2880 × 60 × 24bit ≈ 21.2Gbps
```

Thunderbolt 2가 최대 20Gbps급으로 설명되더라도, 여기서는 패널 입력이 아니라 IP/data transport이므로 capture/packetize/render 오버헤드가 추가된다. [내용 출처 : https://support.apple.com/en-us/111753]

Plan A 구현 지침:

1. synthetic 5K60 frame generator로 receiver 렌더링 한계를 먼저 측정한다.
2. macOS capture 없이 raw/near-raw transport 대역폭을 측정한다.
3. Thunderbolt Bridge와 Gigabit LAN을 각각 측정한다.
4. 5K60 raw가 실패하면 실패 이유를 대역폭/CPU/GPU/render 중 하나로 분류한다.
5. 실패 로그 없이 Plan B로 내려가지 않는다.

### Plan B — 5K 60Hz 실사용급

목표:

- 5120×2880 60fps 표시 목표
- HEVC/H.264 하드웨어 인코딩
- Windows Receiver 하드웨어 디코딩
- 정적 코딩 화면에서 텍스트가 사용 가능해야 함

핵심 기술:

- macOS VideoToolbox hardware encoder [내용 출처 : https://developer.apple.com/documentation/videotoolbox]
- Apple low-delay hardware encoding WWDC reference [내용 출처 : https://developer.apple.com/videos/play/wwdc2021/10158/]
- Windows Media Foundation/H.264 decoder [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]
- FFmpeg hardware acceleration fallback [내용 출처 : https://trac.ffmpeg.org/wiki/HWAccelIntro]

Plan B 구현 지침:

1. 5K60 HEVC부터 시도한다.
2. 실패 시 5K60 H.264 low-latency를 비교한다.
3. latency HUD가 encode/network/decode/render를 분리해야 한다.
4. 5K60이 45~55fps 사이로 불안정하면 5K45를 Luna baseline으로 측정하되 최종 목표는 유지하지 않는다.
5. 5K60이 불합격이면 Plan C로 내려간다.

### Plan C — 60Hz scaled mode

사용자에게 60Hz는 필수에 가깝다. 따라서 최종 실사용 모드는 해상도를 낮추더라도 60Hz를 유지한다.

우선순위:

1. **2560×1440 @ 60Hz** — 5120×2880에 정확히 2배 정수 스케일링
2. **3840×2160 @ 60Hz** — 일반 4K, 인코더/디코더 친화적
3. **3200×1800 @ 60Hz** — QHD보다 넓고 4K보다 가벼운 균형 모드
4. **4096×2304 @ 60Hz** — 고해상도 실험

Plan C 구현 지침:

- 1440p60은 단순 fallback이 아니라 5K 패널에 최적화된 integer scaling mode다.
- Windows Receiver에서 scaling filter를 명시적으로 비교한다: nearest/integer, bilinear, bicubic, sharp filter.
- 텍스트 캡처 이미지를 `benchmarks/screenshots/`에 저장하고 비교한다.

---

## 5. 아키텍처

```text
[macOS Primary]
  ├─ VirtualDisplayManager
  ├─ CaptureEngine
  ├─ EncoderEngine
  ├─ TransportClient
  ├─ CursorPipeline
  ├─ PowerProbe
  └─ DiagnosticsHUD
        ↓
[Transport]
  ├─ Ethernet TCP/UDP
  ├─ Thunderbolt Bridge TCP/UDP
  └─ future QUIC/WebRTC
        ↓
[Windows Receiver]
  ├─ HandshakeServer
  ├─ DecoderEngine
  ├─ D3DRenderer
  ├─ ScalingEngine
  ├─ FullscreenController
  ├─ DiagnosticsHUD
  └─ Input/Pointer overlay
```

---

## 6. 구현 우선순위

### Stage 0 — Environment Probe

- MacBook hardware/OS/capture API 확인
- iMac Windows GPU/decoder/refresh rate 확인
- LAN/TB Bridge iperf3 측정
- 전원 상태 측정

### Stage 1 — Plan A Benchmark

- Windows Receiver synthetic 5K60 렌더링
- raw/near-raw transport simulation
- Thunderbolt Bridge vs LAN throughput/latency 측정

### Stage 2 — Core External Display Pipeline

- macOS virtual display 생성
- capture → encode → transport → decode → render
- 5120×2880 60부터 시작
- 실패 시 명시적 downshift

### Stage 3 — Plan B/C Productionization

- 5K60 compressed mode
- 1440p60 integer scale mode
- 4K60 mode
- reconnect, settings, packaging

---

## 7. 성공 기준

### 핵심 기능 성공 기준

- MacBook에서 별도 작업 공간을 만들고 iMac Windows 앱에서 전체화면 표시한다.
- 사용자는 iMac을 보조 디스플레이처럼 배치하고 작업할 수 있다.
- 최소 하나의 60Hz 모드가 안정적으로 동작한다.
- 진단 HUD로 병목이 확인 가능하다.

### 최소 실사용 합격선

- 2560×1440 @ 60fps
- end-to-end latency가 마우스 사용에 치명적이지 않을 것
- 30분 이상 안정 동작
- reconnect 가능
- Windows Receiver에서 전체화면 유지

### stretch goal

- 5120×2880 @ 60fps practical mode
- Thunderbolt Bridge 최적화
- 5K text mode 품질 개선

