from dataclasses import dataclass
from typing import Any, Callable
import Num

def fact(n):
    if ((n == 0)):
        return (1)
    else:
        return (((((max(0, n - 1)) + 1)) * fact((max(0, n - 1)))))

fact_5 = (fact(5))

def countdown(n):
    if ((n == 0)):
        return ([0])
    else:
        return ([((max(0, n - 1)) + 1)] + countdown((max(0, n - 1))))

def nat_is_even(n):
    if ((n == 0)):
        return (True)
    else:
        return (not nat_is_even((max(0, n - 1))))

is_even_7 = (nat_is_even(7))

countdown_4 = (countdown(4))
