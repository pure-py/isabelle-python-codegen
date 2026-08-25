#!/usr/bin/env python3
"""
Bulk-refresh test/diff/golden/ from the currently generated output under
examples/python_out/, for use with test_examples_golden.py.

Run this *after* reviewing test_examples_golden.py's failure diffs (or
`git diff` on golden/ after a manual copy) and confirming every change
is intentional -- this script does not ask per file before overwriting,
it just makes every golden file match what's currently generated.

Preserves each file's path relative to examples/python_out/ (a single
export can produce more than one .py file -- see
test_examples_golden.py's module docstring), so two different examples
that happen to both pull in the same auxiliary module (e.g.
.../Example_a/code/Num.py and .../Example_b/code/Num.py) get their own
distinct golden copies rather than colliding on a bare filename.

Usage (from test/diff/, after `isabelle build -d . -e Python_Examples`
run from the project root):

    python3 reseed_goldens.py
"""

import shutil
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = THIS_DIR.parent.parent
PYTHON_OUT_ROOT = PROJECT_ROOT / "examples" / "python_out"
GOLDEN_ROOT = THIS_DIR / "golden"

def _canonical_key(rel_parts):
    """Drop the `code/` export-category segment -- see module docstring."""
    if len(rel_parts) >= 2 and rel_parts[1] == "code":
        return rel_parts[:1] + rel_parts[2:]
    return rel_parts
 
def main():
    if not PYTHON_OUT_ROOT.exists():
        raise SystemExit(
            f"No {PYTHON_OUT_ROOT} -- run `isabelle build -d . -e "
            "Python_Examples` first."
        )
 
    GOLDEN_ROOT.mkdir(exist_ok=True)
 
    updated = []
    for generated in sorted(PYTHON_OUT_ROOT.rglob("*.py")):
        rel_path = Path(*_canonical_key(generated.relative_to(PYTHON_OUT_ROOT).parts))
        dest = GOLDEN_ROOT / rel_path
        if not dest.exists() or dest.read_text() != generated.read_text():
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(generated, dest)
            updated.append(rel_path.as_posix())
 
    if updated:
        print(f"Updated {len(updated)} golden file(s):")
        for name in updated:
            print(f"  {name}")
    else:
        print("Nothing to update -- all golden files already match.")
 
 
if __name__ == "__main__":
    main()