"""
Golden-file regression tests for every standalone Example_*.thy under
examples/. Each focused example theory gets diffed against a checked-in 
reference copy.

Prerequisite (run first, from the project root):

    isabelle build -d . -e Python_Examples

That exports every Example_*.thy's generated module(s) somewhere under
examples/python_out/ (Isabelle nests each under a
Python_Examples.<Theory>/code/ subdirectory, so this file searches by
relative path rather than assuming an exact layout).

Run with:

    cd test/diff && pytest test_examples_golden.py -v

Accepting a new baseline after a change to a *.thy file:
  1. Build normally (isabelle build -d . -e Python_Examples).
  2. Run this test. Every failure names the exact `cp` command to accept
     that one file's new output; every skip for a brand-new file names
     the command to seed its first golden file. Or, to review and accept
     everything that changed in one pass, run:
         python3 reseed_goldens.py
     (review the diffs first -- it does not ask per file before
     overwriting).
  3. Commit the updated test/diff/golden/ files alongside the ML change
     that caused them, so the diff in your commit tells the same story
     as the diff in this test's failure output.
"""

import difflib
from pathlib import Path

import pytest


THIS_DIR = Path(__file__).resolve().parent
# THIS_DIR is <project root>/test/diff -- examples/python_out/ lives two
# levels up, as a sibling of test/, not under test/diff/ itself.
PROJECT_ROOT = THIS_DIR.parent.parent
PYTHON_OUT_ROOT = PROJECT_ROOT / "examples" / "python_out"
GOLDEN_ROOT = THIS_DIR / "golden"
 
 
def _canonical_key(rel_parts):
    if len(rel_parts) >= 2 and rel_parts[1] == "code":
        return rel_parts[:1] + rel_parts[2:]
    return rel_parts
 
 
def _discover_generated(root):
    if not root.exists():
        return {}
    result = {}
    for p in root.rglob("*.py"):
        key_parts = _canonical_key(p.relative_to(root).parts)
        result[Path(*key_parts).as_posix()] = p
    return result
 
 
def _discover_golden(root):
    if not root.exists():
        return {}
    return {p.relative_to(root).as_posix(): p for p in root.rglob("*.py")}
 
 
_generated = _discover_generated(PYTHON_OUT_ROOT)
 
if not _generated:
    pytest.skip(
        f"No generated modules found under {PYTHON_OUT_ROOT} -- run "
        "`isabelle build -d . -e Python_Examples` first.",
        allow_module_level=True,
    )
 
 
def _all_relative_paths():
    # Union of what's been generated and what already has a golden file,
    # so both a brand-new file (generated, no golden yet) and a
    # removed/renamed one (golden exists, nothing generated anymore) get
    # their own visible test case instead of being silently skipped.
    golden = _discover_golden(GOLDEN_ROOT)
    return sorted(set(_generated) | set(golden))
 
 
@pytest.mark.parametrize("rel_path", _all_relative_paths())
def test_example_matches_golden(rel_path):
    generated_path = _generated.get(rel_path)
    golden_path = GOLDEN_ROOT / rel_path
 
    if generated_path is None:
        pytest.fail(
            f"golden/{rel_path} exists but nothing at that path was "
            f"generated under {PYTHON_OUT_ROOT} this build -- the theory "
            "was renamed/removed, or this was an auxiliary module (like "
            "HOL.py) that a different example no longer pulls in. Delete "
            "the stale golden file if that's expected."
        )
 
    if not golden_path.exists():
        pytest.skip(
            f"No golden file yet for {rel_path} -- once you're happy "
            f"with its current output, run: mkdir -p {golden_path.parent} "
            f"&& cp {generated_path} {golden_path}, then commit it."
        )
 
    current = generated_path.read_text()
    golden = golden_path.read_text()
    if current != golden:
        diff = "\n".join(difflib.unified_diff(
            golden.splitlines(), current.splitlines(),
            fromfile=f"golden/{rel_path} (expected)",
            tofile=f"generated {rel_path} (actual)",
            lineterm="",
        ))
        pytest.fail(
            f"Generated output for {rel_path} no longer matches its "
            f"checked-in golden file. If this is intentional, run: "
            f"cp {generated_path} {golden_path}, then commit it. "
            f"Diff:\n\n{diff}"
        )