theory Oracle_Classes
  imports Python_Check "Python.Python_Setup"
begin

definition double_sum :: "'a::monoid_add list \<Rightarrow> 'a" where
  "double_sum xs = sum_list xs + sum_list xs"

definition sorted_desc :: "'a::linorder list \<Rightarrow> 'a list" where
  "sorted_desc xs = rev (sort xs)"

python_check c_ds_int: "double_sum [1::int, 2]"
python_check c_ds_nat: "double_sum [1::nat, 2]"
python_check c_ds_both: "(double_sum [1::int], double_sum [2::nat], double_sum [3::integer])"
python_check c_sort_bool: "sorted_desc [True, False, True]"
python_check c_fold_max: "fold max [3::int, 7, -2] 0"

class scalable =
  fixes scale :: "int \<Rightarrow> 'a \<Rightarrow> 'a"

instantiation int :: scalable
begin
definition "scale k (x::int) = k * x"
instance ..
end

instantiation list :: (scalable) scalable
begin
definition "scale k xs = map (scale k) xs"
instance ..
end

instantiation prod :: (scalable, scalable) scalable
begin
definition "scale k p = (scale k (fst p), scale k (snd p))"
instance ..
end

class scalable_zero = scalable +
  fixes szero :: 'a

instantiation int :: scalable_zero
begin
definition "szero = (0::int)"
instance ..
end

instantiation list :: (scalable) scalable_zero
begin
definition "szero = ([] :: 'a list)"
instance ..
end

definition sz_pair :: "'a::scalable_zero \<Rightarrow> 'a list" where
  "sz_pair x = [scale 2 x, szero]"

python_check c_scale: "scale 3 ([(1::int, [2::int])], (4::int))"
python_check c_sz_int: "sz_pair (5::int)"
python_check c_sz_list: "sz_pair [5::int, 6]"
python_check c_sz_nested: "sz_pair [[5::int]]"

end
