open Base
open Lwt.Infix

type t = Feed_t.feed =
  { id : int
  ; title : string option
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

let of_string = Parse.try_parse Feed_j.feed_of_string

let get_by_id client id =
  let path = Printf.sprintf "/v2/feeds/%d.json" id in
  Client.get client path
  >|= Result.bind ~f:of_string
  >|= Result.map ~f:Option.return
  >|= function
  | Error (`Unexpected_status { got = 404 }) -> Ok None
  | v -> v

let%test_unit "parse example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/feeds.md#get-feed *)
  let expect =
    Ok { id = 1
       ; title = Some "Ben Ubois"
       ; feed_url = Uri.of_string "http://feeds.feedburner.com/benubois"
       ; site_url = Uri.of_string "http://benubois.com" }
  in
  {|
    {
      "id": 1,
      "title": "Ben Ubois",
      "feed_url": "http:\/\/feeds.feedburner.com\/benubois",
      "site_url": "http:\/\/benubois.com"
    }
  |}
  |> of_string
  |> [%test_result: t Parse.result] ~expect
