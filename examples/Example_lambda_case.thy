theory Example_lambda_case
  imports Main "Python.Python_Setup"
begin

fun sum_or_zero :: "nat option \<Rightarrow> nat" where
  "sum_or_zero None = 0"
| "sum_or_zero (Some n) = n"

definition sum_options_named :: "nat option list \<Rightarrow> nat list" where
  "sum_options_named xs = map sum_or_zero xs"

definition doubled :: "nat list \<Rightarrow> nat list" where
  "doubled xs = map (\<lambda> n. n + n) xs"

definition sum_options_inline :: "nat option list \<Rightarrow> nat list" where
  "sum_options_inline xs = map (\<lambda> x. case x of None \<Rightarrow> 0 | Some n \<Rightarrow> n) xs"

export_code sum_options_named doubled sum_options_inline 
    in Python file_prefix "."

end