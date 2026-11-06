theory Oracle_Import_Cycle
  imports Python_Check "Python.Python_Setup"
begin

text \<open>Some generated modules of these checks import each other (e.g. \<open>Num\<close>, \<open>Groups\<close>,
  \<open>Power\<close> and \<open>Rings\<close>), and sorting string literals makes this module import \<open>List\<close>
  and \<open>String\<close>. Kept apart because a failure at import, as a value evaluated while a module
  it uses is still being imported, would fail every check in its module.\<close>

python_check sort_str: "sort [STR ''b'', STR ''a'', STR ''c'']"

end
