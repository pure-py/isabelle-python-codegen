from dataclasses import dataclass
from typing import Any, Callable
import Groups

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class power:
    one_power: Any
    times_power: Any

def powera(a_dict, aa, n):
    if ((n == 0)):
        return (a_dict.one_power.one())
    else:
        return (a_dict.times_power.times(aa, powera(a_dict, aa, (max(0, n - 1)))))
