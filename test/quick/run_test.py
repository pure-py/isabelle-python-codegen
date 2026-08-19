"""
Regression tests for the Isabelle-to-Python backend, run against the
Python code generated from Quick_Test.thy.

Prerequisite (run this first, from the project root):

    isabelle build -d . -e Python_Test_Quick

That generates Quick_Test.py somewhere under test/quick/python_out/
(Isabelle nests it under a session/theory-qualified subdirectory rather
than dropping it directly in python_out/, so this file searches for it
instead of assuming an exact path).
"""

import sys
from pathlib import Path

import pytest

THIS_DIR = Path(__file__).resolve().parent
PYTHON_OUT_ROOT = THIS_DIR / "python_out"


def _find_example_all():
    if not PYTHON_OUT_ROOT.exists():
        return None
    matches = list(PYTHON_OUT_ROOT.rglob("Quick_Test.py"))
    return matches[0] if matches else None


_module_path = _find_example_all()
if _module_path is None:
    pytest.skip(
        f"Quick_Test.py not found anywhere under {PYTHON_OUT_ROOT} -- run "
        "`isabelle build -d . -e Python_Test_Quick` first to generate it.",
        allow_module_level=True,
    )
else:
    sys.path.insert(0, str(_module_path.parent))
    import Quick_Test as m


# ---- tuples ----

def test_tuple_values():
    assert m.t_point == (3, 4)


def test_tuple_swap():
    assert m.t_swap(m.t_point) == (4, 3)


def test_tuple_add():
    assert m.t_add_points((1, 2), (3, 4)) == (4, 6)


def test_tuple_points_sum():
    # t_points_sum = t_add_points t_point (t_swap t_point)
    #              = (3,4) + (4,3) = (7,7)
    assert m.t_points_sum == (7, 7)


# ---- int arithmetic ----

def test_int_floor_division():
    # HOL's int div/mod use flooring semantics, matching Python's // and %
    assert m.i_quotient_neg == -4   # (-7) div 2
    assert m.i_remainder_neg == 1   # (-7) mod 2


def test_int_checksum():
    # (x*y) mod (y-x) + x div 2, x=5, y=3 -> 15 mod -2 + 2 = -1 + 2 = 1
    assert m.i_checksum(5, 3) == 1


# ---- nat arithmetic (monus, literals) ----

def test_nat_monus_truncates_at_zero():
    assert m.n_sub_trunc == 0   # 3 - 10, nat subtraction truncates at 0


def test_nat_monus_normal_case():
    assert m.n_sub_pos == 7     # 10 - 3


def test_nat_literal():
    assert m.n_literal == 42


# ---- nat structural pattern matching (0 / Suc) ----

def test_nat_factorial():
    assert m.n_fact(0) == 1
    assert m.n_fact_5 == 120
    assert m.n_fact(6) == 720


def test_nat_countdown():
    assert m.n_countdown(0) == [0]
    assert m.n_countdown_4 == [4, 3, 2, 1, 0]


# ---- records, including extension ----

def test_record_extension_roundtrip():
    # r_shifted3d = r_move_z r_origin3d 7, only pz changes
    assert m.r_total3d == 7


# ---- typeclasses / superclasses ----

def test_typeclass_dispatch():
    assert m.cls_default_b == 2   # default_val TagB
    assert m.cls_double_a == 2    # double_val TagA = 2 * default_val TagA (=1)