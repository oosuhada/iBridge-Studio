# AGENTS.md — iBridge Codex Operating Contract

이 파일은 iBridge 레포지토리에서 Codex가 따라야 하는 단일 지침 파일이다. `CODEX.md`, `CLAUDE.md`는 두지 않는다. 모든 작업은 이 문서와 `prompts/`의 명령 프롬프트를 기준으로 수행한다.

---

## 0. Project Identity

**iBridge**는 2015 27-inch iMac Retina 5K를 하드웨어 개조 없이 MacBook의 보조 디스플레이처럼 활용하기 위한 소프트웨어다.

이 프로젝트는 하네스 문서 자체가 목표가 아니다. 하네스는 Codex가 체계적으로 구현/검증/기록하도록 돕는 작업 방식일 뿐이다.

---

## 1. Non-negotiable User Intent

1. 프로젝트명은 **iBridge**다.
2. 현재 iMac은 **Windows로 부팅되는 상태**다. 초기 구현은 `macOS Primary → Windows Receiver`를 우선한다.
3. 첫 기술 목표는 낮은 MVP가 아니라 **Plan A: 5K 60Hz 무압축/저지연**을 정면 검증하는 것이다.
4. Plan A가 실패하면 실패 근거를 수치/로그로 남기고 **Plan B → Plan C** 순서로 내려간다.
5. 핵심 기능은 “iMac을 외부 디스플레이처럼 쓰는 것”이다. UI polish, landing page, 문서 미화는 후순위다.
6. Luna Display, AirPlay, Duet, Apple private protocols, dongle firmware, proprietary binaries를 리버스엔지니어링하지 않는다.
7. 출처가 필요한 기술 판단은 반드시 `[내용 출처 : URL]` 형태로 문서에 남긴다.
8. 사실 / 가설 / 실험 필요 항목을 혼동하지 않는다.

---

## 2. Execution Style: Karpathy-style Harness

### 2.1 Think Before Coding

작업 시작 전에 다음을 5~10줄로 작성한다.

```text
Assumptions:
- ...
Unknowns:
- ...
Plan:
1. ... → verify: ...
2. ... → verify: ...
Downshift condition:
- ...
```

불확실한 부분이 있으면 임의로 결정하지 말고 `logs/questions.md`에 기록한다. 사소한 명명/포맷 이슈는 직접 결정하되, 아키텍처/OS/프로토콜 선택은 근거를 남긴다.

### 2.2 Simplicity First

- 앱을 먼저 만든다. 프레임워크/추상화부터 만들지 않는다.
- UI는 진단 HUD와 연결 상태 표시만 먼저 구현한다.
- 하나의 모드가 검증되기 전에는 다중 모드 옵션 UI를 만들지 않는다.
- 200줄이면 가능한 작업을 1000줄로 만들지 않는다.

### 2.3 Surgical Changes

- 현재 prompt에서 요구한 범위만 수정한다.
- 관련 없는 문서, 스타일, 폴더 구조를 임의로 개편하지 않는다.
- pre-existing dead code는 삭제하지 말고 `logs/observations.md`에 남긴다.
- 변경된 모든 파일은 `logs/worklog.md`에 기록한다.

### 2.4 Goal-Driven Execution

모든 구현 PR/커밋은 검증 명령을 포함해야 한다.

예시:

```text
Goal: Windows Receiver can open a fullscreen black window and render synthetic frames at 60fps.
Verify:
- cmake --build build
- receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60
- diagnostics HUD shows actual_fps >= 58 for 60 seconds
```

---

## 3. Required Work Log Discipline

작업할 때마다 아래 파일 중 하나 이상을 갱신한다.

- `logs/worklog.md` — 어떤 파일을 왜 바꿨는지
- `logs/experiments.md` — 성능/대역폭/전원 실험 결과
- `logs/decisions.md` — ADR 요약
- `logs/questions.md` — 사용자 확인이 필요한 질문
- `docs/04_SOURCE_LEDGER.md` — 출처 추가

작업 로그 형식:

```markdown
## YYYY-MM-DD HH:mm — short title

Prompt: prompts/...
Changed files:
- ...
Verification:
- [x] command/result
- [ ] skipped because ...
Result:
- ...
Next:
- ...
```

---

## 4. Git Workflow

Codex는 작업 단위를 작게 나눈다.

권장 branch:

```text
feat/plan-a-5k60-benchmark
feat/macos-primary-capture
feat/windows-receiver-synthetic
feat/protocol-v0
feat/power-probe
fix/...
docs/...
```

권장 commit prefix:

```text
research:
probe:
feat:
bench:
test:
docs:
fix:
chore:
```

금지:

- 여러 독립 기능을 한 커밋에 섞기
- 빌드 실패 상태를 성공처럼 설명하기
- 벤치마크 로그 없이 성능 향상을 주장하기

---

## 5. Plan Ladder

### Plan A — 5K60 raw/near-raw feasibility

Goal: 5120×2880 @ 60fps를 가능한 한 압축 없이/최소 처리로 전달할 수 있는지 벤치마크한다.

Exit criteria:

- 성공: 5K60 synthetic/captured stream이 목표 latency/fps를 통과
- 실패: 대역폭/encode/decode/render 병목을 수치로 기록하고 Plan B로 이동

### Plan B — 5K60 practical compressed mode

Goal: HEVC/H.264 hardware acceleration으로 5K60 실사용급을 시도한다.

Exit criteria:

- 성공: 5120×2880 @ 60fps에 가까운 표시, 코딩 화면 사용 가능
- 실패: frame drop, latency, text clarity, thermal/power 근거 기록 후 Plan C로 이동

### Plan C — 60Hz scaled modes for 5K panel

Goal: 60Hz 사용감을 유지하면서 5K 패널에 유리한 입력 해상도를 찾는다.

Priority:

1. 2560×1440 @ 60 — exact 2x integer scale to 5120×2880
2. 3840×2160 @ 60 — common 4K mode
3. 3200×1800 @ 60 — balanced mode
4. 4096×2304 @ 60 — high detail experiment

---

## 6. Architecture Defaults

### Primary macOS

- Prefer Swift/SwiftPM or minimal native macOS project.
- Capture: ScreenCaptureKit first, CGDisplayStream fallback.
- Encode: VideoToolbox H.264 low-latency first; HEVC high-quality after pipeline works.
- Virtual display: investigate CGVirtualDisplay/FreeDisplay-style clean-room usage; document private API risk.

ScreenCaptureKit is Apple's framework for high-performance capture of screen and audio content. [내용 출처 : https://developer.apple.com/documentation/screencapturekit]

VideoToolbox provides access to hardware encoders and decoders. [내용 출처 : https://developer.apple.com/documentation/videotoolbox]

### Windows Receiver

- Prefer C++ first for low-level rendering/decoding, or Rust/C++ if project setup justifies it.
- Use Media Foundation for initial H.264/H.265 decode if practical.
- Use FFmpeg only if Media Foundation slows progress.
- Render with D3D11; SDL2 is acceptable for initial fullscreen window.

Media Foundation H.264 decoder is an official Windows decoder path. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]

### Transport

- Start with TCP only for pipe proof if necessary, but do not stop there.
- For real latency testing, implement UDP packetization or QUIC/WebRTC investigation.
- Always include timestamped frames and latency HUD.

---

## 7. Source/Evidence Rules

When adding technical claims:

1. Put source in `docs/04_SOURCE_LEDGER.md`.
2. Use plain text source format: `[내용 출처 : URL]`.
3. Mark status:
   - `confirmed`
   - `plausible`
   - `hypothesis`
   - `needs-test`
4. Do not state “works” unless it was tested in this repo or the cited source directly proves it.

---

## 8. Review Gate Before Reporting Success

Before saying a task is complete:

- Build commands were run or explicitly impossible in the current environment.
- Tests/benchmarks were run or logged as pending with reason.
- Worklog updated.
- Source ledger updated if claims were added.
- No unrelated files changed.
- No `TODO: implement everything` placeholders in claimed-complete areas.
- Plan A/B/C downshift, if any, has measured reason.
