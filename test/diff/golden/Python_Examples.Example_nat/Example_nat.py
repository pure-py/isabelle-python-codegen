from dataclasses import dataclass
from typing import Any, Callable
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

def _abort(msg, thunk):
    raise RuntimeError(msg)

nat_sum = ((6 + 7))

nat_eq_test = ((4 == 4))

nat_le_test = ((3 <= 5))

nat_literal = (42)

nat_lt_test = ((5 < 3))

nat_product = ((6 * 7))

nat_sub_pos = (max(0, 10 - 3))

def nat_checksum(x, y):
    return ((((lambda a, b: a % b if b else a)(((x * y)), ((y + 1)))) + (max(0, x - y))))

nat_quotient = ((lambda a, b: a // b if b else 0)(7, 2))

nat_remainder = ((lambda a, b: a % b if b else a)(7, 2))

nat_sub_trunc = (max(0, 3 - 10))

nat_zero_test = (0)
