theory Example_lists
    imports Main "Python.Python_Setup"
begin

definition example :: "int list" where
    "example = [1, 2, 3]"

fun prepend :: "'a \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "prepend x xs = x # xs"

definition example2 :: "int list" where
  "example2 = prepend 5 example"

export_code example2 in Python file_prefix "."

end