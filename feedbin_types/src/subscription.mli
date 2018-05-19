open Base

type t = Subscription_t.subscription =
  { id : int
  ; created_at : Ptime.t
  ; feed_id : int
  ; title : string
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

type create = Subscription_t.create =
  { feed_url : string }
[@@deriving compare, sexp_of]

type multiple_option = Subscription_t.multiple_option =
  { feed_url : Uri.t
  ; title : string }
[@@deriving compare, sexp_of]

type update = Subscription_t.update =
  { title : string }
[@@deriving compare, sexp_of]

val of_string : string -> (t, [> Parse.error]) Result.t
val to_string : t -> string

val list_of_string : string -> (t list, [> Parse.error]) Result.t
val list_to_string : t list -> string

val create_of_string : string -> (create, [> Parse.error]) Result.t
val create_to_string : create -> string

val multiple_options_of_string : string -> (multiple_option list, [> Parse.error]) Result.t
val multiple_options_to_string : multiple_option list -> string

val update_of_string : string -> (update, [> Parse.error]) Result.t
val update_to_string : update -> string