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

Clone the repository:

```bash
git clone https://github.com/pure-py/isabelle-python-codegen.git
cd isabelle-python-codegen
```

To make the `Python` session available to *other* Isabelle projects on
this machine, without passing `-d /path/to/isabelle-python-codegen` on
every invocation or copying this directory around, register it as an
Isabelle component:

```bash
isabelle components -u "$(pwd)"
```

From then on, any other Isabelle project can depend on the `Python`
session directly in its own `ROOT` file, without any `-d` flag:

```isabelle
session My_Project = Python +
  theories
    My_Theory
```

If `My_Project` extends `Python` this way (`= Python +`), it inherits
`Python_Setup` and can `imports Main Python_Setup` unqualified. If instead
it depends on `Python` as a sibling session (via `sessions "Python"` in its
`ROOT`), imports need the session-qualified form,
`imports "Python.Python_Setup"`.

## Project layout

Each `Example_*.thy` under `examples/` is a focused, runnable
demonstration of one feature area (e.g. `Example_nat_pattern.thy` for
`0`/`Suc` structural matching, `Example_record_ext.thy` for multi-level
record extension). They're the best starting point for seeing idiomatic
usage of any one feature in isolation. `test/quick/Quick_Test.thy`
combines a representative slice of all of them into a single theory,
which is what the pytest suite (below) is checked against.

Building the examples:

```bash
isabelle build -d . -e Python_Examples
```

`-e` exports the generated `.py` files (per each theory's
`export_files (in "python_out") ...` declaration) to
`examples/python_out/`.

## Running the tests

The regression suite lives under `test/quick/`, in its own session
(`Python_Test_Quick`), separate from the `examples/` theories above — it
combines a representative definition from each feature area into
`Quick_Test.thy` and checks the *generated Python*, not just that the
Isabelle build succeeds — it imports the exported module and asserts on
actual computed values.

1. Build `Quick_Test.thy` first, so its Python output exists:

   ```bash
   isabelle build -d . -e Python_Test_Quick
   ```

2. Run the tests:

   ```bash
   cd test/quick && pytest run_test.py -v
   ```

   (If the test file isn't found where you expect it, or the generated
   module isn't found under `python_out/`, the test will skip with an
   explicit message telling you which build step is missing, rather than
   failing with a bare import error.)

The suite covers: tuple construction/projection/pattern-matching, int
arithmetic including floor-division semantics for negative operands, nat
arithmetic including monus (truncated subtraction), nat structural
pattern matching (factorial, countdown), records including multi-level
extension, and typeclass/superclass method dispatch.

## What the generator currently supports

**Numerics**
 
- `int`: numeral literals print as native Python integers; `+`, `-`
  (binary and unary), `*`, `div`/`mod` (as `//`/`%`, matching HOL's
  flooring semantics), and `=`/`≤`/`<` all print as native Python
  operators — no dictionary/typeclass dispatch machinery in the output.
- `nat`: the same operator set as `int`, plus: `-` correctly implements
  monus (truncated subtraction, `max(0, a - b)`) rather than plain
  subtraction; `0`/`1` and general numeral literals print natively; and
  structural pattern matching on `0`/`Suc` (as used by `fun`/`primrec`
  recursion) compiles to a guarded capture pattern with the predecessor
  bound via an explicit statement (e.g. `case c if (c >= 1): n = (c - 1)`),
  since Python has no runtime `Suc` constructor to match against.
- `abs`, `min`, `max` print as the native Python builtins (`abs(_)`,
  `min(_, _)`, `max(_, _)`) for both `int` and `nat`. `sgn` (currently
  `int` only) prints as `((x > 0) - (x < 0))`, relying on Python's
  `bool`-as-`int` coercion to get `-1`/`0`/`1` without needing a helper
  function. Because these are genuinely typeclass-polymorphic constants
  (defined once via `ord`, not per-type like `+`/`-`/`*`), using them
  pulls in an unused per-type dictionary object (e.g. `ord_int`) as a
  side effect of how the code lives internally — a dead-code elimination
  pass strips these back out of the generated module before it's written,
  so nothing unused ends up in the output.

**Strings**

- `String.literal` maps to native Python `str`; `+` (concatenation),
  equality, `≤`, and `<` print as native Python operators.

**Lists**

- `List.Cons`/`List.Nil` map to native Python lists. Literal-shaped list
  construction prints directly as a Python list literal; a symbolic tail
  (`x # xs` where `xs` is a variable, not a literal continuation) falls
  back to `[x] + xs` concatenation.

**Tuples**

- `Product_Type.prod`/`Pair`/`fst`/`snd` map to native Python tuples and
  indexing. Tuple patterns in equations print as bare Python tuple
  destructuring (`case (a, b):`), not wrapped in a constructor call.

**Records**

- HOL records compile to frozen Python dataclasses (`@dataclass(frozen=True)`)
  with the record's real field names (looked up via Isabelle's record
  package, not auto-invented placeholder names). Selectors and functional
  update (`r⦇field := ...⦈`) compile to pattern-match-and-reconstruct.
  Record extension (`record child = parent + ...`) composes correctly
  across multiple nesting levels — each level prints as its own dataclass,
  linked through the standard "more" slot. `unit` (used to fill a
  non-extended record's "more" slot) maps to `None`.

**Typeclasses**

- Single-level and chained (multi-level, including multiple direct
  superclasses) typeclass instances. Instance dictionaries print as
  keyword-constructed objects; superclass projection fields chain
  correctly across multi-level inheritance.

**Pattern matching / control flow**

- `fun`-style multi-clause equations compile to Python `match`/`case`,
  including nested constructor patterns (tuples, `Suc`-chains, user
  datatypes).
- An explicit `case ... of ...` expression used as a whole definition body
  (as opposed to `fun`-style clauses) also compiles correctly.
- A `case ... of ...` expression *nested inside* a larger surrounding
  expression (e.g. `1 + (case n of 0 ⇒ 10 | Suc m ⇒ 20 + m)`) also compiles
  correctly. Since Python's `match` is a statement, not an expression, the
  generator converts the enclosing right-hand side to A-normal form: the
  nested case is extracted into a preceding `match` block whose arms assign
  into a fresh temporary, and the original expression is rewritten to refer
  to that temporary instead. This is a pure term-to-term rewrite done before
  printing, not a mutable/side-effecting pass, and it composes correctly for
  arbitrarily nested case-within-case expressions.
- `if ... then ... else ...` is recognized specially rather than falling
  through to the generic case-matching machinery it desugars to internally
  (HOL represents it as a two-armed case on `bool`'s `True`/`False`
  constructors). It prints as a native Python `if`/`else`, whether it's the
  whole body of a definition, nested inside a larger expression, or has a
  branch that itself contains further nested pattern matching — in the
  latter case the nested match is hoisted only as far as that branch's own
  `if`/`else` block, so it's only evaluated when that branch is actually
  taken, matching HOL's non-strict `if`/`then`/`else` semantics.
- Every site where Pretty-printing could otherwise silently line-wrap a
  bare `return`/assignment across multiple lines and produce invalid
  Python is guarded with explicit parentheses.

**Module output**

- Statements print in dependency-respecting order; nullary constants
  print as plain `name = value` assignments rather than zero-argument
  function calls; import/blank-line formatting follows normal Python
  conventions.

## Known limitations

- No support yet for `real`, `rat`, or other numeric types beyond
  `int`/`nat`.