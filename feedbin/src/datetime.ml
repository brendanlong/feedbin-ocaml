type t = Ptime.t [@@deriving compare]

let of_string_exn s =
  Ptime.of_rfc3339 s
  |> Ptime.rfc3339_error_to_msg
  |> function
  | Ok (t, _, _) -> t
  | Error (`Msg e) ->
    Printf.sprintf "Failed to parse %s as an RFC 3339 timestamp: %s" s e
    |> failwith

let to_string s =
  Ptime.to_rfc3339 ~frac_s:4 s

let sexp_of_t t =
  to_string t
  |> Sexplib.Sexp.of_string

let wrap = of_string_exn

let unwrap = to_string