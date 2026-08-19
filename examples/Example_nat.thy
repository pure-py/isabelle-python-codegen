theory Example_nat
  imports Main "Python.Python_Setup"
begin

definition nat_zero_test :: "nat" where
  "nat_zero_test = 0"

definition nat_literal :: "nat" where
  "nat_literal = 42"

definition nat_sum :: "nat" where
  "nat_sum = 6 + 7"

definition nat_product :: "nat" where
  "nat_product = 6 * 7"

definition nat_sub_pos :: "nat" where
  "nat_sub_pos = 10 - 3"

definition nat_sub_trunc :: "nat" where
  "nat_sub_trunc = 3 - 10"

definition nat_quotient :: "nat" where
  "nat_quotient = 7 div 2"

definition nat_remainder :: "nat" where
  "nat_remainder = 7 mod 2"

definition nat_le_test :: "bool" where
  "nat_le_test = (3 \<le> (5::nat))"

definition nat_lt_test :: "bool" where
  "nat_lt_test = (5 < (3::nat))"

definition nat_eq_test :: "bool" where
  "nat_eq_test = ((4::nat) = 4)"

definition nat_checksum :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "nat_checksum x y = (x * y) mod (y + 1) + (x - y)"

export_code nat_zero_test nat_literal nat_sum nat_product
  nat_sub_pos nat_sub_trunc nat_quotient nat_remainder
  nat_le_test nat_lt_test nat_eq_test nat_checksum
  in Python file_prefix "."

end