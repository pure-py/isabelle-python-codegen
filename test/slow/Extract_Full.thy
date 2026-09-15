section \<open>Extract Python code (full setup)\<close>

theory Extract_Full
imports
  "Candidates"
  "HOL-Library.AList_Mapping"
  "HOL-Library.Finite_Lattice"
  "Python.Python_Setup"
begin

export_code _ in Python file "./generated_full"

end