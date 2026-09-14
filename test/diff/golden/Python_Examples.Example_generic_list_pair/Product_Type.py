from dataclasses import dataclass
from typing import Any, Callable

@dataclass(frozen=True)
class Pair:
    a: Any
    b: Any
