from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class ord_:
    less_eq: Callable
    less: Callable

@dataclass(frozen=True)
class preorder:
    ord_preorder: Any

@dataclass(frozen=True)
class order:
    preorder_order: Any

@dataclass(frozen=True)
class linorder:
    order_linorder: Any

def len_rec(x0):
    match x0:
        case []:
            return (0)
        case [uu, *xs]:
            return ((len_rec(xs) + 1))
        case _:
            raise RuntimeError("match failed")

def shift_n(n, f):
    if ((n == 0)):
        return (f)
    else:
        return (shift_n((max(0, n - 1)), lambda x: f((x + 1))))

def sum_acc(n, acc):
    if ((n == 0)):
        return (acc)
    else:
        return (sum_acc((max(0, n - 1)), ((acc + (((max(0, n - 1)) + 1))))))

def count_le(a_dict, x, xa1, n):
    match (x, xa1, n):
        case (xa, [], na):
            return (na)
        case (xa, [y, *ys], na):
            if (a_dict.order_linorder.preorder_order.ord_preorder.less_eq(y, xa)):
                z = ((na + 1))
            else:
                z = (na)
            return (count_le(a_dict, xa, ys, z))
        case _:
            raise RuntimeError("match failed")

def gcd_loop(a, b):
    if ((b == 0)):
        return (a)
    else:
        return (gcd_loop(b, ((lambda a, b: a % b if b else a)(a, b))))
