# Measurement (dev-only)

These scripts are how v0.11.0's success criteria (spec §8) get checked by a rerun instead of an estimate.

    python tools/measure/cost.py --since 2026-09-12            # tool calls and bytes per brain skill window
    python tools/measure/snapshots.py --graph E:\Loqsec\ClaudeBrain --since 2026-09-12   # Map accuracy + new findings

Both are read-only against their inputs. `snapshots.py` runs the real helper in a temporary copy of the graph. A snapshot taken partway through a save shows a stale Map by design, so judge `stale` results against the first snapshot *after* a save.
