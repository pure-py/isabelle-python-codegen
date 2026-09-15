from dataclasses import dataclass
from typing import Any, Callable
import HOL

def _unimplemented(name):
    raise NotImplementedError(name)

uses_undefined = (HOL.undefined())
