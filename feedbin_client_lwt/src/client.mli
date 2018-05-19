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

val call
  : ?ok_statuses:Cohttp.Code.status_code list
  -> ?data:string
  -> Cohttp.Code.meth
  -> t
  -> path:string
  -> (Cohttp.Code.status_code * string, [> error]) Lwt_result.t

val get
  : t
  -> path:string
  -> (string -> ('res, [> error ] as 'err) Base.Result.t)
  -> ('res, 'err) Lwt_result.t

val get_opt
  : t
  -> path:string
  -> (string -> ('res, [> error ] as 'err) Base.Result.t)
  -> ('res option, 'err) Lwt_result.t

val check_auth : t -> (bool, [> error ]) Lwt_result.t