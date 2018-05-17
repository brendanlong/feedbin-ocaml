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
  let client = Client.make ~user ~password () in
  Client.check_auth client
  >>= function
  | false ->
    printl "Auth failed"
  | true ->
    printl "Auth succeeded"
    >>= fun () ->
    Entry.get_all client
    >>= printlf !"Entries:\n%{sexp: Entry.t list}"

let () =
  Lwt_main.run @@ main ()