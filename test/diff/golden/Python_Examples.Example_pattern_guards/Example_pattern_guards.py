from dataclasses import dataclass
from typing import Any, Callable
import Num

def nat_fib(x0):
    match x0:
        case 0:
            return (0)
        case c if c == 1:
            return (1)
        case c if c >= 2:
            n = (c - 2)
            return ((nat_fib(n) + nat_fib(((n + 1)))))
        case _:
            raise RuntimeError("match failed")

fib_0 = (nat_fib(0))

fib_1 = (nat_fib(1))

fib_6 = (nat_fib(6))

def at_least_two(x0):
    match x0:
        case 0:
            return (False)
        case c if c == 1:
            return (False)
        case c if c >= 2:
            uu = (c - 2)
            return (True)
        case _:
            raise RuntimeError("match failed")

alt2_0 = (at_least_two(0))

alt2_1 = (at_least_two(1))

alt2_5 = (at_least_two(5))

def starts_with_succ(x0):
    match x0:
        case [c, *uv] if c >= 1:
            uu = (c - 1)
            return (True)
        case []:
            return (False)
        case [0, *va]:
            return (False)
        case _:
            raise RuntimeError("match failed")

sws_empty = (starts_with_succ([]))

def sum_of_preds(x0):
    match x0:
        case [c, *xs] if c >= 1:
            n = (c - 1)
            return ((n + sum_of_preds(xs)))
        case [0, *xs]:
            return (sum_of_preds(xs))
        case []:
            return (0)
        case _:
            raise RuntimeError("match failed")

sop_result = (sum_of_preds([3, 0, 5, 2]))

sws_succ_head = (starts_with_succ([3, 1, 2]))

sws_zero_head = (starts_with_succ([0, 1, 2]))
