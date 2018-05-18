open Sexplib.Conv

type error =
  [ `Unauthorized of (string * string)
  | `Unexpected_status of (string * int) ]
[@@deriving compare, sexp_of]

type t =
  { host : Uri.t
  ; user : string
  ; password : string }
[@@deriving sexp_of]

val make : ?host:Uri.t -> user:string -> password:string -> unit -> t    

val get : t -> string -> (string, error) Lwt_result.t
val delete : t -> string -> (string, error) Lwt_result.t
val patch : t -> string -> string -> (string, error) Lwt_result.t

val check_auth : t -> bool Lwt.t