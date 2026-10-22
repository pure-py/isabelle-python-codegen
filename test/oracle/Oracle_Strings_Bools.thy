theory Oracle_Strings_Bools
  imports Python_Check "Python.Python_Setup"
begin

section \<open>Strings and characters\<close>

python_check str_concat: "STR ''ab'' + STR ''cd''"
python_check str_eq_chain: "(STR ''a'' = STR ''b'') = (STR ''c'' = STR ''d'')"
python_check str_eq_false: "(STR ''a'' = STR ''b'') = False"
python_check str_lt_chain: "(STR ''a'' < STR ''b'') = (STR ''c'' < STR ''b'')"
python_check str_le_eq: "(STR ''b'' \<le> STR ''a'') = (STR ''a'' = STR ''b'')"
python_check str_bool_eq: "(STR ''x'' = STR ''x'') = ((1::int) = 1)"
python_check str_compare: "(STR ''abc'' < STR ''abd'', STR ''b'' < STR ''abc'', STR '''' < STR ''a'')"
python_check str_concat_eq: "STR ''a'' + STR ''b'' = STR ''ab''"
python_check chr_eq: "(CHR ''a'' = CHR ''b'', CHR ''a'' = CHR ''a'')"
python_check chr_list: "''hello'' @ '' world''"
python_check chr_of_nat: "char_of (65::nat)"

section \<open>Booleans and precedence\<close>

python_check b_not_eq: "(\<not> True) = False"
python_check b_int_eq_chain: "((1::int) = 2) = ((3::int) = 4)"
python_check b_bool_eq_chain: "(True = False) = (False = True)"
python_check b_imp: "(False \<longrightarrow> False) \<and> \<not> (True \<longrightarrow> False)"
python_check b_not_and: "\<not> (True \<and> False) \<and> (\<not> False \<or> False)"
python_check_grid b_imp_grid: "\<lambda>a b. a \<longrightarrow> b" over "[True, False]" "[True, False]"
python_check_grid b_eq_not: "\<lambda>a b. (\<not> a) = b" over "[True, False]" "[True, False]"
python_check_grid b_eq_eq: "\<lambda>a b c. (a = (b::bool)) = (c::bool)" over "[True, False]" "[True, False]" "[True, False]"
python_check_grid b_min_max: "\<lambda>a b. (min a (b::bool), max a b, a < b, a \<le> b)" over "[True, False]" "[True, False]"
python_check b_if_arith: "(if True then 1 else 2::int) + (if False then 10 else 20)"
python_check b_neg_neg: "- (- (3::int))"
python_check b_if_cond_eq: "(if (1::int) = 1 = True then 1 else (0::int))"

end
