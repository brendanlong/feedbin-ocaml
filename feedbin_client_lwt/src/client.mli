open Sexplib.Conv

type unauthorized =
  { path : string
  ; user : string }
[@@deriving compare, sexp_of]

type unexpected_status =
  { path : string
  ; expected : int list
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

val get : ?ok_statuses:Cohttp.Code.status_code list -> t -> string -> (Cohttp.Code.status_code * string, [> error ]) Lwt_result.t
val delete : ?ok_statuses:Cohttp.Code.status_code list -> t -> string -> (Cohttp.Code.status_code * string, [> error ]) Lwt_result.t
val patch : ?ok_statuses:Cohttp.Code.status_code list -> t -> string -> string -> (Cohttp.Code.status_code * string, [> error ]) Lwt_result.t
val post : ?ok_statuses:Cohttp.Code.status_code list -> t -> string -> string -> (Cohttp.Code.status_code * string, [> error ]) Lwt_result.t

val check_auth : t -> (bool, [> error ]) Lwt_result.t