from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class Nil:
    pass
@dataclass(frozen=True)
class Cons:
    a: Any
    b: Any
