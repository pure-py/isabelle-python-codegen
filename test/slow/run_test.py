"""
Import check for the Python generated from all code equations of the
slow test suite: every generated module must import, which py_compile
alone does not check (e.g. circular imports between the modules fail
only at import time).

Prerequisite (run this first, from the project root):

    isabelle build -d . -e Python_Test_Slow

Then:

    uv run pytest test/slow/run_test.py -q --tb=line

Each module is imported in a fresh interpreter, since importing a module
also runs (and may break) the modules it imports.
"""

import re
import subprocess
import sys
from pathlib import Path

import pytest

THIS_DIR = Path(__file__).resolve().parent
GENERATED_DIRS = [THIS_DIR / "generated_basic", THIS_DIR / "generated_full"]

# Modules that are known not to import
KNOWN_FAILURES = {}


def _cases():
    for gen_dir in GENERATED_DIRS:
        for path in sorted(gen_dir.glob("*.py")):
            marks = []
            if path.stem in KNOWN_FAILURES:
                marks.append(pytest.mark.xfail(reason=KNOWN_FAILURES[path.stem], strict=True))
            yield pytest.param(gen_dir, path.stem, id=f"{gen_dir.name}:{path.stem}", marks=marks)


_CASES = list(_cases())
if not _CASES:
    pytest.skip(
        "no generated modules under test/slow -- run "
        "`isabelle build -d . -e Python_Test_Slow` first.",
        allow_module_level=True,
    )


_CACHED_DEF = re.compile(r"^@functools\.cache\ndef (\w+)(?:\[[^\]]*\])?\((.*?)\)", re.M)


@pytest.mark.parametrize("gen_dir,module", _CASES)
def test_cached_functions_take_no_arguments(gen_dir, module):
    # Only lazy values and instances without dictionaries are cached, and their
    # uses call them without arguments
    source = (gen_dir / f"{module}.py").read_text()
    with_args = [name for name, params in _CACHED_DEF.findall(source) if params.strip()]
    assert not with_args, f"cached functions with parameters: {', '.join(with_args)}"


@pytest.mark.parametrize("gen_dir,module", _CASES)
def test_imports(gen_dir, module):
    result = subprocess.run(
        [sys.executable, "-c", f"import {module}"],
        cwd=gen_dir, capture_output=True, text=True,
    )
    if result.returncode != 0:
        last_line = (result.stderr.strip().splitlines() or ["(no output)"])[-1]
        pytest.fail(f"import {module} failed: {last_line}", pytrace=False)
