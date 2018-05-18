open Base
open Lwt.Infix

type unauthorized =
  { path : string
  ; user : string }
[@@deriving compare, sexp_of]

type unexpected_status =
  { path : string
  ; expected : int
  ; got : int }
[@@deriving compare, sexp_of]

type error =
  [ `Unauthorized of unauthorized
  | `Unexpected_status of unexpected_status ]
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

let call ?(ok_status=`OK) ?data method_ ({ host ; user } as t) path =
  let uri = Uri.with_path host path in
  let headers = make_headers t in
  Cohttp_lwt_unix.Client.call ~headers method_ uri
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | st when Cohttp.Code.(code_of_status st = code_of_status ok_status) ->
    Cohttp_lwt.Body.to_string body
    >|= Result.return
  | `Unauthorized ->
    Lwt.return_error (`Unauthorized { path ; user })
  | status ->
    Lwt.return_error
      (`Unexpected_status { path
                          ; expected = Cohttp.Code.code_of_status ok_status
                          ; got = Cohttp.Code.code_of_status status })

let get ?ok_status = call ?ok_status `GET
let delete ?ok_status = call ?ok_status `POST
let patch ?ok_status t path data = call ?ok_status ~data `PATCH t path

let check_auth t =
  let path = "/v2/authentication.json" in
  get t path
  >|= function
  | Ok _ -> Ok true
  | Error (`Unauthorized _) -> Ok false
  | Error e -> Error e