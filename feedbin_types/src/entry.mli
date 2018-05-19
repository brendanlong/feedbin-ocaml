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

val of_string : string -> (t, [> Parse.error]) Result.t
val to_string : t -> string

val list_of_string : string -> (t list, [> Parse.error]) Result.t
val list_to_string : t list -> string