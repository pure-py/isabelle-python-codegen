from dataclasses import dataclass
from typing import Any, Callable
import HOL

def _unimplemented(name):
    raise NotImplementedError(name)

def equal_nat():
    return HOL.equal(equala = lambda a, b: (a == b))
