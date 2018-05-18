open Base
open Lwt
open Lwt_io

open Feedbin

let main () =
  print "User: "
  >>= fun () ->
  let%lwt user = read_line stdin in
  print "Password: "
  >>= fun () ->
  let%lwt password = read_line stdin in
  let client = make ~user ~password () in
  check_auth client 
  >>= function
  | Error e ->
    printlf !"Error checking auth: %{sexp: Result.error}" e
  | Ok false ->
    printl "Auth failed"
  | Ok true ->
    printl "Auth succeeded"
    >>= fun () ->
    Entry.get_all client
    >>= printlf !"Entries:\n%{sexp: Entry.t list Result.t}"

let () =
  Lwt_main.run @@ main ()