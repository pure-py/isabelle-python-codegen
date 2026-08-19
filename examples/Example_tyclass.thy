theory Example_tyclass
    imports Main "Python.Python_Setup"
begin

class describable =
    fixes describe :: "'a \<Rightarrow> String.literal"

datatype color = Red | Green | Blue

instantiation color :: describable
begin
    fun describe_color :: "color \<Rightarrow> String.literal" where
        "describe_color Red = STR ''red''" |
        "describe_color Green = STR ''green''" |
        "describe_color Blue = STR ''blue''"
    instance ..
end

datatype shape = Circle | Square

instantiation shape :: describable
begin
    fun describe_shape :: "shape \<Rightarrow> String.literal" where
        "describe_shape Circle = STR ''circle''" |
        "describe_shape Square = STR ''square''"
    instance ..
end

definition announce :: "'a :: describable \<Rightarrow> String.literal" where
    "announce x = describe x + describe x"

definition announce_red :: String.literal where 
    "announce_red = announce Red"

definition announce_circle :: String.literal where 
    "announce_circle = announce Circle"

export_code announce announce_red announce_circle in Python file_prefix "."

end