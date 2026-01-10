#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$HOME/Library/Preferences/iBridgeBackups}"
PREF="$HOME/Library/Preferences/com.apple.systempreferences.plist"
TS="$(date +%Y%m%d-%H%M%S)"

osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true
pkill -x "System Settings" >/dev/null 2>&1 || true
pkill -x "System Preferences" >/dev/null 2>&1 || true

mkdir -p "$BACKUP_DIR"
if [[ -f "$PREF" ]]; then
  cp "$PREF" "$BACKUP_DIR/com.apple.systempreferences.$TS.plist"
  rm -f "$PREF"
  echo "backed_up_system_settings_pref=$BACKUP_DIR/com.apple.systempreferences.$TS.plist"
else
  echo "system_settings_pref_missing"
fi

killall cfprefsd >/dev/null 2>&1 || true
open "x-apple.systempreferences:" >/dev/null 2>&1 || open -a "System Settings" >/dev/null 2>&1 || true
sleep 1
osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "System Settings" to activate
tell application "System Events"
  tell process "System Settings"
    if (count of windows) > 0 then
      set position of window 1 to {120, 120}
      set size of window 1 to {1120, 760}
    end if
  end tell
end tell
APPLESCRIPT
echo "system_settings_repair_done"
