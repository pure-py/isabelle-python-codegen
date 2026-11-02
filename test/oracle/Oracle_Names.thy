theory Oracle_Names
  imports Python_Check "Python.Python_Setup"
begin

text \<open>Constants and variables named like Python builtins that the generated code
  itself uses (\<open>list\<close>, \<open>map\<close>, \<open>max\<close>, \<open>len\<close>, \<open>RuntimeError\<close>, ...).\<close>

definition v_list :: "int \<Rightarrow> int list" where "v_list list = map (\<lambda>x. x + list) [1, 2]"
definition v_len :: "int list \<Rightarrow> nat" where "v_len len = length len"
definition v_ab :: "int \<Rightarrow> int \<Rightarrow> int" where "v_ab a b = b div a + a mod b"
definition v_capture :: "int \<Rightarrow> int list" where "v_capture a = map (\<lambda>b. b div a) [6, 7]"
definition v_self :: "int \<Rightarrow> int \<Rightarrow> int" where "v_self self cls = self - cls"
definition v_bool :: "bool \<Rightarrow> int" where "v_bool bool = (if bool then 1 else 0)"
definition v_iter :: "int \<Rightarrow> int \<Rightarrow> int" where "v_iter iter next = iter + next"
definition v_print :: "int \<Rightarrow> int" where "v_print print = print + 1"
definition v_str :: "int \<Rightarrow> int" where "v_str str = str * 2"
definition v_type :: "int \<Rightarrow> int" where "v_type type = type * 3"
definition v_kw :: "int \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int" where "v_kw pass yield lambda = pass + yield + lambda"

definition RuntimeError :: "int \<Rightarrow> int" where "RuntimeError x = x + 1"
definition NotImplementedError :: "int \<Rightarrow> int" where "NotImplementedError x = x - 1"
definition object :: int where "object = 7"
definition tuple :: "int \<Rightarrow> int \<times> int" where "tuple x = (x, x)"
definition dataclass :: int where "dataclass = 4"
definition Any :: int where "Any = 5"
definition functools :: int where "functools = 6"

python_check n_list: "v_list 10"
python_check n_len: "v_len [1, 2, 3]"
python_check n_ab: "v_ab 3 7"
python_check n_capture: "v_capture 2"
python_check n_self: "v_self 5 3"
python_check n_bool: "v_bool True"
python_check n_iter: "v_iter 1 2"
python_check n_print: "v_print 1"
python_check n_str: "v_str 4"
python_check n_type: "v_type 4"
python_check n_kw: "v_kw 1 2 3"
python_check n_errors: "NotImplementedError (RuntimeError 5)"
python_check n_object_tuple: "tuple object"
python_check n_typing: "dataclass + Any + functools"

end
