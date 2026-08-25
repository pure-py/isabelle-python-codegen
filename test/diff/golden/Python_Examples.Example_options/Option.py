from dataclasses import dataclass
from typing import Any, Callable

@dataclass(frozen=True)
class Nonea:
    pass
@dataclass(frozen=True)
class Some:
    a: Any
