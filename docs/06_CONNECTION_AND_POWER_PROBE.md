# Connection and Power Probe Guide

## 1. User Observation

When iMac USB 3.0 is connected to MacBook USB-C, the MacBook battery UI can change to a plugged-in state, even if the wattage is too low to meaningfully charge.

This should be treated as a real observation and measured, not dismissed.

## 2. USB-A Power Hypothesis

USB 3 default current is usually 900mA at 5V, roughly 4.5W. [내용 출처 : https://tripplite.eaton.com/products/usb-charging]

Potential effect:

- plugged-in status may appear;
- battery drain may slow slightly;
- actual charging while working is unlikely.

## 3. Thunderbolt 2 Bus Power Hypothesis

Thunderbolt 1/2 bus power has references around 10W for bus-powered devices. [내용 출처 : https://global-sei.com/ewp/E/thunderbolt/]

But this is not the same as USB-C PD charging. The Apple TB3-to-TB2 adapter should not be assumed to deliver MacBook charging power. [내용 출처 : https://support.apple.com/en-us/111753]

## 4. Required Tests

### Test A — USB-A to USB-C power

- Connect iMac USB-A to MacBook USB-C.
- Record `pmset -g batt`.
- Record System Information > Power.
- Record if wattage appears.
- Run idle 10 min, coding 10 min, iBridge streaming 10 min.

### Test B — TB2 to USB-C adapter power

- Connect MacBook to iMac through Apple TB3-to-TB2 adapter and TB2 cable.
- Configure Thunderbolt Bridge if possible.
- Record power state.
- Record network throughput.

### Test C — PD hub baseline

- Connect MacBook charger to PD/LAN hub.
- Use Ethernet to iMac.
- Record stable power state.

## 5. Product Decision

Do not market iBridge as one-cable charging. The software can only diagnose and optimize around available power. One-cable display+charging is a hardware controller-board feature, not a software feature.
