theory Example_no_eqs
  imports Main "Python.Python_Setup"
begin

definition uses_undefined :: nat where
  "uses_undefined = undefined"

export_code uses_undefined in Python file_prefix "."

end