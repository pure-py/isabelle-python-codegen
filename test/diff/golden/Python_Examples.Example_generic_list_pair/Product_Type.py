from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class Pair:
    a: Any
    b: Any
