from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

def nat_of_char(c):
    return ((ord(c)))
