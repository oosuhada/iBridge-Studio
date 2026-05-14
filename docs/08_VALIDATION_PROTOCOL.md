# Validation Protocol

## 1. Definition of Done

A feature is not done until:

- it builds;
- it runs or has a documented environment blocker;
- it writes diagnostics;
- it has a worklog entry;
- it has a failure/downshift path if applicable.

## 2. Metrics

Required metrics:

- actual fps
- target fps
- encode latency
- network latency
- decode latency
- render latency
- end-to-end latency
- dropped frames
- bitrate
- resolution
- codec
- transport
- CPU/GPU usage if available
- battery/power state if available

## 3. Mode Acceptance Criteria

### 5K60 Plan B acceptance

- 5120×2880 selected
- actual_fps >= 55 for 5 minutes
- no receiver crash
- text readable in code editor sample
- pointer movement subjectively acceptable
- summary includes caveats

### 1440p60 Plan C acceptance

- 2560×1440 selected
- actual_fps >= 59 for 30 minutes
- text clarity acceptable after 2x scaling
- no severe tearing or stutter

## 4. Downshift Criteria

Downshift from Plan A to B if:

- raw/near-raw bandwidth exceeds measured transport capacity;
- receiver cannot render synthetic 5K60 without stream overhead;
- capture/copy cost alone violates frame budget.

Downshift from Plan B to C if:

- 5K60 compressed cannot stay near 60fps;
- latency remains too high for pointer use;
- text quality is unacceptable at required bitrate;
- thermal/power issues are unacceptable.

## 5. Reporting Format

Use `templates/experiment_report.md` for every benchmark.
