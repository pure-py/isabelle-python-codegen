from dataclasses import dataclass
from typing import Any, Callable
import Num

example = ([1, 2, 3])

def prepend(x, xs):
    return ([x] + xs)

example2 = (prepend(5, example))
