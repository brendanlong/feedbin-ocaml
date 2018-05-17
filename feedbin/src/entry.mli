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

val of_string : string -> t Or_error.t
val list_of_string : string -> t list Or_error.t

val get_by_id : Client.t -> int -> t option Lwt.t
val get_all : Client.t -> t list Lwt.t