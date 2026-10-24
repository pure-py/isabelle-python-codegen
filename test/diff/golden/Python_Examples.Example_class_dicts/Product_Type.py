from dataclasses import dataclass
from typing import Any, Callable
import HOL

def _unimplemented(name):
    raise NotImplementedError(name)

def _abort(msg, thunk):
    raise RuntimeError(msg)

def equal_proda(a_dict, b_dict, x0, x1):
    match (x0, x1):
        case ((x1a, x2), (y1, y2)):
            return (HOL.eq(a_dict, x1a, y1) and HOL.eq(b_dict, x2, y2))

def equal_prod(a_dict, b_dict):
    return HOL.equal(equala = lambda a, b: equal_proda(a_dict, b_dict, a, b))
