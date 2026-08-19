theory Example_record_ext
  imports Main "Python.Python_Setup"
begin

record point =
  px :: int
  py :: int

record point3d = point +
  pz :: int

definition origin3d :: point3d where
  "origin3d = \<lparr>px = 0, py = 0, pz = 0\<rparr>"

definition point3d_sum :: "point3d \<Rightarrow> int" where
  "point3d_sum p = px p + py p + pz p"

definition move_z :: "point3d \<Rightarrow> int \<Rightarrow> point3d" where
  "move_z p dz = p\<lparr>pz := pz p + dz\<rparr>"

definition shifted3d :: point3d where
  "shifted3d = move_z origin3d 7"

definition total3d :: int where
  "total3d = point3d_sum shifted3d"

export_code origin3d point3d_sum move_z shifted3d total3d
  in Python file_prefix "."

end