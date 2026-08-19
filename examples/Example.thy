theory Example
    imports Main "Python.Python_Setup"
begin

datatype color = Red | Green | Blue

fun is_red :: "color \<Rightarrow> bool" where
"is_red Red = True" |
"is_red _ = False"

export_code is_red in Python file_prefix "."

end