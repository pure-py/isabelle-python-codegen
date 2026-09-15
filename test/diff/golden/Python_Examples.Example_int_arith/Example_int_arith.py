from dataclasses import dataclass
from typing import Any, Callable
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

product = ((6 * 7))

def checksum(x, y):
    return ((((((x * y)) % ((y - x)))) + ((x // 2))))

zero_test = (0)

neg_product = ((((- 3)) * 4))

quotient_neg = ((((- 7)) // 2))

quotient_pos = ((7 // 2))

remainder_neg = ((((- 7)) % 2))

remainder_pos = ((7 % 2))

quotient_neg_divisor = ((7 // ((- 2))))

remainder_neg_divisor = ((7 % ((- 2))))
