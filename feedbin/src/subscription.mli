open Base

type t = Subscription_t.subscription =
  { id : int
  ; created_at : Ptime.t
  ; feed_id : int
  ; title : string
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

val of_string : string -> t Or_error.t
val get_by_id : Client.t -> int -> t option Lwt.t
val get_all : Client.t -> t list Lwt.t
(* TODO: Create - https://github.com/feedbin/feedbin-api/blob/master/content/subscriptions.md#create-subscription *)
val delete_by_id : Client.t -> int -> unit Lwt.t
val set_title : Client.t -> int -> string -> t option Lwt.t