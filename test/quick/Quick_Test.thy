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

section \<open>remaining int/nat operators\<close>

definition i_abs_neg :: int where "i_abs_neg = abs (-7::int)"
definition i_sgn_neg :: int where "i_sgn_neg = sgn (-7::int)"
definition i_sgn_zero :: int where "i_sgn_zero = sgn (0::int)"
definition i_sgn_pos :: int where "i_sgn_pos = sgn (7::int)"
definition i_min_ab :: int where "i_min_ab = min (3::int) 9"
definition i_max_ab :: int where "i_max_ab = max (3::int) 9"
 
definition n_min_ab :: nat where "n_min_ab = min (3::nat) 9"
definition n_max_ab :: nat where "n_max_ab = max (3::nat) 9"

section \<open>nested case expressions\<close>
 
fun nat_label :: "nat \<Rightarrow> nat" where
  "nat_label n = 1 + (case n of 0 \<Rightarrow> 10 | Suc m \<Rightarrow> 20 + m)"
 
definition label_zero :: nat where "label_zero = nat_label 0"
definition label_five :: nat where "label_five = nat_label 5"

section \<open>if/then/else\<close>
 
definition abs_manual :: "int \<Rightarrow> int" where
  "abs_manual x = (if x < 0 then -x else x)"
 
definition abs_manual_neg :: int where "abs_manual_neg = abs_manual (-7)"
definition abs_manual_pos :: int where "abs_manual_pos = abs_manual 7"
 
definition classify :: "nat \<Rightarrow> nat" where
  "classify n = 1 + (if n = 0 then 100 else 200)"
 
definition classify_zero :: nat where "classify_zero = classify 0"
definition classify_other :: nat where "classify_other = classify 5"
 
fun weird :: "nat \<Rightarrow> nat" where
  "weird n = (if n = 0 then 1 else 1 + (case n of 0 \<Rightarrow> 10 | Suc m \<Rightarrow> 20 + m))"
 
definition weird_zero :: nat where "weird_zero = weird 0"
definition weird_five :: nat where "weird_five = weird 5"

section \<open>list pattern matching\<close>

fun describe_len :: "nat list \<Rightarrow> nat" where
  "describe_len xs = Suc (case xs of [] \<Rightarrow> 0 | (_ # ys) \<Rightarrow> length ys)"

definition describe_len_123 :: nat where "describe_len_123 = describe_len [1, 2, 3]"

section \<open>partial application\<close>

definition add2 :: "int \<Rightarrow> int \<Rightarrow> int" where
  "add2 x y = x + y"

text \<open>genuine partial application: only 1 of add2's 2 args supplied\<close>
definition add_one :: "int \<Rightarrow> int" where
  "add_one = add2 1"

definition p_add_one_5 :: int where "p_add_one_5 = add_one 5"

text \<open>point-free alias: add2_ref's own equation has 0 explicit parameters\<close>
definition add2_ref :: "int \<Rightarrow> int \<Rightarrow> int" where
  "add2_ref = add2"

definition p_ref_result :: int where "p_ref_result = add2_ref 3 4"

text \<open>requires the native code_printing registration for List.map\<close>
definition p_mapped :: "int list" where "p_mapped = map add_one [1, 2, 3]"

section \<open>code_numeral (integer/natural)\<close>

definition cn_int_lit :: integer where "cn_int_lit = 42"

definition cn_add :: "integer \<Rightarrow> integer \<Rightarrow> integer" where
  "cn_add x y = x + y"

definition cn_sum :: integer where "cn_sum = cn_add cn_int_lit 8"

definition cn_neg :: integer where "cn_neg = -5"

definition cn_nat_lit :: natural where "cn_nat_lit = 7"

definition cn_nat_add :: "natural \<Rightarrow> natural \<Rightarrow> natural" where
  "cn_nat_add x y = x + y"

definition cn_nat_sum :: natural where "cn_nat_sum = cn_nat_add cn_nat_lit 3"

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

text \<open>
  A dictionary-parameterized instance: has_default for 'a list requires
  'a's own has_default dictionary as a constructor argument, exercising
  the fix to print_dict_args for Class_Instance printing (previously this
  silently dropped the dictionary parameter and warned instead).
\<close>

instantiation list :: (has_default) has_default
begin
definition default_val_list :: "'a list \<Rightarrow> int" where
  "default_val_list xs = (case xs of [] \<Rightarrow> 0 | (y # ys) \<Rightarrow> default_val y)"
instance ..
end

definition cls_list_default :: int where "cls_list_default = default_val [TagB, TagA]"
definition cls_list_default_empty :: int where
  "cls_list_default_empty = default_val ([] :: tag list)"

section \<open>option\<close>

definition o_some :: "int option" where "o_some = Some 5"
definition o_none :: "int option" where "o_none = None"

fun describe_opt :: "int option \<Rightarrow> int" where
  "describe_opt None = 0"
| "describe_opt (Some x) = x + 1"

definition o_describe_some :: int where "o_describe_some = describe_opt o_some"
definition o_describe_none :: int where "o_describe_none = describe_opt o_none"

export_code
  t_point t_swap t_add_points t_points_sum
  i_quotient_neg i_remainder_neg i_checksum
  n_sub_trunc n_sub_pos n_literal
  n_fact n_fact_5 n_countdown n_countdown_4
  i_abs_neg i_sgn_neg i_sgn_zero i_sgn_pos 
  i_min_ab i_max_ab n_min_ab n_max_ab
  nat_label label_zero label_five
  abs_manual abs_manual_neg abs_manual_pos
  classify classify_zero classify_other
  weird weird_zero weird_five
  describe_len describe_len_123
  add2 add_one p_add_one_5 add2_ref p_ref_result p_mapped
  cn_int_lit cn_add cn_sum cn_neg cn_nat_lit cn_nat_add cn_nat_sum
  r_origin3d r_move_z r_shifted3d r_total3d
  cls_default_b cls_double_a
  cls_list_default cls_list_default_empty
  o_some o_none describe_opt o_describe_some o_describe_none
  in Python file_prefix "."

end