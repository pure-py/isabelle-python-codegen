from dataclasses import dataclass
from typing import Any, Callable
import Num

def fact(x0):
    match x0:
        case 0:
            return (1)
        case c if c >= 1:
            n = (c - 1)
            return ((((n + 1)) * fact(n)))
        case _:
            raise RuntimeError("match failed")

fact_5 = (fact(5))

def countdown(x0):
    match x0:
        case 0:
            return ([0])
        case c if c >= 1:
            n = (c - 1)
            return ([(n + 1)] + countdown(n))
        case _:
            raise RuntimeError("match failed")

def nat_is_even(x0):
    match x0:
        case 0:
            return (True)
        case c if c >= 1:
            n = (c - 1)
            return (not nat_is_even(n))
        case _:
            raise RuntimeError("match failed")

is_even_7 = (nat_is_even(7))

countdown_4 = (countdown(4))
