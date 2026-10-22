"""
Differential tests: the Python generated for each python_check case in
test/oracle/Oracle_*.thy must agree with Isabelle's SML evaluation of the
same term.

Prerequisite (run this first, from the project root):

    isabelle build -d . -e Python_Test_Oracle

Each theory that runs python_export_checks exports oracle/manifest.json and
the generated modules under test/oracle/python_out/<session>.<theory>/.
Each check `c` in the manifest names the module that defines `c_ok` (the
generated `t = r`, where r is Isabelle's value of t) and `c_actual` (the
generated t, for failure messages), both functions of a unit argument.
"""

import importlib
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
    m = _import(code_dir, module)
    name = check["name"]
    if getattr(m, f"{name}_ok")(None) is not True:
        actual = getattr(m, f"{name}_actual")(None)
        pytest.fail(
            f"{check['term']}\n"
            f"  Isabelle: {check['expected']}\n"
            f"  Python:   {actual!r}"
        )
