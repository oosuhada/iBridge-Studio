import struct
import unittest

from protocol_v0 import (
    CODEC_HEVC,
    COLOR_NV12,
    FLAG_END_OF_FRAME,
    FLAG_KEYFRAME,
    HEADER_LEN,
    MAGIC,
    ProtocolError,
    VERSION,
    FrameHeaderV0,
    header_size,
)


class FrameHeaderV0Tests(unittest.TestCase):
    def sample_header(self) -> FrameHeaderV0:
        return FrameHeaderV0(
            session_id=0x1020304050607080,
            frame_id=42,
            chunk_id=1,
            chunk_count=3,
            width=5120,
            height=2880,
            fps_target=60,
            codec=CODEC_HEVC,
            color_format=COLOR_NV12,
            flags=FLAG_KEYFRAME | FLAG_END_OF_FRAME,
            capture_ns=1000,
            encode_start_ns=1100,
            encode_done_ns=1500,
            send_ns=1600,
            payload_len=1197,
            dropped_before=7,
        )

    def test_header_size_is_fixed_80_bytes(self):
        self.assertEqual(header_size(), HEADER_LEN)
        self.assertEqual(len(self.sample_header().encode()), HEADER_LEN)

    def test_round_trip_preserves_fields(self):
        header = self.sample_header()
        decoded = FrameHeaderV0.decode(header.encode())
        self.assertEqual(decoded, header)

    def test_payload_and_dropped_accounting_are_preserved(self):
        decoded = FrameHeaderV0.decode(self.sample_header().encode())
        self.assertEqual(decoded.payload_len, 1197)
        self.assertEqual(decoded.dropped_before, 7)

    def test_flags_are_preserved(self):
        decoded = FrameHeaderV0.decode(self.sample_header().encode())
        self.assertTrue(decoded.flags & FLAG_KEYFRAME)
        self.assertTrue(decoded.flags & FLAG_END_OF_FRAME)

    def test_rejects_wrong_magic(self):
        packet = bytearray(self.sample_header().encode())
        struct.pack_into("<I", packet, 0, 0xFFFFFFFF)
        with self.assertRaisesRegex(ProtocolError, "wrong magic"):
            FrameHeaderV0.decode(bytes(packet))

    def test_rejects_wrong_version(self):
        packet = bytearray(self.sample_header().encode())
        struct.pack_into("<H", packet, 4, VERSION + 1)
        with self.assertRaisesRegex(ProtocolError, "unsupported version"):
            FrameHeaderV0.decode(bytes(packet))

    def test_rejects_short_header(self):
        packet = self.sample_header().encode()[:-1]
        with self.assertRaisesRegex(ProtocolError, "short header"):
            FrameHeaderV0.decode(packet)

    def test_magic_bytes_are_ibrg_little_endian(self):
        self.assertEqual(MAGIC.to_bytes(4, "little"), b"IBRG")


if __name__ == "__main__":
    unittest.main()
