theory Example_iarray
    imports Main "Python.Python_IArray"
begin

definition example_nth :: int where
  "example_nth = [10, 20, 30] ! 1"

definition squares :: "nat iarray" where
  "squares = IArray.of_fun (\<lambda>i. i * i) 4"

definition sum_ends :: "nat iarray \<Rightarrow> nat" where
  "sum_ends a = a !! 0 + a !! (IArray.length a - 1)"

fun first_or_zero :: "int iarray \<Rightarrow> int" where
  "first_or_zero (IArray []) = 0"
| "first_or_zero (IArray (x # _)) = x"

definition sub_pair :: "int iarray \<times> integer \<Rightarrow> int" where
  "sub_pair p = IArray.sub' p"

definition example :: "nat list \<times> nat \<times> bool \<times> bool" where
  "example = (IArray.list_of squares, sum_ends squares,
     IArray.all (\<lambda>x. x < 10) squares, IArray (map Suc [1, 2]) = IArray [2, 3])"

export_code example_nth example first_or_zero sub_pair in Python file_prefix "."

end
