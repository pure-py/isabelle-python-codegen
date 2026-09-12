from dataclasses import dataclass
from typing import Any, Callable

@dataclass(frozen=True)
class Box:
    pass
@dataclass(frozen=True)
class Crate:
    pass

def label_of_item(x0):
    match x0:
        case Box():
            return ("box")
        case Crate():
            return ("crate")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class labeled:
    label_of: Callable

def labeled_item():
    return labeled(label_of = lambda a: label_of_item(a))

def size_label_item(x0):
    match x0:
        case Box():
            return ("small")
        case Crate():
            return ("large")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class measured:
    size_label: Callable

def measured_item():
    return measured(size_label = lambda a: size_label_item(a))

def full_description_item(x0):
    match x0:
        case Box():
            return ("a plain cardboard box")
        case Crate():
            return ("a sturdy wooden crate")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class labeled_measured:
    labeled_labeled_measured: Any
    measured_labeled_measured: Any
    full_description: Callable

def labeled_measured_item():
    return labeled_measured(labeled_labeled_measured = labeled_item(), measured_labeled_measured = measured_item(), full_description = lambda a: full_description_item(a))

@dataclass(frozen=True)
class Cat:
    pass
@dataclass(frozen=True)
class Dog:
    pass

def tag_animal(x0):
    match x0:
        case Cat():
            return ("cat")
        case Dog():
            return ("dog")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class tagged:
    tag: Callable

def tagged_animal():
    return tagged(tag = lambda a: tag_animal(a))

def tag_verbose_animal(x0):
    match x0:
        case Cat():
            return ("the animal cat")
        case Dog():
            return ("the animal dog")
        case _:
            raise RuntimeError("match failed")

def tag_extra_animal(x0):
    match x0:
        case Cat():
            return ("a small domesticated cat")
        case Dog():
            return ("a loyal domesticated dog")
        case _:
            raise RuntimeError("match failed")

@dataclass(frozen=True)
class tagged_verbose:
    tagged_tagged_verbose: Any
    tag_verbose: Callable

@dataclass(frozen=True)
class tagged_extra:
    tagged_verbose_tagged_extra: Any
    tag_extra: Callable

def tagged_verbose_animal():
    return tagged_verbose(tagged_tagged_verbose = tagged_animal(), tag_verbose = lambda a: tag_verbose_animal(a))

def tagged_extra_animal():
    return tagged_extra(tagged_verbose_tagged_extra = tagged_verbose_animal(), tag_extra = lambda a: tag_extra_animal(a))

def announce_chain(a_dict, x):
    return (a_dict.tagged_verbose_tagged_extra.tagged_tagged_verbose.tag(x) + " | " + a_dict.tagged_verbose_tagged_extra.tag_verbose(x) + " | " + a_dict.tag_extra(x))

def announce_multi(a_dict, x):
    return (a_dict.labeled_labeled_measured.label_of(x) + " (" + a_dict.measured_labeled_measured.size_label(x) + ") -- " + a_dict.full_description(x))

announce_chain_cat = (announce_chain(tagged_extra_animal(), Cat()))

announce_multi_box = (announce_multi(labeled_measured_item(), Box()))
