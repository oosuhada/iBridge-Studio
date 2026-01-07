#!/usr/bin/env python3
import argparse
import csv
from pathlib import Path


def percentile(values: list[float], p: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    raw = (p / 100.0) * (len(ordered) - 1)
    lower = int(raw)
    upper = min(lower + 1, len(ordered) - 1)
    fraction = raw - lower
    return ordered[lower] * (1 - fraction) + ordered[upper] * fraction


def read_metric_file(path: Path) -> dict[str, str]:
    metrics: dict[str, str] = {}
    if not path.exists():
        return metrics
    for line in path.read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            metrics[key] = value
    return metrics


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analyze tiled logical-frame latency against presentation deadlines."
    )
    parser.add_argument("logical_csv", type=Path)
    parser.add_argument("--run-log", type=Path, default=None)
    parser.add_argument("--budgets-ms", default="8.33,12,16.67,20,33.33,50")
    parser.add_argument("--window-size", type=int, default=300)
    parser.add_argument("--summary-md", type=Path, default=None)
    args = parser.parse_args()

    rows = list(csv.DictReader(args.logical_csv.open()))
    latencies = [float(row["group_latency_ms"]) for row in rows]
    metrics = read_metric_file(args.run_log) if args.run_log else {}
    budgets = [float(item.strip()) for item in args.budgets_ms.split(",") if item.strip()]

    lines: list[str] = []
    lines.append(f"# Tiled Deadline Analysis — {args.logical_csv.name}")
    lines.append("")

    lines.append("| Metric | Value |")
    lines.append("|---|---:|")
    lines.append(f"| logical_frames | {len(latencies)} |")
    lines.append(f"| avg_group_latency_ms | {sum(latencies) / max(len(latencies), 1):.3f} |")
    lines.append(f"| p95_group_latency_ms | {percentile(latencies, 95):.3f} |")
    lines.append(f"| max_group_latency_ms | {(max(latencies) if latencies else 0):.3f} |")
    for key in ("effective_logical_fps", "tile_reset_every_frames", "tile_max_inflight_logical_frames"):
        if key in metrics:
            lines.append(f"| {key} | {metrics[key]} |")
    lines.append("")

    lines.append("| Budget ms | Late frames | Late % | First late frame IDs |")
    lines.append("|---:|---:|---:|---|")
    for budget in budgets:
        late = [int(row["frame_id"]) for row in rows if float(row["group_latency_ms"]) > budget]
        preview = ", ".join(str(frame_id) for frame_id in late[:12])
        if len(late) > 12:
            preview += ", ..."
        late_percent = (len(late) / max(len(rows), 1)) * 100.0
        lines.append(f"| {budget:.2f} | {len(late)} | {late_percent:.3f}% | {preview} |")
    lines.append("")

    if args.window_size > 0:
        lines.append("| Window | Avg ms | P95 ms | Max ms |")
        lines.append("|---:|---:|---:|---:|")
        for start in range(0, len(latencies), args.window_size):
            window = latencies[start:start + args.window_size]
            lines.append(
                f"| {start}-{start + len(window) - 1} | "
                f"{sum(window) / max(len(window), 1):.3f} | "
                f"{percentile(window, 95):.3f} | "
                f"{(max(window) if window else 0):.3f} |"
            )

    output = "\n".join(lines) + "\n"
    if args.summary_md:
        args.summary_md.write_text(output)
    print(output)


if __name__ == "__main__":
    main()
