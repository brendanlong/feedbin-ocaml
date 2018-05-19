open Base
open Feedbin_types

type t = Feed.t
[@@deriving compare, sexp_of]

val get_by_id : Client.t -> int -> (t option, [> Client.error | parse_error ]) Lwt_result.t