from dataclasses import dataclass
from typing import Any, Callable

@dataclass(frozen=True)
class super_op:
    sup_apply: Callable

@dataclass(frozen=True)
class sub_op:
    super_op_sub_op: Any

def sub_apply(a_dict, x):
    return (a_dict.super_op_sub_op.sup_apply(a_dict.super_op_sub_op.sup_apply(x)))
