module Entry = Entry
module Feed = Feed
module Subscription = Subscription

type parse_error = Parse.error
[@@deriving compare, sexp_of]