theory Example_nat_edge_cases
  imports Main "Python.Python_Setup"
begin

fun nat_minus2 :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "nat_minus2 0 n = 0"
| "nat_minus2 m 0 = m"
| "nat_minus2 (Suc m) (Suc n) = nat_minus2 m n"

fun peel_positive_head :: "nat list \<Rightarrow> nat" where
  "peel_positive_head (Suc n # _) = n"
| "peel_positive_head _ = 0"

fun pair_pred_sum :: "(nat \<times> nat) \<Rightarrow> nat" where
  "pair_pred_sum (Suc m, Suc n) = m + n"
| "pair_pred_sum _ = 0"

fun classify_small :: "nat \<Rightarrow> nat" where
  "classify_small 0 = 0"
| "classify_small (Suc 0) = 1"
| "classify_small (Suc (Suc _)) = 2"

definition nat_minus2_test :: nat where "nat_minus2_test = nat_minus2 5 3"
definition peel_test :: nat where "peel_test = peel_positive_head [3, 4, 5]"
definition pair_pred_test :: nat where "pair_pred_test = pair_pred_sum (4, 6)"
definition classify_test :: "nat \<times> nat \<times> nat" where
  "classify_test = (classify_small 0, classify_small 1, classify_small 7)"

export_code nat_minus2 peel_positive_head classify_small
  nat_minus2_test peel_test classify_test
  in Python file_prefix "."

end