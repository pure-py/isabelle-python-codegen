theory Example_int_arith
  imports Main "Python.Python_Setup"
begin

definition zero_test :: "int" where
  "zero_test = 0"

definition product :: "int" where
  "product = 6 * 7"

definition neg_product :: "int" where
  "neg_product = (-3) * 4"

definition quotient_pos :: "int" where
  "quotient_pos = 7 div 2"

definition remainder_pos :: "int" where
  "remainder_pos = 7 mod 2"

definition quotient_neg :: "int" where
  "quotient_neg = (-7) div 2"

definition remainder_neg :: "int" where
  "remainder_neg = (-7) mod 2"

definition quotient_neg_divisor :: "int" where
  "quotient_neg_divisor = 7 div (-2)"

definition remainder_neg_divisor :: "int" where
  "remainder_neg_divisor = 7 mod (-2)"

definition checksum :: "int \<Rightarrow> int \<Rightarrow> int" where
  "checksum x y = (x * y) mod (y - x) + x div 2"

export_code zero_test product neg_product
  quotient_pos remainder_pos quotient_neg remainder_neg
  quotient_neg_divisor remainder_neg_divisor checksum
  in Python file_prefix "."

end