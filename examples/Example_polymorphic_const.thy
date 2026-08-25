theory Example_polymorphic_const
    imports Main "Python.Python_Setup"
begin

definition empty_list :: "'a list" where
  "empty_list = []"

definition uses_empty_list :: "nat list" where
  "uses_empty_list = empty_list"

definition magic_number :: "nat" where
  "magic_number = 42"

definition uses_magic_number :: "nat" where
  "uses_magic_number = magic_number + 1"

export_code empty_list uses_empty_list magic_number uses_magic_number
  in Python file_prefix "."

end