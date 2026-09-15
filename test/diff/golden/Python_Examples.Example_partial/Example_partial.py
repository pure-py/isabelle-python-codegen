from dataclasses import dataclass
from typing import Any, Callable
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

def add2(x, y):
    return ((x + y))

add_one = (lambda a: add2(1, a))

add2_ref = (add2)

p_mapped = (list(map(add_one, [1, 2, 3])))

def apply_twice(f, x):
    return (f(f(x)))

p_result = (apply_twice(add_one, 5))

p_ref_result = (add2_ref(3, 4))
