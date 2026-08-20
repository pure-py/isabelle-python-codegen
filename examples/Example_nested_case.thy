theory Example_nested_case
  imports Main "Python.Python_Setup"
begin

fun nat_label :: "nat \<Rightarrow> nat" where
  "nat_label n = 1 + (case n of 0 \<Rightarrow> 10 | Suc m \<Rightarrow> 20 + m)"

definition label_zero :: nat where "label_zero = nat_label 0"
definition label_five :: nat where "label_five = nat_label 5"

text \<open>A second, slightly different shape: the nested case as a function argument.\<close>

fun describe_len :: "nat list \<Rightarrow> nat" where
  "describe_len xs = Suc (case xs of [] \<Rightarrow> 0 | (_ # ys) \<Rightarrow> length ys)"

definition describe_len_123 :: nat where "describe_len_123 = describe_len [1, 2, 3]"

text \<open>if/then/else\<close>
 
definition abs_manual :: "int \<Rightarrow> int" where
  "abs_manual x = (if x < 0 then -x else x)"
 
definition abs_manual_neg :: int where "abs_manual_neg = abs_manual (-7)"
definition abs_manual_pos :: int where "abs_manual_pos = abs_manual 7"
 
text \<open>An if-then-else nested inside a larger expression, not the whole body.\<close>
 
definition classify :: "nat \<Rightarrow> nat" where
  "classify n = 1 + (if n = 0 then 100 else 200)"
 
definition classify_zero :: nat where "classify_zero = classify 0"
definition classify_other :: nat where "classify_other = classify 5"
 
text \<open>An if-then-else where one branch itself contains a further nested case.\<close>
 
fun weird :: "nat \<Rightarrow> nat" where
  "weird n = (if n = 0 then 1 else 1 + (case n of 0 \<Rightarrow> 10 | Suc m \<Rightarrow> 20 + m))"
 
definition weird_zero :: nat where "weird_zero = weird 0"
definition weird_five :: nat where "weird_five = weird 5"

export_code nat_label label_zero label_five
  describe_len describe_len_123
  abs_manual abs_manual_neg abs_manual_pos
  classify classify_zero classify_other
  weird weird_zero weird_five
  in Python file_prefix "."

end