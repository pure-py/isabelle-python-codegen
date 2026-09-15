from dataclasses import dataclass
from typing import Any, Callable
import Arith
import Num

def _unimplemented(name):
    raise NotImplementedError(name)

test_bit = (Arith.bit_integer(10, 1))

test_sgn = (Arith.sgn_integer(-42))

test_mask = (Arith.mask_integer(5))

test_set_bit = (Arith.set_bit_integer(2, 0))

test_drop_bit = (Arith.drop_bit_integer(2, 20))

test_flip_bit = (Arith.flip_bit_integer(1, 5))

test_push_bit = (Arith.push_bit_integer(3, 5))

test_take_bit = (Arith.take_bit_integer(4, 255))

test_unset_bit = (Arith.unset_bit_integer(0, 7))
