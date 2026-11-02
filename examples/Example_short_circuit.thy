theory Example_short_circuit
  imports Main "Python.Python_Setup"
begin

text \<open>
  A case expression in the right operand of a short-circuiting connective
  (conjunction, disjunction, implication) must only be evaluated if the left
  operand does not already determine the result. Here the left operand guards
  @{term "hd xs"}, which fails on the empty list.
\<close>

definition conj_case :: "nat list \<Rightarrow> bool" where
  "conj_case xs = (xs \<noteq> [] \<and> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

definition disj_case :: "nat list \<Rightarrow> bool" where
  "disj_case xs = (xs = [] \<or> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

definition impl_case :: "nat list \<Rightarrow> bool" where
  "impl_case xs = (xs \<noteq> [] \<longrightarrow> (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

text \<open>The same with a case on a datatype instead of @{typ nat}.\<close>

definition conj_case_list :: "nat list list \<Rightarrow> bool" where
  "conj_case_list xss = (xss \<noteq> [] \<and> (case hd xss of [] \<Rightarrow> True | _ \<Rightarrow> False))"

text \<open>Control: the guarded case in a branch of if-then-else.\<close>

definition if_case :: "nat list \<Rightarrow> bool" where
  "if_case xs = (if xs = [] then False else (case hd xs of 0 \<Rightarrow> True | Suc _ \<Rightarrow> False))"

text \<open>Expected values, checked by Isabelle's own code generator (SML).\<close>

lemma "conj_case [] = False" by eval
lemma "disj_case [] = True" by eval
lemma "impl_case [] = True" by eval
lemma "conj_case_list [] = False" by eval
lemma "if_case [] = False" by eval

definition conj_case_empty :: bool where "conj_case_empty = conj_case []"
definition conj_case_zero :: bool where "conj_case_zero = conj_case [0]"
definition disj_case_empty :: bool where "disj_case_empty = disj_case []"
definition disj_case_three :: bool where "disj_case_three = disj_case [3]"
definition impl_case_empty :: bool where "impl_case_empty = impl_case []"
definition conj_case_list_empty :: bool where "conj_case_list_empty = conj_case_list []"
definition if_case_empty :: bool where "if_case_empty = if_case []"

export_code
  conj_case disj_case impl_case conj_case_list if_case
  conj_case_empty conj_case_zero disj_case_empty disj_case_three
  impl_case_empty conj_case_list_empty if_case_empty
  in Python file_prefix "."

end
