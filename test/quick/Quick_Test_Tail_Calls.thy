theory Quick_Test_Tail_Calls
  imports Main "Python.Python_Setup"
begin

text \<open>Runtime checks for python_tail_calls: the values below are computed at import time and
  recurse far deeper than Python's default limit of 1000 frames, unless printed as loops.\<close>

declare [[python_tail_calls]]

fun tc_sum :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "tc_sum 0 acc = acc"
| "tc_sum (Suc n) acc = tc_sum n (acc + Suc n)"

fun tc_count_le :: "'a::linorder \<Rightarrow> 'a list \<Rightarrow> nat \<Rightarrow> nat" where
  "tc_count_le x [] n = n"
| "tc_count_le x (y # ys) n = tc_count_le x ys (if y \<le> x then n + 1 else n)"

fun tc_shift :: "nat \<Rightarrow> (int \<Rightarrow> int) \<Rightarrow> int \<Rightarrow> int" where
  "tc_shift 0 f = f"
| "tc_shift (Suc n) f = tc_shift n (\<lambda>x. f (x + 1))"

definition tc_sum_big :: nat where "tc_sum_big = tc_sum 100000 0"
definition tc_shift_small :: int where "tc_shift_small = tc_shift 3 id 10"

text \<open>For an int list, the dictionary @{text linorder_int} is exported too.\<close>
definition tc_count_le_int :: "int \<Rightarrow> int list \<Rightarrow> nat \<Rightarrow> nat" where
  "tc_count_le_int = tc_count_le"

export_code tc_sum tc_count_le_int tc_shift tc_sum_big tc_shift_small
  in Python module_name Quick_Test_Tail_Calls file_prefix "."

end
