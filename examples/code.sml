structure List : sig
  val map : ('a -> 'b) -> 'a list -> 'b list
end = struct

fun map f [] = []
  | map f (x21 :: x22) = f x21 :: map f x22;

end; (*struct List*)

structure Arith : sig
  datatype num = One | Bit0 of num | Bit1 of num
  datatype int = Zero_int | Pos of num | Neg of num
  val plus_int : int -> int -> int
end = struct

datatype num = One | Bit0 of num | Bit1 of num;

datatype int = Zero_int | Pos of num | Neg of num;

fun dup Zero_int = Zero_int
  | dup (Pos n) = Pos (Bit0 n)
  | dup (Neg n) = Neg (Bit0 n);

fun uminus_int Zero_int = Zero_int
  | uminus_int (Pos m) = Neg m
  | uminus_int (Neg m) = Pos m;

fun plus_num One One = Bit0 One
  | plus_num One (Bit0 n) = Bit1 n
  | plus_num One (Bit1 n) = Bit0 (plus_num n One)
  | plus_num (Bit0 m) One = Bit1 m
  | plus_num (Bit0 m) (Bit0 n) = Bit0 (plus_num m n)
  | plus_num (Bit0 m) (Bit1 n) = Bit1 (plus_num m n)
  | plus_num (Bit1 m) One = Bit0 (plus_num m One)
  | plus_num (Bit1 m) (Bit0 n) = Bit1 (plus_num m n)
  | plus_num (Bit1 m) (Bit1 n) = Bit0 (plus_num (plus_num m n) One);

fun bitM One = One
  | bitM (Bit0 n) = Bit1 (bitM n)
  | bitM (Bit1 n) = Bit1 (Bit0 n);

fun sub One One = Zero_int
  | sub (Bit0 m) One = Pos (bitM m)
  | sub (Bit1 m) One = Pos (Bit0 m)
  | sub One (Bit0 n) = Neg (bitM n)
  | sub One (Bit1 n) = Neg (Bit0 n)
  | sub (Bit0 m) (Bit0 n) = dup (sub m n)
  | sub (Bit1 m) (Bit1 n) = dup (sub m n)
  | sub (Bit1 m) (Bit0 n) = plus_int (dup (sub m n)) (Pos One)
  | sub (Bit0 m) (Bit1 n) = minus_int (dup (sub m n)) (Pos One)
and plus_int k Zero_int = k
  | plus_int Zero_int l = l
  | plus_int (Pos m) (Pos n) = Pos (plus_num m n)
  | plus_int (Pos m) (Neg n) = sub m n
  | plus_int (Neg m) (Pos n) = sub n m
  | plus_int (Neg m) (Neg n) = Neg (plus_num m n)
and minus_int k Zero_int = k
  | minus_int Zero_int l = uminus_int l
  | minus_int (Pos m) (Pos n) = sub m n
  | minus_int (Pos m) (Neg n) = Pos (plus_num m n)
  | minus_int (Neg m) (Pos n) = Neg (plus_num m n)
  | minus_int (Neg m) (Neg n) = sub n m;

end; (*struct Arith*)

structure Example_partial : sig
  val p_mapped : Arith.int list
end = struct

fun add2 x y = Arith.plus_int x y;

fun add_one x = add2 (Arith.Pos Arith.One) x;

val p_mapped : Arith.int list =
  List.map add_one
    [Arith.Pos Arith.One, Arith.Pos (Arith.Bit0 Arith.One),
      Arith.Pos (Arith.Bit1 Arith.One)];

end; (*struct Example_partial*)
