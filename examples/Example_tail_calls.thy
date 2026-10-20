theory Example_tail_calls
  imports Main "Python.Python_Setup"
begin

text \<open>Self tail calls, printed as plain recursion (default) and as loops (python_tail_calls).\<close>

text \<open>Tail recursive with patterns: a match inside the loop.\<close>
fun sum_acc :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "sum_acc 0 acc = acc"
| "sum_acc (Suc n) acc = sum_acc n (acc + Suc n)"

text \<open>Tail recursive without patterns, the tail call under an if.\<close>
fun gcd_loop :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "gcd_loop a b = (if b = 0 then a else gcd_loop b (a mod b))"

text \<open>Polymorphic, with a type-class dictionary that is passed on.\<close>
fun count_le :: "'a::linorder \<Rightarrow> 'a list \<Rightarrow> nat \<Rightarrow> nat" where
  "count_le x [] n = n"
| "count_le x (y # ys) n = count_le x ys (if y \<le> x then n + 1 else n)"

text \<open>Not a tail call: unchanged.\<close>
fun len_rec :: "'a list \<Rightarrow> nat" where
  "len_rec [] = 0"
| "len_rec (_ # xs) = Suc (len_rec xs)"

text \<open>Creates a closure in the tail call: left as recursion, since a loop would rebind the
  variables the closure captured.\<close>
fun shift_n :: "nat \<Rightarrow> (int \<Rightarrow> int) \<Rightarrow> int \<Rightarrow> int" where
  "shift_n 0 f = f"
| "shift_n (Suc n) f = shift_n n (\<lambda>x. f (x + 1))"

export_code sum_acc gcd_loop count_le len_rec shift_n
  in Python module_name Example_tail_calls file_prefix "."

declare [[python_tail_calls]]

export_code sum_acc gcd_loop count_le len_rec shift_n
  in Python module_name Example_tail_calls_loops file_prefix "loops"

end
