# iBridge Studio Developer Guide

This file is for building, packaging, signing, and deploying `v0.1.1-alpha`.

## Branch

Use `deploy` for alpha packaging:

```bash
git checkout deploy
git pull --rebase
```

## Validate

```bash
swift build --package-path apps/controller-macos -c release
swift build --package-path apps/primary-macos -c release
swift build --package-path apps/receiver-macos -c release
python3 apps/shared-protocol/test_protocol_v0.py
bash -n scripts/package_macos_alpha.sh scripts/start_ibridge_virtual_capture.sh scripts/resolve_receiver_ip.sh scripts/wake_receiver.sh
```

## Package

Default alpha packaging uses ad-hoc signing and creates zip, dmg, and pkg:

```bash
scripts/package_macos_alpha.sh
```

Outputs:

```text
dist/iBridge-Studio-0.1.1-alpha/
dist/iBridge-Studio-0.1.1-alpha.zip
dist/iBridge-Studio-0.1.1-alpha.dmg
dist/iBridge-Studio-0.1.1-alpha.pkg
```

## Developer ID signing and notarization

This repository does not store credentials. On a Mac with a valid Developer ID Application identity and a notarytool keychain profile:

```bash
CODE_SIGN_IDENTITY="Developer ID Application: <Team Name> (<TEAMID>)" \
NOTARY_PROFILE="ibridge-notary" \
scripts/package_macos_alpha.sh
```

The script signs the app with hardened runtime, submits zip/dmg/pkg when `NOTARY_PROFILE` is set, and staples the app/dmg/pkg where possible.

If `security find-identity -v -p codesigning` shows no valid Developer ID identity, notarization cannot be completed on that machine.

## Runtime notes

- macOS minimum target is now macOS 13 for controller, sender, and receiver packages.
- OCLP Sequoia is the current tested receiver direction for old Intel iMacs.
- Tahoe is not recommended for this alpha because Apple Intelligence and related system service changes add compatibility variables on OCLP Intel Macs.
- Sender run roots include seconds plus session UUID to avoid multi-session log/CSV collisions.
- Scripts must not contain personal IP, SSH username, or Wake MAC defaults.
- `start_ibridge_virtual_capture.sh` does not build in packaged mode; it uses bundled `bin/ibridge-primary`.

## Clean install test

On the MacBook:

```bash
rm -rf dist/iBridge-Studio-0.1.1-alpha dist/iBridge-Studio-0.1.1-alpha.*
scripts/package_macos_alpha.sh
open "dist/iBridge-Studio-0.1.1-alpha/iBridge Studio.app"
```

On each iMac, remove prior alpha folders before installing the new artifact.

