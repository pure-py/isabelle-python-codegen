from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class one:
    onea: Callable

@dataclass(frozen=True)
class times:
    timesa: Callable
