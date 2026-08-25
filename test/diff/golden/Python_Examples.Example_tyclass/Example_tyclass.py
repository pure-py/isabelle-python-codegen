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

@dataclass(frozen=True)
class Circle:
    pass
@dataclass(frozen=True)
class Square:
    pass

def describe_shape(x0):
    match x0:
        case Circle():
            return ("circle")
        case Square():
            return ("square")
        case _:
            raise RuntimeError("match failed")

def describable_shape():
    return describable(describe = lambda a: describe_shape(a))

def announce(a_dict, x):
    return (a_dict.describe(x) + a_dict.describe(x))

announce_red = (announce(describable_color(), Red()))

announce_circle = (announce(describable_shape(), Circle()))
