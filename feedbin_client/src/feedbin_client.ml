module Entry = Entry
module Feed = Feed
module Subscription = Subscription

type error = [ Client.error | Feedbin_types.parse_error ]
[@@deriving compare, sexp_of]

type 'a result = ('a, error) Base.Result.t
[@@deriving compare, sexp_of]

type t = Client.t [@@deriving sexp_of]

let make = Client.make

let check_auth = Client.check_auth