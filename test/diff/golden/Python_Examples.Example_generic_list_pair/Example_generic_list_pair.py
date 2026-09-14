from dataclasses import dataclass
from typing import Any, Callable
import List
import Product_Type

def swap(x0):
    match x0:
        case Product_Type.Pair(x, y):
            return (Product_Type.Pair(y, x))

def any_true(x0):
    match x0:
        case List.Nil():
            return (False)
        case List.Cons(x, xs):
            return (x or any_true(xs))
        case _:
            raise RuntimeError("match failed")

test_swap = (swap(Product_Type.Pair(True, False)))

test_any_true = (any_true(List.Cons(False, List.Cons(False, List.Cons(True, List.Nil())))))

def first_two_agree(x0):
    match x0:
        case List.Cons(x, List.Cons(y, uu)):
            return (x == y)
        case List.Nil():
            return (False)
        case List.Cons(v, List.Nil()):
            return (False)
        case _:
            raise RuntimeError("match failed")

test_first_two = (Product_Type.Pair(first_two_agree(List.Cons(True, List.Cons(True, List.Cons(False, List.Nil())))), first_two_agree(List.Cons(True, List.Nil()))))
