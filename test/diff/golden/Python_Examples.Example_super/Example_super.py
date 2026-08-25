from dataclasses import dataclass
from typing import Any, Callable

@dataclass(frozen=True)
class Red:
    pass
@dataclass(frozen=True)
class Green:
    pass
@dataclass(frozen=True)
class Blue:
    pass

def describe_color(x0):
    match x0:
        case Red():
            return ("red")
        case Green():
            return ("green")
        case Blue():
            return ("blue")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class describable:
    describe: Callable

def describable_color():
    return describable(describe = lambda a: describe_color(a))

def describe_verbose_color(x0):
    match x0:
        case Red():
            return ("the color red")
        case Green():
            return ("the color green")
        case Blue():
            return ("the color blue")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class describable_verbose:
    describable_describable_verbose: Any
    describe_verbose: Callable

def describable_verbose_color():
    return describable_verbose(describable_describable_verbose =
                                 describable_color(),
                                describe_verbose =
                                  lambda a: describe_verbose_color(a))

def announce_verbose(a_dict, x):
    return (a_dict.describable_describable_verbose.describe(x) + " -- " +
              a_dict.describe_verbose(x))

announce_verbose_red = (announce_verbose(describable_verbose_color(), Red()))
