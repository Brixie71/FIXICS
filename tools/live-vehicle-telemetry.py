#!/usr/bin/env python
"""Live FIXICS vehicle telemetry dashboard.

Tails an Arma 3 RPT file and renders the latest FIXICS vehicle telemetry lines
in a terminal. This is an SQA-only diagnostic tool and does not modify gameplay
state or repository files.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Deque


TELEMETRY_MARKERS = (
    "[FIXICS] Vehicle handling sample:",
    "[FIXICS] Vehicle handling evidence:",
    "[FIXICS][Stability]",
    "[FIXICS][RollStability]",
    "[FIXICS][RuntimeAssistSample]",
    "[FIXICS][TerrainTireSample]",
)

KEY_VALUE_PATTERN = re.compile(r"([A-Za-z][A-Za-z0-9_]*)=([^=\s]+(?:\s(?![A-Za-z][A-Za-z0-9_]*=)[^=\s]+)*)")


@dataclass
class DashboardState:
    rpt_path: Path
    latest_seen: str = "waiting"
    stability: dict[str, str] = field(default_factory=dict)
    roll: dict[str, str] = field(default_factory=dict)
    runtime: dict[str, str] = field(default_factory=dict)
    terrain: dict[str, str] = field(default_factory=dict)
    sample: str = ""
    recent: Deque[str] = field(default_factory=lambda: deque(maxlen=10))
    lines_seen: int = 0


def latest_rpt() -> Path | None:
    candidates: list[Path] = []
    local_app_data = os.environ.get("LOCALAPPDATA")
    user_profile = os.environ.get("USERPROFILE")

    if local_app_data:
        candidates.append(Path(local_app_data) / "Arma 3")
    if user_profile:
        candidates.append(Path(user_profile) / "Documents" / "Arma 3")

    rpt_files: list[Path] = []
    for directory in candidates:
        if directory.exists():
            rpt_files.extend(directory.glob("*.rpt"))

    if not rpt_files:
        return None
    return max(rpt_files, key=lambda path: path.stat().st_mtime)


def parse_key_values(line: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for match in KEY_VALUE_PATTERN.finditer(line):
        value = match.group(2).strip().strip('"')
        values[match.group(1)] = value
    return values


def compact_line(line: str, limit: int = 150) -> str:
    line = line.strip()
    if line.startswith('"') and line.endswith('"'):
        line = line[1:-1]
    if len(line) <= limit:
        return line
    return line[: limit - 3] + "..."


def update_state(state: DashboardState, line: str) -> bool:
    if not any(marker in line for marker in TELEMETRY_MARKERS):
        return False

    state.lines_seen += 1
    state.latest_seen = time.strftime("%H:%M:%S")
    state.recent.append(compact_line(line))

    values = parse_key_values(line)
    if "[FIXICS][Stability]" in line:
        state.stability = values
    elif "[FIXICS][RollStability]" in line:
        state.roll = values
    elif "[FIXICS][RuntimeAssistSample]" in line:
        state.runtime = values
    elif "[FIXICS][TerrainTireSample]" in line:
        state.terrain = values
    elif "[FIXICS] Vehicle handling sample:" in line or "[FIXICS] Vehicle handling evidence:" in line:
        state.sample = compact_line(line, 220)

    return True


def pick(values: dict[str, str], *keys: str, default: str = "-") -> str:
    for key in keys:
        if key in values:
            return values[key]
    return default


def fmt_row(label: str, value: str, width: int = 31) -> str:
    return f"{label:<{width}} {value}"


def clear_screen() -> None:
    print("\033[2J\033[H", end="")


def render(state: DashboardState, follow_from_end: bool) -> None:
    clear_screen()
    print("FIXICS LIVE VEHICLE TELEMETRY")
    print("=" * 78)
    print(fmt_row("RPT", str(state.rpt_path)))
    print(fmt_row("Mode", "tail from end" if follow_from_end else "read existing + follow"))
    print(fmt_row("Telemetry lines seen", str(state.lines_seen)))
    print(fmt_row("Last telemetry", state.latest_seen))
    print()

    print("Vehicle / Stability")
    print("-" * 78)
    print(fmt_row("Class", pick(state.stability, "class")))
    print(fmt_row("Preset / mode", f"{pick(state.stability, 'preset')} / {pick(state.stability, 'mode')}"))
    print(fmt_row("Speed km/h", pick(state.stability, "speedKmh")))
    print(fmt_row("Slip / yaw rate", f"{pick(state.stability, 'slip')} / {pick(state.stability, 'yawRate')}"))
    print(fmt_row("Bank / bank rate", f"{pick(state.stability, 'bank')} / {pick(state.stability, 'bankRate')}"))
    print(fmt_row("Roll applied / reason", f"{pick(state.stability, 'rollApplied')} / {pick(state.stability, 'rollReason')}"))
    print(fmt_row("Controlled slip", f"{pick(state.stability, 'controlledSlipApplied')} / {pick(state.stability, 'controlledSlipReason')}"))
    print(fmt_row("Terrain class", pick(state.stability, "controlledSlipTerrainClass")))
    print()

    print("Runtime Assist")
    print("-" * 78)
    print(fmt_row("Winner", pick(state.runtime, "priorityWinner", "winner")))
    print(fmt_row("Final correction", pick(state.runtime, "finalCorrection", "correction")))
    print(fmt_row("Terrain multiplier", pick(state.runtime, "terrainMultiplier")))
    print(fmt_row("Mass multiplier", pick(state.runtime, "massMultiplier")))
    print(fmt_row("Suppressed assists", pick(state.runtime, "suppressedAssists")))
    print()

    print("Terrain Tire")
    print("-" * 78)
    print(fmt_row("Surface / grip", f"{pick(state.terrain, 'surfaceType')} / {pick(state.terrain, 'terrainGripClass')}"))
    print(fmt_row("Traction multiplier", pick(state.terrain, "tractionMultiplier")))
    print(fmt_row("Accel / brake traction", f"{pick(state.terrain, 'accelerationTractionMultiplier')} / {pick(state.terrain, 'brakingTractionMultiplier')}"))
    print(fmt_row("Turn / slope traction", f"{pick(state.terrain, 'turningTractionMultiplier')} / {pick(state.terrain, 'slopeTractionMultiplier')}"))
    print(fmt_row("Wheelspin", pick(state.terrain, "wheelspinEstimate")))
    print(fmt_row("Tire air / deflation", f"{pick(state.terrain, 'tireAirState')} / {pick(state.terrain, 'tireDeflationState')}"))
    print(fmt_row("Drag / steering penalty", f"{pick(state.terrain, 'tireDragPenalty')} / {pick(state.terrain, 'tireSteeringPenalty')}"))
    print(fmt_row("Mass modifier", pick(state.terrain, "massModifier")))
    print()

    if state.sample:
        print("Latest Handling Sample")
        print("-" * 78)
        print(state.sample)
        print()

    print("Recent FIXICS Lines")
    print("-" * 78)
    for line in state.recent:
        print(line)
    print()
    print("Press Ctrl+C to stop.")


def follow_file(path: Path, from_end: bool, refresh_seconds: float) -> None:
    state = DashboardState(rpt_path=path)
    render(state, from_end)

    with path.open("r", encoding="utf-8", errors="replace") as handle:
        if from_end:
            handle.seek(0, os.SEEK_END)

        next_render = 0.0
        while True:
            line = handle.readline()
            if line:
                if update_state(state, line):
                    now = time.monotonic()
                    if now >= next_render:
                        render(state, from_end)
                        next_render = now + refresh_seconds
                continue

            time.sleep(0.1)
            now = time.monotonic()
            if now >= next_render:
                render(state, from_end)
                next_render = now + refresh_seconds


def main() -> int:
    parser = argparse.ArgumentParser(description="Live terminal dashboard for FIXICS Arma 3 RPT telemetry.")
    parser.add_argument("--rpt", help="Path to an Arma 3 .rpt file. Defaults to the newest Arma 3 RPT.")
    parser.add_argument("--from-start", action="store_true", help="Read existing telemetry before following new lines.")
    parser.add_argument("--refresh", type=float, default=0.5, help="Dashboard refresh interval in seconds.")
    args = parser.parse_args()

    rpt_path = Path(args.rpt).expanduser() if args.rpt else latest_rpt()
    if rpt_path is None or not rpt_path.exists():
        print("No Arma 3 RPT found. Launch Arma 3 first or pass --rpt <path>.", file=sys.stderr)
        return 1

    try:
        follow_file(rpt_path, not args.from_start, max(args.refresh, 0.1))
    except KeyboardInterrupt:
        print("\nStopped.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
