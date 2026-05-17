# Clean Session Encoder Probe

| Case | P95 ms | Result |
|---|---:|---|
| `segment_hints_tiled_first` | 13.765 | pass |
| `post_tiled_4096_fallback` | 14.918 | pass |
| `post_tiled_3200_fallback` | 11.444 | pass |
| `post_tiled_2560_fallback` | 6.307 | pass |

Decision: high-detail fallback switching remains viable after segment-hints tiled 5K60.
