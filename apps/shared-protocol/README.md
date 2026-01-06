# shared-protocol

Protocol schema, packet headers, mode ids, and parser tests.

Keep v0 simple and measurable.

## v0 header

`protocol_v0.py` is a standard-library reference parser for the fixed 80-byte frame header described in `specs/protocol_v0.md`.

Run:

```bash
python3 apps/shared-protocol/test_protocol_v0.py
```

Required receiver behavior:

- reject wrong magic before reading payload bytes;
- reject wrong version before accepting frame data;
- preserve `frame_id`, payload length, timestamps, flags, and dropped-frame counters for diagnostics.
