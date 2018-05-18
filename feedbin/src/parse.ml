open Base

type error = [ `Parse_error of string ]
[@@deriving compare, sexp]

type 'a result = ('a, error) Result.t
[@@deriving compare, sexp]

let try_parse f s =
  try
    Ok (f s)
  with e ->
    Error (`Parse_error (Exn.to_string e))