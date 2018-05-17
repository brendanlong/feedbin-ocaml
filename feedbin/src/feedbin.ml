module Entry = Entry
module Feed = Feed
module Subscription = Subscription

type t = Client.t [@@deriving sexp_of]

let make = Client.make

let check_auth = Client.check_auth