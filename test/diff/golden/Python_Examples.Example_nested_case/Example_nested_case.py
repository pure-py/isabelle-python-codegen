from dataclasses import dataclass
from typing import Any, Callable
import Num

def weird(n):
    if (n == 0):
        return (1)
    else:
        if (n == 0):
            x = (10)
        else:
            x = ((20 + (max(0, n - 1))))
        return ((1 + x))

def classify(n):
    if (n == 0):
        x = (100)
    else:
        x = (200)
    return ((1 + x))

def nat_label(n):
    if (n == 0):
        x = (10)
    else:
        x = ((20 + (max(0, n - 1))))
    return ((1 + x))

def abs_manual(x):
    if (x < 0):
        return ((- x))
    else:
        return (x)

label_five = (nat_label(5))

label_zero = (nat_label(0))

weird_five = (weird(5))

weird_zero = (weird(0))

def describe_len(xs):
    target = xs
    match target:
        case []:
            x = (0)
        case [_, *a]:
            x = (len(a))
        case _:
            raise RuntimeError("match failed")
    return ((x + 1))

classify_zero = (classify(0))

abs_manual_neg = (abs_manual(((- 7))))

abs_manual_pos = (abs_manual(7))

classify_other = (classify(5))

describe_len_123 = (describe_len([1, 2, 3]))
