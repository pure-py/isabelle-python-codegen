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
  export_files (in "../python_out") "*:**"