# MacBook Pro to iMac Tailscale Probe

Prompt: MacBook Pro Primary comparison after MacBook Air / iMac tests.

## Result

- Target: `100.86.52.88` (`oosu-imac`)
- `tailscale ping`: initially DERP Tokyo, then direct `14.4.153.167:1050`
- ICMP ping: 20/20 received, min/avg/max/stddev `14.484/108.629/423.525/96.505 ms`
- TCP port 22: open
- TCP port 48320: not confirmed listening during this probe
- SSH auth: blocked; MBP key is not accepted by Windows iMac SSH

## Interpretation

This path is usable for reachability checks but too jittery to judge display streaming quality. Live receiver tests require either Windows iMac SSH authentication from this MacBook Pro or manual receiver startup on the iMac.
