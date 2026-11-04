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

section \<open>Short-circuiting connectives\<close>

text \<open>A case expression in the right operand of a conjunction, guarded by the left
  operand: @{term "hd []"} must not be evaluated.\<close>

definition conj_case_alt :: "nat list \<Rightarrow> bool" where
  "conj_case_alt xs = (xs \<noteq> [] \<and> ((case hd xs of 0 \<Rightarrow> 0 | Suc n \<Rightarrow> n) = 0))"

python_check_grid sc_conj_case_alt: "conj_case_alt" over "[[], [0], [1], [2], [0, 5], [3, 1]]"

text \<open>The other connectives, with a case of type @{typ nat} in the right operand.\<close>

definition disj_case_alt :: "nat list \<Rightarrow> bool" where
  "disj_case_alt xs = (xs = [] \<or> (case hd xs of 0 \<Rightarrow> 1 | Suc n \<Rightarrow> n) = 1)"

definition impl_case_alt :: "nat list \<Rightarrow> bool" where
  "impl_case_alt xs = (xs \<noteq> [] \<longrightarrow> (case hd xs of 0 \<Rightarrow> 0 | Suc n \<Rightarrow> n) = 0)"

definition not_disj_case :: "nat list \<Rightarrow> bool" where
  "not_disj_case xs = (\<not> (xs = [] \<or> (case hd xs of 0 \<Rightarrow> False | Suc _ \<Rightarrow> True)))"

python_check_grid sc_disj_case_alt: "disj_case_alt" over "[[], [0], [1], [2], [2, 0]]"
python_check_grid sc_impl_case_alt: "impl_case_alt" over "[[], [0], [1], [2], [2, 0]]"
python_check_grid sc_not_disj_case: "not_disj_case" over "[[], [0], [1]]"

text \<open>Each guard protects the operands after it.\<close>

definition conj_chain :: "nat list \<Rightarrow> bool" where
  "conj_chain xs = (xs \<noteq> [] \<and> tl xs \<noteq> [] \<and> (case hd (tl xs) of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

definition disj_conj :: "nat list \<Rightarrow> bool" where
  "disj_conj xs = (xs = [] \<or> (tl xs \<noteq> [] \<and> (case hd (tl xs) of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False)))"

definition case_conj_case :: "nat list \<Rightarrow> bool" where
  "case_conj_case xs = ((case xs of [] \<Rightarrow> False | _ \<Rightarrow> True) \<and> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

python_check_grid sc_conj_chain: "conj_chain" over "[[], [0], [0, 0], [0, 1], [1, 0, 2]]"
python_check_grid sc_disj_conj: "disj_conj" over "[[], [0], [0, 0], [0, 1]]"
python_check_grid sc_case_conj_case: "case_conj_case" over "[[], [0], [1]]"

text \<open>Partial operations other than @{const hd}.\<close>

definition conj_nth :: "nat list \<Rightarrow> nat \<Rightarrow> bool" where
  "conj_nth xs i = (i < length xs \<and> (case xs ! i of 0 \<Rightarrow> True | Suc n \<Rightarrow> n = 2))"

definition conj_the :: "nat option \<Rightarrow> bool" where
  "conj_the x = (x \<noteq> None \<and> (case the x of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

definition conj_option_case :: "nat option list \<Rightarrow> bool" where
  "conj_option_case xs = (xs \<noteq> [] \<and> (case hd xs of None \<Rightarrow> False | Some n \<Rightarrow> 0 < n))"

python_check_grid sc_conj_nth: "conj_nth" over "[[], [0], [3, 1]]" "[0, 1, 2]"
python_check_grid sc_conj_the: "conj_the" over "[None, Some 0, Some 4]"
python_check_grid sc_conj_option_case: "conj_option_case" over "[[], [None], [Some 0], [Some 2, None]]"

text \<open>The connective in an if condition, in a lambda and in a recursive function.\<close>

definition if_conj :: "nat list \<Rightarrow> nat" where
  "if_conj xs = (if xs \<noteq> [] \<and> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False) then 1 else 2)"

fun zero_heads :: "nat list list \<Rightarrow> bool" where
  "zero_heads [] = True"
| "zero_heads (xs # xss) =
    ((xs \<noteq> [] \<longrightarrow> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False)) \<and> zero_heads xss)"

python_check_grid sc_if_conj: "if_conj" over "[[], [0], [1]]"
python_check sc_map_lambda:
  "map (\<lambda>xs. xs \<noteq> [] \<and> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False)) [[], [0::nat], [1, 0]]"
python_check sc_filter_lambda:
  "filter (\<lambda>xs. xs = [] \<or> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False)) [[], [0::nat], [1, 0]]"
python_check_grid sc_zero_heads: "zero_heads" over "[[], [[]], [[0], [], [0, 1]], [[], [2]]]"

end
