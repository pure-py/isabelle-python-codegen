theory Example_lists
    imports Main Python_Setup
begin

definition example :: "int list" where
    "example = [1, 2, 3]"

fun prepend :: "'a \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "prepend x xs = x # xs"

export_code example prepend in Python

end