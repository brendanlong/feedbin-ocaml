open Base
open Lwt.Infix

type error = [ `Unexpected_status of (string * int) ]
[@@deriving compare, sexp_of]

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

let call ?data method_ ?(ok_status=`OK) ({ host ; user } as t) path =
  let uri = Uri.with_path host path in
  let headers = make_headers t in
  Cohttp_lwt_unix.Client.call ~headers method_ uri
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK ->
    Cohttp_lwt.Body.to_string body
    >|= Result.return
  | `Unauthorized ->
    Lwt.return_error (`Unauthorized (path, user))
  | status ->
    Lwt.return_error (`Unexpected_status (path, Cohttp.Code.code_of_status status))

let get = call `GET
let delete = call `POST
let patch t path data = call ~data `PATCH t path

let check_auth t =
  let path = "/v2/authentication.json" in
  get t path
  >|= function
  | Ok _ -> Ok true
  | Error (`Unauthorized _) -> Ok false
  | Error e -> Error e