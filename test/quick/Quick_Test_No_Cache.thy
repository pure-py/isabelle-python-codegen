theory Quick_Test_No_Cache
  imports Main "Python.Python_Setup"
begin

text \<open>Checks for @{text "python_cache = false"}: values and dictionary-free instances are printed
  without @{text "@functools.cache"}, so they are recomputed on every use, but still behave the same.\<close>

declare [[python_cache = false]]

definition nc_value :: nat where "nc_value = sum_list [1..<11]"

definition nc_less :: "int \<Rightarrow> int \<Rightarrow> bool" where "nc_less x y = (x < y)"

definition nc_sorted :: "int list \<Rightarrow> bool" where "nc_sorted = sorted"

export_code nc_value nc_less nc_sorted
  in Python module_name Quick_Test_No_Cache file_prefix "."

end
