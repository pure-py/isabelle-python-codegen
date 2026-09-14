theory Example_generic_list_pair
  imports Main "Python.Python"
begin

fun any_true :: "bool list \<Rightarrow> bool" where
  "any_true [] = False"
| "any_true (x # xs) = (x \<or> any_true xs)"
 
fun swap :: "bool \<times> bool \<Rightarrow> bool \<times> bool" where
  "swap (x, y) = (y, x)"

fun first_two_agree :: "bool list \<Rightarrow> bool" where
  "first_two_agree (x # y # _) = (x = y)"
| "first_two_agree _ = False"
 
definition test_any_true :: bool where "test_any_true = any_true [False, False, True]"
definition test_swap :: "bool \<times> bool" where "test_swap = swap (True, False)"
definition test_first_two :: "bool \<times> bool" where
  "test_first_two = (first_two_agree [True, True, False], first_two_agree [True])"
 
export_code any_true swap first_two_agree
  test_any_true test_swap test_first_two
  in Python file_prefix "."

end