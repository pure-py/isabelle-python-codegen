from dataclasses import dataclass
from typing import Any, Callable
import Num

def cn_add(x, y):
    return ((x + y))

cn_neg = (-5)

cn_int_lit = (42)

cn_sum = (cn_add(cn_int_lit, 8))

def cn_nat_add(x, y):
    return ((x + y))

cn_nat_lit = (max(0, 7))

cn_nat_sum = (cn_nat_add(cn_nat_lit, (max(0, 3))))
