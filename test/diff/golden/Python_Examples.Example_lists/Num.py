from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class One:
    pass
@dataclass(frozen=True)
class Bit0:
    a: Any
@dataclass(frozen=True)
class Bit1:
    a: Any
