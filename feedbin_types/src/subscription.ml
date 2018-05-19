open Base

type t = Subscription_t.subscription =
  { id : int
  ; created_at : Datetime.t
  ; feed_id : int
  ; title : string
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

type create = Subscription_t.create =
  { feed_url : string }
[@@deriving compare, sexp_of]

type multiple_option = Subscription_t.multiple_option =
  { feed_url : Uri.t
  ; title : string }
[@@deriving compare, sexp_of]

type update = Subscription_t.update =
  { title : string }
[@@deriving compare, sexp_of]

let of_string = Parse.try_parse Subscription_j.subscription_of_string

let to_string s = Subscription_j.string_of_subscription s

let list_of_string = Parse.try_parse Subscription_j.subscriptions_of_string

let list_to_string s = Subscription_j.string_of_subscriptions s

let create_of_string = Parse.try_parse Subscription_j.create_of_string

let create_to_string s = Subscription_j.string_of_create s

let multiple_options_of_string = Parse.try_parse Subscription_j.multiple_options_of_string

let multiple_options_to_string s = Subscription_j.string_of_multiple_options s

let update_of_string = Parse.try_parse Subscription_j.update_of_string

let update_to_string s = Subscription_j.string_of_update s

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
