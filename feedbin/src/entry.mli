open Base

type t [@@deriving compare, sexp_of]

val of_string : string -> t Or_error.t
val list_of_string : string -> t list Or_error.t