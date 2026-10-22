theory Oracle_Recursion
  imports Python_Check "Python.Python_Setup"
begin

text \<open>Self tail calls whose new arguments depend on the old ones, which the
  \<open>python_tail_calls\<close> loop must rebind simultaneously.\<close>

fun swap_count :: "nat \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int" where
  "swap_count 0 a b = a - b"
| "swap_count (Suc n) a b = swap_count n b a"

fun rot3 :: "nat \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int" where
  "rot3 0 a b c = 100 * a + 10 * b + c"
| "rot3 (Suc n) a b c = rot3 n c a b"

fun dep_update :: "nat \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int" where
  "dep_update 0 x y = x * 1000 + y"
| "dep_update (Suc n) x y = dep_update n (x + y) (x - y)"

fun acc_rev :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "acc_rev [] acc = acc"
| "acc_rev (x # xs) acc = acc_rev xs (x # acc)"

fun count_pos :: "int list \<Rightarrow> nat \<Rightarrow> nat" where
  "count_pos [] n = n"
| "count_pos (x # xs) n = (if x > 0 then count_pos xs (Suc n) else count_pos xs n)"

fun my_gcd :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "my_gcd a b = (if b = 0 then a else my_gcd b (a mod b))"

text \<open>Closures created in the loop must not see later rebindings.\<close>

fun add_all :: "int list \<Rightarrow> (int \<Rightarrow> int) \<Rightarrow> int \<Rightarrow> int" where
  "add_all [] f x = f x"
| "add_all (y # ys) f x = add_all ys (\<lambda>z. f z + y) x"

fun ev :: "nat \<Rightarrow> bool" and od :: "nat \<Rightarrow> bool" where
  "ev 0 = True"
| "ev (Suc n) = od n"
| "od 0 = False"
| "od (Suc n) = ev n"

fun shift_left :: "nat \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "shift_left n xs = (if n = 0 then xs else case xs of
     [] \<Rightarrow> [] | x # ys \<Rightarrow> shift_left (n - 1) (ys @ [x]))"

fun build :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "build 0 acc = acc"
| "build (Suc n) acc = build n (n # acc)"

python_check_grid tc_build: "\<lambda>n. build n []" over "[0, 1, 3]"
python_check_grid tc_swap: "swap_count" over "[0, 1, 2, 3]" "[10]" "[3]"
python_check_grid tc_rot: "rot3" over "[0, 1, 2, 4]" "[1]" "[2]" "[3]"
python_check_grid tc_dep: "dep_update" over "[0, 1, 2, 5]" "[3]" "[1]"
python_check tc_rev: "acc_rev [1::int, 2, 3] []"
python_check tc_count: "count_pos [1, -2, 3, 0, 5] 0"
python_check_grid tc_gcd: "my_gcd" over "[0, 12, 35]" "[0, 8, 14]"
python_check tc_closure: "add_all [1, 2, 3] (\<lambda>z. z * 10) 1"
python_check_grid tc_mutual: "\<lambda>n. (ev n, od n)" over "[0, 1, 6, 7]"
python_check_grid tc_shift: "\<lambda>n. shift_left n [1::int, 2, 3]" over "[0, 1, 2, 4]"

python_export_checks

end
