theory Quick_Test_Name_Clash
  imports Main "Python.Python_Setup"
begin

text \<open>Three constants with the base name \<open>insert\<close> in one Python module: \<open>Set.insert\<close>,
  \<open>List.insert\<close> (in the code equation of \<open>Set.insert\<close> on \<open>set xs\<close>), and the one below.
  Exported with \<open>module_name\<close>, so all three share a namespace and two of them need fresh
  names. Each must get its own name: if two get the same one (e.g. both \<open>insert_\<close>), the later
  \<open>def\<close> shadows the earlier and calls to the first one run the second.\<close>

definition insert :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "insert x xs = xs @ [x]"

definition nc_own :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "nc_own x xs = insert x xs"

definition nc_list :: "nat \<Rightarrow> nat list \<Rightarrow> nat list" where
  "nc_list x xs = List.insert x xs"

definition nc_set :: "nat \<Rightarrow> nat \<Rightarrow> nat list \<Rightarrow> bool" where
  "nc_set y x xs = (y \<in> Set.insert x (set xs))"

export_code nc_own nc_list nc_set
  in Python module_name Quick_Test_Name_Clash file_prefix "."

end
