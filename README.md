# iBridge

**iBridge**는 `M1/M시리즈 MacBook`의 화면을 `2015 27-inch iMac Retina 5K`에 하드웨어 개조 없이 보조 디스플레이처럼 표시하기 위한 오픈소스 소프트웨어 프로젝트입니다.

이 레포지토리의 목적은 “하네스 문서 세트”를 보관하는 것이 아니라, **실제로 iMac을 외부 디스플레이처럼 활용하는 소프트웨어를 구현**하는 것입니다. 다만 구현을 Codex에게 위임할 때 작업 품질을 높이기 위해, 프로젝트 안에 하네스 엔지니어링 방식의 작업 규칙, 검증 루프, 실험 로그, 출처 ledger, 프롬프트를 함께 포함합니다.

---

## 1. 프로젝트 목표

### 최종 목표

MacBook에서 생성한 가상 보조 디스플레이를 네트워크/Thunderbolt Bridge로 전송하고, Windows로 부팅된 2015 iMac 5K에서 전체 화면으로 저지연 표시합니다.

```text
M1/M-series MacBook macOS Primary
→ virtual display / capture / encode
→ LAN or Thunderbolt Bridge
→ iMac Late 2015 Windows Receiver
→ decode / render / fullscreen / diagnostics HUD
```

### 현재 사용자의 실제 상태

- iMac: 27-inch Retina 5K Late 2015, Radeon R9 M380 계열로 추정
- iMac 현재 OS: **Windows 부팅 상태**
- Primary: M1/M시리즈 MacBook Air/Pro
- 제약: MacBook Air는 USB-C 포트가 적고, 충전/허브/LAN/TB 연결이 동시에 필요할 수 있음

Apple 공식 스펙 기준으로 iMac Retina 5K 27-inch Late 2015는 5120×2880 Retina 5K 디스플레이, USB 3 포트 4개, Thunderbolt 2 포트 2개, Gigabit Ethernet을 제공한다. [내용 출처 : https://support.apple.com/en-us/112035]

---

## 2. 화질 목표: 높은 목표부터 시도하고 단계적으로 낮춘다

사용자의 요구는 “처음부터 MVP 핑계로 낮은 목표를 잡지 말고, 5K60부터 정면으로 시도한 뒤 한계가 검증되면 단계적으로 낮추는 것”입니다. iBridge는 이 방식을 따릅니다.

| Plan | 목표 | 구현 전략 | 성공/하향 조건 |
|---|---|---|---|
| **Plan A** | 5K 60Hz 무압축/저지연 | 원본 대역폭, TB Bridge, capture/encode bypass 가능성 벤치마크 | 무압축이 불가능하다는 수치/실험 근거를 남기고 Plan B로 하향 |
| **Plan B** | 5K 60Hz 실사용급 | HEVC/H.264 하드웨어 인코딩, TB Bridge 우선, Windows 하드웨어 디코딩 | 5K60 지연/프레임/화질이 기준 미달이면 Plan C로 하향 |
| **Plan C** | 60Hz 유지 + 5K 패널에 유리한 스케일링 | 2560×1440 integer 2x, 3840×2160, 3200×1800 등 비교 | 가장 자연스러운 60Hz 실사용 모드 채택 |

Luna Display도 공개적으로 Mac-to-Mac 5K는 45Hz, 4K는 60Hz로 제한된다고 설명한 바 있으므로, iBridge는 이 한계를 기준점으로 삼되 무조건 복제하지 않는다. [내용 출처 : https://astropad.com/blog/luna-display-5-1/]

---

## 3. 우선 구현 경로

### 우선순위 1 — macOS Primary + Windows Receiver

현재 iMac이 Windows 상태이므로, iMac을 다시 macOS/OCLP로 되돌리는 비용을 피하기 위해 Windows Receiver를 우선 구현합니다.

- macOS Primary
  - 가상 디스플레이 생성 후보 검증
  - ScreenCaptureKit / CGDisplayStream 캡처
  - VideoToolbox H.264/HEVC 인코딩
  - LAN / Thunderbolt Bridge 전송
- Windows Receiver
  - Media Foundation 또는 FFmpeg 기반 H.264/HEVC 디코딩
  - D3D11/SDL2/DirectComposition 렌더링
  - 전체 화면 표시
  - 진단 HUD: fps, bitrate, latency, dropped frames, power state

Microsoft의 H.264 decoder는 Media Foundation Transform으로 제공되며, Windows 쪽 수신 앱의 하드웨어 디코딩 경로 검토 기준이다. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]

### 우선순위 2 — macOS Receiver

Windows Receiver가 색/프레임 타이밍/디코딩에서 병목이면 macOS Receiver를 병행합니다. 단, 이는 iMac에 macOS 설치/OCLP가 필요하므로 보조 경로입니다.

---

## 4. 연결 옵션

### Option A: USB-C 허브 + LAN

```text
MacBook USB-C → PD/LAN 허브 → Ethernet → iMac Ethernet
```

장점: 충전과 LAN을 동시에 해결하기 쉬움. MacBook Air에서 현실적입니다. 1GbE는 Plan C의 1440p60/4K60 실험에 적합합니다.

### Option B: iMac TB2 ↔ MacBook USB-C / Thunderbolt Bridge

```text
MacBook USB-C/TB → Apple TB3-to-TB2 adapter → TB2 cable → iMac TB2
```

Apple은 두 Mac을 Thunderbolt 케이블로 연결해 IP 통신할 수 있다고 설명한다. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

장점: Plan B 5K60 실사용급 실험에 가장 유리합니다. 단, 이것은 iMac 패널 입력이 아니라 데이터 경로입니다.

---

## 5. 전원 공급에 대한 현실적인 목표

이 프로젝트는 iMac USB-A/TB2가 MacBook에 어느 정도 전원을 제공할 수 있는지 **실험하고 진단**합니다. 단, USB-C PD 충전 대체를 약속하지 않습니다.

- iMac USB-A → MacBook USB-C 연결 시 “전원 연결됨”으로 인식될 수 있음
- USB 3 기본 전력은 보통 5V 900mA, 약 4.5W 수준이라 실제 작업 유지 충전은 제한적일 가능성이 큼 [내용 출처 : https://tripplite.eaton.com/products/usb-charging]
- Thunderbolt 1/2 버스파워는 최대 10W급 자료가 있으나, 이것이 MacBook USB-C PD 충전으로 이어진다고 단정할 수 없음 [내용 출처 : https://global-sei.com/ewp/E/thunderbolt/]

따라서 iBridge는 `Power Probe`를 포함해 실제 환경에서 전원 인식/방전율/작업 부하별 차이를 측정합니다.

---

## 6. Codex 작업 방식

이 프로젝트에는 `AGENTS.md` 하나만 둡니다. `CODEX.md`, `CLAUDE.md`는 만들지 않습니다. Codex는 항상 `AGENTS.md`와 `prompts/`를 우선 읽고 작업합니다.

핵심 원칙:

1. **Think Before Coding** — 추정과 사실을 분리하고, 막히면 로그에 남긴다.
2. **Simplicity First** — 기능 구현에 직접 필요한 코드만 작성한다.
3. **Surgical Changes** — 요청 범위 외의 코드/문서를 건드리지 않는다.
4. **Goal-Driven Execution** — 모든 작업은 성공 기준과 검증 명령을 가진다.

이 원칙은 Karpathy-style coding agent guidelines를 참고해 iBridge에 맞게 재구성했다. [내용 출처 : https://github.com/forrestchang/andrej-karpathy-skills]

---

## 7. 시작 순서

Codex에게 다음 순서로 맡기세요.

1. `prompts/00_MASTER_PROMPT.md`
2. `prompts/01_SOURCE_AND_ENV_VALIDATION.md`
3. `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`
4. Plan A 결과에 따라 `03_PLAN_B_5K60_PRACTICAL.md` 또는 `04_PLAN_C_60HZ_SCALED_MODES.md`
5. 실제 구현은 `05_PRIMARY_MACOS_IMPLEMENTATION.md` + `06_WINDOWS_RECEIVER_IMPLEMENTATION.md`
6. 각 단계 후 `09_REVIEW_GATE.md`

---

## 8. 레포 구조

```text
.
├── AGENTS.md
├── README.md
├── docs/
├── prompts/
├── specs/
├── apps/
│   ├── primary-macos/
│   ├── receiver-windows/
│   └── shared-protocol/
├── scripts/
├── experiments/
├── logs/
└── templates/
```
