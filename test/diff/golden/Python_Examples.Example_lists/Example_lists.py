from dataclasses import dataclass
from typing import Any, Callable
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

def _abort(msg, thunk):
    raise RuntimeError(msg)

example = ([1, 2, 3])

def prepend(x, xs):
    return ([x] + xs)

example2 = (prepend(5, example))
