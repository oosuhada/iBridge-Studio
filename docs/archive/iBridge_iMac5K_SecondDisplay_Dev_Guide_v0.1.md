# iMac 5K (Late 2015) 보조 디스플레이 오픈소스 프로젝트
## 소프트웨어 개발 목표 및 설계 가이드 v0.1

> **문서 목적**  
> 이 문서는 `M1/M시리즈 MacBook → 2015년형 27인치 Retina 5K iMac`을 **하드웨어 개조 없이 보조 디스플레이처럼 활용하기 위한 오픈소스 소프트웨어 개발 목표/아키텍처/검증 계획**을 정리한 초안이다.  
>
> **중요 원칙**  
> Luna Display, Duet Display, AirPlay, Apple 비공개 프로토콜, 동글 펌웨어, 앱 바이너리를 리버스엔지니어링하지 않는다.  
> 공개 문서, 공개 API, 오픈소스 선례, 독립 구현만 기반으로 한다.  
>
> **작성 기준**  
> - 사용자가 첨부한 `iMac5K_SecondDisplay_Dev_Guide.md`의 구조와 가설을 참고했다.  
> - 추가 온라인 검색 결과를 기반으로 확정 사실/추정/검증 필요 사항을 구분했다.  
> - 출처는 클릭형 각주가 아니라 `[내용 출처 : URL]` 형태로 문서 안에 직접 기재했다.

---

# 0. 현재 상태 진단

## 0.1 현재 보유 하드웨어

- **Primary 후보**
  - M1/M시리즈 MacBook Air 또는 MacBook Pro
  - USB-C/Thunderbolt 포트 수가 제한적임
  - MacBook Air는 충전까지 USB-C 포트 하나를 사용해야 하므로 포트 점유가 특히 중요함

- **Secondary 후보**
  - iMac 27-inch Retina 5K Late 2015
  - Radeon R9 M380 구성으로 판단
  - 5120×2880 Retina 5K 패널
  - USB 3 포트 4개
  - Thunderbolt 2 포트 2개
  - Gigabit Ethernet 포트 1개
  - 현재 부팅 OS는 **Windows가 설치된 상태**

Apple 공식 스펙 기준으로 iMac Retina 5K 27-inch Late 2015는 USB 3 포트 4개, Thunderbolt 2 포트 2개, Mini DisplayPort 출력, 10/100/1000BASE-T Gigabit Ethernet을 제공한다. [내용 출처 : https://support.apple.com/en-us/112035]

한국어 Apple 지원 페이지에도 동일하게 USB 3 포트 4개, Thunderbolt 2 포트 2개, Mini DisplayPort 출력, Gigabit Ethernet이 명시되어 있다. [내용 출처 : https://support.apple.com/ko-kr/112035]

## 0.2 중요한 현실 조건: iMac은 현재 Windows 상태

기존 초안은 iMac을 macOS Monterey + OCLP 환경으로 전제했다. 그러나 현재 실제 iMac은 Windows로 부팅되고 있다.

따라서 개발 목표를 다음처럼 수정한다.

### 우선순위 1: Windows Receiver 우선 지원

현재 iMac을 다시 macOS로 되돌리는 수고를 줄이기 위해, 초기 MVP는 다음 구조를 우선한다.

```text
MacBook macOS Primary App
→ 가상 디스플레이 생성
→ 화면 캡처
→ 인코딩
→ LAN 또는 Thunderbolt Bridge/IP 네트워크 전송
→ iMac Windows Receiver App
→ 하드웨어 디코딩/전체화면 표시
```

이 구조의 장점:

- iMac에 macOS를 다시 설치하지 않아도 됨
- Windows Receiver는 Direct3D/DXGI/Media Foundation 등 저수준 그래픽 API 활용 가능
- iMac의 GPU/디스플레이를 Windows 전체화면 앱으로 그대로 활용 가능
- 사용자가 바로 테스트 가능

Microsoft의 Desktop Duplication API는 앱이 데스크톱 이미지를 프레임 단위로 접근할 수 있게 하며, DXGI surface 형태로 업데이트를 받기 때문에 GPU 처리에 활용할 수 있다. 본 프로젝트의 iMac 쪽은 주로 수신/렌더링이지만, Windows 그래픽 파이프라인 검토 기준으로 중요하다. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/desktop-dup-api]

Windows Media Foundation H.264 decoder는 Baseline/Main/High 프로파일을 지원하는 Media Foundation Transform이며, Windows 쪽 수신 앱에서 H.264 디코딩 경로의 기준이 된다. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]

Media Foundation 기반 하드웨어 디코딩은 DXVA/D3D manager를 통해 하드웨어 가속을 사용할 수 있다. [내용 출처 : https://learn.microsoft.com/en-us/gaming/gdk/docs/gdk-dev/overviews/mediafoundation-decode]

### 우선순위 2: macOS Receiver는 보조 경로로 유지

iMac에 macOS를 설치하는 장점이 명확한 경우에는 macOS Receiver도 유지한다.

macOS Receiver의 장점:

- VideoToolbox/Metal/Bonjour 등 Apple 생태계 API를 양쪽에서 일관되게 사용할 수 있음
- OCLP/AirPlay Receiver 실험 가능
- Luna Display와 더 유사한 Mac-to-Mac 구조 실험 가능

macOS Receiver의 단점:

- 현재 Windows 상태에서 macOS 설치/OCLP 구성까지 추가 작업 필요
- 구형 iMac에서 최신 macOS는 성능/안정성 리스크 존재
- AirPlay/OCLP는 1080p 제한 사례가 많아 5K 목적에는 부적합할 수 있음

---

# 1. 프로젝트 배경과 핵심 문제

## 1.1 해결하려는 문제

2015년형 27인치 Retina 5K iMac은 현재 기준으로도 패널 품질이 매우 좋지만, 최신 MacBook의 외장 디스플레이로 직접 쓰기 어렵다.

주요 문제는 다음과 같다.

1. 2015 5K iMac은 Target Display Mode 대상이 아니다.
2. Thunderbolt 2 포트가 있지만 디스플레이 입력 경로가 아니라 데이터/출력 포트다.
3. AirPlay/OCLP 방식은 가능하더라도 1080p 또는 낮은 해상도/지연 문제가 보고된다.
4. Luna Display는 비파괴 상용 솔루션이지만 국내 구매성, 가격, USB-C 포트 점유, 5K 45Hz 제한이 있다.
5. 하드웨어 개조는 가장 확실하지만 iMac의 컴퓨터 기능을 사실상 포기해야 한다.
6. 사용자는 45Hz/30Hz 이하에서 마우스 움직임과 UI 반응성이 불편하다고 느낀다.

## 1.2 이 프로젝트의 목표

이 프로젝트는 “진짜 Studio Display 대체품”을 바로 만드는 것이 아니다.

목표는 다음이다.

> 2015 27인치 5K iMac을 분해하지 않고, MacBook의 보조 디스플레이처럼 활용할 수 있는 네트워크 기반 오픈소스 디스플레이 시스템을 만든다.

## 1.3 프로젝트 이름 후보

- `iMacCast`
- `iBridge`
- `OldMacDisplay`
- `iMac5KBridge`
- `RetinaRelay`

이 문서에서는 가칭으로 **iBridge**를 사용한다.

---

# 2. 기술적으로 확정된 사실과 수정된 판단

## 2.1 iMac 2015 5K의 Thunderbolt 2는 패널 입력이 아니다

Apple 공식 스펙에서 iMac 2015 5K의 Thunderbolt 2 포트는 Mini DisplayPort **output** 및 HDMI/DVI/VGA/dual-link DVI 출력 어댑터 지원으로 설명된다. 즉 이 포트가 MacBook의 DisplayPort 신호를 받아 iMac 내장 패널에 직접 출력하는 입력 포트라고 보기 어렵다. [내용 출처 : https://support.apple.com/en-us/112035]

따라서 `MacBook USB-C → TB3-to-TB2 어댑터 → iMac TB2` 연결은 진짜 디스플레이 입력이 아니라 **두 컴퓨터 간 고속 데이터 연결**로 다뤄야 한다.

## 2.2 Thunderbolt Bridge는 데이터 경로로는 가능하다

Apple은 두 대의 Thunderbolt-equipped Mac을 Thunderbolt 케이블로 연결한 뒤 IP 통신을 할 수 있다고 설명한다. 시스템 설정의 Network에서 Thunderbolt Bridge 서비스를 사용할 수 있다. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

따라서 TB2는 다음 용도로 유효하다.

```text
MacBook 화면 스트림 데이터
→ Thunderbolt Bridge/IP
→ iMac Receiver 앱
```

그러나 이것은 다음과 다르다.

```text
MacBook GPU DisplayPort 신호
→ iMac 패널 입력
```

## 2.3 Apple TB3-to-TB2 어댑터의 전원 관련 정정

이전 설명에서 “Apple TB3-to-TB2 어댑터는 충전을 제공하지 않는다”라고 단순화했지만, 더 정확하게는 다음과 같이 정리해야 한다.

Apple 공식 문서에 따르면 해당 어댑터는 Thunderbolt/Thunderbolt 2 장치와 최대 10Gbps 또는 20Gbps 데이터 전송을 지원한다. 또한 Apple Thunderbolt Display와 사용할 때는 디스플레이가 어댑터를 통해 전원을 공급하지 않기 때문에 별도 전원이 필요하다고 설명한다. [내용 출처 : https://support.apple.com/en-us/111753]

Apple Store 상품 설명도 Apple Thunderbolt Display 사용 시 디스플레이가 어댑터를 통해 전원을 공급하지 않기 때문에 전원이 필요하다고 설명한다. [내용 출처 : https://www.apple.com/shop/product/myh93am/a/thunderbolt-3-usb%E2%80%91c-to-thunderbolt-2-adapter]

이 말은 다음을 의미한다.

- 어댑터가 MacBook 충전기 역할을 하는 것은 아니다.
- 그러나 “iMac TB2 포트가 전혀 전원 출력을 못 한다”는 의미로 단정하면 안 된다.
- Thunderbolt 1/2 규격 자체는 버스파워를 일부 제공할 수 있다.
- 다만 MacBook을 충전하거나 유지할 정도의 USB-C PD 전원 공급과는 별개의 문제다.

Thunderbolt 1/2는 버스파워로 최대 약 10W를 제공할 수 있다는 기술 자료가 있다. [내용 출처 : https://global-sei.com/ewp/E/thunderbolt/]

Intel Thunderbolt technology brief도 active electrical-only Thunderbolt cable은 bus-powered device에 최대 10W 전원을 제공할 수 있다고 설명한다. [내용 출처 : https://www.intel.com/content/dam/doc/technology-brief/thunderbolt-technology-brief.pdf]

OWC의 Thunderbolt 호환성 설명도 Thunderbolt 1/2는 최대 10W bus power, Thunderbolt 3 이후는 최소 15W라고 정리한다. [내용 출처 : https://eshop.macsales.com/blog/96867-the-simple-guide-to-thunderbolt-forwards-and-backwards-compatibility/]

### 전원 공급 관련 현재 판단

사용자 관찰:

- iMac USB 3.0 단자와 MacBook USB-C 단자를 연결하면 MacBook 배터리 상태가 “전원 케이블 연결됨”처럼 바뀌는 현상이 있음
- 충전 전력은 낮아서 실제 충전은 되지 않거나 매우 느림

이 관찰은 합리적이다. USB-A 포트가 5V 전원을 제공하면 MacBook이 저전력 소스 연결로 감지할 수 있다. 그러나 MacBook Air/Pro의 실제 작업 유지 전력과는 차이가 크다.

USB 3.0/3.1 기본 전력은 5V 900mA, 즉 약 4.5W 수준이라는 자료가 있다. [내용 출처 : https://tripplite.eaton.com/products/usb-charging]

USB-C Power Delivery를 지원하는 전원 어댑터나 디스플레이가 MacBook 충전에 적합하며, Apple은 Mac 노트북 권장 전원 어댑터 이상의 와트 수를 제공하는 어댑터/디스플레이 사용을 안내한다. [내용 출처 : https://support.apple.com/en-us/109509]

따라서 현실적 판단은 다음이다.

| 경로 | 기대 가능성 | 설명 |
|---|---:|---|
| iMac USB-A → MacBook USB-C | 낮음~제한적 | 전원 연결 인식/방전 완화 가능성. 실제 작업 유지 충전은 어려움 |
| iMac TB2 → Apple TB3-to-TB2 → MacBook USB-C | 매우 낮음 | 데이터 연결 가능. MacBook 충전 경로로는 부적합할 가능성이 큼 |
| iMac TB2 bus power | 실험 필요 | 최대 10W급 bus power 자료 존재. USB-C PD와 다름 |
| 하드웨어 개조 USB-C PD 보드 | 높음 | 개조 모니터에서 “케이블 하나로 화면+충전” 가능성이 생기는 이유 |

### 개발 가이드 반영

전원 공급은 필수 기능이 아니라 **실험/진단 기능**으로 넣는다.

앱은 다음을 표시할 수 있다.

```text
Power Source: Battery / USB Low Power / USB PD / Unknown
Detected AC Charger Wattage: 0W / 5W / 10W / 30W / ...
Battery Drain Rate: -4.2W
```

MacBook 쪽에서는 `System Information > Power` 또는 `ioreg`, `pmset` 계열 명령으로 전원 상태를 확인할 수 있다.

---

# 3. Luna Display 기술 분석: 복제 대상이 아니라 벤치마크 대상

## 3.1 Luna 동글 역할에 대한 가설

사용자의 판단처럼, “Luna 동글이 GPU에서 직접 프레임버퍼를 가져와 LIQUID 압축을 수행하는 고성능 하드웨어 가속 칩”이라는 설명은 과장일 가능성이 있다.

그 이유:

1. Luna 동글은 Primary 컴퓨터에 꽂힌다.
2. Secondary iMac/iPad 쪽은 앱만 설치해도 수신기로 동작한다.
3. 실제 데이터 연결은 Wi-Fi, Ethernet, USB, Thunderbolt 등 별도 경로가 사용된다.
4. Luna 공식 문서도 Mac-to-Mac에서 Wi-Fi/Ethernet/USB/Thunderbolt 연결을 지원한다고 설명한다. [내용 출처 : https://support.astropad.com/en/articles/11835375-what-are-the-system-requirements-for-luna-display]

따라서 동글 역할은 다음처럼 보는 것이 더 현실적이다.

- macOS에 외장 디스플레이가 연결된 것처럼 보이게 하는 하드웨어 트리거
- EDID/DisplayPort 계열 디스플레이 존재 신호 제공 가능성
- 라이선스/페어링 키
- Luna 앱이 가상 디스플레이 스트림을 시작할 수 있게 만드는 하드웨어 토큰

다만 이것은 공개 정보 기반의 가설이다. 동글 펌웨어를 분석하지 않는다.

## 3.2 Luna의 공개적으로 확인되는 한계

Luna 5.1 발표 글은 Mac-to-Mac 5K 지원을 설명하면서 **Mac에서는 5K @ 45Hz, 4K @ 60Hz** 제한을 명시한다. [내용 출처 : https://astropad.com/blog/luna-display-5-1/]

Luna 공식 FAQ는 5K iMac을 Retina 해상도로 쓰려면 USB-C Luna Display가 필요하고, 다른 Luna 유닛은 4K 이하로 제한될 수 있다고 설명한다. [내용 출처 : https://support.astropad.com/en/articles/11835385-does-luna-display-support-4k-and-5k-retina-resolutions]

Luna 하드웨어는 허브/어댑터/독 뒤에 연결하는 것이 공식 지원되지 않는다. USB-C Luna는 DisplayPort Alt Mode가 필요하고, 많은 허브/어댑터가 이를 전달하지 못한다는 설명이 있다. [내용 출처 : https://support.astropad.com/en/articles/11835378-can-i-plug-luna-display-into-an-adapter-or-hub]

## 3.3 Luna를 분석해야 하는 이유

Luna는 현재 시장에서 이 문제를 가장 잘 구현한 상용 제품이다.

따라서 분석할 대상은 다음이다.

- UX
- 연결 방식
- 해상도/주사율 타협
- 지연 체감
- 유선 연결의 효과
- 5K 45Hz와 4K 60Hz의 사용성 차이
- 동글 없이 가상 디스플레이를 생성할 수 있는지

분석하지 말아야 할 대상:

- Luna 앱 바이너리
- Luna 동글 펌웨어
- Luna 네트워크 프로토콜
- LIQUID 압축 기술 내부
- 인증/라이선스 우회

---

# 4. 화질 목표 Plan A / Plan B / Plan C

## 4.1 Plan A — 5K 60Hz 무압축 / 저지연

### 목표

- 5120×2880
- 60Hz
- 무압축 또는 사실상 무손실
- 마우스/스크롤 지연 최소
- 외장모니터와 거의 동일한 사용감

### 현실성

**소프트웨어 스트리밍 방식으로는 거의 불가능에 가깝다.**

단순 계산:

```text
5120 × 2880 × 60fps × 24bit
≈ 21.2Gbps
```

여기에 전송 오버헤드, 색상 포맷, 동기화, 프레임 처리 비용이 추가된다.

Thunderbolt 2는 최대 20Gbps급으로 설명되지만, 여기서 TB2는 패널 입력이 아니라 IP 데이터 통신 경로다. [내용 출처 : https://support.apple.com/en-us/111753]

즉 Plan A는 소프트웨어 개발 목표가 아니라 **하드웨어 개조와 비교하기 위한 이론상 상한선**으로 둔다.

### 결론

- MVP 목표에서 제외
- 벤치마크/문서화 목표로만 유지
- 5K 60Hz 무압축이 필요하면 컨트롤러 보드 개조가 현실적

---

## 4.2 Plan B — 5K 60Hz 실사용급

### 목표

- 5120×2880
- 60fps 표시 목표
- HEVC/H.265 또는 H.264 저지연 인코딩
- 텍스트/코딩/브라우징이 가능할 정도의 품질
- Thunderbolt Bridge 또는 고속 유선망 우선

### 현실성

**장기 연구 목표.**

Apple VideoToolbox는 하드웨어 인코더/디코더에 직접 접근할 수 있는 저수준 프레임워크다. [내용 출처 : https://developer.apple.com/documentation/videotoolbox]

Apple WWDC 세션은 VideoToolbox를 이용한 low-delay H.264 hardware encoding을 설명한다. [내용 출처 : https://developer.apple.com/kr/videos/play/wwdc2021/10158/]

5K 60Hz 실사용급을 위해 필요한 최적화:

1. Apple Silicon MacBook에서 하드웨어 인코딩
2. Windows iMac Receiver에서 Media Foundation/DXVA 또는 FFmpeg hardware acceleration 디코딩
3. Thunderbolt Bridge 우선
4. 정지 화면 품질 우선
5. 화면 변화량 기반 adaptive bitrate
6. 마우스 커서 별도 전송/로컬 렌더링
7. 변경 영역 기반 전송 또는 intra-refresh 최적화
8. 텍스트/코딩용 sharpening/scaling filter

### 성공 기준

- 5120×2880 모드가 존재
- 실제 표시 FPS 50~60 근접
- 10~30분 사용 시 안정성 확보
- 정적 코딩 화면에서 글자 뭉개짐이 심하지 않음
- 빠른 스크롤/영상에서는 품질 저하 허용

---

## 4.3 Plan C — 5K 패널 업스케일링에 유리한 60Hz 타협 모드

사용자가 가장 중요하게 느끼는 것은 “60Hz 사용감”이다. 따라서 Plan C가 MVP에 가장 적합하다.

### 핵심 아이디어

5K 패널은 5120×2880이다.  
이 패널에 2560×1440 영상을 표시하면 가로/세로 각각 정확히 2배 정수 스케일링이 가능하다.

```text
2560 × 2 = 5120
1440 × 2 = 2880
```

따라서 4K 3840×2160을 5K로 비정수 업스케일하는 것보다, 2560×1440 정수 스케일링이 텍스트 에지/선명도 측면에서 더 유리할 가능성이 있다.

### 후보 해상도

| 모드 | 해상도 | FPS | 장점 | 단점 |
|---|---:|---:|---|---|
| C1 | 2560×1440 | 60 | 5K에 2배 정수 스케일링. 전송량 낮음. UI 크기 자연스러움 | 정보량은 QHD |
| C2 | 3200×1800 | 60 | QHD보다 넓고 5K보다 가벼움 | 비정수 스케일링 |
| C3 | 3840×2160 | 60 | 4K 표준. 하드웨어 인코딩/디코딩 최적화 유리 | 5K 패널에 1.333배 비정수 스케일 |
| C4 | 4096×2304 | 60 | 5K에 더 가까움 | 인코딩 부담 증가, 비정수 스케일 |
| C5 | 5120×2880 | 45~60 | 패널 원해상도 | 45Hz 또는 높은 지연/압축 가능성 |

### MVP 우선순위

1. **2560×1440 @ 60Hz / 정수 업스케일 모드**
2. 3840×2160 @ 60Hz / 4K 호환 모드
3. 3200×1800 @ 60Hz / 균형 모드
4. 5120×2880 @ 45Hz / Luna 비교 모드
5. 5120×2880 @ 60Hz / 연구 모드

---

# 5. 운영체제 전략: Windows Receiver First

## 5.1 왜 Windows Receiver를 먼저 해야 하는가

현재 iMac이 Windows로 부팅되고 있기 때문에, 사용자가 macOS 설치/OCLP 작업을 감당하기 전에 실제 가능성을 테스트하려면 Windows Receiver가 가장 현실적이다.

초기 MVP는 다음처럼 구성한다.

```text
MacBook macOS Primary
- 가상 디스플레이 생성
- ScreenCaptureKit 또는 CGDisplayStream으로 캡처
- VideoToolbox로 인코딩
- LAN/TB Bridge로 전송

iMac Windows Receiver
- UDP/TCP/WebRTC 수신
- Media Foundation 또는 FFmpeg로 디코딩
- Direct3D/SDL/Qt로 전체화면 렌더링
```

## 5.2 Windows Receiver 기술 후보

### Media Foundation + Direct3D 11

장점:

- Windows 기본 미디어 프레임워크
- H.264 decoder 공식 지원
- DXVA 기반 하드웨어 디코딩 가능
- Direct3D 렌더링과 결합 가능

출처:

- H.264 Video Decoder 공식 문서 [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]
- Media Foundation 하드웨어 디코딩/DXVA 설명 [내용 출처 : https://learn.microsoft.com/en-us/gaming/gdk/docs/gdk-dev/overviews/mediafoundation-decode]

### FFmpeg + D3D11VA/DXVA2

장점:

- H.264/HEVC/AV1 등 코덱 실험이 쉬움
- 크로스플랫폼 가능
- 빠른 PoC 가능

FFmpeg는 다양한 하드웨어 가속 디코딩/인코딩을 지원한다. [내용 출처 : https://trac.ffmpeg.org/wiki/HWAccelIntro]

### SDL2 / Qt / GLFW 기반 렌더링

SDL2는 오디오, 키보드, 마우스, 그래픽 하드웨어에 저수준 접근을 제공하는 크로스플랫폼 개발 라이브러리다. [내용 출처 : https://wiki.libsdl.org/SDL2/Introduction]

장점:

- Windows/macOS 공통 Receiver UI 구현 가능
- 전체화면 렌더링 구현이 쉬움
- 초기 PoC에 적합

단점:

- 초저지연/색관리/프레임 타이밍은 직접 최적화 필요

## 5.3 macOS Receiver로 넘어갈 조건

다음 조건 중 하나가 충족되면 macOS Receiver를 병행한다.

- Windows Receiver에서 색/프레임 타이밍/디코딩 문제가 심함
- Mac-to-Mac Thunderbolt Bridge/Bonjour UX가 더 편리함
- OCLP 없이 설치 가능한 macOS 버전에서 안정적임
- VideoToolbox/Metal이 Windows보다 안정적임
- AirPlay/OCLP/FeatureUnlock 실험도 함께 하고 싶음

---

# 6. Primary MacBook 쪽: 가상 디스플레이 트리거

## 6.1 프로젝트의 핵심 난관

화면을 iMac에 띄우는 것 자체는 어렵지 않다.  
어려운 것은 MacBook macOS가 “보조 디스플레이가 연결됐다”고 인식하게 만드는 것이다.

## 6.2 Luna 동글 없는 접근

### 접근 A: CGVirtualDisplay 기반 소프트웨어 가상 디스플레이

사용자 첨부 문서에서 언급한 것처럼, `CGVirtualDisplay` 기반 오픈소스 선례가 있다.

FreeDisplay는 CGVirtualDisplay private API를 사용해 macOS에서 가상 디스플레이를 생성하는 오픈소스 프로젝트라고 설명한다. [내용 출처 : https://github.com/huberdf/FreeDisplay]

node-mac-virtual-display는 CoreGraphics/CoreDisplay API를 사용해 macOS 가상 디스플레이를 생성하는 Node native library라고 설명한다. [내용 출처 : https://github.com/enfp-dev-studio/node-mac-virtual-display]

Chromium 소스에도 테스트용 CGVirtualDisplay helper 구현이 존재한다. [내용 출처 : https://chromium.googlesource.com/chromium/src/%2B/d441ddf663e568fe8383d59a31e0dfacb9d9535b/ui/display/mac/test/virtual_display_mac_util.mm]

이 접근은 Luna 동글 없이 “가상 외장 디스플레이”를 만들 수 있는 가장 중요한 연구 경로다.

위험:

- private API 사용 시 macOS 업데이트로 차단 가능
- App Store 배포 불가 가능성
- 사용자에게 권한/보안 안내 필요

### 접근 B: dummy display adapter 활용

Luna 동글을 쓰지 않되, 일반 HDMI/USB-C dummy plug로 macOS에 외장 디스플레이를 만들고 그 화면을 캡처한다.

장점:

- macOS가 물리 디스플레이로 인식
- 드라이버 개발 난이도 낮음

단점:

- 추가 동글이 필요함
- 사용자의 “추가 동글 없이 허브로 해결” 목표와 충돌
- 5K dummy plug 안정성 불확실

### 접근 C: DriverKit/System Extension

장기적으로 가장 정석적인 방식이다.

Apple DriverKit은 드라이버를 사용자 공간에서 실행하는 현대적 프레임워크다. [내용 출처 : https://developer.apple.com/documentation/driverkit]

하지만 디스플레이 드라이버 영역은 난이도가 높고, 배포/권한/서명 이슈가 크다.

## 6.3 이 프로젝트의 초기 판단

초기에는 **CGVirtualDisplay / FreeDisplay 계열을 검증**한다.

목표:

- MacBook에 가상 디스플레이 생성
- 해상도 2560×1440 @ 60Hz
- 해상도 3840×2160 @ 60Hz
- 가능하면 5120×2880 @ 45/60Hz
- 해당 가상 디스플레이를 ScreenCaptureKit으로 캡처

---

# 7. 화면 캡처 / 인코딩 / 전송 / 디코딩 아키텍처

## 7.1 전체 구조

```text
[MacBook Primary]
  1. Virtual Display 생성
  2. ScreenCaptureKit/CGDisplayStream 캡처
  3. VideoToolbox H.264/HEVC 인코딩
  4. UDP/QUIC/WebRTC/TCP 전송
        ↓
[Network]
  Option A: Gigabit Ethernet
  Option B: Thunderbolt Bridge
        ↓
[iMac Receiver]
  Windows: Media Foundation / FFmpeg / D3D11
  macOS: VideoToolbox / Metal
  5. 하드웨어 디코딩
  6. 전체화면 렌더링
  7. 진단 HUD
```

## 7.2 화면 캡처

Primary MacBook에서 사용할 API 후보:

- ScreenCaptureKit
- CGDisplayStream
- Quartz Display Services

Apple ScreenCaptureKit은 화면/오디오 콘텐츠를 고성능으로 캡처하기 위한 프레임워크다. [내용 출처 : https://developer.apple.com/documentation/screencapturekit]

## 7.3 인코딩

기본 후보:

- H.264 low-latency
- HEVC/H.265 high-quality
- AV1은 장기 실험

Apple VideoToolbox는 하드웨어 인코더/디코더에 직접 접근할 수 있는 프레임워크다. [내용 출처 : https://developer.apple.com/documentation/videotoolbox]

## 7.4 전송

초기에는 구현 난이도 때문에 TCP도 가능하지만, 최종 목표는 UDP/QUIC/WebRTC 계열이다.

전송 계층 후보:

| 후보 | 장점 | 단점 |
|---|---|---|
| TCP | 구현 쉬움, 디버깅 쉬움 | head-of-line blocking, 지연 증가 |
| UDP raw | 최저 지연 | 패킷 손실/재정렬 직접 처리 |
| QUIC | UDP 기반, 흐름 제어/암호화 | 구현 복잡 |
| WebRTC | NAT/지연/미디어 전송 검증됨 | 튜닝 복잡, 오버헤드 |
| Moonlight/Sunshine 계열 참고 | 저지연 검증 | 직접 통합은 별도 검토 |

초기 PoC는 TCP로 시작하고, 성능 목표를 위해 UDP/QUIC로 확장한다.

## 7.5 Receiver 렌더링

### Windows Receiver

- Media Foundation 또는 FFmpeg로 디코딩
- Direct3D 11 texture로 표시
- SDL2/Qt/GLFW 중 하나로 전체화면 창 구성
- 진단 HUD overlay

### macOS Receiver

- VideoToolbox 디코딩
- Metal rendering
- AVSampleBufferDisplayLayer 실험
- Bonjour discovery

Bonjour는 로컬 네트워크에서 서비스 발견/게시를 쉽게 해주는 Apple의 zero-configuration networking 기술이다. [내용 출처 : https://developer.apple.com/bonjour/]

---

# 8. 연결 옵션 세부 설계

## 8.1 Option A — USB-C 허브 + LAN

```text
MacBook USB-C
→ USB-C 허브
  → PD 충전기
  → Gigabit Ethernet
→ LAN cable
→ iMac Ethernet
```

장점:

- MacBook Air의 충전 문제를 동시에 해결 가능
- 장비 가격 낮음
- Windows iMac에서도 바로 테스트 가능
- 2560×1440 @ 60Hz 실험에 적합

단점:

- 1GbE는 5K 60Hz 원본 전송에는 부족
- 강한 압축 필요
- 4K/5K 실험은 Thunderbolt Bridge보다 불리

Apple은 두 Mac을 Ethernet 케이블로 연결해 파일 공유/네트워크 게임 등에 사용할 수 있다고 설명한다. Mac에 Ethernet 포트가 없으면 USB Ethernet Adapter 또는 Thunderbolt to Gigabit Ethernet Adapter를 사용할 수 있다고 안내한다. [내용 출처 : https://support.apple.com/en-om/guide/mac-help/mchlp1413/mac]

## 8.2 Option B — MacBook USB-C/TB ↔ Apple TB3-to-TB2 ↔ iMac TB2

```text
MacBook USB-C/Thunderbolt
→ Apple Thunderbolt 3 to Thunderbolt 2 Adapter
→ Thunderbolt 2 cable
→ iMac Thunderbolt 2
→ Thunderbolt Bridge/IP
```

장점:

- 높은 대역폭
- 낮은 지연 가능성
- 4K60/5K 실험에 유리

단점:

- 어댑터/케이블 비용 발생
- MacBook Air 포트 점유
- 충전은 별도 필요
- Windows Boot Camp 환경에서 Thunderbolt Bridge/IP 설정이 macOS만큼 쉬운지 검증 필요

Apple은 TB3-to-TB2 어댑터가 Thunderbolt 2 장치와 최대 20Gbps 데이터 전송을 지원한다고 설명한다. [내용 출처 : https://support.apple.com/en-us/111753]

## 8.3 Option C — USB-A 데이터 연결

```text
MacBook USB-C
→ USB-C to USB-A cable
→ iMac USB-A
```

장점:

- 저렴
- 사용자가 이미 일부 케이블/허브를 보유할 수 있음
- 전원 연결 인식 테스트 가능

단점:

- 데이터 네트워크 구성 불확실
- USB tethering/사용자 정의 프로토콜 필요
- 전력은 매우 제한적
- 5K/4K 전송에는 부적합할 가능성 높음

초기 연구 우선순위는 낮다.

---

# 9. 전원 공급 실험 계획

## 9.1 목표 수정

기존 목표:  
“iMac 전원으로 MacBook을 유지 충전한다.”

수정된 목표:  
“iMac USB-A/TB2 연결이 MacBook 배터리 방전 속도를 얼마나 줄이는지 측정하고, 앱에 전원 상태 진단을 표시한다.”

## 9.2 실험 항목

### 실험 1: iMac USB-A → MacBook USB-C

측정:

- System Information > Power에서 AC Charger 인식 여부
- Wattage 표시 여부
- `pmset -g batt`
- 10분 단위 배터리 감소율
- idle / 코딩 / 스트리밍 수신 상태별 차이

예상:

- 전원 연결 인식 가능
- 충전량은 매우 낮음
- 작업 중 방전 속도 완화 수준

### 실험 2: iMac TB2 → Apple TB3-to-TB2 → MacBook USB-C

측정:

- MacBook이 전원 공급원으로 인식하는지
- Thunderbolt Bridge와 동시에 전원 상태가 바뀌는지
- System Information에 충전 와트가 표시되는지

예상:

- 데이터 연결은 가능
- MacBook 충전은 어려울 가능성 높음
- TB2 bus power는 peripheral 전원용이지 USB-C PD host charging과 다름

### 실험 3: PD 허브 병행

가장 현실적인 실사용 구성:

```text
MacBook USB-C 1: 가상 디스플레이 트리거 또는 필요 장치
MacBook USB-C 2: PD + LAN 허브
  → 충전기
  → Ethernet
```

---

# 10. 품질 모드 설계

## Mode 1 — QHD Integer 60

- 해상도: 2560×1440
- FPS: 60
- 표시: iMac 5K 전체화면에서 2배 정수 업스케일
- 코덱: H.264 또는 HEVC
- 연결: LAN 가능
- 목표: MVP 기본 모드

## Mode 2 — 4K Balanced 60

- 해상도: 3840×2160
- FPS: 60
- 코덱: HEVC 우선
- 연결: LAN 상급 또는 TB Bridge
- 목표: QHD보다 선명한 균형 모드

## Mode 3 — 3200×1800 Balanced 60

- 해상도: 3200×1800
- FPS: 60
- 코덱: HEVC
- 연결: LAN/TB Bridge
- 목표: 4K보다 부담을 줄인 고해상도 모드

## Mode 4 — 5K 45

- 해상도: 5120×2880
- FPS: 45
- 코덱: HEVC
- 연결: TB Bridge 권장
- 목표: Luna 5K와 비교 가능한 실험 모드

Luna는 Mac에서 5K @ 45Hz 제한을 공식적으로 언급했다. [내용 출처 : https://astropad.com/blog/luna-display-5-1/]

## Mode 5 — 5K 60 Experimental

- 해상도: 5120×2880
- FPS: 60
- 코덱: HEVC low-latency
- 연결: TB Bridge 필수에 가까움
- 목표: 연구/벤치마크
- 실사용 보장 없음

---

# 11. 성능 진단 HUD

이 프로젝트는 체감 품질을 숨기면 안 된다. 앱은 반드시 진단 HUD를 제공해야 한다.

표시 항목:

```text
Resolution: 2560x1440 / 3840x2160 / 5120x2880
Target FPS: 60
Actual FPS: 59.4
Frame pacing: stable / unstable
Encode latency: 3.8ms
Network latency: 0.7ms
Decode latency: 4.1ms
Render latency: 1.6ms
End-to-end latency: 10.2ms
Bitrate: 85 Mbps
Packet loss: 0.02%
Dropped frames: 0.3%
Codec: H.264 / HEVC
Transport: Ethernet / Thunderbolt Bridge / Wi-Fi
Receiver OS: Windows / macOS
Scaling mode: integer 2x / bilinear / bicubic / Metal custom
Power source: Battery / Low Power USB / PD / Unknown
Battery drain rate: -3.2W
```

---

# 12. 개발 로드맵

## Phase 0 — 하드웨어/OS 진단

- [ ] iMac Windows 버전 확인
- [ ] iMac 디스플레이가 Windows에서 5120×2880으로 구동되는지 확인
- [ ] Radeon driver 상태 확인
- [ ] iMac Ethernet 속도 확인
- [ ] MacBook ↔ iMac LAN iperf3 측정
- [ ] MacBook ↔ iMac TB2 Bridge 가능 여부 측정
- [ ] USB-A 전원 인식/충전 와트 측정

## Phase 1 — MacBook 가상 디스플레이 검증

- [ ] FreeDisplay 또는 유사 CGVirtualDisplay PoC 실행
- [ ] 2560×1440 @ 60Hz 가상 디스플레이 생성
- [ ] 3840×2160 @ 60Hz 생성 가능 여부 확인
- [ ] 5120×2880 생성 가능 여부 확인
- [ ] macOS Display Settings에서 외장 디스플레이처럼 배열되는지 확인

## Phase 2 — Primary Capture/Encode Prototype

- [ ] ScreenCaptureKit으로 가상 디스플레이 캡처
- [ ] VideoToolbox H.264 인코딩
- [ ] VideoToolbox HEVC 인코딩
- [ ] 프레임 타임/인코딩 지연 측정
- [ ] 1440p60 안정성 확인

## Phase 3 — Windows Receiver MVP

- [ ] Windows Receiver 앱 생성
- [ ] TCP 수신부터 구현
- [ ] H.264 디코딩
- [ ] 전체화면 렌더링
- [ ] 1440p60 표시
- [ ] HUD 표시
- [ ] 키보드 단축키: 전체화면, 종료, 진단 표시 토글

## Phase 4 — 네트워크 최적화

- [ ] UDP transport 구현
- [ ] 패킷 loss/reorder 처리
- [ ] adaptive bitrate
- [ ] latency measurement
- [ ] LAN vs TB Bridge 비교

## Phase 5 — 품질 모드 확장

- [ ] 4K60 Balanced
- [ ] 3200×1800 60
- [ ] 5K45 Experimental
- [ ] 5K60 Experimental
- [ ] integer scaling 품질 비교

## Phase 6 — macOS Receiver 선택적 구현

- [ ] macOS Receiver 앱
- [ ] VideoToolbox decode
- [ ] Metal render
- [ ] Bonjour discovery
- [ ] Windows Receiver와 성능 비교

## Phase 7 — 오픈소스 배포

- [ ] README 한글/영문 작성
- [ ] 설치 가이드
- [ ] 성능표
- [ ] 지원 환경표
- [ ] 법적 주의사항
- [ ] Luna/Duet/AirPlay와의 차이점 명확화

---

# 13. 저장소 구조 초안

```text
retina-bridge/
├─ README.md
├─ docs/
│  ├─ iMac5K_SecondDisplay_Dev_Guide_v0.1.md
│  ├─ hardware-matrix.md
│  ├─ power-tests.md
│  ├─ transport-benchmarks.md
│  └─ legal-clean-room-policy.md
├─ apps/
│  ├─ mac-primary/
│  │  ├─ iBridgePrimary.xcodeproj
│  │  ├─ Sources/
│  │  │  ├─ VirtualDisplay/
│  │  │  ├─ Capture/
│  │  │  ├─ Encoder/
│  │  │  ├─ Transport/
│  │  │  └─ Diagnostics/
│  │  └─ README.md
│  ├─ win-receiver/
│  │  ├─ src/
│  │  │  ├─ decoder/
│  │  │  ├─ renderer/
│  │  │  ├─ transport/
│  │  │  └─ diagnostics/
│  │  └─ README.md
│  └─ mac-receiver/
│     ├─ iBridgeReceiver.xcodeproj
│     └─ README.md
├─ prototypes/
│  ├─ cgvirtualdisplay-test/
│  ├─ screencapturekit-test/
│  ├─ videotoolbox-encoder-test/
│  ├─ mediafoundation-receiver-test/
│  └─ iperf-scripts/
└─ scripts/
   ├─ measure-power-macos.sh
   ├─ measure-latency.py
   └─ setup-thunderbolt-bridge.md
```

---

# 14. Clean-room 정책

## 허용

- Apple/Microsoft 공개 문서 사용
- 공개 GitHub 오픈소스 프로젝트 참고
- 공개 API 사용
- 자체 프로토콜 설계
- 자체 인코딩/전송/렌더링 구현
- 공개 벤치마크 수행

## 금지

- Luna Display 바이너리 분석
- Luna 동글 펌웨어 dump
- Luna 프로토콜 패킷 분석
- 라이선스 우회
- AirPlay private protocol 우회/복제
- 상용 앱 UI/문구/로고 모방
- “Luna 호환” 주장

---

# 15. 핵심 리스크

| 리스크 | 영향 | 대응 |
|---|---:|---|
| CGVirtualDisplay private API 변경 | 높음 | FreeDisplay/BetterDisplay 계열 추적, fallback 제공 |
| Windows iMac HEVC 디코딩 성능 부족 | 중간~높음 | H.264 fallback, 1440p60 우선 |
| TB Bridge on Windows 구성 난이도 | 중간 | LAN 우선, TB는 고급 모드 |
| 5K60 품질 미달 | 높음 | Plan C를 MVP로 설정 |
| MacBook 전원 부족 | 중간 | PD 허브 권장, iMac 전원은 실험 항목 |
| 사용자 설치 난이도 | 중간 | installer, auto-discovery, diagnostics 제공 |
| 법적 리스크 | 높음 | clean-room 정책 준수 |

---

# 16. 현실성 판정표

| 목표 | 현실성 | 이 문서의 판단 |
|---|---:|---|
| 2560×1440 @ 60Hz LAN | 높음 | MVP 핵심 |
| 3840×2160 @ 60Hz LAN/TB | 중간 | 1차 확장 |
| 3200×1800 @ 60Hz | 중간 | 균형 실험 |
| 5120×2880 @ 45Hz TB | 낮음~중간 | Luna 비교 실험 |
| 5120×2880 @ 60Hz TB | 낮음 | 장기 연구 |
| 5K60 무압축 | 매우 낮음 | 소프트웨어 목표 제외 |
| 5K120 | 사실상 불가 | 제외 |
| iMac Windows Receiver | 높음 | 현재 상태 기준 우선 |
| iMac macOS Receiver | 중간 | 선택적 |
| iMac USB-A로 유지 충전 | 낮음 | 진단/실험 |
| iMac TB2로 유지 충전 | 매우 낮음 | 검증 필요 |
| 선 하나로 화면+충전 | 소프트웨어 불가 | 하드웨어 개조 영역 |

---

# 17. Codex / Claude Code 1차 프롬프트

```text
You are building an open-source project called iBridge.

Goal:
Create a clean-room, legal, open-source network display system that lets an Apple Silicon MacBook use a 27-inch 2015 Retina 5K iMac as a secondary display without hardware modification.

Important current-state requirement:
The iMac currently boots Windows, not macOS. Therefore the first receiver implementation should target Windows on the iMac. A macOS receiver can be implemented later only if it provides clear technical advantages.

Do not:
- reverse engineer Luna Display, Duet, AirPlay, private protocols, dongle firmware, or commercial app binaries
- claim Luna compatibility
- use private Apple protocols
- bypass licensing
- promise impossible 5K 60Hz lossless output

Primary device:
- Apple Silicon MacBook Air/Pro running macOS

Secondary device:
- iMac 27-inch Retina 5K Late 2015 running Windows first
- optional macOS receiver later

Initial product goals:
Plan C first:
- 2560x1440 @ 60fps
- integer 2x upscale on the iMac 5K panel
- low latency over Gigabit Ethernet
- diagnostics HUD

Plan B later:
- 3840x2160 @ 60fps
- 3200x1800 @ 60fps
- experimental 5120x2880 @ 45/60fps over Thunderbolt Bridge

Architecture:
MacBook Primary:
1. Create a virtual display using CGVirtualDisplay or existing open-source references such as FreeDisplay.
2. Capture the virtual display using ScreenCaptureKit.
3. Encode frames using VideoToolbox H.264 and HEVC.
4. Send frames over TCP first, then UDP/QUIC/WebRTC transport.
5. Show diagnostics for encode latency, bitrate, fps, dropped frames, network latency, and power state.

Windows iMac Receiver:
1. Receive stream over LAN.
2. Decode H.264 first using Media Foundation or FFmpeg.
3. Add HEVC decode later.
4. Render full-screen using Direct3D 11 or SDL2.
5. Implement diagnostics HUD.
6. Support fullscreen borderless mode on the iMac internal 5K panel.
7. Implement scaling modes: integer 2x, bilinear, bicubic, and shader-based sharpening.

Power experiments:
- Detect whether MacBook sees low-power USB from iMac USB-A.
- Detect charger wattage if visible through macOS power APIs.
- Do not promise charging from iMac.
- Log battery drain rate during LAN/TB/USB tests.

Deliverables:
1. Repository structure.
2. macOS primary prototype.
3. Windows receiver prototype.
4. TCP transport MVP.
5. 1440p60 test mode.
6. HUD with fps/latency/bitrate/power.
7. Benchmark scripts.
8. README with clean-room policy and limitations.
```

---

# 18. 다음 액션 아이템

## 즉시 할 일

1. iMac Windows에서 실제 디스플레이 해상도 5120×2880 확인
2. iMac Windows에서 GPU driver / DirectX / Media Foundation 상태 확인
3. MacBook ↔ iMac LAN 연결 후 `iperf3` 측정
4. MacBook ↔ iMac USB-A 연결 시 전원 인식/와트 표시 확인
5. Apple TB3-to-TB2 어댑터 + TB2 케이블이 있다면 Thunderbolt Bridge/IP 가능성 측정
6. MacBook에서 FreeDisplay/CGVirtualDisplay PoC 테스트

## 개발 시작점

가장 현실적인 첫 개발 목표:

```text
MacBook에서 2560×1440 @ 60Hz 가상 디스플레이 생성
→ 해당 화면을 캡처
→ H.264로 인코딩
→ TCP로 전송
→ Windows iMac Receiver에서 전체화면으로 표시
→ FPS/지연/비트레이트 HUD 표시
```

이게 성공하면 다음 순서로 확장한다.

1. HEVC
2. UDP/QUIC
3. 4K60
4. integer scaling 품질 개선
5. TB Bridge
6. 5K45/5K60 실험

---

# 19. 출처 목록

- iMac Retina 5K 27-inch Late 2015 Apple 공식 스펙  
  [내용 출처 : https://support.apple.com/en-us/112035]

- iMac Retina 5K 27형 2015년 후반 모델 Apple 한국어 스펙  
  [내용 출처 : https://support.apple.com/ko-kr/112035]

- Apple Thunderbolt 3 to Thunderbolt 2 Adapter 공식 문서  
  [내용 출처 : https://support.apple.com/en-us/111753]

- Apple Thunderbolt 3 to Thunderbolt 2 Adapter Apple Store 설명  
  [내용 출처 : https://www.apple.com/shop/product/myh93am/a/thunderbolt-3-usb%E2%80%91c-to-thunderbolt-2-adapter]

- Apple IP over Thunderbolt 공식 가이드  
  [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

- Apple Ethernet으로 두 Mac 연결하기  
  [내용 출처 : https://support.apple.com/en-om/guide/mac-help/mchlp1413/mac]

- Luna Display 시스템 요구사항  
  [내용 출처 : https://support.astropad.com/en/articles/11835375-what-are-the-system-requirements-for-luna-display]

- Luna Display 4K/5K 지원 FAQ  
  [내용 출처 : https://support.astropad.com/en/articles/11835385-does-luna-display-support-4k-and-5k-retina-resolutions]

- Luna Display 허브/어댑터 연결 FAQ  
  [내용 출처 : https://support.astropad.com/en/articles/11835378-can-i-plug-luna-display-into-an-adapter-or-hub]

- Luna Display 5.1 5K/4K 업데이트 글  
  [내용 출처 : https://astropad.com/blog/luna-display-5-1/]

- Apple ScreenCaptureKit 문서  
  [내용 출처 : https://developer.apple.com/documentation/screencapturekit]

- Apple VideoToolbox 문서  
  [내용 출처 : https://developer.apple.com/documentation/videotoolbox]

- Apple VideoToolbox low-latency H.264 WWDC 세션  
  [내용 출처 : https://developer.apple.com/kr/videos/play/wwdc2021/10158/]

- Apple Bonjour 문서  
  [내용 출처 : https://developer.apple.com/bonjour/]

- Apple DriverKit 문서  
  [내용 출처 : https://developer.apple.com/documentation/driverkit]

- FreeDisplay GitHub  
  [내용 출처 : https://github.com/huberdf/FreeDisplay]

- node-mac-virtual-display GitHub  
  [내용 출처 : https://github.com/enfp-dev-studio/node-mac-virtual-display]

- Chromium CGVirtualDisplay 테스트 코드  
  [내용 출처 : https://chromium.googlesource.com/chromium/src/%2B/d441ddf663e568fe8383d59a31e0dfacb9d9535b/ui/display/mac/test/virtual_display_mac_util.mm]

- Microsoft Desktop Duplication API  
  [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/direct3ddxgi/desktop-dup-api]

- Microsoft H.264 Video Decoder  
  [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]

- Microsoft Media Foundation hardware decode/DXVA 설명  
  [내용 출처 : https://learn.microsoft.com/en-us/gaming/gdk/docs/gdk-dev/overviews/mediafoundation-decode]

- SDL2 소개 문서  
  [내용 출처 : https://wiki.libsdl.org/SDL2/Introduction]

- FFmpeg Hardware Acceleration 개요  
  [내용 출처 : https://trac.ffmpeg.org/wiki/HWAccelIntro]

- USB 기본 전력 출력 설명  
  [내용 출처 : https://tripplite.eaton.com/products/usb-charging]

- Apple Mac 전원 어댑터/USB-C PD 충전 안내  
  [내용 출처 : https://support.apple.com/en-us/109509]

- Thunderbolt 2 버스파워 10W 설명  
  [내용 출처 : https://global-sei.com/ewp/E/thunderbolt/]

- Intel Thunderbolt technology brief  
  [내용 출처 : https://www.intel.com/content/dam/doc/technology-brief/thunderbolt-technology-brief.pdf]

- OWC Thunderbolt 1/2 bus power 설명  
  [내용 출처 : https://eshop.macsales.com/blog/96867-the-simple-guide-to-thunderbolt-forwards-and-backwards-compatibility/]

---

# 20. 변경 이력

## v0.1

- 사용자 첨부 `iMac5K_SecondDisplay_Dev_Guide.md` 구조 반영
- 현재 iMac이 Windows로 부팅된다는 조건 추가
- Windows Receiver 우선 전략 추가
- Apple TB3-to-TB2 전원 관련 설명 정정
- iMac USB-A/TB2 전원 공급 가능성을 “실험/진단 항목”으로 재분류
- Luna Display 기술 분석을 벤치마크/가설 중심으로 정리
- Plan A/B/C 화질 목표 재정의
- 개발 로드맵과 Codex/Claude Code 프롬프트 추가
