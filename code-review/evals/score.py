#!/usr/bin/env python3
"""Scoring aid for one eval run: prints the expected items and a file-mention hint.

Usage: score.py <manifest.json> <run.json>

Expected items are the manifest's seeds (minus `support` ones, which only remove
covering tests) plus its `known_defects`. A hint of "mentioned" only means the
report names the file; an item counts as caught only after a human checks that a
reported finding describes its defect (see README "Scoring"). Calibration: note
the reported severity next to the expected one; > 1 level apart counts against it.
"""

import json
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    manifest = json.loads(Path(sys.argv[1]).read_text())
    run = json.loads(Path(sys.argv[2]).read_text())
    report = run.get("result") or ""

    expected = [s for s in manifest.get("seeds", []) if not s.get("support")]
    expected += manifest.get("known_defects", [])

    print(f"scenario: {manifest['scenario']} · expected items: {len(expected)}")
    for item in expected:
        files = [item["file"], *item.get("also", [])]
        hit = any(f in report or Path(f).name in report for f in files)
        print(
            f"- {item['id']} [{item['severity']}] {item['file']}: "
            f"{'mentioned' if hit else 'NOT mentioned'} · {item['defect']}"
        )
    if manifest.get("setup"):
        print(f"- pre-pass labelled flaky: {'yes' if 'flaky' in report.lower() else 'NO'}")


if __name__ == "__main__":
    main()
