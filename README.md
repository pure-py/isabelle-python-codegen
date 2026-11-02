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
`Callable`, `Never`, `functools`, `_abort`, `_unimplemented`; `prelude_names` in
`code_python.ML`).

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
add_one: Callable[[int], int] = (lambda a: add2(1, a))
```

A value is annotated too, unless its type has type variables
(`empty_list = []`): a module-level assignment cannot declare type parameters.

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

Set the option like `python_tail_calls`:

```bash
isabelle build -o python_type_annotations -d . -e Python_Examples
```

Changing the option does not rebuild an up-to-date session, so add `-c` to
rebuild the session when switching it on or off. `make typecheck-diff` builds
the examples with the option and runs pyright over them.

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
```

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
