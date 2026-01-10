# iBridge Studio

iBridge Studio는 Target Display Mode가 지원되지 않는 iMac을 MacBook의 소프트웨어 Retina 모니터처럼 다시 쓰기 위한 macOS 앱입니다.

한 앱인 `iBridge Studio.app`를 MacBook과 iMac 모두에 설치합니다. MacBook에서는 Sender 세션을 실행하고, iMac에서는 Receiver를 전체 화면으로 실행합니다.

```text
MacBook Pro / MacBook Air
  BetterDisplay virtual display
  iBridge Studio Sender: capture -> HEVC encode -> network send

Ethernet / Thunderbolt Bridge / LAN

iMac
  iBridge Studio Receiver: receive -> decode -> fullscreen display
  local mouse / keyboard surface
```

## 현재 목표

iBridge Studio의 목표는 오래된 iMac을 단순 원격 데스크톱처럼 쓰는 것이 아니라, MacBook의 확장 디스플레이에 가깝게 쓰는 것입니다.

- MacBook 하나에서 iMac 1대 또는 2대를 확장 화면처럼 사용
- 2015 27-inch 5K iMac, 2017 21.5-inch 4K iMac 같은 Retina iMac 재활용
- 1GbE, Thunderbolt Bridge, 직접 연결 LAN 환경 우선
- BetterDisplay 가상 디스플레이와 iBridge Studio Sender/Receiver 조합
- 마우스/키보드 릴레이, 창 복구, 프리셋 기반 연결 관리

## 브랜치 구조

- `deploy`: 기본 브랜치. 앱을 내려받고 빌드/패키징하는 사용자를 위한 배포 표면입니다.
- `dev`: 개발 브랜치. benchmark, prompts, logs, handoff docs, AGENTS 지침처럼 개발 과정에 필요한 기록을 유지합니다.
- `main`: 초기 bootstrap용 legacy branch입니다. 새 배포 기준은 `deploy`입니다.

## 지원 방향

Target Display Mode를 지원하지 않는 Retina iMac과 Apple Silicon iMac을 소프트웨어 receiver 대상으로 봅니다.

앱 프리셋에는 다음 계열이 포함됩니다.

- iMac 27-inch 5K Late 2014
- iMac 21.5-inch 4K Late 2015
- iMac 27-inch 5K Late 2015
- iMac 21.5-inch 4K 2017
- iMac 27-inch 5K 2017
- iMac Pro 27-inch 5K 2017
- iMac 21.5-inch 4K 2019
- iMac 27-inch 5K 2019
- iMac 27-inch 5K 2020
- iMac 24-inch 4.5K M1 / M3 / M4

프리셋은 해상도와 bitrate의 시작점입니다. 실제 최적값은 네트워크, MacBook 인코더 성능, BetterDisplay 설정에 따라 조정해야 합니다.

## 현재 추천 프로필

### 2015 27-inch 5K iMac

- BetterDisplay virtual display: `iMac 27inch 2015`
- iBridge Studio signal: `5120x2880`
- Bitrate: `280 Mbps`
- Profile: `lan-60hz`
- 현재 직접 Ethernet IP 예시: `169.254.99.112`

### 2017 21.5-inch 4K iMac

- BetterDisplay virtual display: `iMac 21.5inch 2017`
- BetterDisplay UI sweet spot: `2048x1152 HiDPI`
- iBridge Studio signal: `4096x2304`
- Bitrate: `220 Mbps`
- Profile: `imac4k-quality`

## 설치 패키지 만들기

MacBook의 repo checkout에서:

```bash
cd /Users/gabriel/Development/iBridge-Studio
scripts/package_macos_alpha.sh
```

생성물:

```text
dist/iBridge-Studio-0.1.0-alpha/
dist/iBridge-Studio-0.1.0-alpha.zip
```

패키지 안에는 다음이 들어갑니다.

- `iBridge Studio.app`
- `iBridge Studio Receiver.app`
- `bin/ibridge-primary`
- receiver/sender helper scripts
- 배포용 README

현재는 내부 alpha 패키지이며 Developer ID notarization은 아직 적용하지 않았습니다.

## iMac으로 앱 보내기

패키지 zip을 각 iMac에 보냅니다.

2015 iMac Ethernet 예시:

```bash
scp dist/iBridge-Studio-0.1.0-alpha.zip oosu@169.254.99.112:~/Desktop/
```

2017 iMac Tailscale/SSH 예시:

```bash
scp dist/iBridge-Studio-0.1.0-alpha.zip gabrieljang@100.89.104.119:~/Desktop/
```

iMac에서:

```bash
cd ~/Desktop
unzip -o iBridge-Studio-0.1.0-alpha.zip
xattr -dr com.apple.quarantine iBridge-Studio-0.1.0-alpha
open "iBridge-Studio-0.1.0-alpha/iBridge Studio.app"
```

Receiver 전용으로만 쓸 때도 같은 `iBridge Studio.app`를 실행하면 됩니다. 앱 안의 `Receiver` 탭에서 `Start Receiver on This Mac`을 누릅니다.

## 권한

MacBook Sender 쪽:

- Screen Recording: 화면 캡처 필요
- Accessibility: 키보드/마우스 입력 주입, 창 복구 필요

iMac Receiver 쪽:

- Accessibility: receiver 표면의 pointer/key event capture 안정화에 필요할 수 있음
- Local Network: macOS가 네트워크 접근 권한을 묻는 경우 허용

권한을 바꾼 뒤에는 앱과 sender/receiver 프로세스를 다시 시작하는 것이 안전합니다.

## 기본 사용 흐름

### 1. BetterDisplay에서 virtual display 생성

MacBook에서 BetterDisplay virtual screen을 만들고 이름을 iMac과 맞춥니다.

예시:

- `iMac 27inch 2015`
- `iMac 21.5inch 2017`

macOS Displays에서 MacBook 내장 화면 옆에 extended display로 배치합니다.

### 2. iMac에서 Receiver 실행

iMac에서 `iBridge Studio.app` 실행:

1. `Receiver` 탭 선택
2. Port가 `48320`인지 확인
3. `Start Receiver on This Mac`
4. Receiver window가 전체 화면으로 떠 있는지 확인

### 3. MacBook에서 Sender 실행

MacBook에서 `iBridge Studio.app` 실행:

1. `Sender` 탭 선택
2. `Add Sender`에서 iMac 모델 선택
3. Receiver IP 입력
4. Display 이름이 BetterDisplay virtual display 이름과 같은지 확인
5. Signal / Bitrate / Duration 프리셋 확인
6. `Start Sender`

앱은 마지막 탭, receiver 설정, sender session 목록과 세션별 값을 저장합니다. 다음에 앱을 다시 열면 마지막 구성이 복원되므로 매번 모델을 다시 고를 필요가 없습니다.

## 두 iMac 동시 연결 권장 구성

추가 LAN 허브를 사기 전에는 다음 구성이 가장 현실적입니다.

```text
MacBook Pro Ethernet -> 2015 27-inch iMac Ethernet
MacBook Pro Thunderbolt / USB-C -> 2017 21.5-inch iMac Thunderbolt Bridge
```

권장 수동 IP:

```text
MacBook Ethernet:          10.10.15.1
2015 iMac Ethernet:        10.10.15.2

MacBook Thunderbolt Bridge: 10.10.17.1
2017 iMac Thunderbolt:      10.10.17.2

Subnet mask: 255.255.255.0
Router/DNS: blank
```

테스트 순서:

1. 2015 iMac 단독 Receiver/Sender 확인
2. 2017 iMac Thunderbolt Bridge 단독 Receiver/Sender 확인
3. MacBook에서 Sender session 두 개 추가
4. 각 iMac에서 Receiver 실행
5. MacBook에서 두 Sender를 순서대로 시작
6. 마우스 전환, 키보드 입력, copy/paste, 프레임 안정성 확인

## 입력 릴레이

iBridge Studio Receiver는 receiver window 위의 pointer/key 이벤트를 Sender로 보내고, Sender는 MacBook의 captured virtual display 좌표에 `CGEvent`로 재주입합니다.

현재 지원:

- mouse move / drag / click
- key down / key up
- modifier flags: Command, Shift, Option, Control, Caps Lock
- `Cmd+Shift+4` 같은 modifier shortcut 전달
- Caps Lock 기반 입력 소스 전환 이벤트 전달

주의할 점:

- iBridge Studio의 입력 릴레이는 MacBook source OS에 이벤트를 주입합니다. 즉 screenshot, 한영 전환, 단축키는 MacBook 쪽 설정과 권한의 영향을 받습니다.
- Apple Universal Control / Link Keyboard and Mouse가 iMac으로 키보드 포커스를 넘겨도, 일부 시스템 전역 키는 iMac 로컬 macOS가 먼저 처리할 수 있습니다.
- Caps Lock 한영 전환은 MacBook의 Keyboard 입력 소스 설정에서 Caps Lock 전환이 활성화되어 있어야 의도대로 동작합니다.

## 창 복구

virtual display에 Terminal/브라우저 창이 넘어가 있고 receiver를 닫아버리면, 창이 MacBook 내장 화면에 보이지 않을 수 있습니다.

`iBridge Studio`의 `Restore Windows`를 누르면 일반 앱 창을 MacBook 화면 좌표로 다시 이동시킵니다. 이 기능은 Accessibility 권한이 필요합니다.

## 깨끗한 재설치 테스트

GitHub에 최신 branch를 push한 뒤 MacBook에서 앱/빌드 산출물을 지우고 깨끗하게 다시 받을 수 있습니다.

```bash
cd /Users/gabriel/Development
rm -rf iBridge-Studio
git clone https://github.com/oosuhada/iBridge-Studio.git
cd iBridge-Studio
git checkout deploy
scripts/package_macos_alpha.sh
open "dist/iBridge-Studio-0.1.0-alpha/iBridge Studio.app"
```

iMac은 zip을 받아서 같은 앱을 실행하고 Receiver 탭만 쓰면 됩니다.

## 개발 검증 명령

```bash
swift build --package-path apps/primary-macos -c release
swift build --package-path apps/receiver-macos -c release
swift build --package-path apps/controller-macos -c release
python3 apps/shared-protocol/test_protocol_v0.py
scripts/package_macos_alpha.sh
codesign --verify --deep --strict "dist/iBridge-Studio-0.1.0-alpha/iBridge Studio.app"
codesign --verify --deep --strict "dist/iBridge-Studio-0.1.0-alpha/iBridge Studio Receiver.app"
```

## 현재 한계

- 아직 notarized 상용 배포판은 아닙니다.
- 5K60 완전 네이티브 품질은 아직 목표치이며, 실제 사용은 모델별 sweet spot을 찾아야 합니다.
- 1GbE에서는 4K/5K 고 bitrate가 가능해도 모든 장면에서 완전한 60Hz를 보장하지 않습니다.
- 키보드/마우스 공유는 macOS 권한, Universal Control 포커스, 입력 소스 설정의 영향을 받습니다.
- 두 iMac 동시 연결은 Ethernet + Thunderbolt Bridge 또는 USB Ethernet 2개/switch 구성이 필요합니다.

## 레포 구조

```text
apps/
  controller-macos/   iBridge Studio SwiftUI app
  primary-macos/      MacBook sender / capture / encode / input injection
  receiver-macos/     macOS receiver / decode / fullscreen / input capture
  receiver-windows/   Windows receiver scaffold
  shared-protocol/    protocol tests
scripts/
  package_macos_alpha.sh
  start_ibridge_virtual_capture.sh
  start_2015_imac_receiver_macos.sh
  start_2017_imac_receiver_macos.sh
docs/
  development-only implementation notes, benchmark reports, release notes
benchmarks/
  development-only measurement outputs
```
