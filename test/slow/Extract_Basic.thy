section \<open>Extract Python code (basic setup)\<close>

theory Extract_Basic
imports
  "Candidates"
  "HOL-Library.AList_Mapping"
  "HOL-Library.Finite_Lattice"
  "Python.Python"
begin

(* we need to exclude this constant, as it runs into CPython's restriction on
   parentheses nesting depth without using Python list encoding *)
setup \<open> Code_Python.add_undefined_sym \<^const_name>\<open>String.enum_char_inst.enum_char\<close> \<close>

export_code _ in Python file "./generated_basic"

end