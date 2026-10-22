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

# ---- int/nat remaining operators ----

def test_int_abs():
    assert m.i_abs_neg == 7

def test_int_sgn():
    assert m.i_sgn_neg == -1
    assert m.i_sgn_zero == 0
    assert m.i_sgn_pos == 1

def test_int_min_max():
    assert m.i_min_ab == 3
    assert m.i_max_ab == 9

def test_nat_min_max():
    assert m.n_min_ab == 3
    assert m.n_max_ab == 9


# ---- nested case expressions ----
 
def test_nested_case_expression():
    # nat_label n = 1 + (case n of 0 => 10 | Suc m => 20 + m)
    assert m.label_zero == 11   # 1 + 10
    assert m.label_five == 25   # 1 + (20 + 4), since 5 = Suc^5(0), m = 4
    assert m.nat_label(0) == 11
    assert m.nat_label(5) == 25


# ---- if/then/else ----
 
def test_if_then_else_whole_body():
    # abs_manual x = if x < 0 then -x else x
    assert m.abs_manual_neg == 7
    assert m.abs_manual_pos == 7
    assert m.abs_manual(-7) == 7
    assert m.abs_manual(7) == 7
 
 
def test_if_then_else_nested_in_expression():
    # classify n = 1 + (if n = 0 then 100 else 200)
    assert m.classify_zero == 101
    assert m.classify_other == 201
 
 
def test_if_then_else_branch_with_nested_case():
    # weird n = if n = 0 then 1 else 1 + (case n of 0 => 10 | Suc m => 20 + m)
    assert m.weird_zero == 1
    assert m.weird_five == 25


# ---- list pattern matching ----

def test_list_pattern_matching():
    # describe_len xs = Suc (case xs of [] => 0 | (_ # ys) => length ys)
    assert m.describe_len([]) == 1
    assert m.describe_len([1, 2, 3]) == 3
    assert m.describe_len_123 == 3


# ---- partial application ----

def test_partial_application():
    # add_one = add2 1 -- genuine partial application, eta-expanded via
    # Code_Thingol.saturated_application into a Python lambda
    assert m.add_one(5) == 6
    assert m.p_add_one_5 == 6


def test_bare_reference_and_point_free_alias():
    # add2_ref = add2 -- point-free alias; args_num falls back to the
    # declared type's arity since the alias's own equation has no
    # explicit parameters of its own
    assert m.p_ref_result == 7


def test_bare_binary_constant_as_function_value():
    # foldr add2 [1, 2, 3] 0 -- add2 passed bare must be curried, since foldr
    # applies it one argument at a time
    assert m.p_folded == 6


def test_map_native_list():
    # map add_one [1, 2, 3] -- requires the native code_printing
    # registration for List.map (Python_Setup.thy); without it this
    # silently fails to compile map's definition at all
    assert m.p_mapped == [2, 3, 4]


# ---- code numerals ----

def test_code_numeral_integer():
    assert m.cn_int_lit == 42
    assert m.cn_neg == -5
    assert m.cn_sum == 50


def test_code_numeral_natural():
    assert m.cn_nat_lit == 7
    assert m.cn_nat_sum == 10


# ---- records, including extension ----

def test_record_extension_roundtrip():
    # r_shifted3d = r_move_z r_origin3d 7, only pz changes
    assert m.r_total3d == 7


# ---- typeclasses / superclasses ----

def test_typeclass_dispatch():
    assert m.cls_default_b == 2   # default_val TagB
    assert m.cls_double_a == 2    # double_val TagA = 2 * default_val TagA (=1)


# ---- dictionary-parameterized instance ----

def test_dict_parameterized_instance():
    # has_default 'a list requires 'a's own has_default dictionary --
    # exercises print_dict_args for Class_Instance printing.
    assert m.cls_list_default == 2        # default_val TagB (first elem of [TagB, TagA])
    assert m.cls_list_default_empty == 0


# ---- options ----

def test_option_values():
    assert m.o_describe_some == 6
    assert m.o_describe_none == 0

# ---- hoisted multi-argument lambdas ----

def test_hoisted_lambda_is_curried():
    # apply2 calls its function argument as f(a)(b); the hoisted def must accept that.
    assert m.l_curried_none == 3
    assert m.l_curried_some == 7


# ---- native List.nth and IArray ----

def test_list_nth_is_native_indexing():
    assert m.ia_nth([5, 6, 7], 2) == 7
    assert not hasattr(m, "nth")


def test_iarray_is_tuple():
    assert m.ia_grid == ((0, 1, 2), (10, 11, 12))
    assert m.ia_get(1, 2) == 12
    assert m.ia_rows == [[0, 1, 2], [10, 11, 12]]


def test_iarray_pattern_and_exists():
    # IArray [] / IArray (x # _) patterns become sequence patterns on the tuple
    assert m.ia_head(()) == -1
    assert m.ia_head((4, 5)) == 4
    assert m.ia_any_neg((1, -2)) and not m.ia_any_neg(())


# ---- instance dictionaries ----

def test_dict_free_instance_is_built_once():
    # instances without dictionary arguments are wrapped in functools.cache,
    # so every use shares one (frozen) dictionary instead of rebuilding it
    assert m.has_default_tag() is m.has_default_tag()


# ---- division by zero (Isabelle semantics) ----

def test_div_mod_by_zero():
    assert m.z_int_div == 0
    assert m.z_int_mod == -7
    assert m.z_nat_div == 0
    assert m.z_nat_mod == 7
    assert m.z_int_floor == (-4, 1)     # floor division, as in Python


# ---- hoisting, constructors and dictionary-taking definitions ----

def test_hoisted_lambda_does_not_shadow_outer_vars():
    assert m.l_shadow_none == 104       # (1 + 3) + 100
    assert m.l_shadow_some == 14        # (1 + 3) + 10


def test_constructor_of_sorted_datatype():
    assert m.c_boxed == 5


def test_pattern_less_dict_function():
    assert m.e_twice_twice == 12


# ---- python_tail_calls (Quick_Test_Tail_Calls.thy, exported with the option on) ----

def _load_tail_calls():
    matches = list(PYTHON_OUT_ROOT.rglob("Quick_Test_Tail_Calls.py"))
    if not matches:
        pytest.skip("Quick_Test_Tail_Calls.py not generated")
    sys.path.insert(0, str(matches[0].parent))
    import Quick_Test_Tail_Calls
    return Quick_Test_Tail_Calls


def test_tail_calls_run_as_loops():
    tc = _load_tail_calls()
    # computed at import, 100000 calls deep without the loop
    assert tc.tc_sum_big == 100000 * 100001 // 2
    # the list is built in Python: upt itself is not tail recursive. Kept at 20000, as each
    # [y, *ys] match copies the tail (quadratic), but still far deeper than 1000 frames.
    assert tc.tc_count_le_int(10000, list(range(20000)), 0) == 10001


def test_tail_calls_with_closures_stay_recursive():
    tc = _load_tail_calls()
    assert tc.tc_shift_small == 13
    assert tc.tc_shift(3, lambda x: x)(0) == 3
