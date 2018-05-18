open Base

type t = Subscription_t.subscription =
  { id : int
  ; created_at : Ptime.t
  ; feed_id : int
  ; title : string
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

type multiple_option =
  { feed_url : Uri.t
  ; title : string }
[@@deriving compare, sexp_of]

type multiple_options =
  [ `Multiple_options of multiple_option list ]
[@@deriving compare, sexp_of]

val of_string : string -> (t, [> Parse.error ]) Result.t
val get_by_id : Client.t -> int -> (t option, [> Client.error | Parse.error ]) Lwt_result.t
val get_all : Client.t -> (t list, [> Client.error | Parse.error ]) Lwt_result.t
val create_for_url : Client.t -> string -> (t option, [> Client.error | Parse.error | multiple_options ]) Lwt_result.t
val delete_by_id : Client.t -> int -> (unit, [> Client.error ]) Lwt_result.t
val set_title : Client.t -> int -> string -> (t, [> Client.error | Parse.error ]) Lwt_result.t