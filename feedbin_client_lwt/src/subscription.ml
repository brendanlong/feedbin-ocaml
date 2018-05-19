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
  Client.get_opt client ~path Subscription.of_string

let get_all client =
  let path = "/v2/subscriptions.json" in
  Client.get client ~path Subscription.list_of_string

let create_for_url client feed_url =
  let path = "/v2/subscriptions.json" in
  let data =
    { Subscription.feed_url }
    |> Subscription.create_to_string
  in
  Client.call ~data ~ok_statuses:[ `Created ; `Found ; `Not_found ] `POST client
    ~path
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
  Client.call ~ok_statuses:[ `No_content ] `GET client ~path
  >|= Result.map ~f:ignore

let set_title client id title =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  let data =
    { Subscription.title }
    |> Subscription.update_to_string
  in
  Client.call ~data `PATCH client ~path
  >|= Result.map ~f:snd
  >|= Result.bind ~f:Subscription.of_string