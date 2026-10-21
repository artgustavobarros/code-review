#!/usr/bin/env python3
"""Build a code-review benchmark worktree from a scenario manifest.

Usage: build-bench.py <manifest.json> <out_dir> [--skill <skill_dir>]

Creates a detached git worktree at <out_dir>/<scenario> checked out at the
manifest head, applies each seed (exact find/replace, must match once),
commits locally, symlinks node_modules / .env* / the skill under test, and
writes <out_dir>/<scenario>.diff (base...HEAD) and <out_dir>/<scenario>.base
(the ref to review against). Prints the worktree path.

A manifest may carry `setup` edits (same shape as seeds) that must stay OUT of
the reviewed diff, e.g. a test harness that times out once. They are committed
on top of `base`, the linear base..head commits are cherry-picked over them, and
the setup commit becomes the review base.

Never pushes and never touches the main working tree.
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def git(*args, cwd):
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    ).stdout


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    manifest = json.loads(Path(sys.argv[1]).read_text())
    out_dir = Path(sys.argv[2]).resolve()
    skill_dir = None
    if "--skill" in sys.argv:
        skill_dir = Path(sys.argv[sys.argv.index("--skill") + 1]).resolve()

    repo = Path(git("rev-parse", "--show-toplevel", cwd=Path.cwd()).strip())
    if out_dir == repo or repo in out_dir.parents:
        sys.exit(f"out_dir must be outside the repository: {out_dir}")
    out_dir.mkdir(parents=True, exist_ok=True)
    wt = out_dir / manifest["scenario"]
    if wt.exists():
        subprocess.run(["git", "worktree", "remove", "--force", str(wt)], cwd=repo)
    setup = manifest.get("setup", [])
    review_base = manifest["base"]
    ident = ["-c", "user.name=code-review-bench", "-c", "user.email=bench@localhost"]

    def fail(msg):
        subprocess.run(["git", "worktree", "remove", "--force", str(wt)], cwd=repo)
        sys.exit(msg)

    def apply(edits):
        for seed in edits:
            path = wt / seed["file"]
            text = path.read_text()
            count = text.count(seed["find"])
            if count != 1:
                fail(f"seed {seed['id']}: expected 1 match in {seed['file']}, found {count}")
            path.write_text(text.replace(seed["find"], seed["replace"], 1))

    if setup:
        span = f"{manifest['base']}..{manifest['head']}"
        if git("rev-list", "--merges", span, cwd=repo).strip():
            sys.exit(f"setup needs a linear range without merges: {span}")
        git("worktree", "add", "--detach", str(wt), manifest["base"], cwd=repo)
        apply(setup)
        git(*ident, "commit", "-qam", "bench setup (outside the reviewed diff)", cwd=wt)
        review_base = git("rev-parse", "HEAD", cwd=wt).strip()
        try:
            git(*ident, "cherry-pick", span, cwd=wt)
        except subprocess.CalledProcessError as e:
            fail(f"cherry-pick of {span} over the setup failed: {e.stderr.strip()}")
    else:
        git("worktree", "add", "--detach", str(wt), manifest["head"], cwd=repo)

    apply(manifest["seeds"])
    if manifest["seeds"]:
        git(*ident, "commit", "-qam", manifest["title"], cwd=wt)

    for name in ["node_modules", *[p.name for p in repo.glob(".env*") if p.name != ".env.example"]]:
        src, dst = repo / name, wt / name
        if src.exists() and not dst.exists():
            dst.symlink_to(src)

    if skill_dir:
        for rel in [".claude/skills/code-review", ".agents/skills/code-review"]:
            dst = wt / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.is_symlink() or dst.exists():
                subprocess.run(["rm", "-rf", str(dst)], check=True)
            dst.symlink_to(skill_dir)
        commands = repo / ".claude/commands/code-review.md"
        if commands.exists():
            (wt / ".claude/commands").mkdir(parents=True, exist_ok=True)
            dst = wt / ".claude/commands/code-review.md"
            if not dst.exists():
                dst.symlink_to(commands)

    diff = git("diff", f"{review_base}...HEAD", cwd=wt)
    (out_dir / f"{manifest['scenario']}.diff").write_text(diff)
    (out_dir / f"{manifest['scenario']}.base").write_text(review_base + "\n")
    print(wt)


if __name__ == "__main__":
    main()
