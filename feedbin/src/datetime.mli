(** A wrapper for Ptime with atdgen wrappers sexp *)
type t = Ptime.t [@@deriving compare, sexp_of]

val of_string_exn : string -> t
val to_string : t -> string

(* for atdgen *)
val wrap : string -> t
val unwrap : t -> string