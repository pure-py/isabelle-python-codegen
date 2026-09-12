from dataclasses import dataclass
from typing import Any, Callable
import Num

point = ((3, 4))

triple = ((1, ((2, 3))))

def swap_pair(p):
    return (((p[1]), (p[0])))

def add_points(x0, x1):
    match (x0, x1):
        case ((x1a, y1), (x2, y2)):
            return ((((x1a + x2)), ((y1 + y2))))

point_swapped = (swap_pair(point))

points_sum = (add_points(point, point_swapped))

points_list = ([point, point_swapped])
