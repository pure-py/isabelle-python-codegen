signature CODE_PYTHON =
sig
  val target: string
end;

structure Code_Python : CODE_PYTHON =
struct

open Basic_Code_Symbol;
open Basic_Code_Thingol;
open Code_Printer;

val target = "Python";

val python_reserved_words =
  ["False", "None", "True", "and", "as", "assert", "await", "break", "class",
   "continue", "def", "del", "elif", "else", "except", "finally", "for", "from",
   "global", "if", "import", "in", "is", "lambda", "nonlocal", "not", "or", "pass",
   "raise", "return", "try", "while", "with", "yield", "match", "case"];

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
 *   undefineds: intentionally unimplemented symbols, turn into 
 *                 `raise NotImplementedError(...)`
 *   const_syntax: custom registered code_printing declarations for constants
 *   reserved: context of names that are not useable as new names
 *   args_num: how many arguments needed by the current stmt for saturation
 *   is_class_param: true if the current symbol is a type-class method
 *   is_constr: true for any datatype constructor
 *   ctxt: thoery context (neede to look up record field names)
 *   deresolve: module relative naming resolver
 *)
fun print_python_stmt undefineds const_syntax reserved args_num
    is_class_param is_value is_constr ctxt (deresolve, _) =
  let
    fun deresolve_const name = deresolve (Constant name);
    fun deresolve_class name = deresolve (Type_Class name);
    fun deresolve_classrel name = deresolve (Class_Relation name);
    fun deresolve_inst name = deresolve (Class_Instance name);
    
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

    val fallthrough_arm = Pretty.chunks
      [Pretty.block [Pretty.str "case ", Pretty.str "_", Pretty.str ":"],
      indent_block 4 (Pretty.str "raise RuntimeError(\"match failed\")")];

    (* Peel consecutive Suc layers of term *)
    fun dest_suc_chain t = case Code_Thingol.unfold_const_app t of
      SOME ({ sym = Constant "Nat.Suc", ... }, [arg]) =>
        let val (n, base) = dest_suc_chain arg in (n + 1, base) end
      | _ => (0, t)

    and dest_cons_chain t =
      case Code_Thingol.unfold_const_app t of
        SOME ({ sym = Constant "List.list.Cons", ... }, [x, xs]) =>
          let val (es, tail) = dest_cons_chain xs
          in (x :: es, tail) end
      | _ => ([], t);
    
    (* Create patterns from iterms *)
    fun pattern_of_iterm vars (IVar NONE) = (PWild, [], [], vars)
      | pattern_of_iterm vars (IVar (SOME v)) =
          let val vars' = intro_vars [v] vars
          in (PCapture (lookup_var vars' v), [], [], vars') end
      | pattern_of_iterm vars (t as IConst { sym, ...}) =
          if sym = Constant "Nat.zero_nat_inst.zero_nat"
          then (PLiteral (Pretty.str "0"), [], [], vars)
          else if sym = Constant "List.list.Nil"
          then (PLiteral (Pretty.str "[]"), [], [], vars)
          else if is_constr sym andalso args_num sym = 0
          then (PClass (deresolve sym, []), [], [], vars)
          else
            (* fallback, create a new name + attach guards *)
            let val (name, vars') = invent_name vars "c"
            in (PCapture name, [GEq (name, t)], [], vars') end
      | pattern_of_iterm vars t =
        (case Code_Thingol.unfold_const_app t of
          SOME ({ sym = Constant "List.list.Cons", ... }, [_, _]) =>
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
        | _ =>
          (case dest_suc_chain t of
              (0, _) => (case Code_Thingol.unfold_const_app t of
                  SOME ({ sym, ... }, args) =>
                    let
                      val (ps, guards, preamble, vars') = pattern_of_iterms vars args
                    in
                      if sym = Constant "Product_Type.Pair"
                      then (PTuple ps, guards, preamble, vars')
                      else (PClass (deresolve sym, ps), guards, preamble, vars')
                    end
                | NONE => error "bad term in pattern")
            | (depth, base) =>
              let
                val (cname, vars1) = invent_name vars "c"
                fun depth_guard cmp = GRaw (concat
                  [Pretty.str cname, Pretty.str cmp, Pretty.str (string_of_int depth)])
              in
                case base of
                  IVar NONE => (PCapture cname, [depth_guard ">="], [], vars1)
                | IVar (SOME v) =>
                  let
                    val vars2 = intro_vars [v] vars1
                    val bind = Pretty.block [Pretty.str (lookup_var vars2 v), Pretty.str " = (",
                      Pretty.str cname, Pretty.str " - ", Pretty.str (string_of_int depth), Pretty.str ")"]
                  in (PCapture cname, [depth_guard ">="], [bind], vars2) end
                | IConst { sym, ... } =>
                  if sym = Constant "Nat.zero_nat_inst.zero_nat"
                  then (PCapture cname, [depth_guard "=="], [], vars1)
                  else error "unsupported base of nat Suc-chain pattern"
                | _ => error "unsupported base of nat Suc-chain pattern"
              end))

    and pattern_of_iterms vars ts =
      let
        val (rev_ps, guards, preamble, vars') =
          fold (fn t => fn (ps, gs, pre, vs) =>
            let val (p, g, pr, vs') = pattern_of_iterm vs t
            in (p :: ps, gs @ g, pre @ pr, vs') end)
          ts ([], [], [], vars)
      in (rev rev_ps, guards, preamble, vars') end; 

    fun print_python_pattern (PCapture v) = Pretty.str v
      | print_python_pattern PWild = Pretty.str "_"
      | print_python_pattern (PLiteral p) = p
      | print_python_pattern (PClass (name, [])) =
          Pretty.block [Pretty.str name, Pretty.str "()"]
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
        | SOME guard => Pretty.block [concat [Pretty.str "case", pattern_pretty,
            Pretty.str "if", guard], Pretty.str ":"]

    and print_case_arm some_thm vars (pattern, body_pretty) =
      let
        val (p, guards, preamble, vars') = pattern_of_iterm vars pattern
        val header = case print_guard some_thm vars' guards of
            NONE => Pretty.block [concat [Pretty.str "case",
              print_python_pattern p], Pretty.str ":"]
          | SOME guard => Pretty.block [concat [Pretty.str "case", print_python_pattern p,
              Pretty.str "if", guard], Pretty.str ":"]
        val body = Pretty.chunks (preamble @ [body_pretty vars'])
      in (header, vars', body) end
  
    and anf_term vars (t as IConst _) = ([], vars, t)
      | anf_term vars (t as IVar _) = ([], vars, t)
      | anf_term vars (t1 `$ t2) =
          let
            val (b1, vars1, t1') = anf_term vars t1;
            val (b2, vars2, t2') = anf_term vars1 t2;
          in (b1 @ b2, vars2, t1' `$ t2') end
      | anf_term vars (t as (_, _) `|=> (_, _)) = ([], vars, t)
      | anf_term vars (t as ICase _) =
          let val (x, vars') = invent_name vars "x"
          in ([(x, t)], vars', IVar (SOME x)) end

    and print_if_then_else some_thm finish vars target t_branch e_branch =
      let
        val (target_bindings, vars1, target') = anf_term vars target;
        val cond = print_python_expr const_syntax some_thm vars1 NOBR target';
      in
        Pretty.chunks (map (print_binding some_thm vars1) target_bindings @
          [Pretty.block [Pretty.str "if ", cond, Pretty.str ":"],
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
          in Pretty.chunks (map (print_binding some_thm vars') bindings @ [finish vars' t']) end

    and print_binding some_thm vars (name, t) =
      print_tail_expr some_thm
        (fn vars' => fn t' => Pretty.block [Pretty.str name, Pretty.str " = (",
          print_python_expr const_syntax some_thm vars' NOBR t', Pretty.str ")"])
        vars t

    and print_case_block some_thm finish vars target clauses =
      let
        val (target_bindings, vars1, target') = anf_term vars target;
        val (tvar, vars0) = invent_name vars1 "target"
        val assign = concat [Pretty.str tvar, Pretty.str "=",
          print_python_expr const_syntax some_thm vars1 NOBR target'];
        val match_head = Pretty.block [Pretty.str "match ", Pretty.str tvar, Pretty.str ":"];
        fun one_arm (pattern, term) =
          let
            val (header, _, body) = print_case_arm some_thm vars0
              (pattern, fn vars' => print_tail_expr some_thm finish vars' term)
          in Pretty.chunks [header, indent_block 4 body] end;
      in
        Pretty.chunks (map (print_binding some_thm vars1) target_bindings @
          [assign, match_head, indent_block 4 (Pretty.chunks (map one_arm clauses @ [fallthrough_arm]))])
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
              error "TODO: hoist nested def for non-expression lambda body"
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
        Pretty.block [p, Pretty.str".", (Pretty.str o deresolve) (Class_Relation classrel)])
      (rev classrels) (* need to go from source dict inwards *)
      (print_plain_dict some_thm vars plain_dict)
    
    and print_plain_dict some_thm vars (Dict_Const (inst, dictss)) =
          gen_applify true "(" ")" I NOBR
            ((Pretty.str o deresolve) (Class_Instance inst))
            (map_filter (print_dicts some_thm vars BR o snd) dictss)
      | print_plain_dict _ _ (Dict_Var { var, index, length, ... }) =
          Pretty.str (var ^ "_dict" ^ (if length = 1 then "" else string_of_int (index + 1)))

    and print_dicts some_thm vars = tuplify (print_dict some_thm vars)

    and print_app_expr const_syntax some_thm vars (app as ({ sym, dictss, ...}, ts)) =
      let val l = args_num sym in
      if length ts < l
      then
        if null ts andalso not (is_class_param sym andalso not (null dictss))
        then [(Pretty.str o deresolve) sym]
        else [print_python_expr const_syntax some_thm vars BR
                (Code_Thingol.saturated_application l app)]
      else if is_class_param sym andalso not (null dictss)
      then 
        let 
          val self_dict_pretty = print_dict some_thm vars NOBR (hd (hd dictss))
          val extra_dict_pretty = map_filter (print_dicts some_thm vars BR) (tl dictss)
          val (immediate, curried) = chop l ts
          val immediate_pretty =
            map (print_python_expr const_syntax some_thm vars BR) immediate
          val curried_pretty =
            map (fn t => Pretty.enclose "(" ")"
              [print_python_expr const_syntax some_thm vars NOBR t]) curried
          val head_pretty = Pretty.block [self_dict_pretty, Pretty.str ".",
            Pretty.str (Code_Symbol.default_base sym)]
          val call = gen_applify true "(" ")" I NOBR head_pretty (extra_dict_pretty @ immediate_pretty)
        in call :: curried_pretty end
      else if is_value sym andalso forall null dictss andalso null ts
      then [(Pretty.str o deresolve) sym]
      else
        let
          val (immediate, curried) = chop l ts
          val dict_pretty = map_filter (print_dicts some_thm vars BR) dictss
          val immediate_pretty =
            map (print_python_expr const_syntax some_thm vars BR) immediate
          val curried_pretty =
            map (fn t => Pretty.enclose "(" ")"
              [print_python_expr const_syntax some_thm vars NOBR t]) curried
          val head_pretty = (Pretty.str o deresolve) sym
          val call = gen_applify true "(" ")" I NOBR head_pretty (dict_pretty @ immediate_pretty)
        in call :: curried_pretty end
      end

    and print_app const_syntax some_thm vars fxy (const, ts) =
      if List.exists (fn name => #sym const = Constant name) undefineds
      then Pretty.str ("raise NotImplementedError(" ^
        print_python_string (Code_Symbol.default_base (#sym const)) ^ ")")
      else gen_print_app (print_app_expr const_syntax)
        (print_python_expr const_syntax) const_syntax some_thm vars fxy (const, ts)

    fun print_python_typedef tyco { cnstrs, ... } =
      let
        val thy = Proof_Context.theory_of ctxt
        val field_names = 
          case Record.get_info thy (Long_Name.qualifier tyco) of
              SOME { fields, ... } => SOME (map (Long_Name.base_name o fst) fields)
            | NONE => NONE
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
              |> map (fn fname => Pretty.str (fname ^ ": Any"))
          in Pretty.chunks
            [Pretty.str "@dataclass(frozen=True)",
             Pretty.block [Pretty.str "class ", Pretty.str (deresolve_const name), Pretty.str ":"],
             indent_block 4 (if null fields then Pretty.str "pass" else Pretty.chunks fields)]
          end
      in Pretty.chunks (map print_constructor cnstrs) end;

    fun print_python_class sym { super, methods } =
      let
        val fields = methods
          |> map (fn (name, _) => Pretty.str (Long_Name.base_name (deresolve_const name) ^ ": Callable"))
        val super_fields = super
          |> map (fn (self, super) => Pretty.str
            (Long_Name.base_name (deresolve_classrel (self, super)) ^ ": Any"))
      in Pretty.chunks
        [Pretty.str "@dataclass(frozen=True)",
         Pretty.block [Pretty.str "class ", Pretty.str (deresolve_class sym), Pretty.str ":"],
         indent_block 4 (Pretty.chunks (super_fields @ fields))]
      end;

    fun print_dict_args some_thm vars vs = map_filter (fn (v, sort) =>
          print_dicts some_thm vars BR
            (map_index (fn (i, _) => Dict ([],
              Dict_Var { var = v, index = i, length = length sort, 
                class = nth sort i, unique = true })) sort)) vs

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
          in  concat [Pretty.str (Long_Name.base_name (deresolve_const classparam)), Pretty.str "=",
                Pretty.block [Pretty.str "lambda ", params, Pretty.str ": ", call]]
          end

        fun print_superinst_field (super_class, dictss) =
          let
            val field_name = Long_Name.base_name (deresolve_classrel (class, super_class))
            val value = print_plain_dict NONE tyvars
              (Dict_Const ((tyco, super_class), dictss))
          in concat [Pretty.str field_name, Pretty.str "=", value] end
        
        val fields = map print_superinst_field superinsts @ map print_classparam_field inst_params
        val body = Pretty.block [Pretty.str "return ", class_pretty, Pretty.enum "," "(" ")" fields]
        val head = Pretty.block [Pretty.str "def ", Pretty.str instance_name, 
          Pretty.enum "," "(" ")" (print_dict_args NONE tyvars vs), Pretty.str ":"]
      in Pretty.chunks [head, indent_block 4 body] end;

    fun print_func_head const vctxt dicts params =
      Pretty.block [
          Pretty.str "def ", 
          Pretty.str (deresolve_const const),
          Pretty.enum "," "(" ")" (
            dicts @
            map (fn NONE => Pretty.str "_" 
                  | SOME v => Pretty.str (lookup_var vctxt v)
            ) params
          ),
          Pretty.str ":"
      ]

    (* This functions needs to distinguish different cases:
     *  - functions without any code equations => print `pass`
     *  - value definitions (i.e., nullary functions), should not be printed as
     *      python functions, but as simple assignments
     *  - simple functions (i.e., functions that only have one equations, and
     *      where all the argument patterns are simple variables),
     *      these should be printed as standard python functions
     *  - functions that have multiple equations, or where there is a pattern
     *      in the arguments, these have to use match/case
     *)
    fun print_python_func const { vs, ty, eqs = [] } =
      (* if we have no code equations *)
      let
        val arity = Code_Thingol.unfold_fun ty |> fst |> length
        (* register the type variable names to avoid name clashes *)
        val vctxt = intro_vars (map fst vs) reserved
        (* for each argument, invent a name *)
        val (params, vctxt) = invent_names vctxt "a" arity
        (* create necessary typeclass dictionary arguments *)
        val dict_params = print_dict_args NONE vctxt vs
        val head = print_func_head const vctxt dict_params (map SOME params)
        val _ = warning ("function " ^ const ^ " has no code equations")
      in Pretty.chunks [head,
        indent_block 4 (Pretty.block [Pretty.str "raise NotImplementedError(",
          Pretty.str (print_python_string const), Pretty.str ")"])]
      end
      | print_python_func const { vs, eqs, ... } =
        let
          (* same as above, register typevar names to avoid name clashes *)
          val vctxt = intro_vars (map fst vs) reserved
          (* a `simple` function only has one equations, where all arguments
             are bare variables (so no destructuring needed), so it can be
             printed as an ordinary function rather than needing match/case *)
          val (simple, simple_params) = 
            case eqs of 
              [ { patterns, ... } ] => 
                if forall Code_Thingol.is_IVar patterns 
                then (true, map (
                  fn IVar x => x 
                   | _ => raise Fail "should not happen") patterns)
                else (false, [])
              | _ => (false, [])
          val vars1 = vctxt
            |> intro_base_names_for (is_none o const_syntax) deresolve (map #rhs eqs)
          val params = if simple then simple_params
            else map SOME (aux_params vars1 (map #patterns eqs))
          val vars2 = intro_vars (map_filter I params) vars1
          val dict_params = print_dict_args NONE vars2 vs
          (* a simple function without parameters and dictionary arguments can
             be printed as a plain value (i.e., an assignment x = ...) *)
          val prints_as_value = simple andalso null params andalso null dict_params
          val head = print_func_head const vars2 dict_params params
          fun print_rhs some_thm vars t =
            print_tail_expr some_thm
              (fn vars' => fn t' => Pretty.block [Pretty.str "return (",
                print_python_expr const_syntax some_thm vars' NOBR t', Pretty.str ")"])
              vars t
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
            in Pretty.chunks [head, indent_block 4 (print_rhs some_thm vars2 t)] end
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
            in Pretty.chunks
              [head, indent_block 4 (Pretty.chunks
                [Pretty.block [Pretty.str "match ", scrutinee, Pretty.str ":"],
                 indent_block 4 (Pretty.chunks (map print_one_equation eqs @ [fallthrough_arm]))])]
            end
        end;

    fun print_stmt (Constant const, (_, Fun f)) =
          print_python_func const f
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
    fun namify_common base ((nsp_class, nsp_object), nsp_common) =
      let val (base', nsp_common') = Name.variant base nsp_common
      in (base', ((Name.declare base' nsp_class, Name.declare base' nsp_object), nsp_common')) end;

    (* Python doesn't really have any naming restrictions relating to upper/lowercase etc. *)
    fun namify_stmt (Code_Thingol.Fun _) = namify_common
      | namify_stmt (Code_Thingol.Datatype _) = namify_common
      | namify_stmt (Code_Thingol.Datatypecons _) = namify_common
      | namify_stmt (Code_Thingol.Class _) = namify_common
      | namify_stmt (Code_Thingol.Classrel _) = namify_common
      | namify_stmt (Code_Thingol.Classparam _) = namify_common
      | namify_stmt (Code_Thingol.Classinst _) = namify_common
      | namify_stmt (Code_Thingol.NoStmt) = raise Fail "should not be reached";
    
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
  in
    Code_Namespace.flat_program ctxt
      { module_prefix = "", module_name = module_name, reserved = reserved,
        identifiers = identifiers, empty_nsp = ((reserved, reserved), reserved),
        namify_stmt = namify_stmt, modify_stmt = modify_stmt }
      exports program
  end;

fun serialize_python undefineds _ ctxt { module_name, reserved_syms,
    identifiers, includes, const_syntax, ... } program exports =
  let
    val program =
      Code_Symbol.Graph.restrict
        (fn sym => case sym of
            Constant c => is_none (const_syntax c)
          | _ => true)
        program;

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

    (* First pass: print every statement, but tag whether it's a Classinst and
      what its own deresolved name is, so we can do liveness analysis afterward. *)
    val module_stmts_raw = module_names
      |> map (fn mod_name =>
        let
          val (stmt_gr, imports) = Graph.get_node python_program mod_name;
          val entries = (Code_Symbol.Graph.strong_conn stmt_gr |> flat)
            |> rev
            |> map_filter (fn sym => case Code_Symbol.Graph.get_node stmt_gr sym
              of (_, NONE) => NONE
              | (_, SOME (export, stmt)) =>
                  let
                    val is_classinst = case stmt of Code_Thingol.Classinst _ => true | _ => false;
                    val pretty =
                      print_python_stmt undefineds const_syntax
                        (make_vars reserved_syms) args_num is_class_param is_value
                        (Code_Thingol.is_constr program) ctxt (deresolver mod_name, deresolver)
                        (sym, (export, python_stmt_of_thingol stmt));
                    val own_name = deresolver mod_name sym;
                  in SOME (sym, is_classinst, own_name, pretty) end);
        in (mod_name, imports, entries) end);

    val all_entries = maps (fn (_, _, entries) => entries) module_stmts_raw;

    fun text_of pretty = Pretty.unformatted_string_of pretty;

    (* Whole-identifier substring match: avoids "ord_int" matching inside
      some longer identifier like "ord_int2". *)
    fun is_word_ref name text =
      let
        val n = size name;
        fun is_ident_char c = Char.isAlphaNum c orelse c = #"_";
        fun scan i =
          if i + n > size text then false
          else
            let
              val before_ok = i = 0 orelse not (is_ident_char (String.sub (text, i - 1)));
              val after_ok = i + n = size text orelse not (is_ident_char (String.sub (text, i + n)));
            in
              if before_ok andalso after_ok andalso String.substring (text, i, n) = name
              then true else scan (i + 1)
            end;
      in scan 0 end;

    fun classinst_used entries (sym, name) =
      exists (fn (sym', _, _, pretty') =>
        not (sym' = sym) andalso is_word_ref name (text_of pretty'))
        entries;

    (* Iteratively drop Classinst statements whose own name is never referenced
      anywhere else, re-checking after each removal since dropping one instance
      can make another (e.g. a superclass instance it alone depended on) dead too. *)
    fun eliminate entries =
      let
        val (classinsts, others) = List.partition (fn (_, is_ci, _, _) => is_ci) entries;
        val (dead, alive) = List.partition
          (fn (sym, _, name, _) => not (classinst_used entries (sym, name)))
          classinsts;
      in
        if null dead then entries else eliminate (others @ alive)
      end;

    val all_entries_final = eliminate all_entries;
    val kept_syms = map (fn (sym, _, _, _) => sym) all_entries_final;

    val module_stmts = module_stmts_raw
      |> map (fn (mod_name, imports, entries) =>
        let
          val stmt_ps = entries
            |> filter (fn (sym, _, _, _) => member (op =) kept_syms sym)
            |> map (fn (_, _, _, pretty) => pretty);
        in (mod_name, imports, stmt_ps) end)
      |> filter (fn (_, _, stmt_ps) => not (null stmt_ps));

    val nonempty_names = map #1 module_stmts;

    fun print_one_module (mod_name, imports, stmt_ps) =
      let
        val import_ps = imports
          |> filter (fn (imported_name, _) => member (op =) nonempty_names imported_name)
          |> map (fn (imported_name, _) => concat [Pretty.str "import", Pretty.str imported_name]);
        val header_ps = Pretty.chunks (Pretty.str "from dataclasses import dataclass"
          :: Pretty.str "from typing import Any, Callable"
          :: import_ps)
      in ([mod_name ^ ".py"], Pretty.chunks2 (header_ps :: stmt_ps))
      end;

    val p = map print_one_module module_stmts
     |> curry (op @) (map (apfst (fn a => [a])) includes);
  in (Code_Target.Hierarchy (p), try (deresolver "")) end;

val serializer : Code_Target.serializer =
  Code_Target.parse_args (
    (Scan.optional (Args.$$$ "python_module" |-- Args.name) "")
    >> (fn python_module => fn lthy => serialize_python [] python_module lthy));

val _ = Theory.setup
  (Code_Target.add_language
    (target, { serializer = serializer, literals = literals,
      check = { env_var = "ISABELLE_PYTHON", 
      make_destination = fn p => p + Path.explode "export.py",
      run_command = Code_Target.run_command_bash (fn module_name =>
        "python3 -m py_compile " ^ Bash.string module_name ^ "/*.py")},
      evaluation_args = []})
  #> fold (Code_Target.add_reserved target) python_reserved_words);

end; (* struct *)