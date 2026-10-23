theory Oracle_Cases_TC
  imports Oracle_Recursion
begin

text \<open>The recursion checks again, exported with self tail calls printed as loops,
  plus inputs too deep for Python's default recursion limit of 1000.\<close>

declare [[python_tail_calls]]

python_check tc_build_long: "length (build 5000 [])"
python_check tc_rev_long: "length (acc_rev (build 5000 []) [])"
python_check tc_count_long: "count_pos (map int (build 5000 [])) 0"
python_check tc_swap_long: "swap_count 5001 1 2"

python_export_checks

end
