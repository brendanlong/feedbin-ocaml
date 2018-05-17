open Sexplib.Conv

type t =
  { host : Uri.t
  ; user : string
  ; password : string }
[@@deriving sexp_of]

val make : ?host:Uri.t -> user:string -> password:string -> unit -> t    

val get : t -> string -> (Cohttp_lwt.Response.t * Cohttp_lwt.Body.t) Lwt.t
val delete : t -> string -> (Cohttp_lwt.Response.t * Cohttp_lwt.Body.t) Lwt.t
val patch : t -> string -> string -> (Cohttp_lwt.Response.t * Cohttp_lwt.Body.t) Lwt.t

val check_auth : t -> bool Lwt.t