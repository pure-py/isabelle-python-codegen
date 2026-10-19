from dataclasses import dataclass
from typing import Any, Callable
import functools
import HOL

def _unimplemented(name):
    raise NotImplementedError(name)

@functools.cache
def equal_nat():
    return HOL.equal(equala = lambda a, b: (a == b))
