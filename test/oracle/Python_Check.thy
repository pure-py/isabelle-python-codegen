theory Python_Check
  imports Main
  keywords "python_check" "python_check_grid" "python_export_checks" :: thy_decl
    and "over"
begin

text \<open>
  Differential testing of the Python backend against Isabelle's SML evaluator.

  \<^theory_text>\<open>python_check name: "t"\<close> evaluates \<open>t\<close> to \<open>r\<close> with SML code evaluation and
  defines \<open>name_ok \<equiv> \<lambda>_::unit. t = r\<close> and \<open>name_actual \<equiv> \<lambda>_::unit. t\<close>. The
  generated Python must then compute \<open>name_ok(None)\<close> as \<open>True\<close>. If \<open>r\<close> is \<open>True\<close> or
  \<open>False\<close>, \<open>name_ok\<close> is \<open>t\<close> or \<open>\<not> t\<close>, so the check does not wrap a boolean term in
  an equality of its own. A negative control is a check of \<open>t \<noteq> r\<close>.
  \<^theory_text>\<open>python_check_grid name: "f" over "xs\<^sub>1" \<dots> "xs\<^sub>n"\<close> adds one check per
  element of the cartesian product of the argument lists.

  \<^theory_text>\<open>python_export_checks\<close> exports all checks of the theory to Python (like
  \<^theory_text>\<open>export_code \<dots> in Python file_prefix "."\<close>) together with a manifest
  \<open>oracle/manifest.json\<close> that the pytest runner reads.
\<close>

ML \<open>
structure Python_Check =
struct

(*module: the theory that defines the check, i.e. the Python module that holds its constants*)
type check = {name: string, module: string, term: string, expected: string};

structure Data = Theory_Data
(
  type T = check list;  (*newest first*)
  val empty = [];
  fun merge (checks1, checks2) = Library.merge (op =) (checks1, checks2);
);

fun const_names ({name, module, ...}: check) =
  map (fn suffix => Long_Name.qualify module (name ^ suffix)) ["_ok", "_actual"];

fun string_of_term ctxt = XML.content_of o YXML.parse_body o Syntax.string_of_term ctxt;

fun define name rhs lthy =
  let
    val b = Binding.name name;
  in
    lthy
    |> Local_Theory.define ((b, NoSyn), ((Thm.def_binding b, @{attributes [code]}), rhs))
    |> snd
  end;

(*a function of unit, so that an exception only fails its own check, not the
  import of the whole module*)
fun lazy t = Abs ("u", HOLogic.unitT, t);

fun ok_term t r =
  if r aconv \<^term>\<open>True\<close> then t
  else if r aconv \<^term>\<open>False\<close> then HOLogic.mk_not t
  else HOLogic.mk_eq (t, r);

fun check name t lthy =
  let
    val thy = Proof_Context.theory_of lthy;
    val T = fastype_of t;
    val _ = Sign.of_sort thy (T, \<^sort>\<open>equal\<close>) orelse
      error ("python_check " ^ quote name ^ ": type has no equality: " ^
        Syntax.string_of_typ lthy T);
    val r = Code_Evaluation.dynamic_value_strict lthy t;
    val check = {name = name, module = Context.theory_base_name thy,
      term = string_of_term lthy t, expected = string_of_term lthy r};
  in
    lthy
    |> define (name ^ "_ok") (lazy (ok_term t r))
    |> define (name ^ "_actual") (lazy t)
    |> Local_Theory.background_theory (Data.map (cons check))
  end;

fun check_grid name f xss lthy =
  let
    fun combos [] = [[]]
      | combos (xs :: xss) = maps (fn x => map (cons x) (combos xss)) xs;
    val cases = combos (map HOLogic.dest_list xss);
  in
    fold_index (fn (i, xs) =>
      check (name ^ "_" ^ string_of_int i) (Envir.beta_norm (list_comb (f, xs)))) cases lthy
  end;

fun read_grid lthy (raw_f, raw_xss) =
  let
    val f = Syntax.read_term lthy raw_f;
    val argTs = fst (strip_type (fastype_of f));
    val _ = length argTs >= length raw_xss orelse
      error "python_check_grid: more argument lists than function arguments";
    val xss = map2 (fn T => fn raw =>
      Syntax.check_term lthy (Type.constraint (HOLogic.listT T) (Syntax.parse_term lthy raw)))
      (take (length raw_xss) argTs) raw_xss;
  in (f, xss) end;

fun json_string s =
  let
    fun esc #"\"" = "\\\""
      | esc #"\\" = "\\\\"
      | esc #"\n" = "\\n"
      | esc c = if Char.ord c < 32 then "" else String.str c;
  in quote (String.translate esc s) end;

fun json_of_check ({name, module, term, expected}: check) =
  "{" ^ commas (map (fn (key, value) => json_string key ^ ": " ^ json_string value)
    [("name", name), ("module", module), ("term", term), ("expected", expected)]) ^ "}";

fun export_checks lthy =
  let
    val thy = Proof_Context.theory_of lthy;
    val checks = rev (Data.get thy);
    val _ = null checks andalso error "python_export_checks: no checks";
    val manifest =
      "{" ^ json_string "checks" ^ ": [\n  " ^
      space_implode ",\n  " (map json_of_check checks) ^ "\n]}\n";
    val _ = Export.export thy (Path.binding0 (Path.make ["oracle", "manifest.json"]))
      [XML.Text manifest];
  in
    Code_Target.export_code true (maps const_names checks)
      [((("Python", ""), SOME ({physical = false}, (Path.current, Position.none))), [])] lthy
  end;

val _ =
  Outer_Syntax.local_theory \<^command_keyword>\<open>python_check\<close>
    "check a term's Python value against SML evaluation"
    (Parse.name -- (\<^keyword>\<open>:\<close> |-- Parse.term) >>
      (fn (name, raw_t) => fn lthy => check name (Syntax.read_term lthy raw_t) lthy));

val _ =
  Outer_Syntax.local_theory \<^command_keyword>\<open>python_check_grid\<close>
    "check a function on all combinations of the given arguments"
    (Parse.name -- (\<^keyword>\<open>:\<close> |-- Parse.term) --
      (\<^keyword>\<open>over\<close> |-- Scan.repeat1 Parse.term) >>
      (fn ((name, raw_f), raw_xss) => fn lthy =>
        uncurry (check_grid name) (read_grid lthy (raw_f, raw_xss)) lthy));

val _ =
  Outer_Syntax.local_theory \<^command_keyword>\<open>python_export_checks\<close>
    "export all checks of this theory to Python"
    (Scan.succeed export_checks);

end
\<close>

end
