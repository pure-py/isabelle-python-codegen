theory Example_classrel
  imports Example_classrel_base "Python.Python_Setup"
begin

instantiation bool :: rich_op
begin
definition sup_apply_bool :: "bool \<Rightarrow> bool" where
  "sup_apply_bool b = b"
definition rich_marker_bool :: "bool \<Rightarrow> bool" where
  "rich_marker_bool b = b"
instance ..
end

definition test_super :: bool where "test_super = sup_apply True"
definition test_sub :: bool where "test_sub = sub_apply True"

export_code sup_apply sub_apply test_super test_sub in Python file_prefix "."

end