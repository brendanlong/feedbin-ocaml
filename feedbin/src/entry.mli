open Base

type t = Entry_t.entry =
  { id : int
  ; feed_id : int
  ; title : string option
  ; url : Uri.t
  ; author : string option
  ; content : string option
  ; summary : string option
  ; published : Ptime.t
  ; created_at : Ptime.t }
[@@deriving compare, sexp_of]

val of_string : string -> t Parse.result
val list_of_string : string -> t list Parse.result 

val get_by_id : Client.t -> int -> (t option, [ | Client.error | Parse.error ]) Lwt_result.t
val get_all : Client.t -> (t list, [ | Client.error | Parse.error ]) Lwt_result.t