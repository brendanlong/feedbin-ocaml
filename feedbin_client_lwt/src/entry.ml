open Base
open Lwt.Infix
open Feedbin_types

type t = Entry.t
[@@deriving compare, sexp_of]

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

let get_by_id client id =
  let path = Printf.sprintf "/v2/entries/%d.json" id in
  Client.get_opt client ~path Entry.of_string

let make_query ?page ?since ?starred ?per_page ?extended ?include_original
    ?include_enclosure ?include_content_diff () =
  let map_one v f = Option.map v ~f:(fun v -> [f v]) in
  let map_bool v = map_one v Bool.to_string in
  let map_int v = map_one v Int.to_string in
  [ "page", map_int page
  ; "since", map_one since Ptime.to_rfc3339
  ; "starred", map_bool starred
  ; "per_page", map_int per_page
  ; "extended", map_bool extended
  ; "include_original", map_bool include_original
  ; "include_enclosure", map_bool include_enclosure
  ; "include_content_diff", map_bool include_content_diff ]
  |> List.filter_map ~f:(fun (name, value) ->
      Option.map value ~f:(fun value ->
          name, value))

let get_all ?page ?since ?starred ?per_page ?extended ?include_original
    ?include_enclosure ?include_content_diff ?ids client =
  let path = "/v2/entries.json" in
  let query =
    let base_query =
      make_query ?page ?since ?starred ?per_page ?extended
        ?include_original ?include_enclosure ?include_content_diff ()
    in
    match ids with
    | None -> base_query
    | Some ids ->
      ("ids", List.map ids ~f:Int.to_string)
      :: base_query
  in
  Client.get ~query client ~path Entry.list_of_string

let get_all_for_feed_id ?page ?since ?starred ?per_page ?extended
    ?include_original ?include_enclosure ?include_content_diff client id =
  let path = Printf.sprintf "/v2/feeds/%d/entries.json" id in
  let query = make_query ?page ?since ?starred ?per_page ?extended
      ?include_original ?include_enclosure ?include_content_diff ()
  in
  Client.get ~query client ~path Entry.list_of_string