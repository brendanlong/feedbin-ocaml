open Base
open Lwt.Infix
open Feedbin_types

type t = Entry.t
[@@deriving compare, sexp_of]

let get_by_id client id =
  let path = Printf.sprintf "/v2/entries/%d.json" id in
  Client.get ~ok_statuses:[ `OK ; `Not_found ] client path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `OK ->
        Entry.of_string body
        |> Result.map ~f:Option.return
      | _ -> assert false)

let get_all client =
  let path = "/v2/entries.json" in
  Client.get client path
  >|= Result.map ~f:snd
  >|= Result.bind ~f:Entry.list_of_string
