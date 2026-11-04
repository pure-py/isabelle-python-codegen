theory Example_tree_weight
    imports Main "Python.Python_Setup"
begin

datatype 'a tree = Leaf | Node "'a tree" 'a "'a tree"

fun ins :: "'a::linorder \<Rightarrow> 'a tree \<Rightarrow> 'a tree" where
    "ins x Leaf = Node Leaf x Leaf"
  | "ins x (Node l y r) =
      (if x < y then Node (ins x l) y r
       else if y < x then Node l y (ins x r)
       else Node l y r)"

definition root_or :: "'a \<Rightarrow> 'a tree \<Rightarrow> 'a list" where
    "root_or d t = [case t of Leaf \<Rightarrow> d | Node _ x _ \<Rightarrow> x]"

fun fold_tree :: "('b \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> 'b \<Rightarrow> 'a tree \<Rightarrow> 'b" where
    "fold_tree f e Leaf = e"
  | "fold_tree f e (Node l x r) = f (fold_tree f e l) x (fold_tree f e r)"

definition from_list :: "'a::linorder list \<Rightarrow> 'a tree" where
    "from_list xs = foldr ins xs Leaf"

class weight =
    fixes calc_weight :: "'a \<Rightarrow> nat"

instantiation nat :: weight
begin
    definition calc_weight_nat :: "nat \<Rightarrow> nat" where
        "calc_weight_nat n = n"
    instance ..
end

instantiation tree :: (weight) weight
begin
    definition calc_weight_tree :: "'a tree \<Rightarrow> nat" where
        "calc_weight_tree = fold_tree (\<lambda>l x r. l + calc_weight x + r) 0"
    instance ..
end

definition example_weight :: nat where
    "example_weight = calc_weight (Node Leaf (Node Leaf (7::nat) Leaf) Leaf)"

end
