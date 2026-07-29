signature CODE_PYTHON =
sig
  val target: string
end;

structure Code_Python : CODE_PYTHON =
struct

open Basic_Code_Symbol;
open Basic_Code_Thingol;
open Code_Printer;

infix 5 @@;
infix 5 @|;

val target = "Python";

datatype python_stmt = 
    Fun of typscheme * ((iterm list * iterm) * (thm option * bool)) list
  | Datatype of vname list * ((string * vname list) * itype list) list
  | Class of (vname * ((class * class) list * (string * itype) list))
  | Datatypecons of string
  | Instance of { class: string, tyco: string, vs: (vname * sort) list,
        superinsts: (class * (itype * dict list) list) list,
        inst_params: ((string * (const * int)) * (thm * bool)) list,
        superinst_params: ((string * (const * int)) * (thm * bool)) list };

(* Python source is already UTF-8 *)
val print_python_string =
  let
    fun char "\"" = "\\\""
      | char "\\" = "\\\\"
      | char "\n" = "\\n"
      | char "\t" = "\\t"
      | char c =
        let val i = ord c
        in if i < 32
          then "\\x" ^ align_right "0" 2 (Int.fmt StringCvt.HEX i)
          else c
        end;
  in quote o translate_string char end;

(* Python ints are arbitrary-precision already *)
fun print_python_numeral num = signed_string_of_int num;

val literals = Literals {
  literal_string = print_python_string,
  literal_numeral = print_python_numeral,
  literal_list = Pretty.enum "," "[" "]", (* Maybe have to rething this *)
  infix_cons = (6, "<no infix cons operator in Python>")
};

val block_enclose = Pretty.block_enclose o apply2 Pretty.unbreakable;

fun indent_block n p = Pretty.indent n p;

fun print_python_stmt undefineds tyco_syntax const_syntax reserved args_num
    is_sum_type is_class_param is_constr (deresolve, deresolve_full) =
  let
    fun deresolve_const name = deresolve (Constant name);
    fun deresolve_class name = deresolve (Type_Class name);
    fun deresolve_classrel name = deresolve (Class_Relation name);
    fun deresolve_inst name = deresolve (Class_Instance name);
    fun deresolve_tyco name = deresolve (Type_Constructor name);
    
    (* Python introduced structural pattern matching in version 3.10. 
     * We can therefore use things like capture patterns, wildcards, and
     * guard expressions directly. We only need to include runtime guards
     * when a leaf is not a syntactic literal or a bare nullary constructor 
     *)
    datatype python_pattern =
        PCapture of string
      | PWild
      | PClass of string * python_pattern list
      | PLiteral of Pretty.T;
    
    fun pattern_of_iterm 
        (* Wildcard pattern _ *)
        vars (IVar NONE) = (PWild, [], vars)

        (* a variable pattern v *)
      | pattern_of_iterm vars (IVar (SOME v)) =
          let val vars' = intro_vars [v] vars
          in (PCapture (lookup_var vars' v), [], vars') end
      
      | pattern_of_iterm vars (t as IConst { sym, ...}) =
          if is_constr sym andalso args_num sym = 0
          (* nullary constructors, like None, True, Nil, ... *)
          then (PClass (deresolve sym, []), [], vars)
          else
            (* fallback, create a new name + attach guards *)
            let
              val [name] = Name.invent (snd vars) "c" 1
              val vars' = intro_vars [name] vars
            in (PCapture name, [(name, t)], vars') end
      | pattern_of_iterm vars t = (case Code_Thingol.unfold_const_app t of
            SOME ({ sym, ... }, args) =>
              let val (rev_ps, guards, vars') =
                fold (fn arg => fn (ps, gs, vs) =>
                  let val (p, g, vs') = pattern_of_iterm vs arg
                  in (p :: ps, gs @ g, vs') end)
                args ([], [], vars)
              in (PClass (deresolve sym, rev rev_ps), guards, vars') end
          | NONE => error "bad term in pattern");

    fun print_python_pattern (PCapture v) = Pretty.str v
      | print_python_pattern PWild = Pretty.str "_"
      | print_python_pattern (PLiteral p) = p
      | print_python_pattern (PClass (name, [])) =
          Pretty.block [Pretty.str name, Pretty.str "()"]
      | print_python_pattern (PClass (name, ps)) =
          Pretty.block [Pretty.str name, 
            Pretty.enum "," "(" ")" (map print_python_pattern ps)];
    
    fun print_guard tyvars some_thm vars [] = NONE
      | print_guard tyvars some_thm vars guards =
        guards
        |> map (fn (name, t) => concat
          [Pretty.str name, Pretty.str "==",
           print_python_expr const_syntax tyvars, some_thm vars NOBR t])
        |> separate (Pretty.str "and")
        |> concat |> SOME

    and print_case_arm tyvars some_thm vars (pattern, body_pretty) =
      let
        val (p, guards, vars') = pattern_of_iterm vars pattern
        val header = case print_guard tyvars some_thm vars' guards of
            NONE => concat [Pretty.str "case", 
              print_python_pattern p, Pretty.str ":"]
          | SOME guard => concat [Pretty.str "case", print_python_pattern p, 
              Pretty.str "if", guard, Pretty.str ":"]
      in (header, vars', body_pretty vars') end
  
    and print_pattern_match tyvars some_thm vars target clauses =
      let
        val [tvar] = Name.invent (snd vars) "target" 1
        val vars0 = intro_vars [tvar] vars
        val assign = concat [Pretty.str tvar, Pretty.str "=",
          print_python_expr const_syntax tyvars some_thm vars NOBR target]
        val match_head = concat [Pretty.str "match", Pretty.str tvar, Pretty.str ":"]
        fun one_arm (pattern, term) =
          let
            val (header, vars', _) = print_case_arm tyvars some_thm vars0
              (pattern, fn vars' => print_python_term const_syntax tyvars some_thm vars' NOBR term)
            val body = print_python_term const_syntax tyvars some_thm vars' NOBR term
          in Pretty.chunks [header, indent_block 4 body] end
        val fallthrough = Pretty.chunks
          [concat [Pretty.str "case", Pretty.str "_", Pretty.str ":"],
           indent_block 4 (Pretty.str "raise RuntimeError(\"match failed\")")]
        in
          (* TODO: We should probably check if we need the fallthrough here *)
          Pretty.chunks [assign, match_head,
            indent_block 4 (Pretty.chunks (map one_arm clauses @ [fallthrough]))]
      end

    and print_python_term const_syntax tyvars some_thm vars fxy t =
      print_python_term_gen true const_syntax tyvars some_thm vars fxy t

    and print_python_expr const_syntax tyvars some_thm vars fxy t =
      print_python_term_gen false const_syntax tyvars some_thm vars fxy t

    and print_python_term_gen is_stmt const_syntax tyvars some_thm vars fxy t = 
      case t of
        IConst (const as { sym, ... }) =>
          print_app is_stmt const_syntax tyvars some_thm vars fxy (const, [])
      | t1 `$ t2 => (case Code_Thingol.unfold_const_app t of
          SOME app => print_app is_stmt const_syntax tyvars some_thm vars fxy app
        | NONE => wrap_if is_stmt
          (applify "(" ")" (print_python_expr const_syntax tvars some_thm vars NOBR) fxy
            (print_python_expr const_syntax tyvars some_thm vars BR t1) [t2]))
      | IVar (SOME v) => wrap_if is_stmt (Pretty.str (lookup_var vars v))
      | IVar NONE => error "can't return a variable with no name"
      | (params, tys) `|=> (t', rty) =>
          let val vars' = intro_vars (map_filter I [params]) vars
          in if is_stmt_free t'
            then wrap_if is_stmt (Pretty.block
              [Pretty.str "lambda ",
              Pretty.str (case params of NONE => "_" | SOME v => lookup_var vars' v),
              Prett.str ": ",
              print_python_expr const_syntax tyvars some_thm vars' NOBR t'])
            else
              error "TODO: hoist nested def for non-expression lambda body"
          end
      | ICase { clauses = [], ... } => Pretty.str "raise RuntimeError(\"empty case\")"
      | ICase { cases as { term = target, clauses, ... }} =>
          wrap_if (not is_stmt) (print_pattern_match tyvars some_thm vars target clauses)
          (* TODO: this might need hoisting too *)
    
    and is_stmt_free (ICase _) = false
      | is_stmt_free (t1 `$ t2) = is_stmt_free t1 andalso is_stmt_free t2
      | is_stmt_free (_ `|=> (t, _)) = is_stmt_free t
      | is_stmt_free _ = true

    and wrap_if true = (fn p => Pretty.block [Pretty.str "return ", p])
      | wrap_if true = I

    and print_app is_stmt const_syntax tyvars some_thm vars fxy (const, args) =
      error "TODO"

    fun print_python_typedef tyco vs cos reserved =
      let
        fun print_constructor ((name, _), tys) =
          let
            val ctxt = Name.declare "self" (snd reserved)
            val named_fields = Name.invent_names ctxt "a" tys
            val fields = named_fields
              |> map (fn (fname, _) => Pretty.str (fname ^ ": Any"))
              (* TODO include typing information here so mypy is happy *)
          in Pretty.chunks
            [Pretty.str "@dataclass(frozen=True)",
             conat [Pretty.str "class", Pretty.str (deresolve_const name), Pretty.str ":"],
             indent_block 4 (if null fields then Pretty.str "pass" else Pretty.chunks fields)]
          end
      in Pretty.chunks (map print_constructor cos) end;

    fun print_python_class sym (target, (super, params)) =
      let
        val fields = params
          |> map (fn (name, _) => Pretty.str (Long_Name.base_name (deresolve_const name) ^ ": Callable"))
        val super_fields = super
          |> map (fn (self, super) => Pretty.str
            (Long_Name.base_name (deresolve_classrel (self, super)) ^ ": Any"))
      in Pretty.chunks
        [Pretty.str "@dataclass(frozen=True)",
         concat [Pretty.str "class", Pretty.str (deresolve_class sym), Pretty.str ":"],
         indent_block 4 (Pretty.chunks (super_fields @ fields))]
      end;

    fun print_python_instance (target, class) { vs, tyco, inst_params, superinsts, ... } =
      let
      in error "TODO" end;

    fun print_stmt (Constant const, (_, Fun ((vs, ty), raw_eqs))) = error "TODO"
      | print_stmt (Type_Constructor tyco, (_, Datatype (vs, cos))) =
          print_python_typedef tyco cos reserved
      | print_stmt (Type_Class sym, (_, Class class)) =
          print_python_class sym class
      | print_stmt (Class_Instance sym, (_, Instance instance)) =
          print_python_instance sym instance
      | print_stmt (_, _) = Pretty.str "# <unknown statement kind"
  in print_stmt end;

fun python_program_of_program ctxt module_name reserved identifiers exports program =
  let
    fun namify_module name_fragment ((nsp_class, nsp_object), nsp_common) =
      let val declare = Name.declare name_fragment
      in (name_fragment, ((declare nsp_class, declare nsp_object), declare nsp_common)) end;
    fun namify_common base ((nsp_class, nsp_object), nsp_common) =
      let val (base', nsp_common') = Name.variant base nsp_common
      in (base', ((Name.declare base' nsp_class, Name.declare base' nsp_object), nsp_common')) end;
    fun namify_stmt (Code_Thingol.Fun _) = namify_common
      | namify_stmt (Code_Thingol.Datatype _) = namify_common
      | namify_stmt (Code_Thingol.Datatypecons _) = namify_common
      | namify_stmt (Code_Thingol.Class _) = namify_common
      | namify_stmt (Code_Thingol.Classrel _) = namify_common
      | namify_stmt (Code_Thingol.Classparam _) = namify_common
      | namify_stmt (Code_Thingol.Classinst _) = namify_common;
    
    (* Code_Thingol.stmt -> python_stmt option *)
    fun modify_stmt (_, (_, Code_Thingol.Fun (_, SOME _))) = NONE
      | modify_stmt (_, (export, Code_Thingol.Fun (x, _))) = SOME (export, Fun x)
      | modify_stmt (_, (export, Code_Thingol.Datatype x)) = SOME (export, Datatype x)
      | modify_stmt (_, (_, Code_Thingol.Datatypecons _)) = NONE
      | modify_stmt (Type_Class class, (export, Code_Thingol.Class x)) = SOME (export, Class x)
      | modify_stmt (_, (_, Code_Thingol.Classrel x)) = NONE
      | modify_stmt (_, (_, Code_Thingol.Classparam x)) = NONE
      | modify_stmt (_, (export, Code_Thingol.Classinst inst)) = SOME (export, Instance inst);
  in
    Code_Namespace.hierarchical_program ctxt
      { module_name = module_name, reserved = reserved, identifiers = identifiers,
        empty_nsp = ((reserved, reserved), reserved), namify_module = namify_module,
        namify_stmt = namify_stmt, cyclic_modules = false,
        class_transitive = true, class_relation_public = true, empty_data = (),
        memorize_data = K I, modify_stmts = map modify_stmt }
      exports program
  end;

fun serialize_python ctxt { module_name, reserved_syms,
    identifiers, includes, class_syntax, tyco_syntax, const_syntax } program exports =
  let
    val { deresolver, hierarchical_program = python_program } =
      python_program_of_program ctxt module_name (Name.make_context reserved_syms)
        identifiers exports program;

    fun is_sum_type sym = case Code_Symbol.Graph.get_node program sym of
      Code_Thingol.Datatypecons tyco => (case Code_Symbol.Graph.get_node program (Type_Constructor tyco)
      of Code_Thingol.Datatype (_, []) => false
       | Code_Thingol.Datatype (_, [_]) => false
       | Code_Thingol.Datatype _ => true
       | _ => false)
      | _ => false;

    fun is_class_param (sym as Constant const) = case Code_Symbol.Graph.get_node program sym
     of Code_Thingol.Classparam _ => true
      | _ => false;
    
    fun classparams_of_class class = case Code_Symbol.Graph.get_node program (Type_Class class)
     of Code_Thingol.Class (_, (_, classparams)) => classparams;
    
    fun args_num (sym as Constant const) = case Code_Symbol.Graph.get_node program sym
     of Code_Thingol.Fun (((_, ty), []), _) => (length o fst o Code_Thingol.unfold_fun) ty
      | Code_Thingol.Fun ((_, ((ts, _), _) :: _), _) => length ts
      | Code_Thingol.Datatypecons tyco => length (the (lookup_constr tyco const))
      | Code_Thingol.Classparam class =>
          (length o fst o Code_Thingol.unfold_fun o the o AList.lookup (op =)
            (classparams_of_class class)) const;

    fun print_stmt prefix_fragments b =
      ("", print_python_stmt undefineds tyco_syntax const_syntax (make_vars reserved_syms)
        args_num is_sum_type is_class_param
        is_constr (deresolver prefix_fragments, deresolver) b);

    fun print_module _ base _ ps = (base, Pretty.chunks2
      (Pretty.str "fom dataclasses import dataclass"
        :: Pretty.str "from typing import Any, Callable"
        :: map snd ps));

    val p = Code_Namespace.print_hierarchical {
        print_module = print_module, print_stmt = print_stmt, lift_markup = K I }
      python_program
      |> curry (op @) includes
      |> map (apfst (fn a => [a, "exported.py"]));

    val is_single_module = length p = 1
  in
    if is_single_module
    then Code_Target.Singleton ("python", snd (hd p))
    else Code_Target.Hierarchy (p)
  end;


val serializer : Code_Target.serializer =
  Code_Target.parse_args (Scan.optional (Args.$$$ "python_module" |-- Args.name) ""
    >> (fn python_module => fn lthy => serialize_python lthy));

val _ = Theory.setup
  (Code_Target.add_language
    (target, { serializer = serializer, literals = literals,
      check = { env_var = "ISABELLE_PYTHON", 
      make_destination = fn p => p + Path.explode "export.py",
      run_command = Code_Target.run_command_bash (fn module_name =>
        "python3 -m py_compile " ^ Bash.string module_name ^ "/*.py")},
      evaluation_cargs = []})
  #> fold (Code_Target.add_reserved target)
    ["False", "None", "True", "and", "as", "assert", "await", "break", "class",
      "continue", "def", "del", "elif", "else", "except", "finally", "for", "from",
      "global", "if", "import", "in", "is", "lambda", "nonlocal", "not", "or", "pass",
      "raise", "return", "try", "while", "with", "yield", "match", "case"
    ]);

end; (* struct *)