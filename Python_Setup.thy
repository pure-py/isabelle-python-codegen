theory Python_Setup
    imports Main
begin

ML_file \<open>code_python.ML\<close>

code_identifier
  code_module Code_Target_Nat \<rightharpoonup> (Python) Arith
| code_module Code_Target_Int \<rightharpoonup> (Python) Arith
| code_module Code_Numeral \<rightharpoonup> (Python) Arith

(* Bools *)
code_printing
  type_constructor bool \<rightharpoonup> (Python) "bool"
| constant "False::bool" \<rightharpoonup> (Python) "False"
| constant "True::bool" \<rightharpoonup> (Python) "True"

code_printing
  constant Code.abort \<rightharpoonup> (Python) "raise RuntimeError(\"_\")"

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
  fold Literal.add_code ["Python"]
\<close>

end