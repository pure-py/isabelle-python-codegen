signature CODE_PYTHON =
sig
  val target: string
  val add_transparent_wrapper_sym: string -> theory -> theory
  val add_undefined_sym: string -> theory -> theory
  val enable_native_encoding: string -> theory -> theory
  val print_python_string: string -> string
  val tail_calls: bool Config.T
end;

structure Code_Python : CODE_PYTHON =
struct

open Basic_Code_Symbol;
open Basic_Code_Thingol;
open Code_Printer;

val target = "Python";

(* Print self tail calls as loops (see print_python_func). Off by default; set it with
   `declare [[python_tail_calls]]` in a theory, or `isabelle build -o python_tail_calls`.
   The system option is declared in etc/options, which Isabelle only reads for a registered
   component; with just `isabelle build -d .` (as in CI) it is unknown, so fall back to a plain
   configuration option, which `declare` can still set. *)
val tail_calls =
  if can Options.default_typ "python_tail_calls"
  then Attrib.setup_option_bool ("python_tail_calls", \<^here>)
  else Attrib.setup_config_bool \<^binding>\<open>python_tail_calls\<close> (K false);

structure Transparent_Wrapper_Data = Theory_Data
(
  type T = unit Symtab.table
  val empty = Symtab.empty
  val merge = Symtab.merge (K true)
);

fun add_transparent_wrapper_sym name = Transparent_Wrapper_Data.map (Symtab.update (name, ()));

fun is_transparent_wrapper_sym thy (Constant name) =
      Symtab.defined (Transparent_Wrapper_Data.get thy) name
  | is_transparent_wrapper_sym _ _ = false;

fun strip_transparent_wrappers thy t =
  case Code_Thingol.unfold_const_app t of
    SOME ({ sym, ... }, [arg]) =>
      if is_transparent_wrapper_sym thy sym
      then strip_transparent_wrappers thy arg
      else t
  | _ => t

structure Undefined_Data = Theory_Data
(
  type T = unit Symtab.table
  val empty = Symtab.empty
  val merge = Symtab.merge (K true)
);

fun add_undefined_sym name = Undefined_Data.map (Symtab.update (name, ()));

structure Native_Encoding_Data = Theory_Data
(
  type T = unit Symtab.table
  val empty = Symtab.empty
  val merge = Symtab.merge (K true)
);

fun enable_native_encoding name = Native_Encoding_Data.map (Symtab.update (name, ()));

fun use_native_encoding thy name = Symtab.defined (Native_Encoding_Data.get thy) name;

(* Names bound by the prelude of every generated module: its imports and the abort function *)
val prelude_names = ["dataclass", "Any", "Callable", "functools", "_abort"];

(* Keywords and builtins of the target Python, except the wildcard _ printed by the generator; generated names
   must not hide these. *)
fun python_names thy =
  let
    val version = trim_line (File.read (Resources.master_directory thy + Path.basic ".python-version"));
    val (out, rc) = Isabelle_System.bash_output ("uv run -q --no-project --python " ^ Bash.string version ^
      " python -c 'import builtins, keyword; " ^
      "print(*keyword.kwlist, *(k for k in keyword.softkwlist if k != \"_\"), *dir(builtins))'");
  in if rc = 0 then space_explode " " (trim_line out) else error ("No names of Python " ^ version) end;

type eqtn = { 
  patterns: iterm list,       (* left hand side pattern list *)
  rhs: iterm,                 (* rhs expr *)
  thm: thm option             (* original theorem, only used for error printing *)
}

type cnstr = {
  name: string,               (* name of the constructor *)
  typarams: vname list,       (* type parameters *)
  arg_tys: itype list         (* types of the constructor arguments *)
} 

type superinst = class * (itype * dict list) list
type inst_param = (string * (const * int)) * (thm * bool)

(* In the spirit of some of the other code generator backends we define our own
 * datatype of python stmts, which is a subset of the the stmts defined
 * in Thingol (built by `python_stmt_of_thingol`).
 *)
datatype python_stmt =
    (* A function (or value definition, if it has no arguments) *)
    Fun of { 
      vs: (vname * sort) list,  (* tyvars, sort constraints *)
      ty: itype,                (* type of the function *)
      eqs: eqtn list            (* code equations, see above *)
    }

    (* A datatype definition (turns into one `@dataclass` per constructor) *)
  | Datatype of { 
      typarams: vname list,     (* type parameter names *)
      cnstrs: cnstr list        (* constructor list, see above *)
    } 

    (* A typeclass definition (turns into a `@dataclass with one Callable
       field per method, and one field per direct superclass) *)
  | Class of { 
      super: (class * class) list,    (* super classes *)
      methods: (string * itype) list  (* class methods *)
    }

    (* A typeclass instance definition *)
  | Instance of { 
      tyco: string,                 (* type constructor this instance is for *)
      vs: (vname * sort) list,      (* type params + sort constraints *)
      superinsts: superinst list,   (* superclass instances this instance provides *)
      inst_params: inst_param list  (* method implementations *)
    };

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
  literal_list = Pretty.enum "," "[" "]",
  infix_cons = (6, "+")
};

fun indent_block n p = Pretty.indent n p;

fun invent_name vars prefix = 
  let 
    val name = Name.invent (snd vars) prefix 1 |> hd
    val vars' = intro_vars [name] vars
  in (name, vars') end

fun invent_names vars prefix n =
  let
    val names = Name.invent (snd vars) prefix n
    val vars' = intro_vars names vars
  in (names, vars') end

(*
 * arguments:
 *   undefineds: intentionally unimplemented symbols, turn into `_abort(...)`
 *   const_syntax: custom registered code_printing declarations for constants
 *   reserved: context of names that are not useable as new names
 *   args_num: how many arguments needed by the current stmt for saturation
 *   is_class_param: true if the current symbol is a type-class method
 *   is_constr: true for a datatype constructor without a printing
 *   ctxt: thoery context (neede to look up record field names)
 *   deresolve: module relative naming resolver
 *)
fun print_python_stmt undefineds const_syntax reserved args_num
    is_class_param is_value is_constr ctxt deresolve =
  let
    fun deresolve_const name = deresolve (Constant name);
    fun deresolve_class name = deresolve (Type_Class name);
    fun deresolve_inst name = deresolve (Class_Instance name);

    (* Attribute name of a class dataclass field (method or superclass).
       Declaration, construction and projection must all use this, as
       deresolve may rename (`equal` -> `equala`) or module-qualify. *)
    fun attr_name sym = Long_Name.base_name (deresolve sym);

    (* Abort for a constant without code, named by its full name *)
    fun print_abort const =
      Pretty.block [Pretty.str "_abort(", Pretty.str (print_python_string const), Pretty.str ", None)"];

    (* extract the theory from the context *)
    val thy = Proof_Context.theory_of ctxt
    
    (* Python introduced structural pattern matching in version 3.10. 
     * We can therefore use things like capture patterns, wildcards, and
     * guard expressions directly. We only need to include runtime guards
     * when a leaf is not a syntactic literal or a bare nullary constructor 
     *)
    datatype python_pattern =
        PCapture of string
      | PWild
      | PClass of string * python_pattern list
      | PTuple of python_pattern list
      | PLiteral of Pretty.T
      | PList of python_pattern list * string option;

    datatype python_guard = GEq of string * iterm | GRaw of Pretty.T;

    (* A "preamble" entry is a statement that needs to run before the
       expression that depends on it *)
    (* A branch of a short-circuiting connective: a term, or a fixed truth value *)
    datatype python_branch = BTerm of iterm | BBool of bool;

    datatype python_preamble = PBind of string * iterm | PRaw of Pretty.T
      (* `x = (cond ? then : else)`, printed as an if statement so that only the
         branch that is taken gets evaluated *)
      | PIf of string * iterm * python_branch * python_branch;

    val fallthrough_arm = Pretty.chunks
      [Pretty.block [Pretty.str "case ", Pretty.str "_", Pretty.str ":"],
      indent_block 4 (Pretty.str "raise RuntimeError(\"match failed\")")];

    (* Peel consecutive Cons layers of term *)
    fun dest_cons_chain t =
      case Code_Thingol.unfold_const_app t of
        SOME ({ sym = Constant "List.list.Cons", ... }, [x, xs]) =>
          let val (es, tail) = dest_cons_chain xs
          in (x :: es, tail) end
      | _ => ([], t);

    (* Arity of a constant, or of its printing if it has one *)
    fun const_arity (sym as Constant c) = (case const_syntax c of SOME (k, _) => k | NONE => args_num sym)
      | const_arity _ = raise Fail "should never be reached";
    
    (* Create patterns from iterms *)
    fun pattern_of_iterm vars (IVar NONE) = (PWild, [], [], vars)
      | pattern_of_iterm vars (IVar (SOME v)) =
          let val vars' = intro_vars [v] vars
          in (PCapture (lookup_var vars' v), [], [], vars') end
      | pattern_of_iterm vars (t as IConst { sym, ...}) =
          if sym = Constant "List.list.Nil" andalso use_native_encoding 
            thy "list"
          then (PLiteral (Pretty.str "[]"), [], [], vars)
          else if is_constr sym andalso args_num sym = 0
          then (PClass (deresolve sym, []), [], [], vars)
          else
            (* fallback, create a new name + attach guards *)
            let val (name, vars') = invent_name vars "c"
            in (PCapture name, [GEq (name, t)], [], vars') end
      | pattern_of_iterm vars t =
        (case Code_Thingol.unfold_const_app t of
            SOME ({ sym, ... }, args) =>
              if sym = Constant "List.list.Cons" andalso length args = 2
                andalso use_native_encoding thy "list"
              then
                let
                  val (elems, tail) = dest_cons_chain t;
                  val (ps, guards, preamble, vars') = pattern_of_iterms vars elems;
                in
                  case tail of
                    IConst { sym = Constant "List.list.Nil", ... } =>
                      (PList (ps, NONE), guards, preamble, vars')
                  | IVar (SOME v) =>
                      let val vars'' = intro_vars [v] vars'
                      in (PList (ps, SOME (lookup_var vars'' v)), guards, preamble, vars'') end
                  | IVar NONE => (PList (ps, SOME "_"), guards, preamble, vars')
                  | _ => error "unsupported tail of list Cons-chain pattern"
                end
              else if sym = Constant "IArray.iarray.IArray" andalso length args = 1
                andalso use_native_encoding thy "iarray"
              then
                (* an iarray is a tuple: [*xs] matches it and binds xs to a list *)
                (case hd args of
                  IVar (SOME v) =>
                    let val vars' = intro_vars [v] vars
                    in (PList ([], SOME (lookup_var vars' v)), [], [], vars') end
                | IVar NONE => (PWild, [], [], vars)
                | xs => pattern_of_iterm vars xs)
              else if sym = Constant "Product_Type.Pair" andalso use_native_encoding
                thy "pair"
              then
                let val (ps, guards, preamble, vars') = pattern_of_iterms vars args
                in (PTuple ps, guards, preamble, vars') end
              else if is_transparent_wrapper_sym thy sym 
                andalso length args = 1
              then pattern_of_iterm vars (hd args)
              else if can deresolve sym
              then
                let val (ps, guards, preamble, vars') = pattern_of_iterms vars args
                in (PClass (deresolve sym, ps), guards, preamble, vars') end
              else
                (* sym has no name in our namespace -- e.g. pruned because
                   it has custom Python code_printing syntax *)
                let val (name, vars') = invent_name vars "c"
                in (PCapture name, [GEq (name, t)], [], vars') end
          | NONE => error "bad term in pattern")

    and pattern_of_iterms vars ts =
      let
        val (rev_ps, guards, preamble, vars') =
          fold (fn t => fn (ps, gs, pre, vs) =>
            let val (p, g, pr, vs') = pattern_of_iterm vs t
            in (p :: ps, gs @ g, pre @ pr, vs') end)
          ts ([], [], [], vars)
      in (rev rev_ps, guards, preamble, vars') end;

    fun is_sole_constr (Constant const) =
          (case Code.get_type_of_constr_or_abstr thy const of
            SOME (tyco, false) =>
              let val ((_, constrs), _) = Code.get_type thy tyco
              in length constrs = 1 end
          | _ => false)
      | is_sole_constr _ = false

    fun exhaustive (IVar _) = true
      | exhaustive (IConst { sym, ... }) =
          is_constr sym andalso args_num sym = 0 andalso is_sole_constr sym
      | exhaustive t =
          (case Code_Thingol.unfold_const_app t of
            SOME ({ sym, ... }, args) =>
              if is_transparent_wrapper_sym thy sym 
                andalso length args = 1
              then exhaustive (hd args)
              else is_sole_constr sym andalso forall exhaustive args
          | NONE => false)

    fun is_trivial_pattern _ t = exhaustive t

    fun print_python_pattern (PCapture v) = Pretty.str v
      | print_python_pattern PWild = Pretty.str "_"
      | print_python_pattern (PLiteral p) = p
      | print_python_pattern (PTuple ps) =
          Pretty.enum "," "(" ")" (map print_python_pattern ps)
      | print_python_pattern (PClass (name, ps)) =
          Pretty.block [Pretty.str name, 
            Pretty.enum "," "(" ")" (map print_python_pattern ps)]
      | print_python_pattern (PList (ps, NONE)) =
          Pretty.enum "," "[" "]" (map print_python_pattern ps)
      | print_python_pattern (PList (ps, SOME rest)) =
          Pretty.enum "," "[" "]" (map print_python_pattern ps @ [Pretty.str ("*" ^ rest)]);
    
    fun print_guard _ _ [] = NONE
      | print_guard some_thm vars guards =
        guards
        |> map (fn GEq (name, t) => concat
                  [Pretty.str name, Pretty.str "==",
                  print_python_expr const_syntax some_thm vars NOBR t]
                | GRaw p => p)
        |> separate (Pretty.str "and")
        |> concat |> SOME

    and print_case_header some_thm vars pattern_pretty guards =
      case print_guard some_thm vars guards of
          NONE => Pretty.block [concat [Pretty.str "case", pattern_pretty], Pretty.str ":"]
        | SOME guard => Pretty.block [concat [Pretty.str "case", pattern_pretty],
            Pretty.str " if (", guard, Pretty.str "):"]

    and print_case_arm some_thm vars (pattern, body_pretty) =
      let
        val (p, guards, preamble, vars') = pattern_of_iterm vars pattern
        val header = print_case_header some_thm vars' (print_python_pattern p) guards
        val body = Pretty.chunks (preamble @ [body_pretty vars'])
      in (header, vars', body) end
  
    (* The connectives are printed as Python's short-circuiting `and`/`or`, so the
       right operand is only evaluated when the left one does not decide the result.
       Hoisting statements out of the right operand would evaluate them
       unconditionally; such a connective is turned into an if statement instead. *)
    and short_circuit t =
      case Code_Thingol.unfold_const_app t of
        SOME ({ sym = Constant c, ... }, [a, b]) =>
          if is_stmt_free b then NONE
          else (case c of
              "HOL.conj" => SOME (a, BTerm b, BBool false)
            | "HOL.disj" => SOME (a, BBool true, BTerm b)
            | "HOL.implies" => SOME (a, BTerm b, BBool true)
            | _ => NONE)
      | _ => NONE

    and anf_term vars (t as IConst _) = ([], vars, t)
      | anf_term vars (t as IVar _) = ([], vars, t)
      | anf_term vars (t as t1 `$ t2) =
          (case short_circuit t of
            SOME (cond, t_branch, e_branch) =>
              let
                val (bc, vars1, cond') = anf_term vars cond;
                val (x, vars2) = invent_name vars1 "x";
              in (bc @ [PIf (x, cond', t_branch, e_branch)], vars2, IVar (SOME x)) end
          | NONE =>
              let
                val (b1, vars1, t1') = anf_term vars t1;
                val (b2, vars2, t2') = anf_term vars1 t2;
              in (b1 @ b2, vars2, t1' `$ t2') end)
      | anf_term vars (t as (_, _) `|=> (_, _)) =
          if is_stmt_free t
          then ([], vars, t)
          else
            let
              fun strip_lambdas vs ((param, _) `|=> (body, _)) =
                    let
                      val vs' = intro_vars (map_filter I [param]) vs
                      val (ps, vs'', body') = strip_lambdas vs' body
                    in (param :: ps, vs'', body') end
                | strip_lambdas vs body = ([], vs, body)
              val (params, vars1, body) = strip_lambdas vars t
              val (param_prettys, vars2) = fold_map
                (fn NONE => (fn vs => let val (n, vs') = invent_name vs "unused"
                      in (Pretty.str n, vs') end)
                  | SOME v => (fn vs => (Pretty.str (lookup_var vs v), vs)))
                params vars1
              (* Function values are applied one argument at a time (f(x)(y)), so a
                 multi-parameter lambda becomes nested one-parameter defs. *)
              fun def_head vs fname param =
                Pretty.block [Pretty.str "def ", Pretty.str (lookup_var vs fname),
                  Pretty.str "(", param, Pretty.str "):"]
              fun curried_defs vs [param] =
                    let
                      val (fname, vs') = invent_name vs "lam"
                      val body_pretty = print_tail_expr NONE
                        (fn vars' => fn t' => Pretty.block [Pretty.str "return (",
                          print_python_expr const_syntax NONE vars' NOBR t', Pretty.str ")"])
                        vs' body
                    in (Pretty.chunks [def_head vs' fname param, indent_block 4 body_pretty],
                      fname, vs') end
                | curried_defs vs (param :: params') =
                    let
                      val (fname, vs1) = invent_name vs "lam"
                      val (inner, inner_name, vs2) = curried_defs vs1 params'
                      val inner_block = Pretty.chunks [inner,
                        Pretty.str ("return " ^ lookup_var vs2 inner_name)]
                    in (Pretty.chunks [def_head vs2 fname param, indent_block 4 inner_block],
                      fname, vs2) end
                | curried_defs _ [] = error "internal error: hoisted lambda without parameters"
              val (def_stmt, fname, vars3) = curried_defs vars2 param_prettys
              (* the lambda's parameters are local to the def: keep the outer
                 bindings (only adding the def's name), but keep all names
                 reserved so later fresh names cannot clash *)
              val vars4 = (Symtab.update (fname, lookup_var vars3 fname) (fst vars), snd vars3)
              in ([PRaw def_stmt], vars4, IVar (SOME fname)) end
      | anf_term vars (t as ICase _) =
          let val (x, vars') = invent_name vars "x"
          in ([PBind (x, t)], vars', IVar (SOME x)) end

    and print_if_then_else some_thm finish vars target t_branch e_branch =
      let
        val (target_bindings, vars1, target') = anf_term vars target;
        val cond = print_python_expr const_syntax some_thm vars1 NOBR target';
      in
        Pretty.chunks (map (print_preamble some_thm vars1) target_bindings @
          [Pretty.block [Pretty.str "if (", cond, Pretty.str "):"],
          indent_block 4 (print_tail_expr some_thm finish vars1 t_branch),
          Pretty.str "else:",
          indent_block 4 (print_tail_expr some_thm finish vars1 e_branch)])
      end

    and get_if_then_else [(p1, t1), (p2, t2)] =
          let
            fun is_true (IConst { sym = Constant "HOL.True", ... }) = true
              | is_true _ = false;
            fun is_false (IConst { sym = Constant "HOL.False", ... }) = true
              | is_false _ = false;
          in
            if is_true p1 andalso is_false p2 then SOME (t1, t2)
            else if is_false p1 andalso is_true p2 then SOME (t2, t1)
            else NONE
          end
      | get_if_then_else _ = NONE

    and print_tail_expr some_thm finish vars (ICase { term = target, clauses, ... }) =
        (case get_if_then_else clauses of
          SOME (t_branch, e_branch) => print_if_then_else some_thm finish vars target t_branch e_branch
        | NONE => print_case_block some_thm finish vars target clauses)
      | print_tail_expr some_thm finish vars t =
          let val (bindings, vars', t') = anf_term vars t
          in Pretty.chunks (map (print_preamble some_thm vars') bindings @ [finish vars' t']) end

    and print_binding some_thm vars (name, t) =
      print_tail_expr some_thm
        (fn vars' => fn t' => Pretty.block [Pretty.str name, Pretty.str " = (",
          print_python_expr const_syntax some_thm vars' NOBR t', Pretty.str ")"])
        vars t

    and print_preamble some_thm vars (PBind (name, t)) = print_binding some_thm vars (name, t)
      | print_preamble _ _ (PRaw p) = p
      | print_preamble some_thm vars (PIf (name, cond, t_branch, e_branch)) =
          let
            fun branch (BTerm t) = print_binding some_thm vars (name, t)
              | branch (BBool b) =
                  Pretty.str (name ^ " = (" ^ (if b then "True" else "False") ^ ")")
          in
            Pretty.chunks [
              Pretty.block [Pretty.str "if (",
                print_python_expr const_syntax some_thm vars NOBR cond, Pretty.str "):"],
              indent_block 4 (branch t_branch),
              Pretty.str "else:",
              indent_block 4 (branch e_branch)]
          end

    and print_case_block some_thm finish vars target clauses =
      let
        val (target_bindings, vars1, target') = anf_term vars target;
        val (tvar, vars0) = invent_name vars1 "target"
        val assign = Pretty.block [Pretty.str tvar, Pretty.str " = (",
          print_python_expr const_syntax some_thm vars1 NOBR target', Pretty.str ")"];
        val match_head = Pretty.block [Pretty.str "match ", Pretty.str tvar, Pretty.str ":"];
        fun one_arm (pattern, term) =
          let
            val (header, _, body) = print_case_arm some_thm vars0
              (pattern, fn vars' => print_tail_expr some_thm finish vars' term)
          in Pretty.chunks [header, indent_block 4 body] end;
        (* A clause list already ending in a bare-variable (or wildcard)
           pattern is exhaustive on its own *)
        val last_clause_pattern = case rev clauses of (p, _) :: _ => SOME p | [] => NONE
        val already_exhaustive = case last_clause_pattern of
            SOME p => is_trivial_pattern vars0 p
          | NONE => false
        val arms = map one_arm clauses @ (if already_exhaustive then [] else [fallthrough_arm])
      in
        Pretty.chunks (map (print_preamble some_thm vars1) target_bindings @
          [assign, match_head, indent_block 4 (Pretty.chunks arms)])
      end

    and print_python_expr const_syntax some_thm vars fxy t =
      case t of
        (* bare reference to name constant *)
        IConst (const as { ... }) =>
          print_app const_syntax some_thm vars fxy (const, [])
        (* function application *)
      | t1 `$ t2 => (case Code_Thingol.unfold_const_app t of
          (* is this an actual function appliction with a named function? *)
          SOME app => print_app const_syntax some_thm vars fxy app
          (* If not, then this might be a lambda application or similar *)
        | NONE =>
          applify "(" ")" (print_python_expr const_syntax some_thm vars NOBR) fxy
            (print_python_expr const_syntax some_thm vars BR t1) [t2])
      | IVar (SOME v) => Pretty.str (lookup_var vars v)
      | IVar NONE => error "can't return a variable with no name"
      | (params, _) `|=> (t', _) =>
          let val vars' = intro_vars (map_filter I [params]) vars
          in if is_stmt_free t'
            then Pretty.block
              [Pretty.str "lambda ",
              Pretty.str (case params of NONE => "_" | SOME v => lookup_var vars' v),
              Pretty.str ": ",
              print_python_expr const_syntax some_thm vars' NOBR t']
            else
              error "internal error: non-expression lambda, anf_term should have hoisted it"
          end
      | ICase { clauses = [], ... } => Pretty.str "raise RuntimeError(\"empty case\")"
      | ICase _ =>
          error "internal error: ICase reached in expression position -- anf_term should have extracted it"

    (* For things like lambdas we need to decide if the body is an expression *)
    and is_stmt_free (ICase _) = false
      | is_stmt_free (t1 `$ t2) = is_stmt_free t1 andalso is_stmt_free t2
      | is_stmt_free (_ `|=> (t, _)) = is_stmt_free t
      | is_stmt_free _ = true

    and print_dict some_thm vars _ (Dict (classrels, plain_dict)) =
      fold (fn classrel => fn p =>
        Pretty.block [p, Pretty.str".", Pretty.str (attr_name (Class_Relation classrel))])
      (rev classrels) (* need to go from source dict inwards *)
      (print_plain_dict some_thm vars plain_dict)
    
    and print_plain_dict some_thm vars (Dict_Const (inst, dictss)) =
          gen_applify true "(" ")" I NOBR
            ((Pretty.str o deresolve) (Class_Instance inst))
            (map_filter (print_dicts some_thm vars BR o snd) dictss)
      | print_plain_dict _ _ (Dict_Var { var, index, length, ... }) =
          if length = 1
          then Pretty.str (var ^ "_dict")
          else Pretty.str (var ^ "_dict[" ^ string_of_int index ^ "]")

    and print_dicts some_thm vars = tuplify (print_dict some_thm vars)

    and print_app_expr const_syntax some_thm vars (app as ({ sym, dictss, ...}, ts)) =
      let
        val l = args_num sym
        fun call_with head_pretty extra_dicts =
          let
            val (immediate, curried) = chop l ts
            val immediate_pretty =
              map (print_python_expr const_syntax some_thm vars BR) immediate
            val curried_pretty =
              map (fn t => Pretty.enclose "(" ")"
                [print_python_expr const_syntax some_thm vars NOBR t]) curried
            val call = gen_applify true "(" ")" I NOBR head_pretty (extra_dicts @ immediate_pretty)
          in call :: curried_pretty end
      in
      if length ts < l
      then
        (* A unary constant is printed by name, since the corresponding Python function already takes
           one argument. A constant of higher arity is eta-expanded, since the corresponding Python
           function is uncurried but function values are applied one argument at a time. *)
        if null ts andalso forall null dictss andalso l = 1
        then [(Pretty.str o deresolve) sym]
        else [print_python_expr const_syntax some_thm vars BR
                (Code_Thingol.saturated_application l app)]
      else if is_class_param sym andalso not (null dictss)
      then
        let
          val self_dict_pretty = print_dict some_thm vars NOBR (hd (hd dictss))
          val extra_dict_pretty = map_filter (print_dicts some_thm vars BR) (tl dictss)
          val head_pretty = Pretty.block [self_dict_pretty, Pretty.str ".",
            Pretty.str (attr_name sym)]
        in call_with head_pretty extra_dict_pretty end
      else if is_value sym andalso forall null dictss andalso null ts
      then [(Pretty.str o deresolve) sym]
      else
        let
          (* constructors take no dictionaries (as in SML), even when the type has sort
             constraints, e.g. the abstype morphism vec_lambda of ('a, 'b::finite) vec *)
          val dict_pretty = if is_constr sym then []
            else map_filter (print_dicts some_thm vars BR) dictss
        in call_with ((Pretty.str o deresolve) sym) dict_pretty end
      end

    and print_app const_syntax some_thm vars fxy (const as { sym, ... }, ts) =
      case find_first (fn name => sym = Constant name) undefineds of
        SOME name => print_abort name
      | NONE =>
        let
          fun stock fxy' ts' =
            gen_print_app (print_app_expr const_syntax) (print_python_expr const_syntax)
              const_syntax some_thm vars fxy' (const, ts')
        in
          case sym of
            Constant name =>
              (case const_syntax name of
                SOME (_, Plain_printer s) =>
                  if null ts then Pretty.str s
                  else applify "(" ")" (print_python_expr const_syntax some_thm vars NOBR) fxy
                        (Pretty.str s) ts
              | SOME (wanted, Complex_printer _) =>
                  if length ts > wanted
                  then
                    let val (ts1, ts2) = chop wanted ts
                    in applify "(" ")" (print_python_expr const_syntax some_thm vars NOBR) fxy
                        (stock APP ts1) ts2
                    end
                  else stock fxy ts
              | NONE => stock fxy ts)
          | _ => stock fxy ts
        end

    fun print_python_typedef tyco { cnstrs, ... } =
      let
        val field_names = 
          case Record.get_info thy (Long_Name.qualifier tyco) of
              SOME { fields, ... } => SOME (map (Long_Name.base_name o fst) fields)
            | NONE => NONE
        fun python_safe_ident s =
          String.translate (fn c =>
              if Char.isAlphaNum c orelse c = #"_" then String.str c else "_") s
        fun print_constructor { name, arg_tys, ... } =
          let
            val name_ctxt = Name.declare "self" (snd reserved)
            val named_fields = Name.invent_names name_ctxt "a" arg_tys
            val labels =
              case field_names of
                  SOME names =>
                    if length names <= length named_fields
                    then names @ (case length named_fields - length names of
                          0 => []
                        | 1 => ["more"]
                        | n => "more" :: List.tabulate (n - 1, fn i => "more" ^ string_of_int (i + 2)))
                    else map fst named_fields
                | NONE => map fst named_fields
            val fields = labels
              |> map (fn fname => Pretty.str (python_safe_ident fname ^ ": Any"))
          in Pretty.chunks
            [Pretty.str "@dataclass(frozen=True)",
             Pretty.block [Pretty.str "class ", Pretty.str (deresolve_const name), Pretty.str ":"],
             indent_block 4 (if null fields then Pretty.str "pass" else Pretty.chunks fields)]
          end
      in Pretty.chunks (map print_constructor cnstrs) end;

    fun print_python_class sym { super, methods } =
      let
        val fields = methods
          |> map (fn (name, _) => Pretty.str (attr_name (Constant name) ^ ": Callable"))
        val super_fields = super
          |> map (fn (self, super) => Pretty.str
            (attr_name (Class_Relation (self, super)) ^ ": Any"))
        val all_fields = super_fields @ fields
      in Pretty.chunks
        [Pretty.str "@dataclass(frozen=True)",
        Pretty.block [Pretty.str "class ", Pretty.str (deresolve_class sym), Pretty.str ":"],
        indent_block 4 (if null all_fields then Pretty.str "pass" else Pretty.chunks all_fields)]
      end;

    fun print_dict_args vs = map_filter (fn (v, sort) =>
      if null sort then NONE else SOME (Pretty.str (v ^ "_dict"))) vs

    fun print_python_instance (target', class) { vs, tyco, inst_params, superinsts, ... } =
      let
        val tyvars = intro_vars (map fst vs) reserved
        val class_pretty = Pretty.str (deresolve_class class)
        val instance_name = deresolve_inst (target', class)
        
        fun print_classparam_field ((classparam, (const, dom_length)), (thm, _)) =
          let
            val aux_names = Name.invent (snd reserved) "a" dom_length
            val vars = intro_vars aux_names reserved
            val args = map (IVar o SOME) aux_names
            val call = print_app const_syntax (SOME thm) vars NOBR (const, args)
            val params = Pretty.enum "," "" "" (map (Pretty.str o lookup_var vars) aux_names)
          in  concat [Pretty.str (attr_name (Constant classparam)), Pretty.str "=",
                Pretty.block [Pretty.str "lambda ", params, Pretty.str ": ", call]]
          end

        fun print_superinst_field (super_class, dictss) =
          let
            val field_name = attr_name (Class_Relation (class, super_class))
            val value = print_plain_dict NONE tyvars
              (Dict_Const ((tyco, super_class), dictss))
          in concat [Pretty.str field_name, Pretty.str "=", value] end
        
        val fields = map print_superinst_field superinsts @ map print_classparam_field inst_params
        val body = Pretty.block [Pretty.str "return ", class_pretty, Pretty.enum "," "(" ")" fields]
        val dict_args = print_dict_args vs
        val head = Pretty.block [Pretty.str "def ", Pretty.str instance_name, 
          Pretty.enum "," "(" ")" dict_args, Pretty.str ":"]
        (* an instance without dictionary arguments always builds the same
           (frozen) dictionary, so build it once *)
        val decorator = if null dict_args then [Pretty.str "@functools.cache"] else []
      in Pretty.chunks (decorator @ [head, indent_block 4 body]) end;

    fun print_func_head const vctxt dicts params =
      Pretty.block [
        Pretty.str "def ",
        Pretty.str (deresolve_const const),
        Pretty.enum "," "(" ")" (
          dicts @
          map_index (fn (_, SOME v) => Pretty.str (lookup_var vctxt v)
                      | (i, NONE) => Pretty.str ("unused" ^ string_of_int i))
            params
        ),
        Pretty.str ":"
      ]

    fun print_undefined_func_stub const { vs, ty, ... } =
      let
        val arity = Code_Thingol.unfold_fun ty |> fst |> length
        val vctxt = intro_vars (map fst vs) reserved
        val (params, vctxt) = invent_names vctxt "a" arity
        val dict_params = print_dict_args vs
        val head = print_func_head const vctxt dict_params (map SOME params)
      in Pretty.chunks [head,
        indent_block 4 (Pretty.block [Pretty.str "return ", print_abort const])]
      end

    (* A pattern-less equation whose rhs is a constant (`f_int = f`) can't be an
       alias: callers use the arity of the type (see args_num), whereas a bare
       constant of higher arity is printed as a curried lambda, and any instance
       dictionaries must be applied. So eta-expand to an ordinary function:
       `def f_int(a, aa): return f(dicts, a, aa)` *)
    fun eta_expand_alias _ n
        (eq as { patterns = [], rhs = IConst (const as { dictss, ... }), thm }) =
          if n = 0 then eq
          else
            let
              val (vs_tys, body) = Code_Thingol.unfold_abs
                (Code_Thingol.saturated_application n (const, []))
            in { patterns = map (IVar o fst) vs_tys, rhs = body, thm = thm } end
      (* The same holds for any pattern-less equation of a function that takes
         dictionaries itself, e.g. `to_nat = nat o Rep` in a class context: it is
         printed as `def to_nat(a_dict)`, but callers pass the arguments too. *)
      | eta_expand_alias takes_dicts n (eq as { patterns = [], rhs, thm }) =
          if n = 0 orelse not takes_dicts then eq
          else
            let
              val names = Name.invent
                (Name.make_context (Code_Thingol.add_varnames rhs [])) "x" n
              val vars = map (IVar o SOME) names
            in { patterns = vars, rhs = rhs `$$ vars, thm = thm } end
      | eta_expand_alias _ _ eq = eq;

    (* This function needs to distinguish different cases:
     *  - functions without any code equations, which are declared to abort => print a stub that aborts
     *  - value definitions (i.e., nullary functions), should not be printed as
     *      python functions, but as simple assignments
     *  - simple functions (i.e., functions that only have one equation, and
     *      where all the argument patterns are simple variables),
     *      these should be printed as standard python functions
     *  - functions that have multiple equations, or where there is a pattern
     *      in the arguments, these have to use match/case
     *)
    fun print_python_func const (f as { eqs = [], ... }) = print_undefined_func_stub const f
      | print_python_func const { vs, ty, eqs = eqs0 } =
        let
          (* same as above, register typevar names to avoid name clashes *)
          val eqs = map (eta_expand_alias (not (null (print_dict_args vs)))
           (length (fst (Code_Thingol.unfold_fun ty)))) eqs0
          val vctxt = intro_vars (map fst vs) reserved
          (* a `simple` function only has one equations, where all arguments
             are bare variables (so no destructuring needed), so it can be
             printed as an ordinary function rather than needing match/case *)
          val (simple, simple_params) =
            case eqs of
              [ { patterns, ... } ] =>
                let val stripped = map (strip_transparent_wrappers thy) patterns 
                in
                  if forall Code_Thingol.is_IVar stripped
                  then (true, map (
                    fn IVar x => x
                     | _ => raise Fail "should not happen") stripped)
                  else (false, [])
                end
              | _ => (false, [])
          val vars1 = vctxt
            |> intro_base_names_for (is_none o const_syntax) deresolve (map #rhs eqs)
          val params = if simple then simple_params
            else map SOME (aux_params vars1 (map #patterns eqs))
          val vars2 = intro_vars (map_filter I params) vars1
          val dict_params = print_dict_args vs
          (* a simple function without parameters and dictionary arguments can
             be printed as a plain value (i.e., an assignment x = ...) *)
          val prints_as_value = simple andalso null params andalso null dict_params
          val head = print_func_head const vars2 dict_params params
          fun print_return some_thm vars' t' = Pretty.block [Pretty.str "return (",
            print_python_expr const_syntax some_thm vars' NOBR t', Pretty.str ")"]

          (* Tail calls: with the python_tail_calls option, a function that calls itself
             in tail position runs its body in `while True:`, and each such call becomes
             a reassignment of the parameters followed by `continue`. Python closures
             capture variables, not values, so a closure created in one iteration would
             see the rebinding of the next: functions whose equations create closures
             (lambdas, or partial applications printed as lambdas) are left alone. *)
          fun self_call t = case Code_Thingol.unfold_const_app t of
              SOME (c as { sym = Constant name, ... }, ts) =>
                if name = const andalso length ts = length params then SOME (c, ts) else NONE
            | _ => NONE
          fun has_self_tail_call (ICase { clauses, ... }) =
                exists (has_self_tail_call o snd) clauses
            | has_self_tail_call t = is_some (self_call t)
          fun creates_closure (_ `|=> _) = true
            | creates_closure (ICase { term, clauses, ... }) =
                creates_closure term orelse exists (creates_closure o snd) clauses
            | creates_closure t = (case Code_Thingol.unfold_const_app t of
                SOME ({ sym, dictss, ... }, ts) =>
                  let val arity = const_arity sym
                  in exists creates_closure ts orelse
                    (length ts < arity
                      andalso not (null ts andalso forall null dictss andalso arity = 1))
                  end
              | NONE => (case t of
                  t1 `$ t2 => creates_closure t1 orelse creates_closure t2
                | _ => false))
          val loops = Config.get ctxt tail_calls andalso not (null params)
            andalso exists (has_self_tail_call o #rhs) eqs
            andalso not (exists (creates_closure o #rhs) eqs)
          val param_strs = map_index (fn (_, SOME v) => lookup_var vars2 v
            | (i, NONE) => "unused" ^ string_of_int i) params
          val dict_strs = map Pretty.unformatted_string_of dict_params
          fun print_finish some_thm vars' t' = case (if loops then self_call t' else NONE) of
              NONE => print_return some_thm vars' t'
            | SOME ({ dictss, ... }, ts) =>
                let
                  val new_dicts = map Pretty.unformatted_string_of
                    (map_filter (print_dicts some_thm vars' BR) dictss)
                  val new_args = map (Pretty.unformatted_string_of o
                    print_python_expr const_syntax some_thm vars' NOBR) ts
                  (* skip parameters that are passed on unchanged *)
                  val changed = filter (fn (old, new) => old <> new)
                    ((dict_strs ~~ new_dicts) @ (param_strs ~~ new_args))
                  val assign = if null changed then []
                    else [Pretty.str (commas (map fst changed) ^ " = " ^
                      commas (map (enclose "(" ")" o snd) changed))]
                in
                  if length new_dicts <> length dict_strs
                  then print_return some_thm vars' t'
                  else Pretty.chunks (assign @ [Pretty.str "continue"])
                end
          fun print_rhs some_thm vars t = print_tail_expr some_thm (print_finish some_thm) vars t
          fun loop_body body = if loops
            then Pretty.chunks [Pretty.str "while True:", indent_block 4 body]
            else body
        in
          if prints_as_value
          then
            (* value definition: `const = (expr)` *)
            let val { rhs = t, thm = some_thm, ... } = hd eqs
            in print_binding some_thm vars2 (deresolve_const const, t) end
          else if simple
          then
            (* simple function, plain variable args *)
            let val { rhs = t, thm = some_thm, ... } = hd eqs
            in Pretty.chunks [head, indent_block 4 (loop_body (print_rhs some_thm vars2 t))] end
          else
            (* multiple equations and/or patterns in arguments, this compiles
               to a match/case over the arguments *)
            let 
              val param_names = map_filter (Option.map (lookup_var vars2)) params
              val scrutinee = if length param_names = 1
                then Pretty.str (hd param_names)
                else Pretty.enum "," "(" ")" (map Pretty.str param_names)
              fun print_one_equation { patterns, rhs, thm } =
                let
                  val (sub_patterns, guards, preamble, vars') = pattern_of_iterms vars2 patterns
                  val pattern_pretty = if length sub_patterns = 1
                    then print_python_pattern (hd sub_patterns)
                    else Pretty.enum "," "(" ")" (map print_python_pattern sub_patterns)
                  val header = print_case_header thm vars' pattern_pretty guards
                in Pretty.chunks [header,
                    indent_block 4 (Pretty.chunks (preamble @ [print_rhs thm vars' rhs]))]
                end
              (* Same reasoning as print_case_block: if the last equation's
                 own patterns are already all bare variables, that arm is
                 unconditionally exhaustive on its own *)
              val last_is_exhaustive = case rev eqs of
                  { patterns, ... } :: _ => forall (is_trivial_pattern vars2) patterns
                | [] => false
              val arms = map print_one_equation eqs @
                (if last_is_exhaustive then [] else [fallthrough_arm])
            in Pretty.chunks
              [head, indent_block 4 (loop_body (Pretty.chunks
                [Pretty.block [Pretty.str "match ", scrutinee, Pretty.str ":"],
                 indent_block 4 (Pretty.chunks arms)]))]
            end
        end;

    fun print_stmt (Constant const, (_, Fun f)) =
          if member (op =) undefineds const
          then print_undefined_func_stub const f
          else print_python_func const f
      | print_stmt (Type_Constructor tyco, (_, Datatype d)) =
          print_python_typedef tyco d
      | print_stmt (Type_Class sym, (_, Class class)) =
          print_python_class sym class
      | print_stmt (Class_Instance sym, (_, Instance instance)) =
          print_python_instance sym instance
      | print_stmt (_, _) = Pretty.str "# <unknown statement kind>"
  in print_stmt end;

fun python_program_of_program ctxt module_name reserved identifiers exports program =
  let
    (* Add trailing underscores to a name until it is unused and not a module name, following PEP 8 *)
    fun namify_common module_names base ((nsp_class, nsp_object), nsp_common) =
      let
        fun fresh x =
          if Name.is_declared nsp_common x orelse member (op =) module_names x then fresh (x ^ "_") else x;
        val base' = fresh base;
      in
        (base', ((Name.declare base' nsp_class, Name.declare base' nsp_object), Name.declare base' nsp_common))
      end;

    (* Python doesn't really have any naming restrictions relating to upper/lowercase etc. *)
    fun namify_stmt _ (Code_Thingol.NoStmt) = raise Fail "should not be reached"
      | namify_stmt module_names _ = namify_common module_names;
    
    (* Code_Thingol.stmt -> python_stmt option *)
    fun modify_stmt (Code_Thingol.Fun (_, SOME _)) = NONE
      | modify_stmt (stmt as Code_Thingol.Fun _) = SOME stmt
      | modify_stmt (Code_Thingol.Datatype (_, [])) = NONE
      | modify_stmt (stmt as Code_Thingol.Datatype _) = SOME stmt
      | modify_stmt (Code_Thingol.Datatypecons _) = NONE
      | modify_stmt (stmt as Code_Thingol.Class _) = SOME stmt
      | modify_stmt (Code_Thingol.Classrel _) = NONE
      | modify_stmt (Code_Thingol.Classparam _) = NONE
      | modify_stmt (stmt as Code_Thingol.Classinst _) = SOME stmt
      | modify_stmt (Code_Thingol.NoStmt) = raise Fail "should not be reached";
    fun flat_program module_names =
      Code_Namespace.flat_program ctxt
        { module_prefix = "", module_name = module_name, reserved = reserved,
          identifiers = identifiers, empty_nsp = ((reserved, reserved), reserved),
          namify_stmt = namify_stmt module_names, modify_stmt = modify_stmt }
        exports program;

    (* Find the module names by a first pass *)
    val module_names = Graph.keys (#flat_program (flat_program []));
  in flat_program module_names end;

fun serialize_python undefineds _ ctxt { module_name, reserved_syms,
    identifiers, includes, const_syntax, ... } program exports =
  let
    val program =
      Code_Symbol.Graph.restrict
        (fn sym => case sym of
            Constant c => is_none (const_syntax c)
          | _ => true)
        program;

    val program =
      Code_Symbol.Graph.fold (fn (sym, (stmt, _)) =>
          case (sym, stmt) of
            (Class_Instance _, Code_Thingol.Classinst { class, superinsts, ... }) =>
              fold (fn (super_class, _) =>
                  Code_Symbol.Graph.add_edge (sym, Class_Relation (class, super_class)))
                superinsts
          | _ => I)
        program program;

    val program =
      let
        val roots = Code_Symbol.Graph.keys program
          |> filter (fn sym => case Code_Symbol.Graph.get_node program sym of
               Code_Thingol.Classinst _ => false | _ => true);
        val live = Code_Symbol.Graph.all_succs program roots;
      in Code_Symbol.Graph.restrict (member (op =) live) program end;

    val { deresolver, flat_program = python_program } =
      python_program_of_program ctxt module_name (Name.make_context reserved_syms)
        identifiers exports program;

    fun lookup_constr tyco constr = case Code_Symbol.Graph.get_node program (Type_Constructor tyco)
      of Code_Thingol.Datatype (_, constrs) => AList.lookup (op = o apsnd fst) constrs constr
       | _ => NONE;

    fun is_class_param (sym as Constant _) = (
        case Code_Symbol.Graph.get_node program sym of 
          Code_Thingol.Classparam _ => true
        | _ => false)
      | is_class_param _ = raise Fail "should never be reached";
      
    fun is_value sym = 
      case sym of
        Constant _ => (
          case Code_Symbol.Graph.get_node program sym of 
            Code_Thingol.Fun (((vs, _), [((ts, _), _)]), _) => 
              forall (null o snd) vs andalso null ts
          | _ => false)
      | _ => false;
    
    fun classparams_of_class class = 
      case Code_Symbol.Graph.get_node program (Type_Class class) of 
        Code_Thingol.Class (_, (_, classparams)) => classparams
      | _ => raise Fail "should never be reached";
    
    (* Datatype constructor without a printing *)
    fun is_constr sym = Code_Symbol.Graph.defined program sym andalso Code_Thingol.is_constr program sym;

    fun args_num (sym as Constant const) = (case Code_Symbol.Graph.get_node program sym
      of Code_Thingol.Fun (((_, ty), []), _) => (length o fst o Code_Thingol.unfold_fun) ty
        | Code_Thingol.Fun (((_, ty), ((ts, _), _) :: _), _) =>
            if null ts
            then (length o fst o Code_Thingol.unfold_fun) ty
            else length ts
        | Code_Thingol.Datatypecons tyco => length (the (lookup_constr tyco const))
        | Code_Thingol.Classparam class =>
            (length o fst o Code_Thingol.unfold_fun o the o AList.lookup (op =)
              (classparams_of_class class)) const
        | _ => raise Fail "should never be reached")
      | args_num _ = raise Fail "should never be reached";

    fun python_stmt_of_thingol (Code_Thingol.Fun (x, _)) = 
          let
            val (typescheme, eqs) = x
            val eqs' = List.mapPartial (fn ((patterns, rhs), (thm, def)) =>
              if def 
              then SOME { patterns = patterns, rhs = rhs, thm = thm }
              else NONE) eqs
            val (vs, ty) = typescheme
          in Fun { vs = vs, ty = ty, eqs = eqs' } end
      | python_stmt_of_thingol (Code_Thingol.Datatype x) =
          let
            val (typarams, cnstrs) = x
            val constrs' = map (fn ((name, typarams), arg_tys) =>
              { name = name, typarams = typarams, arg_tys = arg_tys }
            ) cnstrs
          in Datatype { typarams = typarams, cnstrs = constrs' } end
      | python_stmt_of_thingol (Code_Thingol.Class x) =
          let val (_, (super, methods)) = x
          in Class { super = super, methods = methods } end
      | python_stmt_of_thingol (Code_Thingol.Classinst inst) = 
        let val { vs, tyco, inst_params, superinsts, ... } = inst
        in Instance { vs = vs, tyco = tyco, inst_params = inst_params, superinsts = superinsts }
        end
      | python_stmt_of_thingol _ = raise Fail "unexpected statement";

    val module_names = Graph.keys python_program;

    (* `program` (and therefore python_program) has already been pruned
      down to exactly the live statements above, so this is just: print
      every surviving statement, drop empty modules. *)
    val module_stmts = module_names
      |> map (fn mod_name =>
        let
          val (stmt_gr, imports) = Graph.get_node python_program mod_name;
          val stmt_ps = (Code_Symbol.Graph.strong_conn stmt_gr |> flat)
            |> rev
            |> map_filter (fn sym => case Code_Symbol.Graph.get_node stmt_gr sym
              of (_, NONE) => NONE
              | (_, SOME (export, stmt)) =>
                  SOME (print_python_stmt undefineds const_syntax
                    (make_vars reserved_syms) args_num is_class_param is_value
                    is_constr ctxt (deresolver mod_name)
                    (sym, (export, python_stmt_of_thingol stmt))));
        in (mod_name, imports, stmt_ps) end)
      |> filter (fn (_, _, stmt_ps) => not (null stmt_ps));

    val nonempty_names = map #1 module_stmts;

    (* modules that print a cached (dictionary-free) instance need functools *)
    fun needs_functools mod_name =
      let val (stmt_gr, _) = Graph.get_node python_program mod_name
      in Code_Symbol.Graph.fold (fn (_, ((_, stmt), _)) => fn b => b orelse
          (case stmt of
            SOME (_, Code_Thingol.Classinst { vs, ... }) => forall (null o snd) vs
          | _ => false)) stmt_gr false
      end;

    (* Full names of the theories in the context, by short name *)
    val theory_long_names = Symtab.make (map (fn thy => (Context.theory_base_name thy,
      Context.theory_long_name thy)) (Theory.nodes_of (Proof_Context.theory_of ctxt)));

    (* Full names of the theories defining the symbols of a module *)
    fun source_theories mod_name =
      let val (stmt_gr, _) = Graph.get_node python_program mod_name
      in
        Code_Symbol.Graph.fold (insert (op =) o Code_Symbol.default_prefix ctxt o fst) stmt_gr []
        |> map (the o Symtab.lookup theory_long_names)
        |> sort_strings
      end;

    fun print_header mod_name =
      let val thys = source_theories mod_name
      in Pretty.str ("# Generated by Isabelle from " ^ (if length thys = 1 then "theory " else "theories ") ^
        commas thys ^ "; do not edit")
      end;

    fun print_one_module (mod_name, imports, stmt_ps) =
      let
        val import_ps = imports
          |> filter (fn (imported_name, _) => member (op =) nonempty_names imported_name)
          |> map (fn (imported_name, _) => concat [Pretty.str "import", Pretty.str imported_name]);
        val imports_block = Pretty.chunks (Pretty.str "from dataclasses import dataclass"
          :: Pretty.str "from typing import Any, Callable"
          :: (if needs_functools mod_name then [Pretty.str "import functools"] else [])
          @ import_ps)
        val abort_def = Pretty.chunks
          [Pretty.str "def _abort(msg, thunk):",
           indent_block 4 (Pretty.str "raise RuntimeError(msg)")]
      in ([mod_name ^ ".py"],
        Pretty.chunks2 (print_header mod_name :: imports_block :: abort_def :: stmt_ps))
      end;

    val p = map print_one_module module_stmts
     |> curry (op @) (map (apfst (fn a => [a])) includes);
  in (Code_Target.Hierarchy (p), try (deresolver "")) end;

val serializer : Code_Target.serializer =
  Code_Target.parse_args (
    (Scan.optional (Args.$$$ "python_module" |-- Args.name) "")
    >> (fn python_module => fn lthy =>
          serialize_python (Symtab.keys (Undefined_Data.get (Proof_Context.theory_of lthy)))
            python_module lthy));

val _ = Theory.setup
  (Code_Target.add_language
    (target, { serializer = serializer, literals = literals,
      check = { env_var = "ISABELLE_PYTHON", 
      make_destination = fn p => p + Path.explode "export.py",
      run_command = Code_Target.run_command_bash (fn module_name =>
        "python3 -m py_compile " ^ Bash.string module_name ^ "/*.py")},
      evaluation_args = []})
  #> (fn thy => fold (Code_Target.add_reserved target)
    (distinct (op =) (python_names thy @ prelude_names)) thy));

end; (* struct *)
