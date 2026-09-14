chapter AFP

session Python = HOL +
  description "A Python frontend for the Isabelle code generator."
  options [timeout = 300, document = false]
  sessions
    "HOL-Library"
  theories
    Python
    Python_Setup

session Python_Examples in "examples" = Python +
  options [timeout = 300]
  theories
    Example
    Example_tyclass
    Example_lists
    Example_super
    Example_super_chain
    Example_tuples
    Example_int_arith
    Example_nat
    Example_nat_pattern
    Example_nat_edge_cases
    Example_records
    Example_record_ext
    Example_nested_case
    Example_partial
    Example_options
    Example_code_numerals
    Example_unused_arg
    Example_polymorphic_const
    Example_no_eqs
    Example_nested_if
    Example_transparent_wrapper
    Example_lambda_case
    Example_classrel_base
    Example_classrel
    Example_generic_list_pair
  export_files (in "python_out") "*:**"

session Python_Test_Quick in "test/quick" = Python +
  description "Quick test session for Python backend"
  options [timeout = 300]
  theories [document = false]
    Quick_Test
  export_files (in "python_out") "*:**"

session Python_Test_Slow in "test/slow" = "HOL-Library" +
  description "Slow test session: a slimmed subset of the HOL-Library candidate set"
  options [timeout = 2400]
  sessions
    Python
    "HOL-Number_Theory"
    "HOL-Data_Structures"
    "HOL-Examples"
    "HOL-Computational_Algebra"
  theories [document = false, condition = ISABELLE_PYTHON]
    Candidates
    Generate
  export_files (in "python_out") "*:**"