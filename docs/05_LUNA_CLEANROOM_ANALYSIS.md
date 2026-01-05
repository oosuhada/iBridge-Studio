# Luna Display Clean-Room Analysis

## 1. Purpose

Luna Display is the closest commercial product to iBridge's goal. It should be studied as a benchmark and product reference, not reverse engineered.

## 2. Publicly Confirmed Behavior

Luna supports Mac-to-Mac using Wi-Fi/Ethernet/USB/Thunderbolt connection paths. [내용 출처 : https://support.astropad.com/en/articles/11835375-what-are-the-system-requirements-for-luna-display]

Luna states that 5K Retina resolutions require USB-C Luna Display, while other units may be limited to 4K or lower. [내용 출처 : https://support.astropad.com/en/articles/11835385-does-luna-display-support-4k-and-5k-retina-resolutions]

Luna 5.1 publicly described Mac support as 5K @ 45Hz and 4K @ 60Hz. [내용 출처 : https://astropad.com/blog/luna-display-5-1/]

Luna hardware should be plugged directly into a compatible port; hubs/docks/adapters are not officially supported. [내용 출처 : https://support.astropad.com/en/articles/11835378-can-i-plug-luna-display-into-an-adapter-or-hub]

## 3. Working Hypothesis

The Luna USB-C dongle is likely closer to:

- external display presence trigger;
- EDID/DisplayPort-style hardware token;
- license/pairing key;
- app activation/coordination device;

than to a standalone 5K wireless video transmitter.

This is a hypothesis, not a proven claim.

## 4. iBridge Differentiation

- No proprietary dongle.
- No reverse engineering.
- Windows Receiver first because the user's iMac is currently Windows.
- Plan A starts at 5K60 but allows measured downshift.
- Transparent diagnostics instead of black-box quality claims.
