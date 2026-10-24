from dataclasses import dataclass
from typing import Any, Callable
import Arith

def _unimplemented(name):
    raise NotImplementedError(name)

def code(c):
    return (Arith.nat_of_char(c))

chars = (list("hi"))

greeting = (["h", "e", "l", "l", "o"])

literal = ("".join(greeting))

newline = ("\x0A")

def is_digit(c):
    return ("0" <= c and c <= "9")
