open Base
open Feedbin_types

type t = Entry.t
[@@deriving compare, sexp_of]

val get_by_id : Client.t -> int -> (t option, [> Client.error | parse_error ]) Lwt_result.t
val get_all : Client.t -> (t list, [> Client.error | parse_error ]) Lwt_result.t