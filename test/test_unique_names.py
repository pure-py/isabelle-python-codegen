"""
Every generated module must bind each top-level name (and each name in a
class body) only once. If the backend gives two constants the same Python
name, the later binding silently shadows the earlier one and calls to the
first constant run the second; the code still imports and often still
passes tests that do not exercise both.

The check is purely syntactic (ast), so it runs on whatever has been
generated: the outputs of the quick, oracle, slow and example sessions, and
the checked-in golden files. Build the sessions first (see the Makefile),
then:

    uv run pytest test/test_unique_names.py -q

or, on any files or directories:

    uv run python3 test/test_unique_names.py PATH...
"""

import ast
import sys
from collections import Counter
from pathlib import Path

import pytest

THIS_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = THIS_DIR.parent

SEARCH_ROOTS = [
    PROJECT_ROOT / "examples" / "python_out",
    THIS_DIR / "quick" / "python_out",
    THIS_DIR / "oracle" / "python_out",
    THIS_DIR / "slow" / "generated_basic",
    THIS_DIR / "slow" / "generated_full",
    THIS_DIR / "diff" / "golden",
]

# Temporaries the backend invents (invent_name in code_python.ML) for lambdas and
# top-level matches; each is used right after it is bound, so rebinding is harmless.
TEMPORARIES = {"lam", "target"}


def _bound_names(body):
    """Names bound directly by the statements of a module or class body."""
    for stmt in body:
        if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            yield stmt.name
        elif isinstance(stmt, ast.Assign):
            for target in stmt.targets:
                if isinstance(target, ast.Name):
                    yield target.id
        elif isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name):
            yield stmt.target.id
        elif isinstance(stmt, ast.TypeAlias):
            yield stmt.name.id


def duplicate_names(source, filename="<generated>"):
    """List of (scope, name, count) for every name bound more than once."""
    tree = ast.parse(source, filename)
    scopes = [("<module>", tree.body)]
    scopes += [
        (stmt.name, stmt.body) for stmt in ast.walk(tree) if isinstance(stmt, ast.ClassDef)
    ]
    return [
        (scope, name, count)
        for scope, body in scopes
        for name, count in Counter(_bound_names(body)).items()
        if count > 1 and name not in TEMPORARIES
    ]


def _python_files(paths):
    for path in paths:
        if path.is_dir():
            yield from sorted(path.rglob("*.py"))
        elif path.suffix == ".py":
            yield path


_FILES = list(_python_files(root for root in SEARCH_ROOTS if root.exists()))

if __name__ != "__main__" and not _FILES:
    pytest.skip(
        "No generated modules found -- build a test session first (e.g. "
        "`isabelle build -d . -e Python_Test_Quick`).",
        allow_module_level=True,
    )


@pytest.mark.parametrize("path", _FILES, ids=lambda p: p.relative_to(PROJECT_ROOT).as_posix())
def test_names_bound_once(path):
    dups = duplicate_names(path.read_text(), str(path))
    assert not dups, "names bound more than once: " + ", ".join(
        f"{name} ({count}x in {scope})" for scope, name, count in dups
    )


if __name__ == "__main__":
    status = 0
    for path in _python_files(Path(arg) for arg in sys.argv[1:]):
        for scope, name, count in duplicate_names(path.read_text(), str(path)):
            print(f"{path}: {name} bound {count} times in {scope}")
            status = 1
    sys.exit(status)
