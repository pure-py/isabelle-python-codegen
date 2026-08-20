theory Python_Setup
    imports Main
begin

ML_file \<open>code_python.ML\<close>

code_identifier
  code_module Code_Target_Nat \<rightharpoonup> (Python) Arith
| code_module Code_Target_Int \<rightharpoonup> (Python) Arith
| code_module Code_Numeral \<rightharpoonup> (Python) Arith

(* Panic *)
code_printing
  constant Code.abort \<rightharpoonup> (Python) "raise RuntimeError(\"_\")"

(* unit *)
code_printing
    type_constructor Product_Type.unit \<rightharpoonup> (Python) "None"
  | constant Unity \<rightharpoonup> (Python) "None"

(* Bools *)
code_printing
  type_constructor bool \<rightharpoonup> (Python) "bool"
| constant "False::bool" \<rightharpoonup> (Python) "False"
| constant "True::bool" \<rightharpoonup> (Python) "True"
| constant HOL.Not \<rightharpoonup> (Python) "not _"
| constant HOL.conj \<rightharpoonup> (Python) infixl 1 "and"
| constant HOL.disj \<rightharpoonup> (Python) infixl 0 "or"
| constant HOL.implies \<rightharpoonup> (Python) "!(not ((_)) or (_))"
| constant "HOL.equal :: bool \<Rightarrow> bool \<Rightarrow> bool" \<rightharpoonup> (Python) infix 4 "=="

(* Strings *)
code_printing
    type_constructor String.literal \<rightharpoonup> (Python) "str"
  | constant "STR ''''" \<rightharpoonup> (Python) "\"\""
  | constant "(+) :: String.literal \<Rightarrow> String.literal \<Rightarrow> String.literal" \<rightharpoonup>
      (Python) infixl 65 "+"
  | constant "HOL.equal :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) infixl 40 "=="
  | constant "(\<le>) :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) infixl 35 "<="
  | constant "(<) :: String.literal \<Rightarrow> String.literal \<Rightarrow> bool" \<rightharpoonup>
      (Python) infixl 35 "<"

setup \<open>
  Literal.add_code "Python"
\<close>

(* Integers *)
code_printing
    type_constructor Int.int \<rightharpoonup> (Python) "int"
  | constant "0 :: int" \<rightharpoonup> (Python) "0"
  | constant "(+) :: int \<Rightarrow> int \<Rightarrow> int" \<rightharpoonup> (Python) "(_ + _)"
  | constant "(-) :: int \<Rightarrow> int \<Rightarrow> int" \<rightharpoonup> (Python) "(_ - _)"
  | constant "uminus :: int \<Rightarrow> int" \<rightharpoonup> (Python) "(- _)"
  | constant "HOL.equal :: int \<Rightarrow> int \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ == _)"
  | constant "(\<le>) :: int \<Rightarrow> int \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ <= _ )"
  | constant "(<) :: int \<Rightarrow> int \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ < _)"
  | constant "(*) :: int \<Rightarrow> int \<Rightarrow> int" \<rightharpoonup> (Python) "(_ * _)"
  | constant "(div) :: int \<Rightarrow> int \<Rightarrow> int" \<rightharpoonup> (Python) "(_ '/'/ _)"
  | constant "(mod) :: int \<Rightarrow> int \<Rightarrow> int" \<rightharpoonup> (Python) "(_ % _)"

code_printing
    constant "abs :: int \<Rightarrow> int" \<rightharpoonup> (Python) "abs'(_')"
  | constant "min" \<rightharpoonup> (Python) "min(_, _)"
  | constant "max" \<rightharpoonup> (Python) "max(_, _)"

lemma one_int_code [code_unfold]:
  "(1::int) = Int.Pos Num.One"
  by simp

setup \<open>
  (fn target =>
    Numeral.add_code \<^const_name>\<open>Int.Pos\<close> I
      Code_Printer.literal_numeral target
    #> Numeral.add_code \<^const_name>\<open>Int.Neg\<close> (~)
      Code_Printer.literal_numeral target)
    "Python"
\<close>

setup \<open>
  let
    open Code_Thingol Code_Printer;

    fun pretty literals print_term thm vars fxy [(x, _)] =
      let val p = print_term vars NOBR x
      in Pretty.block [Pretty.str "((", p, Pretty.str " > 0) - (", p, Pretty.str " < 0))"] end;

  in
    (fn target =>
      Code_Target.set_printings (Code_Symbol.Constant (\<^const_name>\<open>Int.sgn_int_inst.sgn_int\<close>,
        [(target, SOME (complex_const_syntax (1, pretty)))])))
    "Python"
  end
\<close>

(* nats *)
code_printing
    type_constructor Nat.nat \<rightharpoonup> (Python) "int"
  | constant "0 :: nat" \<rightharpoonup> (Python) "0"
  | constant "1 :: nat" \<rightharpoonup> (Python) "1"
  | constant Suc \<rightharpoonup> (Python) "(_ + 1)"
  | constant "(+) :: nat \<Rightarrow> nat \<Rightarrow> nat" \<rightharpoonup> (Python) "(_ + _)"
  | constant "(-) :: nat \<Rightarrow> nat \<Rightarrow> nat" \<rightharpoonup> (Python) "max(0, _ - _)"
  | constant "(*) :: nat \<Rightarrow> nat \<Rightarrow> nat" \<rightharpoonup> (Python) "(_ * _)"
  | constant "(div) :: nat \<Rightarrow> nat \<Rightarrow> nat" \<rightharpoonup> (Python) "(_ '/'/ _)"
  | constant "(mod) :: nat \<Rightarrow> nat \<Rightarrow> nat" \<rightharpoonup> (Python) "(_ % _)"
  | constant "HOL.equal :: nat \<Rightarrow> nat \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ == _)"
  | constant "(\<le>) :: nat \<Rightarrow> nat \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ <= _)"
  | constant "(<) :: nat \<Rightarrow> nat \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ < _)"

setup \<open>
  Numeral.add_code \<^const_name>\<open>Num.nat_of_num\<close> I Code_Printer.literal_numeral "Python"
\<close>

(* Lists *)
code_printing
    type_constructor List.list \<rightharpoonup> (Python) "_ list"
  | constant List.list.Nil \<rightharpoonup> (Python) "[]"
  
code_printing
    constant "length" \<rightharpoonup> (Python) "len'(_')"
  | constant List.map \<rightharpoonup> (Python) "list(map((_), (_)))"

setup \<open>
  let
    open Code_Thingol Code_Printer;

    fun dest_list_literal (IConst { sym = Code_Symbol.Constant 
          \<^const_name>\<open>List.list.Nil\<close>, ...}) = SOME []
      | dest_list_literal (IConst { sym = Code_Symbol.Constant
          \<^const_name>\<open>List.list.Cons\<close>, ...} `$ x `$ xs) =
            (case dest_list_literal xs of
              SOME ys => SOME (x :: ys)
            | NONE => NONE)
      | dest_list_literal _ = NONE;

    fun pretty literals print_term thm vars fxy [(x, _), (xs, _)] =
      case dest_list_literal xs of
        SOME ys =>
          Code_Printer.literal_list literals
            (map (print_term vars NOBR) (x :: ys))
      | NONE =>
          Pretty.block [Pretty.str "[", print_term vars NOBR x, Pretty.str "] + ",
            print_term vars NOBR xs];
    
  in
    (fn target =>
      Code_Target.set_printings (Code_Symbol.Constant (\<^const_name>\<open>List.list.Cons\<close>,
        [(target, SOME (complex_const_syntax (2, pretty)))])))
    "Python"
  end
\<close>

(* Pairs *)
code_printing
    type_constructor Product_Type.prod \<rightharpoonup> (Python) "(_ * _)"
  | constant Product_Type.Pair \<rightharpoonup> (Python) "(_, _)"
  | constant fst \<rightharpoonup> (Python) "_[0]"
  | constant snd \<rightharpoonup> (Python) "_[1]"

end