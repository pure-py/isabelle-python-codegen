theory Example_class_dicts
  imports Main "Python.Python_Setup"
begin

fun occurrences :: "'a \<Rightarrow> 'a list \<Rightarrow> nat" where
  "occurrences x [] = 0"
| "occurrences x (y # ys) = (if x = y then 1 else 0) + occurrences x ys"

fun weight :: "'a::linorder \<Rightarrow> 'a list \<Rightarrow> nat" where
  "weight x [] = 0"
| "weight x (y # ys) = (if y < x then 2 else if y = x then 1 else 0) + weight x ys"

definition occurrences_int :: "int \<Rightarrow> int list \<Rightarrow> nat" where
  "occurrences_int = occurrences"

definition occurrences_int_eta :: "int \<Rightarrow> int list \<Rightarrow> nat" where
  "occurrences_int_eta x ys = occurrences x ys"

definition occurrences_pair :: "int \<times> int \<Rightarrow> (int \<times> int) list \<Rightarrow> nat" where
  "occurrences_pair = occurrences"

definition weight_int :: "int \<Rightarrow> int list \<Rightarrow> nat" where
  "weight_int = weight"

lemma "occurrences_int 2 [1, 2, 3, 2] = 2"
  by eval

lemma "occurrences_int_eta 2 [1, 2, 3, 2] = 2"
  by eval

lemma "occurrences_pair (1, 2) [(1, 2), (1, 3), (1, 2)] = 2"
  by eval

lemma "weight_int 2 [1, 2, 3] = 3"
  by eval

export_code
  occurrences_int occurrences_int_eta occurrences_pair weight_int
  in Python file_prefix "."

end
