theory Example_annotation_edges
  imports Main "Python.Python_Setup"
begin

text \<open>Cases a type checker can get wrong in the code generated with type annotations.\<close>

text \<open>A constructor at a nested position of a generic parameter: from the argument
  \<open>[Leaf]\<close> of \<open>first_or\<close>, a type checker may take \<open>Leaf\<close> rather than \<open>nat tree\<close>
  for \<open>'b\<close>, which does not fit the function argument.\<close>

datatype 'a tree = Leaf | Node "'a tree" 'a "'a tree"

definition first_or :: "'b list \<Rightarrow> ('b \<Rightarrow> 'b) \<Rightarrow> 'b \<Rightarrow> 'b" where
  "first_or xs f d = (case xs of [] \<Rightarrow> d | x # _ \<Rightarrow> f x)"

definition grow :: "nat tree \<Rightarrow> nat tree" where
  "grow t = first_or [Leaf] (\<lambda>l. Node l 0 t) t"

text \<open>An instance dictionary passed to an ordinary function, where the instance has a
  type parameter that no dictionary argument determines: the instance for functions
  only constrains their result type.\<close>

class pointed =
  fixes point :: 'a

instantiation nat :: pointed
begin
definition point_nat :: nat where "point_nat = 0"
instance ..
end

instantiation "fun" :: (type, pointed) pointed
begin
definition point_fun :: "'a \<Rightarrow> 'b" where "point_fun = (\<lambda>_. point)"
instance ..
end

definition with_point :: "'a::pointed \<Rightarrow> 'a \<times> 'a" where
  "with_point x = (point, x)"

definition fun_with_point :: "(nat \<Rightarrow> nat) \<times> (nat \<Rightarrow> nat)" where
  "fun_with_point = with_point (\<lambda>n. n + 1)"

export_code grow fun_with_point in Python file_prefix "."

end
