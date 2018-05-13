open Base

type t [@@deriving compare, sexp_of]

val of_string : string -> t Or_error.t
val list_of_string : string -> t list Or_error.t

val fetch_by_id : Client.t -> int -> t option Lwt.t
val fetch_all : Client.t -> t list Lwt.t