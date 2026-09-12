from dataclasses import dataclass
from typing import Any, Callable
import Num

@dataclass(frozen=True)
class point_exta:
    px: Any
    py: Any
    more: Any

def py(x0):
    match x0:
        case point_exta(px, py, more):
            return (py)

def px(x0):
    match x0:
        case point_exta(px, py, more):
            return (px)

def point_sum(p, q):
    return ((((((px(p) + py(p))) + px(q))) + py(q)))

origin = (point_exta(0, 0, None))

def px_update(pxa, x1):
    match (pxa, x1):
        case (pxaa, point_exta(px, py, more)):
            return (point_exta((pxaa(px)), py, more))

def move_x(p, dx):
    return (px_update(lambda _: (px(p) + dx), p))

shifted = (move_x(origin, 5))

total = (point_sum(origin, shifted))
