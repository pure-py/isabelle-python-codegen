from dataclasses import dataclass
from typing import Any, Callable
import Orderings
import HOL

def _unimplemented(name):
    raise NotImplementedError(name)

def equal_int():
    return HOL.equal(equala = lambda a, b: (a == b))

def ord_int():
    return Orderings.ord(less_eq = lambda a, b: (a <= b ), less = lambda a, b: (a < b))

def preorder_int():
    return Orderings.preorder(ord_preorder = ord_int())

def order_int():
    return Orderings.order(preorder_order = preorder_int())

def linorder_int():
    return Orderings.linorder(order_linorder = order_int())
