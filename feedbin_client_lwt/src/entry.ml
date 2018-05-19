open Base
open Lwt.Infix
open Feedbin_types

type t = Entry.t
[@@deriving compare, sexp_of]

let get_by_id client id =
  let path = Printf.sprintf "/v2/entries/%d.json" id in
  Client.get_opt client ~path Entry.of_string

let get_all client =
  let path = "/v2/entries.json" in
  Client.get client ~path Entry.list_of_string
