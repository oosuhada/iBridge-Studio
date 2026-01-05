# iBridge Protocol v0 Draft

## Transport

- TCP control channel initially.
- UDP frame channel for low latency.
- All frames have monotonic frame id.

## Control handshake

```json
{
  "magic": "IBRIDGE",
  "version": 0,
  "role": "primary",
  "supported_codecs": ["h264", "hevc"],
  "supported_modes": ["5k60", "5k45", "4k60", "1440p60"],
  "transport": ["tcp", "udp"]
}
```

## Frame header binary fields

| Field | Type | Notes |
|---|---|---|
| magic | u32 | `IBRG` |
| version | u16 | 0 |
| header_len | u16 | bytes |
| session_id | u64 | random |
| frame_id | u64 | increment |
| chunk_id | u16 | for UDP fragmentation |
| chunk_count | u16 | for UDP fragmentation |
| width | u16 | pixels |
| height | u16 | pixels |
| fps_target | u16 | target |
| codec | u8 | 1=h264,2=hevc,3=raw |
| flags | u32 | keyframe, cursor, etc |
| capture_ns | u64 | timestamp |
| encode_ns | u64 | timestamp |
| send_ns | u64 | timestamp |
| payload_len | u32 | bytes |

## Latency calculation

Receiver should calculate:

- network time: receive_ns - send_ns
- decode time
- render time
- frame interval jitter
