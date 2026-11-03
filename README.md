# isabelle-python-codegen

A custom Isabelle/HOL code-generation backend that targets
Python 3.

## Requirements

- A recent Isabelle/HOL release (with `isabelle` on your `PATH`, currently only 
`Isabelle2025-2` has been tested)
- [uv](https://docs.astral.sh/uv/), which runs Python at the version in `.python-version`, the target version of
  the generated code

## Installing as a component

```bash
git clone https://github.com/pure-py/isabelle-python-codegen.git
cd isabelle-python-codegen
isabelle components -u "$(pwd)"
```

This registers the `Python` session so other Isabelle projects can depend
on it without a `-d` flag:

```isabelle
session My_Project = Python +
  theories
    My_Theory
```

## Using the code generator

In order to use this generator you have to import one of the following theories:

- `Python.Python`
- `Python.Python_Setup`

`Python.Python` introduces only a minimum set of custom printers (Booleans, Unit,
Strings), and relies on the automatically extracted HOL definitions for other
things.

`Python.Python_Setup` extends `Python.Python` by printing `int` and `nat` as
Python integers, lists as Python lists, pairs as tuples and `char` as
one-character strings.

### Reserved names

Generated code must not use Python's keywords as names, nor hide the builtins
it calls itself (`len`, `list`, `range`, ...). The names to avoid are listed one
per line in `etc/python_reserved_words`: the keywords, soft keywords and
builtins of the Python version in `.python-version`. Lines starting with `#`
are comments. `Python.thy` reserves every name in the file, together with the
names that the prelude of each generated module binds (`dataclass`, `Any`,
`Callable`, `Never`, `cast`, `functools`, `_abort`, `_cached`, `_unimplemented`;
`prelude_names` in
`code_python.ML`).

### Values and modules

A value is printed as a cached function without arguments, and its uses call
it, so it is evaluated once, when it is first used:

```python
@functools.cache
def num_of_nat():
    return (Fun.comp(Arith.num_of_integer, lambda a: a))
```

Code that uses the generated modules therefore calls a value too
(`Example_nat.nat_sum()`). An alias of a function (`f_int = f`), or a value
whose type is a function of two or more arguments, is printed as an ordinary
function instead.

Importing a module thus evaluates nothing, which matters for two reasons. Each
theory becomes a Python module (unless `code_identifier` or the `module_name` of
`export_code` says otherwise), and code equations may use constants of later
theories, e.g. `Num.num_of_nat` is implemented by `Code_Numeral.num_of_integer`.
So the modules can import each other: in the HOL library, about 50 modules form
one import cycle. Python allows this as long as no module reads an attribute of
a module that is still being imported, which evaluating a value could do. And a
value that calls a constant without code (`_abort`) raises when it is used,
rather than when its module is imported.

A definition, class or datatype with a reserved name gets a trailing
underscore (`tuple` becomes `tuple_`), and a variable gets a fresh variant
(`len` becomes `lena`).

The list is generated rather than edited by hand. After changing
`.python-version`, regenerate it with

```bash
make reserved-words
```

which runs `etc/update_reserved_words.py` with the project's Python through
`uv run`. The script refuses to run under any other Python version than the
one in `.python-version`. Commit the updated list with the version change.
`Python.thy` declares the file with `external_file`, so the next
`isabelle build` rebuilds the `Python` session, and every session built on it,
whenever the list changes.

### Tail calls as loops

Python does not eliminate tail calls, so a function that recurses once per
element hits the default recursion limit of 1000 frames. With the option
`python_tail_calls` (off by default), a function that calls itself in tail
position is printed with its body inside `while True:`, and each such call
becomes a reassignment of its parameters followed by `continue`. Set it for a
whole build, without changing any theory:

```bash
isabelle build -o python_tail_calls -d . -e Python_Examples
```

or in a theory, before `export_code`:

```isabelle
declare [[python_tail_calls]]
```

Only direct self calls are turned into loops, not mutual recursion. A function
whose equations create closures (a lambda, or a partial application printed as
one) is left recursive: Python closures capture variables, not values, so a
closure created in one iteration would see the next iteration's rebinding.
`examples/Example_tail_calls.thy` shows both outputs side by side.

### Type annotations

The option `python_type_annotations` (off by default) is the start of type
annotations in the generated code, in the PEP 695 syntax of Python 3.12. It is
work in progress: it covers datatypes, functions, values and type classes, but
not yet local definitions such as hoisted lambdas. Each constructor becomes a generic dataclass with typed
fields, over the type parameters these fields use, and the datatype becomes the
union of its constructors:

```python
@dataclass(frozen=True)
class None_:
    pass
@dataclass(frozen=True)
class Some[A]:
    a: A
type option[A] = None_ | Some[A]
```

A function gets annotated parameters and a return type, and declares the type
variables of its type as PEP 695 type parameters. Since function values are
applied one argument at a time, a function-typed parameter or return value has
a curried type:

```python
def px[A](x0: point_ext[A]) -> int: ...
def apply_twice(f: Callable[[int], int], x: int) -> int: ...
@_cached
def empty_list[A]() -> list[A]: ...
```

A value is cached with `_cached`, which the prelude defines on top of
`functools.cache`: `functools.cache` would hide the type parameters of
`empty_list` from a type checker.

A type class becomes a generic dataclass over its type variable. Methods are
called with all their arguments at once, so their fields have uncurried types.
An instance returns the class at its type, and a function with a sort
constraint takes a dictionary of that class (a tuple of dictionaries, for a
sort with several classes):

```python
@dataclass(frozen=True)
class ord_[A]:
    less_eq: Callable[[A, A], bool]
    less: Callable[[A, A], bool]

def ord_list[A](a_dict: ord_[A]) -> ord_[list[A]]: ...
def announce[A](a_dict: describable[A], x: A) -> str: ...
```

A type that has no Python name is annotated as `Any`: a type without a
printing whose datatype has no constructors (for example one with an abstract
representation) is not part of the generated code.

Some printing differs from the output without the option, so that a type
checker accepts the code. A `match` keeps its final `case _:` arm that raises an
error, unless its last pattern is a variable or a wildcard: a type checker
cannot tell that the other patterns are exhaustive, and would otherwise report
a missing return.

Set the option like `python_tail_calls`:

```bash
isabelle build -o python_type_annotations -d . -e Python_Examples
```

Changing the option does not rebuild an up-to-date session, so add `-c` to
rebuild the session when switching it on or off. `make typecheck-diff` builds
the examples with the option and runs mypy over them, one example directory at
a time (each has its own copy of the library modules).

A function without code, which always aborts, returns `Never`. A lambda becomes
a local function with annotated parameters, and so does a partial application:

```python
@_cached
def add_one() -> Callable[[int], int]:
    def lam(a: int) -> int:
        return (add2(1, a))
    return (lam)
```

A variable that the branches of an `if` or the arms of a `match` assign is
declared with its type first, and the subject of a `match` is annotated too;
otherwise a type checker would take the constructor of the first assignment
(`Inl`) for the type of the variable, and reject the others:

```python
x: Sum_Type.sum_[Nat.nat, Nat.nat]
if (Int.less_eq_int(Int.zero_int_(), i)):
    x = (Sum_Type.Inl(Int.nat(i)))
else:
    x = (Sum_Type.Inr(...))
```

These local definitions, and the hoisted lambdas, get names that differ within
a definition, since mypy rejects one name declared at different types, even in
different arms of a `match`.

Mypy infers the parameter types of a lambda passed to a generic function by
checking its body again for each candidate, so nested lambdas take exponential
time: the generators of `Quickcheck_Random` took it hours to check.

A type checker infers a type parameter of a generic function from a
constructor argument as the constructor's class: in `fold(f, xs, Nil())`, mypy
takes `Nil` for `B` rather than `list_[A]`, which then does not fit `f`; and from
a generic value such as `top_set()` it infers `set_[Never]`. Such an argument for
a parameter declared with a bare type variable is therefore cast to the type at
the call:

```python
return (fold(lam, xs, cast(list_[A], Nil())))
```

Mypy does not accept all annotated code. It cannot always infer the type
parameters of a generic higher-order call (`Fun.comp(Fun.comp(f, g), List.rev)`
in `Word`). An instance whose type parameter only occurs in its result
(`def inf_fun[A, B](b_dict) -> inf[Callable[[A], B]]`) cannot be applied where
that parameter is needed. And the unit result of `trace` and `flush` (`Debug`) is
bound to a variable, although their annotation says they return nothing. Over
the slow suite this leaves 4 errors in `generated_basic` and 3 in
`generated_full`; mypy checks each in about a second.

## Running the tests

This repository comes with three test suites:

- **quick**

Unit test that extracts Python code from `/test/quick/Quick_Test.thy` 
and runs various tests defined in `/test/quick/run_test.py`.

```bash
isabelle build -d . -e Python_Test_Quick
uv run pytest test/quick/run_test.py -v
```

- **slow**

This draws in a sizeable section of the HOL library. The file
`test/slow/Candidates.thy` was originally written by Florian Haftmann from TU München, and taken almost verbatim from the Go backend.

Two different theories extract the code once with `Python.Python` and once
with `Python.Python_Setup`. Unfortunately, we can currently not use Isabelle's
`code_export _ checking ...`, as the code formatter for `checking` has a hardcoded margin of 80 characters, which causes problems with nested statements in Python.

```bash
isabelle build -d . -e Python_Test_Slow
uv run python -m py_compile test/slow/generated_basic/*.py
uv run python -m py_compile test/slow/generated_full/*.py
uv run pytest test/slow/run_test.py
```

`run_test.py` imports every generated module in a fresh interpreter; the
modules that are known not to import are listed in `KNOWN_FAILURES` there.

- **diff**

During the development of this code generator, different Isabelle features were
tested in isolation in different example theories under `examples/`. To see if
changes to the backend result in changes to the extracted code, the `diff` test
suite holds golden reference files under `test/diff/golden/`.

```bash
isabelle build -d . -e Python_Examples
uv run pytest test/diff/run_test.py
```

If a new example is added, or the output has changed and is confirmed correct,
the golden files can be recreated by

```bash
isabelle build -d . -e Python_Examples
uv run python test/diff/reseed_goldens.py
```

## Known limitations

- No support yet for `real`, `rat`, or other numeric types beyond
  `int`/`nat`.
- Introducing a pretty printer that unboxes a type with exactly one constructor
which maps to an identity in Python causes an `undefined name error`. To
circumvent this, such a symbol must be declared with
`Code_Python.add_transparent_wrapper_sym`. For an example, look at
`examples/Example_transparent_wrapper.thy`.


## License

BSD
