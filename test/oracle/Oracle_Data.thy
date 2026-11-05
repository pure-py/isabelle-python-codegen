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
(* TODO: uncomment once moving to Isabelle 2026 *)
(* python_check l_indexed_from: "indexed_from 5 [True, False]" *)
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

section \<open>Mutually recursive datatypes\<close>

text \<open>Arithmetic and boolean expressions, each embedding the other.\<close>

datatype aexp = N int | Var nat | Plus aexp aexp | Times aexp aexp | Ite bexp aexp aexp
and bexp = BC bool | Less aexp aexp | Not bexp | And bexp bexp

fun aval :: "aexp \<Rightarrow> (nat \<Rightarrow> int) \<Rightarrow> int" and bval :: "bexp \<Rightarrow> (nat \<Rightarrow> int) \<Rightarrow> bool" where
  "aval (N n) s = n"
| "aval (Var x) s = s x"
| "aval (Plus a b) s = aval a s + aval b s"
| "aval (Times a b) s = aval a s * aval b s"
| "aval (Ite c a b) s = (if bval c s then aval a s else aval b s)"
| "bval (BC v) s = v"
| "bval (Less a b) s = (aval a s < aval b s)"
| "bval (Not b) s = (\<not> bval b s)"
| "bval (And b1 b2) s = (bval b1 s \<and> bval b2 s)"

text \<open>Constant folding: rebuilds values of both types.\<close>

fun asimp :: "aexp \<Rightarrow> aexp" and bsimp :: "bexp \<Rightarrow> bexp" where
  "asimp (Plus a b) = (case (asimp a, asimp b) of
     (N x, N y) \<Rightarrow> N (x + y) | (a', b') \<Rightarrow> Plus a' b')"
| "asimp (Times a b) = (case (asimp a, asimp b) of
     (N x, N y) \<Rightarrow> N (x * y) | (a', b') \<Rightarrow> Times a' b')"
| "asimp (Ite c a b) = (case bsimp c of
     BC True \<Rightarrow> asimp a | BC False \<Rightarrow> asimp b | c' \<Rightarrow> Ite c' (asimp a) (asimp b))"
| "asimp a = a"
| "bsimp (Less a b) = (case (asimp a, asimp b) of
     (N x, N y) \<Rightarrow> BC (x < y) | (a', b') \<Rightarrow> Less a' b')"
| "bsimp (Not b) = (case bsimp b of BC v \<Rightarrow> BC (\<not> v) | b' \<Rightarrow> Not b')"
| "bsimp (And b1 b2) = (case (bsimp b1, bsimp b2) of
     (BC False, _) \<Rightarrow> BC False | (BC True, b') \<Rightarrow> b' | (b', BC True) \<Rightarrow> b'
   | (b1', b2') \<Rightarrow> And b1' b2')"
| "bsimp b = b"

fun avars :: "aexp \<Rightarrow> nat list" and bvars :: "bexp \<Rightarrow> nat list" where
  "avars (N _) = []"
| "avars (Var x) = [x]"
| "avars (Plus a b) = avars a @ avars b"
| "avars (Times a b) = avars a @ avars b"
| "avars (Ite c a b) = bvars c @ avars a @ avars b"
| "bvars (BC _) = []"
| "bvars (Less a b) = avars a @ avars b"
| "bvars (Not b) = bvars b"
| "bvars (And b1 b2) = bvars b1 @ bvars b2"

definition ex_a :: aexp where
  "ex_a = Ite (And (Less (Var 0) (N 5)) (Not (BC False)))
     (Plus (Var 0) (Times (N 2) (Var 1)))
     (Ite (Less (N 1) (N 0)) (N 7) (Var 1))"

definition ex_s :: "nat \<Rightarrow> int" where
  "ex_s x = (if x = 0 then 3 else if x = 1 then -4 else 0)"

python_check m_aval: "aval ex_a ex_s"
python_check m_aval_else: "aval ex_a (\<lambda>x. 10)"
python_check m_bval: "bval (And (Less (Var 0) (Var 1)) (Not (BC False))) (\<lambda>x. int x)"
python_check m_asimp: "asimp (Plus (Times (N 2) (N 3)) (Ite (Less (N 1) (N 2)) (Var 0) (N 9)))"
python_check m_asimp_ex: "asimp ex_a"
python_check m_bsimp: "bsimp (And (Not (BC False)) (Less (Var 0) (Plus (N 1) (N 1))))"
python_check m_bsimp_short: "bsimp (And (Less (N 3) (N 2)) (Less (Var 0) (Var 1)))"
python_check m_simp_sound: "aval (asimp ex_a) ex_s = aval ex_a ex_s"
python_check m_vars: "(avars ex_a, bvars (Not (Less (Var 2) (Var 3))))"
python_check m_eq: "(asimp (Plus (N 1) (N 2)) = N 3, Not (BC True) = Not (BC False))"
python_check m_eq_cross: "(Ite (BC True) (N 1) (N 2) = Ite (BC True) (N 1) (N 2),
  Ite (BC True) (N 1) (N 2) = Ite (Not (BC False)) (N 1) (N 2))"
python_check m_case: "case Ite (BC True) (N 1) (N 2) of Ite c _ _ \<Rightarrow> c | _ \<Rightarrow> BC False"
python_check m_size: "(size ex_a, size (And (BC True) (BC False)))"

text \<open>A polymorphic rose tree as a tree/forest pair.\<close>

datatype 'a tree = Node 'a "'a forest"
and 'a forest = FNil | FCons "'a tree" "'a forest"

fun tsum :: "int tree \<Rightarrow> int" and fsum :: "int forest \<Rightarrow> int" where
  "tsum (Node x f) = x + fsum f"
| "fsum FNil = 0"
| "fsum (FCons t f) = tsum t + fsum f"

fun tflat :: "'a tree \<Rightarrow> 'a list" and fflat :: "'a forest \<Rightarrow> 'a list" where
  "tflat (Node x f) = x # fflat f"
| "fflat FNil = []"
| "fflat (FCons t f) = tflat t @ fflat f"

fun tmap :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a tree \<Rightarrow> 'b tree"
  and fmap :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a forest \<Rightarrow> 'b forest" where
  "tmap g (Node x f) = Node (g x) (fmap g f)"
| "fmap g FNil = FNil"
| "fmap g (FCons t f) = FCons (tmap g t) (fmap g f)"

fun tdepth :: "'a tree \<Rightarrow> nat" and fdepth :: "'a forest \<Rightarrow> nat" where
  "tdepth (Node _ f) = Suc (fdepth f)"
| "fdepth FNil = 0"
| "fdepth (FCons t f) = max (tdepth t) (fdepth f)"

text \<open>Reverses the children at every level, via an accumulator over the forest.\<close>

fun tmirror :: "'a tree \<Rightarrow> 'a tree" and fmirror :: "'a forest \<Rightarrow> 'a forest \<Rightarrow> 'a forest" where
  "tmirror (Node x f) = Node x (fmirror f FNil)"
| "fmirror FNil acc = acc"
| "fmirror (FCons t f) acc = fmirror f (FCons (tmirror t) acc)"

fun forest_of :: "'a tree list \<Rightarrow> 'a forest" where
  "forest_of [] = FNil"
| "forest_of (t # ts) = FCons t (forest_of ts)"

definition ex_t :: "int tree" where
  "ex_t = Node 1 (forest_of [Node 2 FNil, Node 3 (forest_of [Node 4 FNil, Node (-5) FNil]), Node 6 FNil])"

python_check m_tsum: "tsum ex_t"
python_check m_tflat: "tflat ex_t"
python_check m_tmap: "tmap (\<lambda>x. x > 2) ex_t"
python_check m_tmap_flat: "tflat (tmap (\<lambda>x. STR ''n'' + (if x > 0 then STR ''+'' else STR ''-'')) ex_t)"
python_check m_tdepth: "(tdepth ex_t, tdepth (Node () FNil), fdepth (FNil :: nat forest))"
python_check m_tmirror: "tflat (tmirror ex_t)"
python_check m_tmirror_inv: "tmirror (tmirror ex_t) = ex_t"
python_check m_tmirror_neq: "tmirror ex_t = ex_t"
python_check m_forest: "fmap (\<lambda>x. [x, x]) (forest_of [Node (1::nat) FNil, Node 2 FNil])"
python_check m_tree_pair: "Node (1::int, True) (FCons (Node (2, False) FNil) FNil)"

text \<open>Three types in a cycle, with an option and a list in between.\<close>

datatype ta = A0 | A1 nat tb
and tb = B "tc option"
and tc = C "ta list"

fun ca :: "ta \<Rightarrow> nat" and cb :: "tb \<Rightarrow> nat" and cc :: "tc \<Rightarrow> nat" and cl :: "ta list \<Rightarrow> nat" where
  "ca A0 = 1"
| "ca (A1 n b) = n + cb b"
| "cb (B None) = 0"
| "cb (B (Some c)) = cc c"
| "cc (C as) = cl as"
| "cl [] = 0"
| "cl (a # as) = ca a + cl as"

definition ex_ta :: ta where
  "ex_ta = A1 10 (B (Some (C [A0, A1 5 (B None), A1 2 (B (Some (C [A0, A0])))])))"

python_check m_cycle: "ca ex_ta"
python_check m_cycle_val: "ex_ta"
python_check m_cycle_eq: "(ex_ta = ex_ta, B (Some (C [])) = B None)"
python_check_grid m_cycle_grid: "\<lambda>n. ca (A1 n (B (Some (C (replicate n A0)))))" over "[0, 1, 3]"

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
