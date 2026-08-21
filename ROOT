chapter AFP

session Python = HOL +
  description "A Python frontend for the Isabelle code generator."
  options [timeout = 300, document = false]
  theories
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
    Example_records
    Example_record_ext
    Example_nested_case
    Example_partial
    Example_options
  export_files (in "../python_out") "*:**"

session Python_Test_Quick in "test/quick" = Python +
  description "Quick test session for Python backend"
  options [timeout = 300]
  theories [document = false]
    Quick_Test
  export_files (in "python_out") "*:**"