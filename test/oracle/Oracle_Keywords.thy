theory Oracle_Keywords
  imports Python_Check "Python.Python_Setup"
begin

text \<open>Names that are Python keywords. Kept in their own module: if one is not
  renamed, the module does not even parse.\<close>

definition async :: int where "async = 1"
definition await :: int where "await = 2"
definition k_vars :: "int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int" where
  "k_vars nonlocal global del = nonlocal + global + del"

python_check k_async: "async + await"
python_check k_vars: "k_vars 1 2 3"

end
