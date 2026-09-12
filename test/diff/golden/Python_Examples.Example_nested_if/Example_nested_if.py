from dataclasses import dataclass
from typing import Any, Callable
import Num

def grade_code(score):
    if ((score < 60)):
        return (0)
    else:
        if ((score < 70)):
            return (1)
        else:
            if ((score < 80)):
                return (2)
            else:
                if ((score < 90)):
                    return (3)
                else:
                    return (4)

grade_a = (grade_code(95))

grade_b = (grade_code(85))

grade_c = (grade_code(75))

grade_d = (grade_code(65))

grade_f = (grade_code(40))

def nested_then(x, y):
    if ((0 < x)):
        if ((0 < y)):
            return (1)
        else:
            return (2)
    else:
        return (3)

nested_then_f = (nested_then(((- 1)), 1))

nested_then_tf = (nested_then(1, ((- 1))))

nested_then_tt = (nested_then(1, 1))
