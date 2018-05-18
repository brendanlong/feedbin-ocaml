open Sexplib.Conv

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
  ; password : string }
[@@deriving sexp_of]

val make : ?host:Uri.t -> user:string -> password:string -> unit -> t    

val get : ?ok_status: Cohttp.Code.status_code -> t -> string -> (string, [> error ]) Lwt_result.t
val delete : ?ok_status: Cohttp.Code.status_code -> t -> string -> (string, [> error ]) Lwt_result.t
val patch : ?ok_status: Cohttp.Code.status_code -> t -> string -> string -> (string, [> error ]) Lwt_result.t

val check_auth : t -> (bool, [> error ]) Lwt_result.t