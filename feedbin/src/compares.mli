(** Exposing this as a module for Atdgen to be able to derive compare. Ideally,
    we would just [open Base], but that messed up [=] *)
val compare_int : int -> int -> int
val compare_option : ('a -> 'a -> int) -> 'a option -> 'a option -> int
val compare_string : string -> string -> int
val compare_list : ('a -> 'a -> int) -> 'a list -> 'a list -> int