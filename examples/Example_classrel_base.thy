theory Example_classrel_base
  imports Main
begin

class super_op =
  fixes sup_apply :: "'a \<Rightarrow> 'a"

class sub_op = super_op
begin
definition sub_apply :: "'a \<Rightarrow> 'a" where
  "sub_apply x = sup_apply (sup_apply x)"
end

class rich_op = super_op +
  fixes rich_marker :: "'a \<Rightarrow> 'a"

context rich_op
begin
subclass sub_op .
end

end