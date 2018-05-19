open Base
open Feedbin_types

type t = Subscription.t
[@@deriving compare, sexp_of]

type multiple_option =
  { feed_url : Uri.t
  ; title : string }
[@@deriving compare, sexp_of]

type multiple_options = 
  [ `Multiple_options of multiple_option list ]
[@@deriving compare, sexp_of]

val get_by_id : Client.t -> int -> (t option, [> Client.error | parse_error ]) Lwt_result.t
val get_all : ?since:Ptime.t -> Client.t -> (t list, [> Client.error | parse_error ]) Lwt_result.t
val create_for_url : Client.t -> string -> (t option, [> Client.error | parse_error | multiple_options ]) Lwt_result.t
val delete_by_id : Client.t -> int -> (unit, [> Client.error ]) Lwt_result.t
val set_title : Client.t -> int -> string -> (t, [> Client.error | parse_error ]) Lwt_result.t