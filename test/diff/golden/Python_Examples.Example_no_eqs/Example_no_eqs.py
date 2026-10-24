from dataclasses import dataclass
from typing import Any, Callable
import HOL

def _unimplemented(name):
    raise NotImplementedError(name)

def _abort(msg, thunk):
    raise RuntimeError(msg)

uses_undefined = (HOL.undefined())
