# Prompt 08 — Power Probe

Goal:
Measure whether iMac USB-A or TB2 connections provide any meaningful power to MacBook.

Tasks:

1. Add macOS script to collect:
   - `pmset -g batt`
   - System Information power data if scriptable
   - `ioreg` adapter info if available
2. Define manual test cases:
   - no cable
   - USB-A to USB-C
   - TB2 to TB3 adapter
   - PD hub baseline
3. Log battery drain rate during idle and streaming.
4. Add result parser if practical.

Important:
Do not claim charging works unless measured wattage and battery trend support it.

Verification:
- `logs/power_probe.md` contains test table.
- Any claim about wattage is marked measured/estimated/source.
