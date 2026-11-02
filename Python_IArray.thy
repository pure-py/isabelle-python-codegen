theory Python_IArray
    imports Python_Setup "HOL-Library.IArray"
begin

text \<open>
  Native Python code for immutable arrays (HOL-Library IArray), in the style of the SML
  setup in IArray.thy. An @{typ "'a iarray"} becomes a Python tuple: element access and length
  are O(1), and a tuple cannot be mutated, which matches the semantics of the type (unlike a
  list, it is also hashable, so it can sit in a frozen dataclass or a set).
  A pattern @{term "IArray xs"} becomes the sequence pattern \<open>[*xs]\<close>, which binds
  \<open>xs\<close> to a list. Kept apart from Python_Setup so that only theories that use IArray
  depend on HOL-Library.IArray.
\<close>

code_printing
    type_constructor iarray \<rightharpoonup> (Python) "_ tuple"
  | constant IArray \<rightharpoonup> (Python) "tuple'(_')"
  | constant IArray.list_of \<rightharpoonup> (Python) "list'(_')"
  | constant IArray.sub \<rightharpoonup> (Python) "_[_]"
  | constant IArray.length \<rightharpoonup> (Python) "len'(_')"
  | constant IArray.length' \<rightharpoonup> (Python) "len'(_')"
  | constant IArray.of_fun \<rightharpoonup> (Python) "tuple'(map'(_, range'(_')')')"
  | constant IArray.all \<rightharpoonup> (Python) "all'(map'(_, _')')"
  | constant IArray.exists \<rightharpoonup> (Python) "any'(map'(_, _')')"

text \<open>@{const IArray.sub'} and @{const IArray.tabulate} take a pair; a literal pair is
  printed directly, any other pair expression is unpacked into a lambda.\<close>

setup \<open>
  let
    open Code_Thingol Code_Printer;

    fun dest_pair (IConst { sym = Code_Symbol.Constant \<^const_name>\<open>Product_Type.Pair\<close>, ...}
          `$ a `$ b) = SOME (a, b)
      | dest_pair _ = NONE;

    fun paired name params body = fn print_term => fn vars => fn t =>
      case dest_pair t of
        SOME (a, b) => body (print_term vars BR a) (print_term vars NOBR b)
      | NONE => Pretty.block [Pretty.str ("(lambda " ^ params ^ ": "),
          body (Pretty.str (fst name)) (Pretty.str (snd name)),
          Pretty.str ")(*", print_term vars NOBR t, Pretty.str ")"];

    val sub' = paired ("a", "i") "a, i" (fn a => fn i =>
      Pretty.block [a, Pretty.str "[", i, Pretty.str "]"]);
    val tabulate = paired ("n", "f") "n, f" (fn n => fn f =>
      Pretty.block [Pretty.str "tuple(map(", f, Pretty.str ", range(", n, Pretty.str ")))"]);

    fun set target (c, pr) =
      Code_Target.set_printings (Code_Symbol.Constant (c,
        [(target, SOME (complex_const_syntax (1,
          fn _ => fn print_term => fn _ => fn vars => fn _ => fn [(t, _)] =>
            pr print_term vars t)))]));
  in
    (fn target =>
      set target (\<^const_name>\<open>IArray.sub'\<close>, sub')
      #> set target (\<^const_name>\<open>IArray.tabulate\<close>, tabulate))
    "Python"
  end
\<close>

setup \<open> Code_Python.enable_native_encoding "iarray" \<close>

end
