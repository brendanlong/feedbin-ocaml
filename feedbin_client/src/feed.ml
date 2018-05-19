open Base
open Lwt.Infix
open Feedbin_types

type t = Feed.t
[@@deriving compare, sexp_of]

let get_by_id client id =
  let path = Printf.sprintf "/v2/feeds/%d.json" id in
  Client.get client path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `OK ->
        Feed.of_string body
        |> Result.map ~f:Option.return
      | _ -> assert false)
