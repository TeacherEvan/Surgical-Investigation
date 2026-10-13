#!/usr/bin/env python3
"""Replay .github/workflows/skill-ci.yml locally, step by step.

Reads the workflow itself (so there is no second copy of the checks to drift) and
runs every `run:` block of the `validate` job inside the repo. `uses:` steps such
as actions/checkout are skipped, since you are already in the checkout.

    python3 -m venv .venv
    .venv/bin/pip install pytest pyyaml
    .venv/bin/python scripts/run-ci-locally.py

Exit 0 = every step passed, 1 = a step failed (its output is printed).
"""
from __future__ import annotations

import os
import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent  # scripts/ -> repo root
WORKFLOW = REPO / ".github/workflows/skill-ci.yml"


def main() -> int:
    try:
        import yaml
    except ImportError:
        print("pyyaml missing — run: pip install pytest pyyaml", file=sys.stderr)
        return 1

    if not WORKFLOW.is_file():
        print(f"workflow not found: {WORKFLOW}", file=sys.stderr)
        return 1

    wf = yaml.safe_load(WORKFLOW.read_text())
    steps = wf["jobs"]["validate"]["steps"]

    print(f"workflow : {WORKFLOW.relative_to(REPO)}")
    print(f"python   : {sys.executable}")
    print(f"job      : validate ({len(steps)} steps)\n")

    failed = 0
    for i, step in enumerate(steps, 1):
        name = step.get("name") or step.get("uses", "?")
        if "run" not in step:
            print(f"  [skip] {i:2}. {name}  (uses: {step.get('uses', '')})")
            continue

        proc = subprocess.run(
            ["bash", "-eo", "pipefail", "-c", step["run"]],
            cwd=REPO,
            env=os.environ.copy(),
            capture_output=True,
            text=True,
        )
        tag = "PASS" if proc.returncode == 0 else "FAIL"
        print(f"  [{tag}] {i:2}. {name}")

        lines = [ln for ln in proc.stdout.strip().splitlines() if ln.strip()]
        for ln in lines[-2:]:
            print(f"          {ln}")

        if proc.returncode != 0:
            failed += 1
            for label, blob in (("stdout", proc.stdout), ("stderr", proc.stderr)):
                tail = blob.strip().splitlines()[-12:]
                if tail:
                    print(f"          --- {label} ---")
                    for ln in tail:
                        print(f"          {ln}")
            break

    print()
    if failed:
        print("CI would FAIL — fix the step above before pushing.")
        return 1
    print("CI would PASS — all validate steps succeeded locally.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
