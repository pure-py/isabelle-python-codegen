from dataclasses import dataclass
from typing import Any, Callable
import Example_classrel_base

def _unimplemented(name):
    raise NotImplementedError(name)

def sup_apply_bool(b):
    return (b)

def super_op_bool():
    return Example_classrel_base.super_op(sup_apply = lambda a: sup_apply_bool(a))

def sub_op_bool():
    return Example_classrel_base.sub_op(super_op_sub_op = super_op_bool())

test_sub = (Example_classrel_base.sub_apply(sub_op_bool(), True))

test_super = (sup_apply_bool(True))
