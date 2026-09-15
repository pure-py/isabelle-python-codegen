from dataclasses import dataclass
from typing import Any, Callable
import Option

def _unimplemented(name):
    raise NotImplementedError(name)

def doubled(xs):
    return (list(map(lambda n: (n + n), xs)))

def sum_or_zero(x0):
    match x0:
        case Option.Nonea():
            return (0)
        case Option.Some(n):
            return (n)
        case _:
            raise RuntimeError("match failed")

def sum_options_named(xs):
    return (list(map(sum_or_zero, xs)))

def sum_options_inline(xs):
    def lam(a):
        target = (a)
        match target:
            case Option.Nonea():
                return (0)
            case Option.Some(n):
                return (n)
            case _:
                raise RuntimeError("match failed")
    return (list(map(lam, xs)))
