# Prompt 02 — Plan A: 5K60 First Spike

Goal:
Start with the user's highest target: 5120×2880 @ 60Hz raw/near-raw feasibility.

Do not skip to 1440p/4K first. The purpose is to prove or disprove Plan A with data.

Tasks:

1. Create `benchmarks/theory/5k60_bandwidth.md`.
   - Calculate raw RGB bandwidth.
   - Calculate YUV 4:2:0 bandwidth.
   - Compare with 1GbE and TB2 theoretical/expected transport.
   - Use `[내용 출처 : URL]` for transport source claims.

2. Create Windows Receiver synthetic renderer plan.
   - Target: display generated 5120×2880 frames at 60fps locally on the iMac.
   - No network yet.
   - Measure render time and actual fps.

3. Create transport benchmark plan.
   - LAN iperf3.
   - Thunderbolt Bridge iperf3 if available.
   - latency ping.

4. Implement only the smallest code needed to test synthetic 5K60 render if the repo already has app scaffolding; otherwise create scaffolding first.

5. Write downshift gate:
   - what result means Plan A continues;
   - what result means Plan A fails and Plan B starts.

Verification:
- A benchmark summary is written under `benchmarks/runs/.../summary.md` or a clear pending plan exists if hardware is unavailable.
- `logs/worklog.md` updated.
- Plan A is not declared impossible without calculation and at least one local benchmark path.
