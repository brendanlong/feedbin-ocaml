open Base
open Lwt.Infix

type t = Subscription_t.subscription =
  { id : int
  ; created_at : Datetime.t
  ; feed_id : int
  ; title : string
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

type multiple_option = Subscription_j.multiple_option =
  { feed_url : Uri.t
  ; title : string }
[@@deriving compare, sexp_of]

type multiple_options =
  [ `Multiple_options of multiple_option list ]
[@@deriving compare, sexp_of]

let to_string = Subscription_j.string_of_subscription

let of_string = Parse.try_parse Subscription_j.subscription_of_string

let list_of_string = Parse.try_parse Subscription_j.subscriptions_of_string

let get_by_id client id =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  Client.get client path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `OK ->
        of_string body
        |> Result.map ~f:Option.return
      | _ -> assert false)

let get_all client =
  let path = "/v2/subscriptions.json" in
  Client.get client path
  >|= Result.map ~f:snd
  >|= Result.bind ~f:list_of_string

let create_for_url client feed_url =
  let path = "/v2/subscriptions.json" in
  { Subscription_t.feed_url }
  |> Subscription_j.string_of_create
  |> Client.post ~ok_statuses:[ `Created ; `Found ; `Not_found ] client path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `Found
      | `Created ->
        of_string body
        |> Result.map ~f:Option.return
      | `Multiple_choices ->
        Parse.try_parse Subscription_j.multiple_options_of_string body
        |> Result.bind ~f:(fun options ->
            Error (`Multiple_options options))
      | _ -> assert false)

let delete_by_id client id =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  Client.delete ~ok_statuses:[ `No_content ] client path
  >|= Result.map ~f:ignore

let set_title client id title =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  { Subscription_t.title }
  |> Subscription_j.string_of_update
  |> Client.patch client path
  >|= Result.map ~f:snd
  >|= Result.bind ~f:of_string

let%test_unit "get example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/subscriptions.md#get-subscriptions *)
  let expect =
    Ok [{ id = 525
        ; feed_id = 47
        ; title = "Daring Fireball"
        ; created_at = Datetime.of_string_exn "2013-03-12T11:30:25.209432Z"
        ; feed_url = Uri.of_string "http://daringfireball.net/index.xml"
        ; site_url = Uri.of_string "http://daringfireball.net/" }]
  in
  {|
    [
      {
        "id": 525,
        "created_at": "2013-03-12T11:30:25.209432Z",
        "feed_id": 47,
        "title": "Daring Fireball",
        "feed_url": "http://daringfireball.net/index.xml",
        "site_url": "http://daringfireball.net/"
      }
    ]
  |}
  |> list_of_string
  |> [%test_result: t list Parse.result] ~expect


let%test_unit "get single example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/subscriptions.md#get-subscription *)
  let expect =
    Ok { id = 525
       ; feed_id = 47
       ; title = "Daring Fireball"
       ; created_at = Datetime.of_string_exn "2013-03-12T11:30:25.209432Z"
       ; feed_url = Uri.of_string "http://daringfireball.net/index.xml"
       ; site_url = Uri.of_string "http://daringfireball.net/" }
  in
  {|
    {
      "id": 525,
      "created_at": "2013-03-12T11:30:25.209432Z",
      "feed_id": 47,
      "title": "Daring Fireball",
      "feed_url": "http://daringfireball.net/index.xml",
      "site_url": "http://daringfireball.net/"
    }
  |}
  |> of_string
  |> [%test_result: t Parse.result] ~expect
