# iBridge Protocol v0

Prompt: `prompts/07_PROTOCOL_AND_TRANSPORT.md`

Protocol v0 is intentionally small. It exists to make the first local point-to-point display pipeline measurable before adding QUIC/WebRTC or richer control semantics.

## Transport

- TCP control channel: handshake, mode negotiation, ping/echo timing, receiver status, debug fallback.
- UDP frame channel: low-latency frame chunks.
- TCP-only frame fallback: debug path when UDP/firewall/fragmentation is suspect.

Default control port: `48320`

## Control Handshake

Primary sends JSON over TCP:

```json
{
  "magic": "IBRIDGE",
  "version": 0,
  "role": "primary",
  "session_id": 1234,
  "supported_codecs": ["h264", "hevc", "raw_bgra"],
  "supported_modes": ["plan_a_5k60_raw", "plan_b_5k60_hevc", "plan_c_1440p60"],
  "supported_scale_modes": ["nearest", "linear"],
  "frame_transport": ["udp", "tcp"],
  "control_port": 48320,
  "udp_port": 48321
}
```

Receiver replies:

```json
{
  "magic": "IBRIDGE",
  "version": 0,
  "role": "receiver",
  "session_id": 1234,
  "accepted": true,
  "selected_codec": "h264",
  "selected_mode": "plan_b_5k60_hevc",
  "selected_scale_mode": "linear",
  "selected_frame_transport": "udp",
  "max_payload_bytes": 1200,
  "reason": ""
}
```

Wrong `magic`, wrong `version`, unsupported codec, unsupported mode, unsupported scale mode, or unsupported frame transport must be rejected before any frame payload is accepted.

## Mode IDs

| ID | Source resolution | Output resolution | Target | Notes |
|---|---:|---:|---:|---|
| `plan_a_5k60_raw` | 5120x2880 | 5120x2880 | 60fps | Raw/near-raw feasibility path. |
| `plan_b_5k60_hevc` | 5120x2880 | 5120x2880 | 60fps | Compressed 5K practical path. |
| `plan_c_1440p60` | 2560x1440 | 5120x2880 | 60fps | Exact 2x integer scale candidate. |
| `plan_c_1800p60` | 3200x1800 | 5120x2880 | 60fps | Balanced detail/bandwidth candidate. |
| `plan_c_4k60` | 3840x2160 | 5120x2880 | 60fps | Common 4K fallback candidate. |
| `plan_c_2304p60` | 4096x2304 | 5120x2880 | 60fps | Higher-detail fallback candidate. |

Scale mode IDs:

- `nearest`: point/integer sampling. Primary candidate for exact 2560x1440 -> 5120x2880.
- `linear`: bilinear sampling. First fallback for non-integer scaled modes.

## Clock Offset Probe

Do not calculate end-to-end latency from wall-clock timestamps alone. Primary and Receiver clocks may not be synchronized.

Use TCP ping/echo samples:

```json
{
  "type": "clock_probe",
  "probe_id": 1,
  "primary_send_ns": 100000
}
```

Receiver replies immediately:

```json
{
  "type": "clock_probe_reply",
  "probe_id": 1,
  "primary_send_ns": 100000,
  "receiver_recv_ns": 250000,
  "receiver_send_ns": 260000
}
```

Primary records `primary_recv_ns` and estimates:

```text
rtt_ns = primary_recv_ns - primary_send_ns
offset_ns ~= receiver_recv_ns - (primary_send_ns + rtt_ns / 2)
```

This is an estimate only. Frame order and drops must be tracked by `frame_id` even when timestamps are noisy.

## Frame Header

Binary frame header v0 is little-endian and fixed-size.

Magic bytes are ASCII `IBRG`, encoded as `0x47524249` in little-endian `u32`.

| Offset | Field | Type | Notes |
|---:|---|---|---|
| 0 | magic | u32 | `IBRG` |
| 4 | version | u16 | must be `0` |
| 6 | header_len | u16 | `80` for v0 |
| 8 | session_id | u64 | negotiated over TCP |
| 16 | frame_id | u64 | monotonic per frame |
| 24 | chunk_id | u16 | 0-based UDP chunk index |
| 26 | chunk_count | u16 | total chunks for frame |
| 28 | width | u16 | pixels |
| 30 | height | u16 | pixels |
| 32 | fps_target | u16 | target fps |
| 34 | codec | u8 | 1=h264, 2=hevc, 3=raw_bgra |
| 35 | color_format | u8 | 1=nv12, 2=bgra, 3=p010 |
| 36 | flags | u32 | bit flags below |
| 40 | capture_ns | u64 | primary monotonic timestamp |
| 48 | encode_start_ns | u64 | primary monotonic timestamp |
| 56 | encode_done_ns | u64 | primary monotonic timestamp |
| 64 | send_ns | u64 | primary monotonic timestamp |
| 72 | payload_len | u32 | bytes following this header/chunk |
| 76 | dropped_before | u32 | frames dropped before this frame |

Header size: `80` bytes.

## Codecs

| ID | Name |
|---:|---|
| 1 | h264 |
| 2 | hevc |
| 3 | raw_bgra |

## Color Formats

| ID | Name |
|---:|---|
| 1 | nv12 |
| 2 | bgra |
| 3 | p010 |

## Flags

| Bit | Name | Meaning |
|---:|---|---|
| 0 | keyframe | payload starts a keyframe |
| 1 | cursor | payload includes cursor metadata |
| 2 | end_of_frame | last chunk for this frame |
| 3 | config | codec config payload such as SPS/PPS/VPS |

## Dropped Frame Accounting

Primary increments `dropped_before` when it skips frames before send. Receiver independently tracks missing `frame_id` gaps:

```text
missing = current_frame_id - previous_frame_id - 1
```

Both values should appear in diagnostics. They answer different questions:

- `dropped_before`: sender-side drops before transport.
- `missing`: receiver-observed drops over transport or decode/render.

## Latency Breakdown

Receiver records its own monotonic timestamps:

- `receive_ns`
- `decode_start_ns`
- `decode_done_ns`
- `render_start_ns`
- `present_done_ns`

With clock offset estimate, diagnostics can approximate:

- capture to encode done
- encode done to receive
- receive to decode done
- decode done to present
- total estimated end-to-end latency

## Validation

Parser tests live in `apps/shared-protocol/test_protocol_v0.py`.

Required behavior:

- round-trip encode/decode keeps every field;
- wrong magic is rejected;
- wrong version is rejected;
- payload length is preserved;
- dropped frame accounting fields are decoded.
