# isabelle-python-codegen

A custom Isabelle/HOL code-generation backend (`Code_Python`) that targets
Python 3, aiming for idiomatic, native-feeling output rather than a literal
transliteration of HOL's internal representations — integers print as
integers, lists as lists, tuples as tuples, records as dataclasses, and so
on, instead of exposing HOL's constructor machinery directly.

## Requirements

- A recent Isabelle/HOL release (with `isabelle` on your `PATH`)
- Python 3.10+ (generated pattern-matching code uses `match`/`case`)
- `pytest`, if you want to run the generated-code regression tests

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

If `My_Project` extends `Python` this way, it inherits `Python_Setup` and
can `imports Main Python_Setup` unqualified. If it instead depends on
`Python` as a sibling session (`sessions "Python"` in its `ROOT`), use the
session-qualified import, `imports "Python.Python_Setup"`.

## Project layout

Each `Example_*.thy` under `examples/` is a focused, runnable demo of one
feature area (e.g. `Example_nat_pattern.thy` for `0`/`Suc` structural
matching, `Example_record_ext.thy` for multi-level record extension) — the
best starting point for idiomatic usage of any one feature in isolation.
`test/quick/Quick_Test.thy` combines a representative slice of all of them
into a single theory, which is what the pytest suite is checked against.

Build the examples with:

```bash
isabelle build -d . -e Python_Examples
```

`-e` exports the generated `.py` files to `/python_out`.

## Running the tests

The regression suite lives under `test/quick/`, in its own session
(`Python_Test_Quick`). It checks the *generated Python*, not just that the
build succeeds — it imports the exported module and asserts on actual
computed values.

```bash
isabelle build -d . -e Python_Test_Quick
cd test/quick && pytest run_test.py -v
```

(If the test file or generated module isn't found, the test skips with a
message naming the missing build step, rather than a bare import error.)

The suite covers: tuples, int/nat arithmetic (including floor-division and
monus), nat structural pattern matching, records including multi-level
extension, and typeclass/superclass method dispatch.

## What the generator currently supports

**Numerics**

- `int`: numeral literals, `+`, `-`, `*`, `div`/`mod` (as `//`/`%`, HOL's
  flooring semantics), and `=`/`≤`/`<` all print as native Python
  operators — no dictionary/typeclass dispatch in the output.
- `nat`: same operators as `int`, plus `-` correctly implements monus
  (`max(0, a - b)`), and structural matching on `0`/`Suc` compiles to a
  guarded capture with the predecessor bound explicitly (e.g.
  `case c if (c >= 1): n = (c - 1)`), since Python has no `Suc` to match.
- `abs`/`min`/`max` print as the native builtins for both `int` and `nat`.
  `sgn` (`int` only) prints as `((x > 0) - (x < 0))`. These are
  typeclass-polymorphic constants, so using them pulls in an unused
  per-type dictionary object as a side effect of internal representation —
  a dead-code elimination pass strips it back out before writing.

**Strings**

- `String.literal` maps to native `str`; `+`, equality, `≤`, `<` print as
  native operators.

**Lists**

- `List.Cons`/`List.Nil` map to native Python lists; literal-shaped
  construction prints as a list literal, a symbolic tail falls back to
  `[x] + xs`.
- Pattern matching against `[]`/`x # xs` prints as native Python
  destructuring (`case []:` / `case [x, *xs]:`). A chain of `Cons`
  applications flattens into one pattern with a single star-capture, since
  Python's `match` allows only one `*name` per list pattern.
- `map` has a native printer (`list(map(_, _))`). This isn't just style:
  standard-library list functions whose equations pattern-match on
  `Nil`/`Cons` internally can silently fail to compile for this target —
  it builds fine for other Isabelle targets but for Python calls into a
  module that's never generated. Watch for this with other list functions
  (`filter`, `List.rev`, etc.); the fix is the same native-printer
  treatment given to `map`.

**Tuples**

- `Product_Type.prod`/`Pair`/`fst`/`snd` map to native tuples and
  indexing; tuple patterns print as bare destructuring (`case (a, b):`).

**Records**

- HOL records compile to frozen dataclasses with real field names.
  Selectors and functional update compile to pattern-match-and-reconstruct.
  Record extension composes across nesting levels, each level its own
  dataclass linked through the "more" slot. `unit` maps to `None`.

**Typeclasses**

- Single-level and chained (multi-level, multiple superclasses) instances.
  Dictionaries print as keyword-constructed objects; superclass projection
  chains correctly across levels.

**Pattern matching / control flow**

- `fun`-style multi-clause equations compile to `match`/`case`, including
  nested constructor patterns (tuples, `Suc`-chains, user datatypes).
- `case ... of ...` compiles correctly both as a whole definition body and
  nested inside a larger expression — since Python's `match` is a
  statement, nested cases are hoisted via an A-normal-form rewrite into a
  preceding `match` block assigning into a fresh temporary.
- `if`/`then`/`else` prints as native Python `if`/`else` rather than
  falling through to the generic `True`/`False` case-matching it desugars
  to internally, preserving non-strict semantics even when a branch itself
  contains nested pattern matching.
- Pretty-printing sites that could otherwise silently line-wrap a bare
  `return`/assignment are guarded with explicit parentheses.

**Partial application**

- Under-arity application — genuine partial application (`add2 1`), a bare
  function reference used as a value, or a point-free alias (`f = g`) —
  prints correctly. Under-saturated calls are eta-expanded via Isabelle's
  own `Code_Thingol.saturated_application`, coming out as a Python
  `lambda`; a bare reference prints as the plain function name instead of
  a no-op lambda. Point-free aliases get their arity from the declared
  type rather than the (misleadingly empty) equation parameter list.

**Option**

- `Some`/`None` compile via the generic constructor path: `option` prints
  as a two-constructor datatype, and `match`/`case` arms are structurally
  correct regardless of clause order. The empty constructor's generated
  class is named `Nonea`, not `None` (a reserved word) — cosmetic only.


**Code_Numeral (`integer`/`natural`)**
 
- HOL's own "target language numeral" types print as native Python ints,
  the same as `int`/`nat`: literals, `+`, `-`, `*`, `div`/`mod`, and
  comparisons all print as native operators. `natural`'s conversion from
  `integer` (`natural_of_integer`) prints as `max(0, _)`, matching its
  real clamp-negative-to-zero semantics rather than a bare pass-through.
  `integer`'s `sgn` and the cross-type conversions
  (`nat_of_integer`/`integer_of_nat`/etc.) aren't registered yet.

**Module output**

- Statements print in dependency-respecting order; nullary constants print
  as plain assignments rather than zero-argument calls; import/blank-line
  formatting follows normal Python conventions.

## Known limitations

- No support yet for `real`, `rat`, or other numeric types beyond
  `int`/`nat`.
- A numeral payload passed through a generic constructor path (e.g.
  `Some 5`, or an `integer`/`natural` literal) triggers an unused `import
  Num` in the generated module -- HOL's term-level dependency graph
  records a reference to `Num.numeral`'s binary encoding even though the
  literal itself prints natively. Harmless (the import just goes unused),
  and deliberately not fixed: doing so would mean matching against the
  generated source text to detect it, which is more brittle than the
  payoff is worth.