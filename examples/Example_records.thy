theory Example_records
  imports Main "Python.Python_Setup"
begin

record point =
  px :: int
  py :: int

definition origin :: point where
  "origin = \<lparr>px = 0, py = 0\<rparr>"

definition move_x :: "point \<Rightarrow> int \<Rightarrow> point" where
  "move_x p dx = p\<lparr>px := px p + dx\<rparr>"

definition point_sum :: "point \<Rightarrow> point \<Rightarrow> int" where
  "point_sum p q = px p + py p + px q + py q"

definition shifted :: point where
  "shifted = move_x origin 5"

definition total :: int where
  "total = point_sum origin shifted"

export_code origin move_x point_sum shifted total in Python file_prefix "."

end