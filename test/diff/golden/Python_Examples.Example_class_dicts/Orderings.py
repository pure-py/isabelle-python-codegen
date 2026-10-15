from dataclasses import dataclass
from typing import Any, Callable

def _unimplemented(name):
    raise NotImplementedError(name)

@dataclass(frozen=True)
class ord:
    less_eq: Callable
    less: Callable

@dataclass(frozen=True)
class preorder:
    ord_preorder: Any

@dataclass(frozen=True)
class order:
    preorder_order: Any

@dataclass(frozen=True)
class linorder:
    order_linorder: Any
