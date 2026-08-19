theory Example_nat_pattern
  imports Main "Python.Python_Setup"
begin

fun fact :: "nat \<Rightarrow> nat" where
  "fact 0 = 1"
| "fact (Suc n) = Suc n * fact n"

fun countdown :: "nat \<Rightarrow> nat list" where
  "countdown 0 = [0]"
| "countdown (Suc n) = Suc n # countdown n"

fun nat_is_even :: "nat \<Rightarrow> bool" where
  "nat_is_even 0 = True"
| "nat_is_even (Suc n) = (\<not> nat_is_even n)"

definition fact_5 :: "nat" where "fact_5 = fact 5"

definition countdown_4 :: "nat list" where "countdown_4 = countdown 4"

definition is_even_7 :: "bool" where "is_even_7 = nat_is_even 7"

export_code fact countdown nat_is_even fact_5 countdown_4 is_even_7
  in Python file_prefix "."

end