open Base
open Feedbin_types

type t = Entry.t
[@@deriving compare, sexp_of]

val get_by_id
  : Client.t
  -> int
  -> (t option, [> Client.error | parse_error ]) Lwt_result.t

type 'a entries_options =
  ?page:int
  -> ?since:Ptime.t
  -> ?starred:bool
  -> ?per_page:int
  -> ?extended:bool
  -> ?include_original:bool
  -> ?include_enclosure:bool
  -> ?include_content_diff:bool
  -> 'a

val get_all
  : (?ids:int list
     -> Client.t
     -> (t list, [> Client.error | parse_error ]) Lwt_result.t) entries_options

val get_all_for_feed_id
  : (Client.t
     -> int
     -> (t list, [> Client.error | parse_error ]) Lwt_result.t) entries_options