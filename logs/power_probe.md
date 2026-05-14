# Power Probe

Prompt: `prompts/08_POWER_PROBE.md`

Purpose: determine whether iMac USB-A or Thunderbolt 2 connections provide useful power to the MacBook during iBridge use.

Important distinction:

- `charging`: battery percentage increases during the test window.
- `sustaining`: battery percentage is effectively flat during active streaming.
- `slowing drain`: battery still decreases, but slower than no-cable baseline.
- `no useful power`: no measurable improvement over no-cable baseline.

Do not classify a setup as charging from the macOS "power connected" UI alone.

## Collection Script

Run:

```bash
scripts/mac_power_probe.sh
```

Artifacts are written under `logs/power/<timestamp>/`:

- `pmset_batt.txt`
- `system_profiler_power.txt`
- `ioreg_apple_smart_battery.txt`

## Current Baseline Snapshot

Date: 2026-05-15

Commands:

```bash
pmset -g batt
system_profiler SPPowerDataType
ioreg -rn AppleSmartBattery
```

Observed current state:

| Field | Value |
|---|---|
| Power source | Battery Power |
| Battery percent | 98% |
| Charging | No |
| AC charger connected | No |
| `ExternalConnected` | No |
| `ExternalChargeCapable` | No |
| `AppleRawAdapterDetails` | empty |

Classification: `no cable baseline snapshot`, not a drain-rate test.

## Manual Test Matrix

Each case should be measured at idle and during active streaming. Record start/end battery percentage and timestamp. Prefer 30 minutes minimum; 10 minutes is acceptable only as a quick screen.

| Case | Cable state | Workload | Start time | End time | Start % | End % | Adapter shown? | Wattage shown? | Classification | Notes |
|---|---|---|---|---|---:|---:|---|---|---|---|
| A | no cable | idle | pending | pending | pending | pending | pending | pending | pending | baseline drain |
| B | iMac USB-A -> MacBook USB-C | idle | pending | pending | pending | pending | pending | pending | pending | user observed "power connected" needs measurement |
| C | iMac USB-A -> MacBook USB-C | streaming active | pending | pending | pending | pending | pending | pending | pending | must compare against A |
| D | iMac TB2 -> Apple TB3-to-TB2 -> MacBook USB-C | idle | pending | pending | pending | pending | pending | pending | pending | do not assume charging |
| E | iMac TB2 -> Apple TB3-to-TB2 -> MacBook USB-C | streaming active | pending | pending | pending | pending | pending | pending | pending | must compare against A |
| F | PD hub baseline | idle | pending | pending | pending | pending | pending | pending | pending | positive-control charger |
| G | PD hub baseline | streaming active | pending | pending | pending | pending | pending | pending | pending | positive-control charger |

## Logging Procedure

For each cable/workload case:

1. Connect only the cable setup being tested.
2. Wait 60 seconds for macOS power state to settle.
3. Run `scripts/mac_power_probe.sh`.
4. Record `pmset -g batt` start percentage and timestamp.
5. Keep the workload steady for 10/30/60 minutes.
6. Run `scripts/mac_power_probe.sh` again.
7. Classify by battery trend, not UI icon alone.

## Known Limits

- This session cannot physically switch cables while the user is asleep.
- No wattage is measured yet for USB-A or TB2 cases.
- The current snapshot only proves the MacBook Air is presently on battery with no charger detected.
