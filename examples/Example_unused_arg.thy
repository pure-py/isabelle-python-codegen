theory Example_unused_arg
    imports Main "Python.Python_Setup"
begin

fun const_fn :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat" where
  "const_fn x _ _ = x + 1"

export_code const_fn in Python file_prefix "."

end