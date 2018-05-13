open Base

type t = Uri.t [@@deriving compare, sexp_of]

let wrap = Uri.of_string

let unwrap = Uri.to_string