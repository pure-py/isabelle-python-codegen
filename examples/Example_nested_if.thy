theory Example_nested_if
  imports Main "Python.Python_Setup"
begin

fun grade_code :: "nat \<Rightarrow> nat" where
  "grade_code score =
     (if score < 60 then 0
      else if score < 70 then 1
      else if score < 80 then 2
      else if score < 90 then 3
      else 4)"

definition grade_f :: nat where "grade_f = grade_code 40"
definition grade_d :: nat where "grade_d = grade_code 65"
definition grade_c :: nat where "grade_c = grade_code 75"
definition grade_b :: nat where "grade_b = grade_code 85"
definition grade_a :: nat where "grade_a = grade_code 95"

definition nested_then :: "int \<Rightarrow> int \<Rightarrow> int" where
  "nested_then x y =
     (if x > 0
      then (if y > 0 then 1 else 2)
      else 3)"

definition nested_then_tt :: int where "nested_then_tt = nested_then 1 1"
definition nested_then_tf :: int where "nested_then_tf = nested_then 1 (-1)"
definition nested_then_f :: int where "nested_then_f = nested_then (-1) 1"

export_code
  grade_code grade_f grade_d grade_c grade_b grade_a
  nested_then nested_then_tt nested_then_tf nested_then_f
  in Python file_prefix "."

end