theory Example_code_numerals
  imports Main "Python.Python_Setup"
begin

definition cn_int_lit :: integer where "cn_int_lit = 42"

definition cn_add :: "integer \<Rightarrow> integer \<Rightarrow> integer" where
  "cn_add x y = x + y"

definition cn_sum :: integer where "cn_sum = cn_add cn_int_lit 8"

definition cn_neg :: integer where "cn_neg = -5"

definition cn_nat_lit :: natural where "cn_nat_lit = 7"

definition cn_nat_add :: "natural \<Rightarrow> natural \<Rightarrow> natural" where
  "cn_nat_add x y = x + y"

definition cn_nat_sum :: natural where "cn_nat_sum = cn_nat_add cn_nat_lit 3"

export_code cn_int_lit cn_add cn_sum cn_neg cn_nat_lit cn_nat_add cn_nat_sum
  in Python file_prefix "."

end