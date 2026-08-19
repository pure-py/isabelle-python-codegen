theory Example_super_chain
    imports Main "Python.Python_Setup"
begin

(* Part 1: a three-level chain of superclasses *)

class tagged =
    fixes tag :: "'a \<Rightarrow> String.literal"

class tagged_verbose = tagged +
    fixes tag_verbose :: "'a \<Rightarrow> String.literal"

class tagged_extra = tagged_verbose +
    fixes tag_extra :: "'a \<Rightarrow> String.literal"

datatype animal = Cat | Dog

instantiation animal :: tagged
begin
    fun tag_animal :: "animal \<Rightarrow> String.literal" where
        "tag_animal Cat = STR ''cat''" |
        "tag_animal Dog = STR ''dog''"
    instance ..
end

instantiation animal :: tagged_verbose
begin
    fun tag_verbose_animal :: "animal \<Rightarrow> String.literal" where
        "tag_verbose_animal Cat = STR ''the animal cat''" |
        "tag_verbose_animal Dog = STR ''the animal dog''"
    instance ..
end

instantiation animal :: tagged_extra
begin
    fun tag_extra_animal :: "animal \<Rightarrow> String.literal" where
        "tag_extra_animal Cat = STR ''a small domesticated cat''" |
        "tag_extra_animal Dog = STR ''a loyal domesticated dog''"
    instance ..
end

definition announce_chain :: "'a :: tagged_extra \<Rightarrow> String.literal" where
    "announce_chain x = tag x + STR '' | '' + tag_verbose x + STR '' | '' + tag_extra x"

definition announce_chain_cat :: String.literal where
    "announce_chain_cat = announce_chain Cat"

(* Part 2: two independent direct superclasses on the same class *)

class labeled =
    fixes label_of :: "'a \<Rightarrow> String.literal"

class measured =
    fixes size_label :: "'a \<Rightarrow> String.literal"

class labeled_measured = labeled + measured +
    fixes full_description :: "'a \<Rightarrow> String.literal"

datatype item = Box | Crate

instantiation item :: labeled
begin
    fun label_of_item :: "item \<Rightarrow> String.literal" where
        "label_of_item Box = STR ''box''" |
        "label_of_item Crate = STR ''crate''"
    instance ..
end

instantiation item :: measured
begin
    fun size_label_item :: "item \<Rightarrow> String.literal" where
        "size_label_item Box = STR ''small''" |
        "size_label_item Crate = STR ''large''"
    instance ..
end

instantiation item :: labeled_measured
begin
    fun full_description_item :: "item \<Rightarrow> String.literal" where
        "full_description_item Box = STR ''a plain cardboard box''" |
        "full_description_item Crate = STR ''a sturdy wooden crate''"
    instance ..
end

definition announce_multi :: "'a :: labeled_measured \<Rightarrow> String.literal" where
    "announce_multi x = label_of x + STR '' ('' + size_label x + STR '') -- '' + full_description x"

definition announce_multi_box :: String.literal where
    "announce_multi_box = announce_multi Box"

export_code announce_chain announce_chain_cat announce_multi announce_multi_box
  in Python file_prefix "."

end