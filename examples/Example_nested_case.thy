theory Example_nested_case
  imports Main "Python.Python_Setup"
begin

fun nat_label :: "nat \<Rightarrow> nat" where
  "nat_label n = 1 + (case n of 0 \<Rightarrow> 10 | Suc m \<Rightarrow> 20 + m)"

definition label_zero :: nat where "label_zero = nat_label 0"
definition label_five :: nat where "label_five = nat_label 5"

text \<open>A second, slightly different shape: the nested case as a function argument.\<close>

(* fun describe_len :: "nat list \<Rightarrow> nat" where
  "describe_len xs = Suc (case xs of [] \<Rightarrow> 0 | (_ # ys) \<Rightarrow> length ys)"

definition describe_len_123 :: nat where "describe_len_123 = describe_len [1, 2, 3]" *)

export_code nat_label label_zero label_five 
  (* describe_len describe_len_123 *)
  in Python file_prefix "."

end