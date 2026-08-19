theory Example_super
    imports Main "Python.Python_Setup"
begin

class describable =
  fixes describe :: "'a \<Rightarrow> String.literal"

class describable_verbose = describable +
  fixes describe_verbose :: "'a \<Rightarrow> String.literal"

datatype color = Red | Green | Blue

instantiation color :: describable
begin
  fun describe_color :: "color \<Rightarrow> String.literal" where
    "describe_color Red = STR ''red''" |
    "describe_color Green = STR ''green''" |
    "describe_color Blue = STR ''blue''"
  instance ..
end

instantiation color :: describable_verbose
begin
  fun describe_verbose_color :: "color \<Rightarrow> String.literal" where
    "describe_verbose_color Red = STR ''the color red''" |
    "describe_verbose_color Green = STR ''the color green''" |
    "describe_verbose_color Blue = STR ''the color blue''"
  instance ..
end

definition announce_verbose :: "'a :: describable_verbose \<Rightarrow> String.literal" where
  "announce_verbose x = describe x + STR '' -- '' + describe_verbose x"

definition announce_verbose_red :: String.literal where
  "announce_verbose_red = announce_verbose Red"

export_code announce_verbose announce_verbose_red in Python file_prefix "."

end