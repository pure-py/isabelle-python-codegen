theory Example_builtin_names
    imports Main "Python.Python_Setup"
begin

datatype prim = int | str | object

fun len :: "prim list \<Rightarrow> nat" where
  "len [] = 0" |
  "len (_ # ps) = Suc (len ps)"

definition hash :: "prim \<Rightarrow> nat" where
  "hash p = (case p of int \<Rightarrow> 0 | str \<Rightarrow> 1 | object \<Rightarrow> 2)"

export_code len hash in Python file_prefix "."

end
