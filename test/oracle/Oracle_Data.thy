theory Oracle_Data
  imports Python_Check "Python.Python_Setup" "Python.Python_IArray"
begin

section \<open>Lists\<close>

fun alt :: "'a list \<Rightarrow> 'a list" where
  "alt (x # y # zs) = x # alt zs"
| "alt xs = xs"

python_check l_rev: "rev [1::int, 2, 3]"
python_check l_sort: "sort [3::int, -1, 2, -1]"
python_check l_sort_key: "sort_key (\<lambda>x. - x) [3::int, -1, 2]"
python_check l_remdups: "remdups [1::nat, 2, 1, 3, 2]"
python_check l_zip: "zip [1::nat, 2, 3] [True, False]"
python_check l_upt: "[2..<6]"
python_check l_upt_empty: "[6..<2]"
python_check l_upt_long: "length [0..<5000]"
python_check l_upto: "[(-2::int)..2]"
python_check l_take_drop: "(take 2 [1::int, 2, 3], drop 5 [1::int, 2])"
python_check l_nth: "[10::int, 20, 30] ! 2"
python_check l_concat: "concat [[1::int], [], [2, 3]]"
python_check l_foldr: "foldr (\<lambda>x acc. x - acc) [1::int, 2, 3] 0"
python_check l_foldl: "foldl (\<lambda>acc x. acc - x) (0::int) [1, 2, 3]"
python_check l_sum: "sum_list [1::int, -2, 3]"
python_check l_sum_nat: "sum_list [1::nat, 2, 3]"
python_check l_prod: "prod_list [2::int, -3]"
python_check l_distinct: "(distinct [1::int, 2, 1], distinct [1::int, 2])"
python_check l_replicate: "replicate 3 (0::nat)"
python_check l_butlast: "butlast [1::int, 2, 3]"
python_check l_last: "last [1::int, 2, 3]"
python_check l_update: "[1::int, 2, 3][1 := 9]"
python_check l_filter: "filter (\<lambda>x. x mod 2 = 0) [1::int, 2, 3, 4]"
python_check l_find: "(find (\<lambda>x. x > 2) [1::int, 2, 3, 4], find (\<lambda>x. x > 9) [1::int])"
python_check l_append_nested: "([1::int] @ [2]) @ ([] @ [3])"
python_check l_cons_var: "let xs = [2::int, 3] in 1 # xs"
python_check l_cons_cons: "let xs = [3::int] in 1 # 2 # xs"
python_check l_length: "length [[1::int], [], [2]]"
python_check l_map_pair: "map (\<lambda>(a, b). a + b) [(1::int, 2), (3, 4)]"
python_check l_list_all: "(list_all (\<lambda>x. x > 0) [1::int, 2], list_ex (\<lambda>x. x < 0) [1::int])"
python_check l_insert: "(List.insert 2 [1::int, 3], List.insert 1 [1::int, 3])"
python_check l_product: "List.product [1::int, 2] [True, False]"
python_check l_enumerate: "enumerate 5 [True, False]"
python_check l_splice: "splice [1::int, 3] [2, 4, 6]"
python_check l_rotate: "rotate 2 [1::int, 2, 3]"
python_check l_min_list: "min_list [3::int, -1, 2]"
python_check l_maps: "List.maps (\<lambda>x. [x, x]) [1::int, 2]"
python_check l_nested_eq: "([[1::int], []] = [[1], []], [[1::int]] = [[]])"
python_check l_alt: "alt [1::int, 2, 3, 4, 5]"
python_check l_map_nested: "map (map (\<lambda>x. x + 1)) [[1::int], [], [2, 3]]"
python_check l_hd_tl: "(hd [1::int, 2], tl [1::int, 2])"
python_check l_member: "(List.member [1::int, 2] 2, (3::int) \<in> set [1, 2])"

section \<open>Options and pairs\<close>

python_check o_map: "map_option (\<lambda>x. x + 1) (Some (1::int))"
python_check o_bind: "Option.bind (Some (3::int)) (\<lambda>x. if x > 2 then None else Some x)"
python_check o_the: "the (Some (2::nat)) + 1"
python_check o_map_filter: "List.map_filter (\<lambda>x. if x > 1 then Some (x * 2) else None) [1::int, 2, 3]"
python_check o_case: "case (None::int option) of None \<Rightarrow> 0 | Some x \<Rightarrow> x"
python_check o_nested: "Some (Some (None::int option))"
python_check p_nested: "((1::int, True), (STR ''a'', [2::nat]))"
python_check p_swap: "prod.swap (1::int, False)"
python_check p_case: "case (3::int, 4::int) of (a, b) \<Rightarrow> a * b"
python_check p_case_prod: "case_prod (\<lambda>a b. a - b) (5::int, 7)"
python_check p_fst_snd: "fst (snd ((1::int), (2::int, 3::int)))"

section \<open>Sets\<close>

python_check s_union: "{1::int, 2} \<union> {2, 3}"
python_check s_eq: "{1::int, 2} = {2, 1, 1}"
python_check s_card: "card {1::int, 2, 2, 3}"
python_check s_max: "Max {3::int, -1, 2}"
python_check s_subset: "({1::int} \<subseteq> {1, 2}, {1::int, 2} \<subseteq> {1})"
python_check s_coset_mem: "(2::int) \<in> - {1}"
python_check s_coset_subset: "{1::int, 3} \<subseteq> - {2}"
python_check s_image: "(\<lambda>x. x mod 2) ` {1::int, 2, 3}"
python_check s_filter: "Set.filter (\<lambda>x. x > 1) {1::int, 2, 3}"
python_check s_inter_coset: "{1::int, 2, 3} \<inter> - {2}"
python_check s_min: "min {1::int} {2}"
python_check s_max_sets: "max {1::int} {2}"
python_check s_of_sets: "card {{1::int}, {1}, {2}}"

section \<open>Records\<close>

record point = px :: int  py :: int
record cpoint = point + col :: bool

python_check r_update: "px (\<lparr>px = 1, py = 2\<rparr>\<lparr>px := 5\<rparr>)"
python_check r_eq: "(\<lparr>px = 1, py = 2\<rparr> = \<lparr>px = 1, py = (2::int)\<rparr>, \<lparr>px = 1, py = 2\<rparr> = \<lparr>px = 2, py = (1::int)\<rparr>)"
python_check r_ext: "col (\<lparr>px = 1, py = 2, col = True\<rparr>\<lparr>py := 3\<rparr>)"
python_check r_ext_px: "px (\<lparr>px = 1, py = 2, col = True\<rparr>\<lparr>py := 3\<rparr>)"

section \<open>Immutable arrays\<close>

python_check ia_sub: "IArray [1::int, 2, 3] !! 1"
python_check ia_len: "IArray.length (IArray [True, False])"
python_check ia_of_fun: "IArray.list_of (IArray.of_fun (\<lambda>i. i * i) 4)"
python_check ia_eq: "(IArray [1::int] = IArray [1], IArray [1::int] = IArray [])"
python_check ia_all: "(IArray.all (\<lambda>x. x > 0) (IArray [1::int, 2]), IArray.exists (\<lambda>x. x > 1) (IArray [1::int]))"
python_check ia_tabulate: "IArray.list_of (IArray.tabulate (3, \<lambda>i. i + 1))"
python_check ia_sub_pair: "IArray.sub' (IArray [10::int, 20], 1)"
python_check ia_sub_pair_var: "let p = (IArray [10::int, 20], 1) in IArray.sub' p"

end
