theory Example_transparent_wrapper
  imports Main "Python.Python_Setup"
begin

(* any user-defined type that is 
    (a) represented by a single constructor for code-generation purposes and 
    (b) given identity ("_") in Python printing because its runtime 
        representation is identical to its argument's, needs a custom printer 
        setup.

   Box is boxed's sole constructor (declared automatically by `datatype`), and 
   we tell the Python backend it should print with zero runtime overhead,
   as just the underlying bool, no wrapper object, via `constant 
   Box => (Python) "_"`. *)

datatype boxed = Box bool

code_printing
    type_constructor boxed \<rightharpoonup> (Python) "bool"
  | constant Box \<rightharpoonup> (Python) "_"

(* Crashes without custom setup: Box wraps a genuinely free pattern variable (n). *)
fun unbox :: "boxed \<Rightarrow> bool" where
  "unbox (Box n) = n"

fun box_is_true :: "boxed \<Rightarrow> bool" where
  "box_is_true (Box True) = True"
| "box_is_true (Box False) = False"

definition unbox_test :: bool where "unbox_test = unbox (Box True)"
definition box_is_true_test :: "bool \<times> bool" where
  "box_is_true_test = (box_is_true (Box True), box_is_true (Box False))"

setup \<open>
  Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Box\<close>
\<close>

export_code unbox box_is_true unbox_test box_is_true_test in 
    Python file_prefix "."

end