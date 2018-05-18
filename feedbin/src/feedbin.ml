module Entry = Entry
module Feed = Feed
module Subscription = Subscription

module Result = struct
  type error = [ | Client.error | Parse.error ]
  [@@deriving compare, sexp_of]

  type 'a t = ('a, error) Base.Result.t
  [@@deriving compare, sexp_of]
end

type t = Client.t [@@deriving sexp_of]

let make = Client.make

let check_auth = Client.check_auth