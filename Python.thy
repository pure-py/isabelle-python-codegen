theory Python
    imports Main
begin

ML_file \<open>code_python.ML\<close>

(* Keywords and builtins of the target Python, which generated names must not hide;
   make reserved-words writes the file from the Python in .python-version *)
external_file \<open>etc/python_reserved_words\<close>

setup \<open>fn thy =>
  File.read_lines (Resources.master_directory thy + \<^path>\<open>etc/python_reserved_words\<close>)
  |> map trim_line
  |> filter_out (fn line => line = "" orelse String.isPrefix "#" line)
  |> (fn names => fold (Code_Target.add_reserved Code_Python.target) names thy)
\<close>

declare [[default_code_width = 2000]]

code_identifier
  code_module Code_Numeral \<rightharpoonup> (Python) Arith

(* Panic, by a helper function, since Code.abort occurs in expression position *)
code_printing
  constant Code.abort \<rightharpoonup> (Python) "'_abort"

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
      (Python) "(_ == _)"
  | constant "(\<le>) :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) "(_ <= _)"
  | constant "(<) :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) "(_ < _)"

setup \<open>
  Literal.add_code "Python"
\<close>

end
