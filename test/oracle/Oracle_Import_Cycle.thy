theory Oracle_Import_Cycle
  imports Python_Check "Python.Python_Setup"
begin

text \<open>Sorting string literals makes this module import \<open>String\<close> before \<open>Arith\<close>.
  The generated \<open>Arith\<close> and \<open>String\<close> import each other, and a value of
  \<open>Arith\<close> uses \<open>String.char_of_integer\<close>, which fails if it is evaluated at import
  time. Kept apart because such a failure is at import, so it fails every check in its module.\<close>

python_check sort_str: "sort [STR ''b'', STR ''a'', STR ''c'']"

end
