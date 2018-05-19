type t = Uri.t [@@deriving compare, sexp_of]

val wrap : string -> t
val unwrap : t -> string