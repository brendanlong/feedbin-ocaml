open Base
open Lwt.Infix

type t = Feed_t.feed =
  { id : int
  ; title : string option
  ; feed_url : Uri.t
  ; site_url : Uri.t }
[@@deriving compare, sexp_of]

let of_string s =
  Or_error.try_with @@ fun () ->
  Feed_j.feed_of_string s

let get_by_id client id =
  let path = Printf.sprintf "/v2/entries/%d.json" id in
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
  |> [%test_result: t Or_error.t] ~expect
