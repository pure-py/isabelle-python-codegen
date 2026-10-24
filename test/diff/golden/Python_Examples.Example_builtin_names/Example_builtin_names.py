from dataclasses import dataclass
from typing import Any, Callable
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class int_:
    pass
@dataclass(frozen=True)
class str_:
    pass
@dataclass(frozen=True)
class object_:
    pass

def len_(x0):
    match x0:
        case []:
            return (0)
        case [uu, *ps]:
            return ((len_(ps) + 1))
        case _:
            raise RuntimeError("match failed")

def hash_(p):
    target = (p)
    match target:
        case int_():
            return (0)
        case str_():
            return (1)
        case object_():
            return (2)
        case _:
            raise RuntimeError("match failed")
