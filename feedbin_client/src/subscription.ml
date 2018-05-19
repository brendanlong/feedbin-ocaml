open Base
open Lwt.Infix
open Feedbin_types

type t = Subscription.t
[@@deriving compare, sexp_of]

type multiple_option = Subscription.multiple_option =
  { feed_url : Uri.t
  ; title : string }
[@@deriving compare, sexp_of]

type multiple_options =
  [ `Multiple_options of multiple_option list ]
[@@deriving compare, sexp_of]

let get_by_id client id =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  Client.get client path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `OK ->
        Subscription.of_string body
        |> Result.map ~f:Option.return
      | _ -> assert false)

let get_all client =
  let path = "/v2/subscriptions.json" in
  Client.get client path
  >|= Result.map ~f:snd
  >|= Result.bind ~f:Subscription.list_of_string

let create_for_url client feed_url =
  let path = "/v2/subscriptions.json" in
  { Subscription.feed_url }
  |> Subscription.create_to_string
  |> Client.post ~ok_statuses:[ `Created ; `Found ; `Not_found ] client path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `Found
      | `Created ->
        Subscription.of_string body
        |> Result.map ~f:Option.return
      | `Multiple_choices ->
        Subscription.multiple_options_of_string body
        |> Result.bind ~f:(fun options ->
            Error (`Multiple_options options))
      | _ -> assert false)

let delete_by_id client id =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  Client.delete ~ok_statuses:[ `No_content ] client path
  >|= Result.map ~f:ignore

let set_title client id title =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  { Subscription.title }
  |> Subscription.update_to_string
  |> Client.patch client path
  >|= Result.map ~f:snd
  >|= Result.bind ~f:Subscription.of_string