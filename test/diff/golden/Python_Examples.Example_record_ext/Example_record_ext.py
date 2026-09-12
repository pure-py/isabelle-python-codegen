from dataclasses import dataclass
from typing import Any, Callable
import Num

@dataclass(frozen=True)
class point_exta:
    px: Any
    py: Any
    more: Any

@dataclass(frozen=True)
class point3d_exta:
    pz: Any
    more: Any

def pz_update(pza, x1):
    match (pza, x1):
        case (pzaa, point_exta(px, py, point3d_exta(pz, more))):
            return (point_exta(px, py, point3d_exta((pzaa(pz)), more)))

def pz(x0):
    match x0:
        case point_exta(px, py, point3d_exta(pz, more)):
            return (pz)

def move_z(p, dz):
    return (pz_update(lambda _: (pz(p) + dz), p))

def py(x0):
    match x0:
        case point_exta(px, py, more):
            return (py)

def px(x0):
    match x0:
        case point_exta(px, py, more):
            return (px)

def point3d_sum(p):
    return ((((px(p) + py(p))) + pz(p)))

origin3d = (point_exta(0, 0, point3d_exta(0, None)))

shifted3d = (move_z(origin3d, 7))

total3d = (point3d_sum(shifted3d))
