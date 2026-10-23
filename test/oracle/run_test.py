"""
Differential tests: the Python generated for each python_check case in
test/oracle/Oracle_*.thy must agree with Isabelle's SML evaluation of the
same term.

Prerequisite (run this first, from the project root):

    isabelle build -d . -e Python_Test_Oracle

Then:

    uv run pytest test/oracle/run_test.py -q --tb=line


Each theory that runs python_export_checks exports oracle/manifest.json and
the generated modules under test/oracle/python_out/<session>.<theory>/.
Each check `c` in the manifest names the module that defines `c_ok` (the
generated `t = r`, where r is Isabelle's value of t) and `c_actual` (the
generated t, for failure messages), both functions of a unit argument.
"""

import importlib
import inspect
import json
import sys
from pathlib import Path

import pytest

THIS_DIR = Path(__file__).resolve().parent
PYTHON_OUT_ROOT = THIS_DIR / "python_out"

def _load_manifests():
    if not PYTHON_OUT_ROOT.exists():
        return []
    return sorted(PYTHON_OUT_ROOT.rglob("oracle/manifest.json"))

def _cases():
    for manifest_path in _load_manifests():
        manifest = json.loads(manifest_path.read_text())
        code_dir = manifest_path.parent.parent / "code"
        for check in manifest["checks"]:
            yield pytest.param(
                code_dir, check["module"], check,
                id=f"{manifest_path.parent.parent.name}:{check['name']}",
            )

_CASES = list(_cases())
if not _CASES:
    pytest.skip(
        f"no oracle/manifest.json under {PYTHON_OUT_ROOT} -- run "
        "`isabelle build -d . -e Python_Test_Oracle` first.",
        allow_module_level=True,
    )

_loaded = {}

def _import(code_dir, module):
    # Each export directory has its own copy of the same module names
    # (Num, List, Oracle_Arith, ...), so forget the previous directory's
    # modules before importing from another one.
    key = (code_dir, module)
    if key not in _loaded:
        for path in code_dir.glob("*.py"):
            sys.modules.pop(path.stem, None)
        sys.path.insert(0, str(code_dir))
        try:
            _loaded[key] = importlib.import_module(module)
        finally:
            sys.path.remove(str(code_dir))
    return _loaded[key]


@pytest.mark.parametrize("code_dir,module,check", _CASES)
def test_agrees_with_isabelle(code_dir, module, check):
    # Each failure's first line names the term and the verdict, since that line is
    # all that --tb=line shows.
    term = check["term"]
    try:
        m = _import(code_dir, module)
    except Exception as e:
        pytest.fail(f"{term}: module {module} does not import: {_describe(e)}",
                    pytrace=False)
    name = check["name"]
    actual_fn = getattr(m, f"{name}_actual")
    try:
        ok = getattr(m, f"{name}_ok")(None)
    except Exception as e:
        pytest.fail(f"{term}: Isabelle gives {check['expected']}, "
                    f"Python raises {_describe(e)}\n  {_source(actual_fn)}",
                    pytrace=False)
    if ok is not True:
        pytest.fail(f"{term}: Isabelle gives {check['expected']}, "
                    f"Python gives {actual_fn(None)!r}\n  {_source(actual_fn)}",
                    pytrace=False)


def _describe(e):
    message = str(e).splitlines()[0] if str(e) else ""
    return f"{type(e).__name__}: {message}" if message else type(e).__name__


def _source(fn):
    code = fn.__code__
    try:
        source = inspect.getsource(fn).strip()
    except:
        source = "<source unavailable>"
    return f"{Path(code.co_filename).name}:{code.co_firstlineno}: {source}"
