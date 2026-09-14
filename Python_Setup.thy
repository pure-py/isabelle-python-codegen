theory Python_Setup
    imports Python "HOL-Library.Code_Target_Int" "HOL-Library.Code_Target_Nat"
begin

code_identifier
  code_module Code_Target_Nat \<rightharpoonup> (Python) Arith
| code_module Code_Target_Int \<rightharpoonup> (Python) Arith

(* Integers *)
code_printing
    type_constructor Int.int \<rightharpoonup> (Python) "int"
  | constant "0 :: int" \<rightharpoonup> (Python) "0"
  | constant "1 :: int" \<rightharpoonup> (Python) "1"
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

(* Bridge between int and integer *)
code_printing
    constant Code_Numeral.int_of_integer \<rightharpoonup> (Python) "_"
  | constant Code_Numeral.integer_of_int \<rightharpoonup> (Python) "_"

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

code_printing
    constant Code_Numeral.nat_of_integer \<rightharpoonup> (Python) "_"
  | constant Code_Numeral.integer_of_nat \<rightharpoonup> (Python) "_"

setup \<open>
  Numeral.add_code \<^const_name>\<open>Num.nat_of_num\<close> I Code_Printer.literal_numeral "Python"
\<close>

code_printing
  constant Code_Target_Nat.Nat \<rightharpoonup> (Python) "_"

setup \<open>
  Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Code_Target_Nat.Nat\<close>
\<close>

(* Code_Numeral: integer/natural (target-language numerals) *)
code_printing
    type_constructor Code_Numeral.integer \<rightharpoonup> (Python) "int"
  | constant "0 :: Code_Numeral.integer" \<rightharpoonup> (Python) "0"
  | constant "1 :: Code_Numeral.integer" \<rightharpoonup> (Python) "1"
  | constant "(+) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ + _)"
  | constant "(-) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ - _)"
  | constant "uminus :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(- _)"
  | constant "(*) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ * _)"
  | constant "(div) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ '/'/ _)"
  | constant "(mod) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ % _)"
  | constant Code_Numeral.divmod_abs \<rightharpoonup> (Python) "divmod(_, _)"
  | constant "HOL.equal :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ == _)"
  | constant "(\<le>) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ <= _)"
  | constant "(<) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ < _)"
  | constant "abs :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "abs'(_')"

unbundle bit_operations_syntax

code_printing
    constant Code_Numeral.dup \<rightharpoonup> (Python) "(2 * _)"
  | constant "(AND) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ & _)"
  | constant "(OR) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ | _)"
  | constant "(XOR) :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(_ ^ _)"
  | constant "NOT :: Code_Numeral.integer \<Rightarrow> Code_Numeral.integer" \<rightharpoonup> (Python) "(~ _)"

unbundle no bit_operations_syntax

setup \<open>
  (fn target =>
    Numeral.add_code \<^const_name>\<open>Code_Numeral.Pos\<close> I
      Code_Printer.literal_numeral target
    #> Numeral.add_code \<^const_name>\<open>Code_Numeral.Neg\<close> (~)
      Code_Printer.literal_numeral target)
    "Python"
\<close>

code_printing
    type_constructor Code_Numeral.natural \<rightharpoonup> (Python) "int"
  | constant "0 :: Code_Numeral.natural" \<rightharpoonup> (Python) "0"
  | constant "1 :: Code_Numeral.natural" \<rightharpoonup> (Python) "1"
  | constant "(+) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> Code_Numeral.natural" \<rightharpoonup> (Python) "(_ + _)"
  | constant "(-) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> Code_Numeral.natural" \<rightharpoonup> (Python) "max(0, _ - _)"
  | constant "(*) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> Code_Numeral.natural" \<rightharpoonup> (Python) "(_ * _)"
  | constant "(div) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> Code_Numeral.natural" \<rightharpoonup> (Python) "(_ '/'/ _)"
  | constant "(mod) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> Code_Numeral.natural" \<rightharpoonup> (Python) "(_ % _)"
  | constant "HOL.equal :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ == _)"
  | constant "(\<le>) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ <= _)"
  | constant "(<) :: Code_Numeral.natural \<Rightarrow> Code_Numeral.natural \<Rightarrow> bool" \<rightharpoonup> (Python) "(_ < _)"
  | constant Code_Numeral.natural_of_integer \<rightharpoonup> (Python) "max(0, _)"

code_printing
  constant Code_Numeral.Nat \<rightharpoonup> (Python) "_"

setup \<open>
  Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Code_Numeral.Nat\<close>
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

setup \<open> Code_Python.enable_native_encoding "list" \<close>

(* Pairs *)
code_printing
    type_constructor Product_Type.prod \<rightharpoonup> (Python) "(_ * _)"
  | constant Product_Type.Pair \<rightharpoonup> (Python) "(_, _)"
  | constant fst \<rightharpoonup> (Python) "_[0]"
  | constant snd \<rightharpoonup> (Python) "_[1]"

setup \<open> Code_Python.enable_native_encoding "pair" \<close>

setup \<open>
  Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Code_Numeral.int_of_integer\<close>
  #> Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Code_Numeral.integer_of_int\<close>
  #> Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Code_Numeral.nat_of_integer\<close>
  #> Code_Python.add_transparent_wrapper_sym \<^const_name>\<open>Code_Numeral.integer_of_nat\<close>
\<close>

setup \<open>
  Code_Python.add_undefined_sym \<^const_name>\<open>Code_Numeral.sub\<close>
  #> Code_Python.add_undefined_sym \<^const_name>\<open>Bit_Operations.and_not_num\<close>
  #> Code_Python.add_undefined_sym \<^const_name>\<open>Bit_Operations.or_not_num_neg\<close>
  #> Code_Python.add_undefined_sym \<^const_name>\<open>Code_Target_Nat.natural\<close>
\<close>

end