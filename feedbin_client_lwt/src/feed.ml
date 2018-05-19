open Base
open Lwt.Infix
open Feedbin_types

type t = Feed.t
[@@deriving compare, sexp_of]

let get_by_id client id =
  let path = Printf.sprintf "/v2/feeds/%d.json" id in
  Client.get_opt client ~path Feed.of_string