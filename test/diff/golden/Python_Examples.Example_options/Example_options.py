from dataclasses import dataclass
from typing import Any, Callable
import Num
import Option

def describe_opt(x0):
    match x0:
        case Option.Nonea():
            return (0)
        case Option.Some(x):
            return ((x + 1))
        case _:
            raise RuntimeError("match failed")

o_some = (Option.Some(5))

d1 = (describe_opt(o_some))

o_none = (Option.Nonea())

d2 = (describe_opt(o_none))

def describe_opt2(x0):
    match x0:
        case Option.Some(x):
            return ((x + 100))
        case Option.Nonea():
            return ((- 1))
        case _:
            raise RuntimeError("match failed")

d3 = (describe_opt2(o_some))

d4 = (describe_opt2(o_none))
