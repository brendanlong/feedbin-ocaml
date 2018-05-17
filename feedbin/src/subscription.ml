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

let to_string = Subscription_j.string_of_subscription

let of_string s =
  Or_error.try_with @@ fun () ->
  Subscription_j.subscription_of_string s

let list_of_string s =
  Or_error.try_with @@ fun () ->
  Subscription_j.subscriptions_of_string s

let get_by_id client id =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  Client.get client path
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK ->
    Cohttp_lwt.Body.to_string body
    >|= of_string
    >|= Or_error.ok_exn
    >|= Option.return
  | `Not_found ->
    Lwt.return None
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith

let get_all client =
  let path = "/v2/subscriptions.json" in
  Client.get client path
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK ->
    Cohttp_lwt.Body.to_string body
    >|= list_of_string
    >|= Or_error.ok_exn
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith

let delete_by_id client id =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  Client.delete client path
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `No_content ->
    Lwt.return_unit
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith

let set_title client id title =
  let path = Printf.sprintf "/v2/subscriptions/%d.json" id in
  { Subscription_t.title }
  |> Subscription_j.string_of_update
  |> Client.patch client path
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK ->
    Cohttp_lwt.Body.to_string body
    >|= of_string
    >|= Or_error.ok_exn
    >|= Option.return
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith

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
  |> [%test_result: t list Or_error.t] ~expect


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
  |> [%test_result: t Or_error.t] ~expect
