from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

def undefined():
    raise NotImplementedError("HOL.undefined")
