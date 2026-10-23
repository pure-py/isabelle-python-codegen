theory Oracle_Arith
  imports Python_Check "Python.Python_Setup"
begin

unbundle bit_operations_syntax

section \<open>div and mod on all four numeric types\<close>

python_check_grid int_div: "\<lambda>x y. (x::int) div y" over "[-7, -1, 0, 1, 7]" "[-2, 0, 2]"
python_check_grid int_mod: "\<lambda>x y. (x::int) mod y" over "[-7, -1, 0, 1, 7]" "[-2, 0, 2]"
python_check_grid nat_div: "\<lambda>x y. (x::nat) div y" over "[0, 1, 7]" "[0, 2, 3]"
python_check_grid nat_mod: "\<lambda>x y. (x::nat) mod y" over "[0, 1, 7]" "[0, 2, 3]"
python_check_grid integer_div: "\<lambda>x y. (x::integer) div y" over "[-7, 0, 7]" "[-2, 0, 2]"
python_check_grid integer_mod: "\<lambda>x y. (x::integer) mod y" over "[-7, 0, 7]" "[-2, 0, 2]"
python_check_grid natural_div: "\<lambda>x y. (x::natural) div y" over "[0, 7]" "[0, 2]"
python_check_grid natural_mod: "\<lambda>x y. (x::natural) mod y" over "[0, 7]" "[0, 2]"

text \<open>Negative control: truncating division would give \<open>-3\<close>.\<close>
python_check int_div_not_trunc: "(-7::int) div 2 \<noteq> -3"

section \<open>Subtraction and conversions into nat\<close>

python_check_grid nat_minus: "\<lambda>x y. (x::nat) - y" over "[0, 3, 10]" "[0, 3, 10]"
python_check_grid natural_minus: "\<lambda>x y. (x::natural) - y" over "[0, 3]" "[0, 3]"

definition to_nat :: "int \<Rightarrow> nat" where "to_nat x = nat x"

python_check nat_neg: "nat (-5)"
python_check nat_pos: "nat 5"
python_check to_nat_neg: "to_nat (-5)"
python_check_grid nat_of_diff: "\<lambda>x y. nat ((x::int) - y)" over "[0, 3]" "[0, 3]"
python_check int_nat_neg: "int (nat (-3)) + 1"
python_check nat_of_integer_neg: "nat_of_integer (-5)"
python_check natural_of_integer_neg: "natural_of_integer (-5)"
python_check int_of_nat: "int (3::nat) - 5"
python_check integer_of_int_ex: "integer_of_int (-5) * 2"
python_check int_of_integer_ex: "int_of_integer (-7) div 2"
python_check nat_of_natural_ex: "nat_of_natural 7 + 1"
python_check integer_of_nat_ex: "integer_of_nat 3 - 5"

section \<open>Big numbers and powers\<close>

python_check big_mul: "(2::int) ^ 100 * 3 ^ 50"
python_check big_div: "(- ((2::int) ^ 70)) div 3"
python_check big_mod: "(- ((2::int) ^ 70)) mod 7"
python_check big_literal: "(123456789012345678901234567890::int) + 1"
python_check big_neg_literal: "(-123456789012345678901234567890::int) * -1"
python_check big_nat: "(2::nat) ^ 80 - 2 ^ 81"
python_check_grid int_pow: "\<lambda>x n. (x::int) ^ n" over "[-2, 0, 3]" "[0, 1, 5]"
python_check neg_pow: "(-2::int) ^ 2"
python_check nat_pow_zero: "(0::nat) ^ 0"

section \<open>gcd, lcm, abs, sgn, min, max, comparisons\<close>

python_check_grid int_gcd: "\<lambda>x y. gcd (x::int) y" over "[-12, 0, 18]" "[-8, 0, 8]"
python_check_grid int_lcm: "\<lambda>x y. lcm (x::int) y" over "[-4, 0, 6]" "[-6, 0, 4]"
python_check_grid nat_gcd: "\<lambda>x y. gcd (x::nat) y" over "[0, 12]" "[0, 8]"
python_check_grid int_sgn: "\<lambda>x. sgn (x::int)" over "[-3, 0, 3]"
python_check_grid int_abs: "\<lambda>x. \<bar>x::int\<bar>" over "[-3, 0, 3]"
python_check_grid integer_abs: "\<lambda>x. \<bar>x::integer\<bar>" over "[-3, 0, 3]"
python_check_grid int_minmax: "\<lambda>x y. (min x y, max (x::int) y)" over "[-1, 2]" "[-1, 2]"
python_check_grid int_cmp: "\<lambda>x y. ((x::int) \<le> y, x < y, x = y)" over "[-1, 0, 1]" "[-1, 0, 1]"
python_check_grid int_even: "\<lambda>x. (even (x::int), odd x)" over "[-3, -2, 0, 7]"
python_check minus_assoc: "(5::int) - (3 - 1) - - 2"

section \<open>Bit operations\<close>

python_check_grid int_and: "\<lambda>x y. (x::int) AND y" over "[-6, -1, 0, 5]" "[-3, 0, 3]"
python_check_grid int_or: "\<lambda>x y. (x::int) OR y" over "[-6, -1, 0, 5]" "[-3, 0, 3]"
python_check_grid int_xor: "\<lambda>x y. (x::int) XOR y" over "[-6, -1, 0, 5]" "[-3, 0, 3]"
python_check_grid int_not: "\<lambda>x. NOT (x::int)" over "[-1, 0, 5]"
python_check_grid int_push_bit: "\<lambda>n x. push_bit n (x::int)" over "[0, 3]" "[-5, 5]"
python_check_grid int_drop_bit: "\<lambda>n x. drop_bit n (x::int)" over "[0, 1, 3]" "[-5, -1, 5]"
python_check_grid int_take_bit: "\<lambda>n x. take_bit n (x::int)" over "[0, 3]" "[-5, 5]"
python_check_grid int_signed_take_bit: "\<lambda>n x. signed_take_bit n (x::int)" over "[0, 3]" "[-5, 5, 6]"
python_check_grid int_bit: "\<lambda>x n. bit (x::int) n" over "[-5, 5]" "[0, 1, 10]"
python_check_grid int_mask: "\<lambda>n. mask n :: int" over "[0, 1, 8]"
python_check_grid nat_and: "\<lambda>x y. (x::nat) AND y" over "[0, 5, 12]" "[3, 10]"
python_check_grid nat_xor: "\<lambda>x y. (x::nat) XOR y" over "[0, 5, 12]" "[3, 10]"
python_check_grid nat_drop_bit: "\<lambda>n x. drop_bit n (x::nat)" over "[0, 2]" "[0, 13]"

end
