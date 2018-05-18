open Base

type t = Feed_t.feed =
  { id : int
  ; title : string option
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

val of_string : string -> (t, [> Parse.error ]) Result.t

val get_by_id : Client.t -> int -> (t option, [> Client.error | Parse.error ]) Lwt_result.t