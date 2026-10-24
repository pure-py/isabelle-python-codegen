theory Example_chars
    imports Main "Python.Python_Setup"
begin

definition greeting :: string where
  "greeting = ''hello''"

definition is_digit :: "char \<Rightarrow> bool" where
  "is_digit c = (CHR ''0'' \<le> c \<and> c \<le> CHR ''9'')"

definition code :: "char \<Rightarrow> nat" where
  "code c = of_char c"

definition literal :: String.literal where
  "literal = String.implode greeting"

definition chars :: string where
  "chars = String.explode (STR ''hi'')"

definition newline :: char where
  "newline = CHR 0x0A"

export_code greeting is_digit code literal chars newline in Python file_prefix "."

end
