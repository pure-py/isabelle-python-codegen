chapter AFP

session Python = HOL +
  description "A Python frontend for the Isabelle code generator."
  options [timeout = 300, document = false]
  theories
    Python_Setup
  export_files (in "python_out") "*:**"

session Python_Examples in "examples" = Python +
  options [timeout = 300]
  theories
    Example
    Example_tyclass
    Example_lists
  export_files (in "python_out") "*:**"