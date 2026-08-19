theory Example_tuples
    imports Main "Python.Python_Setup"
begin

definition point :: "int \<times> int" where
    "point = (3, 4)"

definition swap_pair :: "'a \<times> 'b \<Rightarrow> 'b \<times> 'a" where
    "swap_pair p = (snd p, fst p)"

definition point_swapped :: "int \<times> int" where
    "point_swapped = swap_pair point"

fun add_points :: "(int \<times> int) \<Rightarrow> (int \<times> int) \<Rightarrow> (int \<times> int)" where
    "add_points (x1, y1) (x2, y2) = (x1 + x2, y1 + y2)"

definition points_sum :: "int \<times> int" where
    "points_sum = add_points point point_swapped"

definition triple :: "int \<times> int \<times> int" where
    "triple = (1, 2, 3)"

definition points_list :: "(int \<times> int) list" where
    "points_list = [point, point_swapped]"

export_code point point_swapped points_sum triple points_list add_points swap_pair
  in Python file_prefix "."

end