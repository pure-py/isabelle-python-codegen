from dataclasses import dataclass
from typing import Any, Callable
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class inta:
    pass
@dataclass(frozen=True)
class stra:
    pass
@dataclass(frozen=True)
class objecta:
    pass

def lena(x0):
    match x0:
        case []:
            return (0)
        case [uu, *ps]:
            return ((lena(ps) + 1))
        case _:
            raise RuntimeError("match failed")

def hasha(p):
    target = (p)
    match target:
        case inta():
            return (0)
        case stra():
            return (1)
        case objecta():
            return (2)
        case _:
            raise RuntimeError("match failed")
