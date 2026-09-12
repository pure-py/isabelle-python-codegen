from dataclasses import dataclass
from typing import Any, Callable
import Num

def peel_positive_head(x0):
    match x0:
        case []:
            return (0)
        case [n, *va]:
            if ((n == 0)):
                return (0)
            else:
                return (max(0, n - 1))
        case _:
            raise RuntimeError("match failed")

peel_test = (peel_positive_head([3, 4, 5]))

def nat_minus2(v, n):
    if ((v == 0)):
        return (0)
    else:
        if ((n == 0)):
            return (((max(0, v - 1)) + 1))
        else:
            return (nat_minus2((max(0, v - 1)), (max(0, n - 1))))

def classify_small(uu):
    if ((uu == 0)):
        return (0)
    else:
        if (((max(0, uu - 1)) == 0)):
            return (1)
        else:
            return (2)

classify_test = ((classify_small(0), ((classify_small(1), classify_small(7)))))

nat_minus2_test = (nat_minus2(5, 3))
