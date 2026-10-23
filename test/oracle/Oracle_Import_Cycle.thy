theory Oracle_Import_Cycle
  imports Python_Check "Python.Python_Setup"
begin

text \<open>Sorting string literals makes this module import \<open>String\<close> before \<open>Arith\<close>.
  The generated \<open>Arith\<close> and \<open>String\<close> import each other, and \<open>Arith\<close> uses
  \<open>String.char_of_integer\<close> at import time. Kept apart because the failure is at
  import, so it fails every check in its module.\<close>

python_check sort_str: "sort [STR ''b'', STR ''a'', STR ''c'']"

end
