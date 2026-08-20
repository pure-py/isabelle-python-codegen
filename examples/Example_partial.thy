theory Example_partial
  imports Main "Python.Python_Setup"
begin

definition add2 :: "int \<Rightarrow> int \<Rightarrow> int" where
  "add2 x y = x + y"

(* genuine partial application: only 1 of add2's 2 args supplied *)
definition add_one :: "int \<Rightarrow> int" where
  "add_one = add2 1"

(* bare reference: add2 used as a value with 0 args supplied *)
definition add2_ref :: "int \<Rightarrow> int \<Rightarrow> int" where
  "add2_ref = add2"

definition apply_twice :: "(int \<Rightarrow> int) \<Rightarrow> int \<Rightarrow> int" where
  "apply_twice f x = f (f x)"

definition p_result :: int where "p_result = apply_twice add_one 5"
definition p_mapped :: "int list" where "p_mapped = map add_one [1, 2, 3]"
definition p_ref_result :: int where "p_ref_result = add2_ref 3 4"

export_code add2 add_one add2_ref apply_twice p_result p_mapped p_ref_result
  in Python file_prefix "."

end