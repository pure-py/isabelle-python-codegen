from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

def const_fn(x, uu, uv):
    return ((x + 1))
