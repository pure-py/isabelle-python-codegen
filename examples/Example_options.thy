theory Example_options
  imports Main "Python.Python_Setup"
begin

definition o_some :: "int option" where "o_some = Some 5"
definition o_none :: "int option" where "o_none = None"

fun describe_opt :: "int option \<Rightarrow> int" where
  "describe_opt None = 0"
| "describe_opt (Some x) = x + 1"

(* Some-arm listed first, to see how arm order plays out *)
fun describe_opt2 :: "int option \<Rightarrow> int" where
  "describe_opt2 (Some x) = x + 100"
| "describe_opt2 None = (-1)"

definition d1 :: int where "d1 = describe_opt o_some"
definition d2 :: int where "d2 = describe_opt o_none"
definition d3 :: int where "d3 = describe_opt2 o_some"
definition d4 :: int where "d4 = describe_opt2 o_none"

export_code o_some o_none describe_opt describe_opt2 d1 d2 d3 d4
  in Python file_prefix "."

end