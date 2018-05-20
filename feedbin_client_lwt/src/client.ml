open Base
open Lwt.Infix

type unauthorized =
  { path : string
  ; user : string }
[@@deriving compare, sexp_of]

type unexpected_status =
  { path : string
  ; expected : Cohttp.Code.status_code list
  ; got : Cohttp.Code.status_code }
[@@deriving sexp_of]

type error =
  [ `Unauthorized of unauthorized
  | `Unexpected_status of unexpected_status ]
[@@deriving sexp_of]

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

let call ?(query=[]) ?data ~ok_statuses method_ ({ host ; user } as t) ~path =
    let uri =
      Uri.with_path host path
      |> Fn.flip Uri.with_query query
    in
    let headers = make_headers t in
    let body = Option.map data ~f:Cohttp_lwt.Body.of_string in
    Cohttp_lwt_unix.Client.call ?body ~headers method_ uri
    >>= fun (res, body) ->
    let status = Cohttp_lwt.Response.status res
    and subtype_equal = fun x y -> Poly.equal x (y :> Cohttp.Code.status_code)
    in
    List.find ok_statuses ~f:(subtype_equal status)
    |> function
    | Some status ->
      Cohttp_lwt.Body.to_string body
      >|= fun body ->
      Ok (status, body)
    | None ->
      match status with
      | `Unauthorized ->
        Lwt.return_error (`Unauthorized { path ; user })
      | status ->
        Lwt.return_error
          (`Unexpected_status { path
                              ; expected =
                                  (ok_statuses :> Cohttp.Code.status_code list)
                              ; got = status })

let get ?query t ~path f =
  call ?query ~ok_statuses:[ `OK ] `GET t ~path
  >|= Result.bind ~f:(fun (`OK, body) -> f body)

let get_opt ?query t ~path f =
  call ~ok_statuses:[ `OK ; `Not_found ] `GET t ~path
  >|= Result.bind ~f:(fun (status, body) ->
      match status with
      | `Not_found -> Ok None
      | `OK ->
        f body
        |> Result.map ~f:Option.return)

let check_auth t =
  let path = "/v2/authentication.json" in
  call ~ok_statuses:[ `OK ; `Unauthorized ] `GET t ~path
  >|= Result.bind ~f:(
    function
    | `OK, _ -> Ok true
    | `Unauthorized, _ -> Ok false)