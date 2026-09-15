# isabelle-python-codegen

A custom Isabelle/HOL code-generation backend that targets
Python 3.

## Requirements

- A recent Isabelle/HOL release (with `isabelle` on your `PATH`, currently only 
`Isabelle2025-2` has been tested)
- Python 3.10+ (generated pattern-matching code uses `match`/`case`)
- `pytest`, if you want to run the tests

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

`Python.Python_Setup` includes additional custom code printers to utilise 
Python native integers for `int` and `nat`, as well as using Python's own
list and tuple data types. Most people will probably want to use this setup for
code generation.

## Running the tests

This repository comes with three test suites:

- **quick**

Unit test that extracts Python code from `/test/quick/Quick_Test.thy` 
and runs various tests defined in `/test/quick/run_test.py`.

```bash
isabelle build -d . -e Python_Test_Quick
pytest test/quick/run_test.py -v
```

- **slow**

This draws in a sizeable section of the HOL library. The file
`test/slow/Candidates.thy` was originally written by Florian Haftmann from TU München, and taken almost verbatim from the Go backend.

Two different theories extract the code once with `Python.Python` and once
with `Python.Python_Setup`. Unfortunately, we can currently not use Isabelle's
`code_export _ checking ...`, as the code formatter for `checking` has a hardcoded margin of 80 characters, which causes problems with nested statements in Python.

```bash
isabelle build -d . -e Python_Test_Slow
python3 -m py_compile test/slow/generated_basic/*.py
python3 -m py_compile test/slow/generated_full/*.py
```

- **diff**

During the development of this code generator, different Isabelle features were
tested in isolation in different example theories under `examples/`. To see if
changes to the backend result in changes to the extracted code, the `diff` test
suite holds golden reference files under `test/diff/golden/`.

```bash
isabelle build -d . -e Python_Examples
pytest test/diff/run_test.py
```

If a new example is added, or the output has changed and is confirmed correct,
the golden files can be recreated by

```bash
isabelle build -d . -e Python_Examples
python3 test/diff/reseed_goldens.py
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