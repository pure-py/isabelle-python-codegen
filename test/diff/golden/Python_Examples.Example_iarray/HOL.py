from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

def _abort(msg, thunk):
    raise RuntimeError(msg)

@dataclass(frozen=True)
class equal:
    equala: Callable

def eq(a_dict, aa, b):
    return (a_dict.equala(aa, b))
