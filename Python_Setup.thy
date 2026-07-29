theory Python_Setup
    imports Main
begin

ML_file \<open>code_python.ML\<close>

code_identifier
  code_module Code_Target_Nat \<rightharpoonup> (Python) Arith
| code_module Code_Target_Int \<rightharpoonup> (Python) Arith
| code_module Code_Numeral \<rightharpoonup> (Python) Arith

code_printing
  constant Code.abort \<rightharpoonup> (Python) "raise RuntimeError(\"_\")"

end