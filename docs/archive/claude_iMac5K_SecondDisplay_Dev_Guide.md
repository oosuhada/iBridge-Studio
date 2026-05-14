# iMac 5K (Late 2015) 보조 디스플레이 오픈소스 프로젝트
## 소프트웨어 개발 목표 및 설계 가이드 초안 v0.1

> **작성 기준**: 온라인 검색 및 GitHub 레퍼런스 기반. 추측성 내용 최소화.  
> **대상 환경**: M1 MacBook Air (Primary) + iMac 27인치 Late 2015 5K (Secondary, macOS Monterey + OCLP)

---

## 1. 프로젝트 배경 및 목표

### 1.1 해결하려는 문제 (Pain Point)

- iMac Late 2015 이후 모델은 Apple의 **Target Display Mode 공식 지원이 종료**됨
- Luna Display($130)는 유일한 상업적 해결책이지만 국내 구매 불편, 가격 부담 존재
- AirPlay/Miracast 기반 무선 방식은 **최대 1080p 한계**로 5K 패널 낭비
- 기존 오픈소스 시도들(FluffyDisplay, macos-virtual-display)은 **macOS Screen Sharing 품질 한계**에 묶임

### 1.2 핵심 가설 (검색 근거 있음)

**Luna Display 동글의 실제 역할:**

Luna 공식 문서와 기술 구조를 분석하면 동글은 크게 두 가지 역할을 함:

1. **가상 디스플레이 트리거**: macOS가 외장 모니터가 연결됐다고 인식하게 만드는 하드웨어 토큰
2. **앱 라이선스/페어링 키**: 소프트웨어 활성화 잠금장치

근거: iMac(Secondary) 쪽은 순수 소프트웨어 앱만으로 작동함. 즉 동글이 GPU에서 직접 압축을 수행하는 "하드웨어 가속 칩"이라는 설명은 마케팅 과장일 가능성이 높음.

**소프트웨어만으로 가상 디스플레이 생성이 가능함:**

- [`CGVirtualDisplay` Private API](https://github.com/KhaosT/CGVirtualDisplay): macOS CoreGraphics에 존재하는 비공개 API로 소프트웨어만으로 가상 디스플레이 생성 가능
- [FreeDisplay](https://github.com/huberdf/FreeDisplay): `CGVirtualDisplay private API`를 활용한 오픈소스 MIT 라이선스 프로젝트 실제 존재
- [node-mac-virtual-display](https://github.com/enfp-dev-studio/node-mac-virtual-display): CoreGraphics/CoreDisplay API로 가상 디스플레이 생성, 해상도/주사율 설정 가능
- [macos-virtual-display](https://github.com/miolini/macos-virtual-display): `IOFramebuffer` 서브클래스로 물리 모니터와 구분 불가능한 가상 디스플레이 커널 익스텐션 구현 선례

---

## 2. 화질 목표 (Plan A / B / C)

### Plan A — 5K 60Hz 무압축/저지연 (이상적 목표)
- **현실 가능성**: 낮음
- **이유**: 5K 60Hz 무압축 원시 데이터량 = 약 40Gbps 필요. Thunderbolt 2(20Gbps), LAN(1Gbps) 모두 대역폭 부족
- **결론**: 현재 하드웨어 환경에서 구현 불가. 향후 TB4/USB4 환경에서 재검토

### Plan B — 5K 60Hz 실사용급 (주목표)
- **현실 가능성**: 중간
- **방법**: GPU 하드웨어 인코딩(VideoToolbox H.265/HEVC) + 고비트레이트 유선 전송
- **근거**: macOS VideoToolbox는 M1에서 H.265 하드웨어 인코딩 지원. [WebRTC 코덱 비교 연구](https://www.webrtc-developers.com/comparison-of-webrtc-codecs-for-video-and-screen-sharing/)에서 H.265가 CPU 효율과 화질 모두 우수함을 확인
- **목표 지표**: 레이턴시 10ms 이하, 비트레이트 50~100Mbps, 해상도 5120×2880 or 스케일링

### Plan C — 5K 패널 최적 업스케일링 + 60Hz (현실적 타협)
- **현실 가능성**: 높음 ✅
- **핵심 인사이트**: 5K 패널(218ppi)에 저해상도를 입력해도 업스케일링 품질이 일반 4K 모니터보다 선명함
- **목표**: **2560×1440 (QHD) 60Hz** 입력 → 5K 패널 업스케일 표시
- **근거**: QHD는 5K의 정확히 절반 해상도(픽셀 2:1 매핑)라 업스케일링 아티팩트 최소화
- **전송 대역폭**: QHD 60Hz H.265 ≒ 15~30Mbps → LAN(1Gbps)으로 충분히 커버
- **레이턴시 목표**: 유선 기준 5ms 이하

---

## 3. 기술 아키텍처 설계

### 3.1 전체 구조

```
[M1 MacBook Air - Primary]
        |
  ┌─────────────────────────────┐
  │  ① CGVirtualDisplay API     │  ← 소프트웨어로 가상 외장 모니터 생성
  │  ② Quartz DisplayStream     │  ← GPU 프레임버퍼 캡처
  │  ③ VideoToolbox H.265 인코딩│  ← M1 하드웨어 가속 인코딩
  │  ④ 네트워크 전송 (UDP)      │  ← LAN or TB2 어댑터 경유
  └─────────────────────────────┘
        |
   [유선 네트워크]
   옵션A: USB-C 허브 → LAN케이블 → iMac
   옵션B: USB-C → TB3→TB2 어댑터 → TB2케이블 → iMac TB2 포트
        |
  ┌─────────────────────────────┐
  │  ⑤ 수신 디코딩 앱 (iMac)   │  ← VideoToolbox H.265 디코딩
  │  ⑥ 전체화면 렌더링          │  ← Metal/CoreGraphics
  └─────────────────────────────┘
[iMac 27인치 Late 2015 - Secondary]
```

### 3.2 핵심 컴포넌트별 구현 근거

#### ① 가상 디스플레이 생성 (Primary/MacBook 측)

| 방법 | 근거 | 제약 |
|------|------|------|
| `CGVirtualDisplay` Private API | [FreeDisplay](https://github.com/huberdf/FreeDisplay), [KhaosT 예제](https://github.com/KhaosT/CGVirtualDisplay) | Private API → App Store 배포 불가, 직접 배포만 가능 |
| `IOFramebuffer` kext | [macos-virtual-display](https://github.com/miolini/macos-virtual-display) | SIP 비활성화 필요, macOS 최신에서 kext 로딩 제한 |
| `CGVirtualDisplay` (공개 API) | macOS 12.4+에서 일부 공개됨 | 버전 제한 |

**권장**: `CGVirtualDisplay` Private API 활용. FreeDisplay, node-mac-virtual-display 모두 이 방법으로 실제 작동 확인됨.

**해상도 설정 목표**:
- Plan B: 5120×2880 @ 60Hz
- Plan C: 2560×1440 @ 60Hz (권장 시작점)

#### ② 프레임버퍼 캡처

| 방법 | 레이턴시 | 근거 |
|------|---------|------|
| `Quartz DisplayStream` | 낮음 | displayx 프로젝트에서 "high performance data capture" 용도로 사용 확인 |
| `ScreenCaptureKit` (macOS 12.3+) | 낮음 | Apple 공식 공개 API, GPU 가속 지원 |
| `CGDisplayStream` | 중간 | 구버전 호환 |

**권장**: `ScreenCaptureKit` (macOS 12.3+ 공식 지원, 하드웨어 가속)

#### ③ 인코딩

| 코덱 | CPU 효율 | 화질 | 근거 |
|------|---------|------|------|
| H.265/HEVC | ✅ 매우 높음 | ✅ 높음 | [WebRTC 코덱 비교](https://www.webrtc-developers.com/comparison-of-webrtc-codecs-for-video-and-screen-sharing/): "H265는 CPU 효율과 화질 모두 우수" |
| H.264 | 중간 | 중간 | M1 하드웨어 가속 지원 |
| AV1 | 낮은 CPU | ✅ 최고 | 저대역폭에서 최강이나 실시간 인코딩 부담 |

**권장**: `VideoToolbox` H.265 하드웨어 인코딩. M1은 하드웨어 H.265 인코더 내장.

#### ④ 네트워크 전송

| 프로토콜 | 레이턴시 | 근거 |
|---------|---------|------|
| UDP Raw | 최저 | Head-of-line blocking 없음 |
| WebRTC (UDP 기반) | 낮음 | [Multi.app 블로그](https://multi.app/blog/making-illegible-slow-webrtc-screenshare-legible-and-fast): jitter/playout delay 설정으로 sub-100ms 달성 가능 |
| TCP | 높음 | Head-of-line blocking 문제 |

**권장**: UDP 기반 커스텀 프로토콜 또는 WebRTC with tuned jitter settings

**macOS High Performance Screen Sharing 참고**:
[9to5Mac 가이드](https://9to5mac.com/2026/02/05/how-to-use-macos-high-performance-screen-sharing-for-lower-latency-and-better-color-video/)에 따르면:
- Apple은 단일 4K 디스플레이 기준 **유선 75Mbps 이상** 권장
- UDP 포트 5900~5902 사용
- Gigabit Ethernet으로 구성 시 최저 레이턴시 달성

---

## 4. 연결 옵션

### 옵션 A: USB-C 허브 → LAN 케이블 → iMac (권장 시작점)

```
MacBook Air USB-C
    └── USB-C 허브
         ├── LAN 포트 → LAN 케이블 → iMac LAN 포트
         └── USB-C PD → 충전 어댑터
```

- **대역폭**: Gigabit Ethernet = 1Gbps → QHD 60Hz H.265(15~30Mbps) 충분
- **레이턴시**: LAN 직결 시 0.1~1ms 수준
- **비용**: 랜포트 포함 허브 1~3만원 추가 필요 (기존 허브에 랜포트 없는 경우)
- **Luna 동글 위치**: 불필요 (소프트웨어로 대체가 목표)

### 옵션 B: USB-C → TB3→TB2 어댑터 → iMac TB2

```
MacBook Air USB-C
    └── Apple TB3→TB2 어댑터 (MMEL2AM/A)
         └── TB2 케이블 → iMac Thunderbolt 2 포트
```

- **대역폭**: Thunderbolt 2 = 20Gbps (이론치), 실제 데이터 전송은 10Gbps급
- **레이턴시**: TB2 직결로 LAN보다 낮을 수 있음
- **비용**: Apple TB3→TB2 어댑터 약 5만원 + TB2 케이블 2~3만원
- **호환성 근거**: [MacRumors 포럼](https://forums.macrumors.com/threads/is-there-a-usb-c-to-thunderbolt-2-adapter-for-imac-2015-27-retina-mid-2015-15-1.2346767/)에서 iMac 2015(15,1)과 Apple MMEL2AM/A 어댑터 호환 확인됨. "Sierra 이상에서 TB1/2 포트가 있는 모든 Mac과 작동"

**주의**: MacBook Air USB-C 포트 점유로 충전 포트 1개 소모. 허브 경유 충전 병행 필요.

---

## 5. iMac 전원에서 MacBook 충전 가능성

### 결론: 제한적 가능 (방전 속도 완화 수준)

| 포트 | 출력 | MacBook Air 필요량 | 가능 여부 |
|------|------|-------------------|---------|
| iMac USB-A (2015, 구형) | 최대 10~12W | 30W 이상 | ❌ 충전 불가, 방전 지연 수준 |
| iMac TB2 포트 | 데이터 전용, 전원 공급 미지원 | - | ❌ |

**근거**: [iFixit](https://www.ifixit.com/Answers/View/25287/What+is+the+USB+port+power+output+): "2017년 이전 구형 iMac은 최대 10~12W, USB PD 미지원"

**현실적 결론**:
- iMac USB-A → MacBook 충전 어댑터 입력: 30W 미달로 충전 불가
- 그러나 MacBook Air가 저부하 작업(보조 모니터로만 사용) 중일 때 방전 속도를 일부 줄이는 효과는 기대 가능 (5~10W 보조)
- **완전한 충전은 별도 충전 어댑터 필요**. 허브의 PD 패스스루 포트 활용 권장

---

## 6. 기존 오픈소스 레퍼런스 목록

| 프로젝트 | 역할 | 링크 | 라이선스 |
|---------|------|------|---------|
| FreeDisplay | CGVirtualDisplay Private API 활용 가상 디스플레이 | [GitHub](https://github.com/huberdf/FreeDisplay) | MIT |
| CGVirtualDisplay Example | CGVirtualDisplay 기본 예제 | [GitHub](https://github.com/KhaosT/CGVirtualDisplay) | - |
| node-mac-virtual-display | Node.js로 macOS 가상 디스플레이 생성 | [GitHub](https://github.com/enfp-dev-studio/node-mac-virtual-display) | - |
| macos-virtual-display | IOFramebuffer kext 기반 구현 (구버전) | [GitHub](https://github.com/miolini/macos-virtual-display) | Apple License |
| FluffyDisplay | Screen Sharing 기반 iMac 보조 디스플레이 활용 | [GitHub](https://github.com/tml1024/FluffyDisplay) | - |
| displayx | Quartz DisplayStream 기반 프레임 캡처 샘플 | [GitHub](https://github.com/tSoniq/displayx) | 학술용 무료 |
| deskreen | WebRTC 기반 화면 전송 오픈소스 | [GitHub](https://github.com/pavlobu/deskreen) | GPL |

---

## 7. 개발 단계별 로드맵

### Phase 1: 검증 (1~2주)
- [ ] FreeDisplay 또는 node-mac-virtual-display로 MacBook에 가상 디스플레이 생성 테스트
- [ ] 생성된 가상 디스플레이가 macOS 디스플레이 설정에 외장 모니터로 인식되는지 확인
- [ ] ScreenCaptureKit으로 가상 디스플레이 프레임 캡처 테스트
- [ ] VideoToolbox H.265 인코딩 → UDP 전송 → 디코딩 → 렌더링 기본 파이프라인 구성

### Phase 2: 연결 및 화질 (2~4주)
- [ ] LAN 연결 기반 전송 구현 및 레이턴시 측정
- [ ] TB2 연결 테스트 (옵션 B)
- [ ] Plan C 목표 달성: QHD 60Hz 안정 전송
- [ ] 레이턴시 10ms 이하 달성 여부 확인

### Phase 3: 최적화 및 배포 (4~8주)
- [ ] Plan B 목표 도전: 5K 또는 고해상도 60Hz
- [ ] 자동 연결/재연결 구현
- [ ] GitHub 오픈소스 배포
- [ ] README 및 설치 가이드 작성 (한/영)

---

## 8. 알려진 위험 요소 및 한계

| 항목 | 위험도 | 내용 |
|------|--------|------|
| CGVirtualDisplay Private API | 중간 | Apple이 언제든 변경/차단 가능. macOS 업데이트 시 작동 불가 가능성 |
| SIP(System Integrity Protection) | 낮음 | CGVirtualDisplay 방식은 SIP 비활성화 불필요 (kext 방식은 필요) |
| 5K 60Hz 달성 | 높음 | 네트워크 대역폭 및 인코딩 처리량이 병목. Plan C(QHD)를 우선 목표로 |
| iMac macOS 설치 필요 | 필수 | 현재 Windows 설치 상태 → macOS Monterey + OCLP 설치 선행 필요 |
| AirPlay to Mac 활성화 | 필요 | OCLP + FeatureUnlock + iMac19,1 스푸핑으로 해결 가능 (Reddit 선례 다수 확인) |

---

## 9. 다음 단계 액션 아이템

1. **iMac에 macOS Monterey 설치** + OCLP로 AirPlay to Mac 활성화 (기존 Reddit 가이드 활용)
2. **MacBook에서 FreeDisplay 설치 테스트** → 가상 디스플레이 생성 확인
3. **LAN 포트 포함 USB-C 허브 구매** (1~3만원, 쿠팡)
4. Phase 1 개발 시작

---

*문서 버전: v0.1 | 최초 작성일: 2026-05*  
*검색 기반 작성. 추측성 내용 포함 시 별도 표기.*
