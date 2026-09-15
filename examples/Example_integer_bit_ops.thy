theory Example_integer_bit_ops
  imports Main "Python.Python_Setup"
begin

definition test_push_bit :: integer where
  "test_push_bit = push_bit 3 (5 :: integer)"

definition test_drop_bit :: integer where
  "test_drop_bit = drop_bit 2 (20 :: integer)"

definition test_take_bit :: integer where
  "test_take_bit = take_bit 4 (255 :: integer)"

definition test_bit :: bool where
  "test_bit = bit (10 :: integer) 1"

definition test_mask :: integer where
  "test_mask = mask 5"

definition test_set_bit :: integer where
  "test_set_bit = set_bit 2 (0 :: integer)"

definition test_unset_bit :: integer where
  "test_unset_bit = unset_bit 0 (7 :: integer)"

definition test_flip_bit :: integer where
  "test_flip_bit = flip_bit 1 (5 :: integer)"

definition test_sgn :: integer where
  "test_sgn = sgn (-42 :: integer)"

export_code
  test_push_bit test_drop_bit test_take_bit test_bit test_mask
  test_set_bit test_unset_bit test_flip_bit test_sgn
  in Python file_prefix "."

end