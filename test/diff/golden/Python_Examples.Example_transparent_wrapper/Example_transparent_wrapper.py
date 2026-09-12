from dataclasses import dataclass
from typing import Any, Callable

def unbox(n):
    return (n)

unbox_test = (unbox(True))

def box_is_true(x0):
    match x0:
        case c if (c == True):
            return (True)
        case c if (c == False):
            return (False)
        case _:
            raise RuntimeError("match failed")

box_is_true_test = ((box_is_true(True), box_is_true(False)))
