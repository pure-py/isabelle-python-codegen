from dataclasses import dataclass
from typing import Any, Callable

@dataclass(frozen=True)
class Red:
    pass
@dataclass(frozen=True)
class Green:
    pass
@dataclass(frozen=True)
class Blue:
    pass

def is_red(x0):
    match x0:
        case Red():
            return (True)
        case Green():
            return (False)
        case Blue():
            return (False)
        case _:
            raise RuntimeError("match failed")
