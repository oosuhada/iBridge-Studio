# iBridge Studio Troubleshooting

## Receiver offline

- Confirm the iMac Receiver tab shows `Listening on :48320`.
- Confirm the Sender card Receiver IP matches an address shown in the iMac Receiver tab.
- Click `Test Connection`.
- If SSH Discovery is configured, check SSH auth separately before blaming iBridge.

## Virtual display not found

- Open BetterDisplay on the MacBook.
- Confirm the virtual screen is connected.
- Confirm macOS Displays treats it as an extended display, not mirroring.
- Click Refresh Displays in iBridge Studio.
- Match the Sender card Display name to the BetterDisplay virtual screen name.

## Black screen

- Start with a lower resolution such as `2560x1440`.
- Move a window or cursor onto the virtual display.
- Verify Screen Recording permission for iBridge Studio.
- Check Logs for display selection and encoder errors.

## Permission missing

MacBook Sender needs:

- Screen Recording
- Accessibility
- Local Network when prompted

iMac Receiver may need:

- Accessibility
- Local Network when prompted

After changing permissions, quit and reopen iBridge Studio.

## Universal Control cursor moves but clicks do not affect the virtual display

- Use `Universal Control Relay` cursor mode on the Sender card.
- Keep the BetterDisplay virtual display arranged next to the MacBook display so MacBook windows can move onto it.
- Keep the real iMac arranged for Universal Control so the local cursor can enter the iMac receiver window.
- Grant Accessibility permission on both Macs:
  - MacBook: `iBridge Studio.app` posts the relayed click/drag/scroll/key events into the virtual display.
  - iMac: `iBridge Studio.app` observes receiver-window mouse events and sends them back to the MacBook.
- Quit and reopen iBridge Studio after changing Accessibility permission.
- During a running stream, Logs should show `input_event_received` on the MacBook and `receiver_input_event` on the iMac when you click or drag inside the receiver.

## Wake-on-LAN does not wake the iMac

- Confirm Wake MAC is correct.
- Confirm the iMac network adapter supports Wake-on-LAN in the current sleep state.
- Use `255.255.255.255` or the subnet broadcast address for Wake broadcast.
- iBridge sends the magic packet three times and can wait for the receiver port, but it cannot wake a machine whose adapter/firmware ignores WoL.

## Diagnostics export

Open Logs and click Export. The exported support bundle is written to Desktop and masks user names and MAC addresses in logs.
