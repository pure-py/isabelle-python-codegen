theory Python
    imports Main
begin

ML_file \<open>code_python.ML\<close>

declare [[default_code_width = 2000]]

code_identifier
  code_module Code_Numeral \<rightharpoonup> (Python) Arith

(* Panic *)
code_printing
  constant Code.abort \<rightharpoonup> (Python) "raise RuntimeError(\"_\")"

(* unit *)
code_printing
    type_constructor Product_Type.unit \<rightharpoonup> (Python) "None"
  | constant Unity \<rightharpoonup> (Python) "None"

(* Bools *)
code_printing
  type_constructor bool \<rightharpoonup> (Python) "bool"
| constant "False::bool" \<rightharpoonup> (Python) "False"
| constant "True::bool" \<rightharpoonup> (Python) "True"
| constant HOL.Not \<rightharpoonup> (Python) "not _"
| constant HOL.conj \<rightharpoonup> (Python) infixl 1 "and"
| constant HOL.disj \<rightharpoonup> (Python) infixl 0 "or"
| constant HOL.implies \<rightharpoonup> (Python) "!(not ((_)) or (_))"
| constant "HOL.equal :: bool \<Rightarrow> bool \<Rightarrow> bool" \<rightharpoonup> (Python) infix 4 "=="

(* Strings *)
code_printing
    type_constructor String.literal \<rightharpoonup> (Python) "str"
  | constant "STR ''''" \<rightharpoonup> (Python) "\"\""
  | constant "(+) :: String.literal \<Rightarrow> String.literal \<Rightarrow> String.literal" \<rightharpoonup>
      (Python) infixl 65 "+"
  | constant "HOL.equal :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) infixl 40 "=="
  | constant "(\<le>) :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) infixl 35 "<="
  | constant "(<) :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) infixl 35 "<"

setup \<open>
  Literal.add_code "Python"
\<close>

code_printing
    constant "min" \<rightharpoonup> (Python) "min(_, _)"
  | constant "max" \<rightharpoonup> (Python) "max(_, _)"

end