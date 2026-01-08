# Clean Session Encoder Probe

| Case | P95 ms | Result |
|---|---:|---|
| `segment_hints_tiled_first` | 14.417 | pass |
| `post_tiled_4096_fallback` | 46.669 | fail |
| `post_tiled_3200_fallback` | 42.616 | fail |
| `post_tiled_2560_fallback` | 16.482 | pass |

Decision: high-detail fallback switching remains unsafe; keep product emergency fallback at `2560x1440@60` until a stronger reset boundary is proven.
