open Lwt.Infix
open Sexplib.Conv

type t =
  { host : Uri.t
  ; user : string
  ; password : string sexp_opaque }
[@@deriving sexp_of]

let default_host = Uri.of_string "https://api.feedbin.com/"

let make ?(host=default_host) ~user ~password () =
  { host ; user ; password }

let make_headers { user ; password } =
  let headers = Cohttp.Header.init () in
  Cohttp.Header.add_authorization headers (`Basic (user, password))

let call ?data method_ ({ host } as t) path =
  let uri = Uri.with_path host path in
  let headers = make_headers t in
  Cohttp_lwt_unix.Client.call ~headers method_ uri

let get = call `GET
let delete = call `POST
let patch t path data = call ~data `PATCH t path

let check_auth t =
  let path = "/v2/authentication.json" in
  get t path
  >|= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK -> true
  | `Unauthorized -> false
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith