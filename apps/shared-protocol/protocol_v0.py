from __future__ import annotations

from dataclasses import dataclass
import struct


MAGIC = int.from_bytes(b"IBRG", "little")
VERSION = 0
HEADER_LEN = 80

CODEC_H264 = 1
CODEC_HEVC = 2
CODEC_RAW_BGRA = 3

COLOR_NV12 = 1
COLOR_BGRA = 2
COLOR_P010 = 3

FLAG_KEYFRAME = 1 << 0
FLAG_CURSOR = 1 << 1
FLAG_END_OF_FRAME = 1 << 2
FLAG_CONFIG = 1 << 3

_HEADER = struct.Struct("<IHHQQHHHHHBBIQQQQII")


class ProtocolError(ValueError):
    pass


@dataclass(frozen=True)
class FrameHeaderV0:
    session_id: int
    frame_id: int
    chunk_id: int
    chunk_count: int
    width: int
    height: int
    fps_target: int
    codec: int
    color_format: int
    flags: int
    capture_ns: int
    encode_start_ns: int
    encode_done_ns: int
    send_ns: int
    payload_len: int
    dropped_before: int

    def encode(self) -> bytes:
        return _HEADER.pack(
            MAGIC,
            VERSION,
            HEADER_LEN,
            self.session_id,
            self.frame_id,
            self.chunk_id,
            self.chunk_count,
            self.width,
            self.height,
            self.fps_target,
            self.codec,
            self.color_format,
            self.flags,
            self.capture_ns,
            self.encode_start_ns,
            self.encode_done_ns,
            self.send_ns,
            self.payload_len,
            self.dropped_before,
        )

    @classmethod
    def decode(cls, data: bytes) -> "FrameHeaderV0":
        if len(data) < HEADER_LEN:
            raise ProtocolError(f"short header: got {len(data)} bytes, need {HEADER_LEN}")

        fields = _HEADER.unpack(data[:HEADER_LEN])
        magic, version, header_len = fields[:3]

        if magic != MAGIC:
            raise ProtocolError("wrong magic")
        if version != VERSION:
            raise ProtocolError(f"unsupported version: {version}")
        if header_len != HEADER_LEN:
            raise ProtocolError(f"unsupported header length: {header_len}")

        return cls(
            session_id=fields[3],
            frame_id=fields[4],
            chunk_id=fields[5],
            chunk_count=fields[6],
            width=fields[7],
            height=fields[8],
            fps_target=fields[9],
            codec=fields[10],
            color_format=fields[11],
            flags=fields[12],
            capture_ns=fields[13],
            encode_start_ns=fields[14],
            encode_done_ns=fields[15],
            send_ns=fields[16],
            payload_len=fields[17],
            dropped_before=fields[18],
        )


def header_size() -> int:
    return _HEADER.size
