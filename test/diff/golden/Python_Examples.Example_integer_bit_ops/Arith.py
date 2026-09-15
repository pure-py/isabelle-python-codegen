from dataclasses import dataclass
from typing import Any, Callable
import Num
import Power
import Groups

def _unimplemented(name):
    raise NotImplementedError(name)

def one_integer():
    return Groups.one(onea = lambda : 1)

def times_integer():
    return Groups.times(timesa = lambda a, b: (a * b))

def power_integer():
    return Power.power(one_power = one_integer(), times_power = times_integer())

def drop_bit(i, k):
    return ((k // Power.powera(power_integer(), 2, (abs(i)))))

def push_bit(i, k):
    return ((k * Power.powera(power_integer(), 2, (abs(i)))))

def sgn_integer(k):
    if ((k == 0)):
        return (0)
    else:
        if ((k < 0)):
            return (-1)
        else:
            return (1)

def push_bit_integer(n, k):
    return (push_bit(n, k))

def bit_integer(k, n):
    return (not ((((k & push_bit_integer(n, 1))) == 0)))

def mask_integer(n):
    return ((push_bit_integer(n, 1) - 1))

def set_bit_integer(n, k):
    return ((k | push_bit_integer(n, 1)))

def drop_bit_integer(n, k):
    return (drop_bit(n, k))

def flip_bit_integer(n, k):
    return ((k ^ push_bit_integer(n, 1)))

def take_bit_integer(n, k):
    return ((k & mask_integer(n)))

def unset_bit_integer(n, k):
    return ((k & ((~ push_bit_integer(n, 1)))))
