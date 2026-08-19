theory Quick_Test
  imports Main "Python.Python_Setup"
begin

section \<open>Tuples\<close>

definition t_point :: "int \<times> int" where
  "t_point = (3, 4)"

definition t_swap :: "'a \<times> 'b \<Rightarrow> 'b \<times> 'a" where
  "t_swap p = (snd p, fst p)"

fun t_add_points :: "(int \<times> int) \<Rightarrow> (int \<times> int) \<Rightarrow> (int \<times> int)" where
  "t_add_points (x1, y1) (x2, y2) = (x1 + x2, y1 + y2)"

definition t_points_sum :: "int \<times> int" where
  "t_points_sum = t_add_points t_point (t_swap t_point)"

section \<open>int arithmetic\<close>

definition i_quotient_neg :: int where "i_quotient_neg = (-7) div 2"
definition i_remainder_neg :: int where "i_remainder_neg = (-7) mod 2"

definition i_checksum :: "int \<Rightarrow> int \<Rightarrow> int" where
  "i_checksum x y = (x * y) mod (y - x) + x div 2"

section \<open>nat arithmetic (monus, literals, div/mod)\<close>

definition n_sub_trunc :: nat where "n_sub_trunc = 3 - 10"
definition n_sub_pos :: nat where "n_sub_pos = 10 - 3"
definition n_literal :: nat where "n_literal = 42"

section \<open>nat structural pattern matching\<close>

fun n_fact :: "nat \<Rightarrow> nat" where
  "n_fact 0 = 1"
| "n_fact (Suc n) = Suc n * n_fact n"

definition n_fact_5 :: nat where "n_fact_5 = n_fact 5"

fun n_countdown :: "nat \<Rightarrow> nat list" where
  "n_countdown 0 = [0]"
| "n_countdown (Suc n) = Suc n # n_countdown n"

definition n_countdown_4 :: "nat list" where "n_countdown_4 = n_countdown 4"

section \<open>records, including extension\<close>

record point =
  px :: int
  py :: int

record point3d = point +
  pz :: int

definition r_origin3d :: point3d where
  "r_origin3d = \<lparr>px = 0, py = 0, pz = 0\<rparr>"

definition r_move_z :: "point3d \<Rightarrow> int \<Rightarrow> point3d" where
  "r_move_z p dz = p\<lparr>pz := pz p + dz\<rparr>"

definition r_shifted3d :: point3d where
  "r_shifted3d = r_move_z r_origin3d 7"

definition r_total3d :: int where
  "r_total3d = px r_shifted3d + py r_shifted3d + pz r_shifted3d"

section \<open>typeclasses / superclasses\<close>

class has_default =
  fixes default_val :: "'a \<Rightarrow> int"

class has_double = has_default +
  fixes double_val :: "'a \<Rightarrow> int"

datatype tag = TagA | TagB

instantiation tag :: has_default
begin
definition default_val_tag :: "tag \<Rightarrow> int" where
  "default_val_tag t = (case t of TagA \<Rightarrow> 1 | TagB \<Rightarrow> 2)"
instance ..
end

instantiation tag :: has_double
begin
definition double_val_tag :: "tag \<Rightarrow> int" where
  "double_val_tag t = 2 * default_val t"
instance ..
end

definition cls_default_b :: int where "cls_default_b = default_val TagB"
definition cls_double_a :: int where "cls_double_a = double_val TagA"

export_code
  t_point t_swap t_add_points t_points_sum
  i_quotient_neg i_remainder_neg i_checksum
  n_sub_trunc n_sub_pos n_literal
  n_fact n_fact_5 n_countdown n_countdown_4
  r_origin3d r_move_z r_shifted3d r_total3d
  cls_default_b cls_double_a
  in Python file_prefix "."

end