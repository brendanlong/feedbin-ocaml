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
  ; password : string }
[@@deriving sexp_of]

val make : ?host:Uri.t -> user:string -> password:string -> unit -> t    

val call
  : ?query:(string * string list) list
  -> ?data:string
  -> ok_statuses:([< Cohttp.Code.status_code ] as 'status) list
  -> Cohttp.Code.meth
  -> t
  -> path:string
  -> ('status * string, [> error]) Lwt_result.t

val get
  : ?query:(string * string list) list
  -> t
  -> path:string
  -> (string -> ('res, [> error ] as 'err) Base.Result.t)
  -> ('res, 'err) Lwt_result.t

val get_opt
  : ?query:(string * string list) list
  -> t
  -> path:string
  -> (string -> ('res, [> error ] as 'err) Base.Result.t)
  -> ('res option, 'err) Lwt_result.t

val check_auth : t -> (bool, [> error ]) Lwt_result.t