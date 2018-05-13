open Base
open Lwt

open Entry_t

type t = entry [@@deriving compare, sexp_of]

let of_string s =
  Or_error.try_with @@ fun () ->
  Entry_j.entry_of_string s

let list_of_string s =
  Or_error.try_with @@ fun () ->
  Entry_j.entries_of_string s

let fetch_by_id client id =
  let path = Printf.sprintf "/v2/entries/%d.json" id in
  Client.get client path
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK ->
    Cohttp_lwt.Body.to_string body
    >|= of_string
    >|= Or_error.ok_exn
    >|= Option.return
  | `Not_found ->
    return None
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith

let fetch_all client =
  let path = "/v2/entries.json" in
  Client.get client path
  >>= fun (res, body) ->
  match Cohttp_lwt.Response.status res with
  | `OK ->
    Cohttp_lwt.Body.to_string body
    >|= list_of_string
    >|= Or_error.ok_exn
  | status ->
    Cohttp.Code.string_of_status status
    |> Printf.sprintf "Unexpected status for %s: %s" path
    |> failwith

let%test_unit "parse first entries example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#entries *)
  let expect =
    Ok [{ id = 2077
        ; feed_id = 135
        ; title = Some "Objective-C Runtime Releases"
        ; url = Uri.of_string "http://mjtsai.com/blog/2013/02/02/objective-c-runtime-releases/"
        ; author = Some "Michael Tsai"
        ; content = Some "<p><a href=\"https://twitter.com/bavarious/status/297851496945577984\">Bavarious</a> created a <a href=\"https://github.com/bavarious/objc4/commits/master\">GitHub repository</a> that shows the differences between versions of <a href=\"http://www.opensource.apple.com/source/objc4/\">Apple\226\128\153s Objective-C runtime</a> that shipped with different versions of Mac OS X.</p>"
        ; summary = Some "Bavarious created a GitHub repository that shows the differences between versions of Apple\226\128\153s Objective-C runtime that shipped with different versions of Mac OS X."
        ; published = Option.value_exn (Ptime.of_date_time ((2013, 2, 3), ((1, 0, 19), 0)))
        ; created_at = Datetime.of_string_exn "2013-02-04T01:00:19.127893Z" }]
  in
  {|
    [
      {
        "id": 2077,
        "feed_id": 135,
        "title": "Objective-C Runtime Releases",
        "url": "http:\/\/mjtsai.com\/blog\/2013\/02\/02\/objective-c-runtime-releases\/",
        "author": "Michael Tsai",
        "content": "<p><a href=\"https:\/\/twitter.com\/bavarious\/status\/297851496945577984\">Bavarious<\/a> created a <a href=\"https:\/\/github.com\/bavarious\/objc4\/commits\/master\">GitHub repository<\/a> that shows the differences between versions of <a href=\"http:\/\/www.opensource.apple.com\/source\/objc4\/\">Apple\u2019s Objective-C runtime<\/a> that shipped with different versions of Mac OS X.<\/p>",
        "summary": "Bavarious created a GitHub repository that shows the differences between versions of Apple\u2019s Objective-C runtime that shipped with different versions of Mac OS X.",
        "published": "2013-02-03T01:00:19.000000Z",
        "created_at": "2013-02-04T01:00:19.127893Z"
      }
    ]
  |}
  |> list_of_string
  |> [%test_result: t list Or_error.t] ~expect

let%test_unit "parse second entries example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#entries *)
  let expect =
    Ok [{ id = 1570169709
        ; feed_id = 1356310
        ; title = None
        ; url = Uri.of_string "http://s3.amazonaws.com"
        ; author = None
        ; content = None
        ; summary = Some ""
        ; published = Datetime.of_string_exn "2017-10-28T14:54:19.885152Z"
        ; created_at = Datetime.of_string_exn "2017-10-28T14:54:19.885105Z" }]
  in
  {|
    [{
      "id": 1570169709,
      "feed_id": 1356310,
      "title": null,
      "author": null,
      "summary": "",
      "content": null,
      "url": "http://s3.amazonaws.com",
      "published": "2017-10-28T14:54:19.885152Z",
      "created_at":"2017-10-28T14:54:19.885105Z"
    }]
  |}
  |> list_of_string
  |> [%test_result: t list Or_error.t] ~expect

let%test_unit "parse extended mode example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#about-extended-modes *)
  let expect =
    Ok { id = 1682191545
       ; feed_id = 1379740
       ; title = Some "Peter Kafka @pkafka"
       ; author = Some "Peter Kafka"
       ; summary = Some "In 2009, the big magazine publishers built their own digital service so they wouldn't be cut out by Apple or Google. Now they're selling to Apple."
       ; content = Some "<div>Content</div>"
       ; url = Uri.of_string "https://twitter.com/fromedome/status/973315765393920000"
       ; published = Datetime.of_string_exn "2018-03-12T21:52:16.000000Z"
       ; created_at = Datetime.of_string_exn "2018-03-12T22:55:53.437304Z" }
  in
  {|
    {
      "id": 1682191545,
      "feed_id": 1379740,
      "title": "Peter Kafka @pkafka",
      "author": "Peter Kafka",
      "summary": "In 2009, the big magazine publishers built their own digital service so they wouldn't be cut out by Apple or Google. Now they're selling to Apple.",
      "content": "<div>Content</div>",
      "url": "https://twitter.com/fromedome/status/973315765393920000",
      "published": "2018-03-12T21:52:16.000000Z",
      "created_at": "2018-03-12T22:55:53.437304Z",
      "original": {
        "author": "Brent Simmons",
                  "content": "<div>Content</div>",
                  "title": "Catching Up on The Omni Show",
                  "url": "https://www.omnigroup.com/blog/entry/catching-up-on-the-omni-show",
                  "entry_id": "https://www.omnigroup.com/blog/entry/catching-up-on-the-omni-show",
                  "published": "2018-03-12T21:24:00.000Z",
                  "data": {}
      },
      "twitter_id": 973315765393920000,
      "twitter_thread_ids": [973315765393920000, 973315765393920001],
      "images": {
        "original_url": "http://www.macdrifter.com/uploads/2018/03/ScreenShot20180312_044129.jpg",
                        "size_1": {
                          "cdn_url": "https://images.feedbinusercontent.com/85996e1/85996e10ef95a3b96a914e67dfc08d5d3362c6e0.jpg",
                                      "width": 542,
                                      "height": 304
                        }
      },
      "enclosure": {
        "enclosure_url": "http://traffic.libsyn.com/atpfm/atp264.mp3",
                          "enclosure_type": "audio/mpeg",
                          "enclosure_length": "54103635",
                          "itunes_duration": "01:51:35",
                          "itunes_image": "http://static1.squarespace.com/static/513abd71e4b0fe58c655c105/t/52c45a37e4b0a77a5034aa84/1388599866232/1500w/Artwork.jpg"
      },
      "extracted_articles": [
        {
          "url": "https://www.recode.net/2018/3/12/17109592/apple-buys-texture-magazine-next-issue-media-eddy-cue-sxsw?utm_campaign=recode.net&utm_content=chorus&utm_medium=social&utm_source=twitter",
                  "title": "Apple is buying Texture, the digital magazine distributor",
                  "host": "www.recode.net",
                  "author": "Peter Kafka",
                  "content": "<div>Content</div>"
        }
      ]
    }
  |}
  |> of_string
  |> [%test_result: t Or_error.t] ~expect

let%test_unit "parse fourth entries example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#get-v2feeds203entriesjson *)
  let expect =
    Ok [{ id = 3648
        ; feed_id = 203
        ; title = Some "Cleveland Drinkup February 6"
        ; url = Uri.of_string "https://github.com/blog/1398-cleveland-drinkup-february-6"
        ; author = Some "juliamae"
        ; content = Some "<p>Cleveland <img class=\"emoji\" title=\":metal:\" alt=\":metal:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/metal.png\" height=\"20\" width=\"20\" align=\"absmiddle\">! Let's <img class=\"emoji\" title=\":beers:\" alt=\":beers:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/beers.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":cocktail:\" alt=\":cocktail:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/cocktail.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":neckbeard:\" alt=\":neckbeard:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/neckbeard.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":guitar:\" alt=\":guitar:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/guitar.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":octocat:\" alt=\":octocat:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/octocat.png\" height=\"20\" width=\"20\" align=\"absmiddle\"> in one of Ohio's greatest cities, Cleveland!</p>\n\n<p>Join <a href=\"https://github.com/asenchi\" class=\"user-mention\">@asenchi</a> and me Wednesday at the <a href=\"http://www.yelp.com/biz/great-lakes-brewing-company-cleveland-4\">Great Lakes Brewing Company Taproom</a>, drinks on GitHub.</p>\n\n<p><img src=\"https://f.cloud.github.com/assets/849/119266/79ef6bbe-6c9e-11e2-9150-47d7da0b85c9.jpg\" alt=\"Great Lakes Taproom\"></p>\n\n<p><strong>The Facts:</strong></p>\n\n<ul>\n<li>\n<a href=\"http://www.greatlakesbrewing.com/brewpub/around-the-brewpub\">Great Lakes Brewing Company</a> - <a href=\"https://maps.google.com/?q=2516+Market+Ave,+Cleveland,+OH,+USA\">2516 Market Ave</a>\n</li>\n<li>Wednesday, February 6 at 8:00pm</li>\n</ul><p><a href=\"https://maps.google.com/?q=2516+Market+Ave,+Cleveland,+OH,+USA\"><img src=\"https://f.cloud.github.com/assets/849/119328/c8cbb682-6ca0-11e2-81c8-246e4027f892.png\" alt=\"Screen Shot 2013-02-01 at 1 53 02 PM\"></a>          </p>"
        ; summary = None
        ; published = Datetime.of_string_exn "2013-02-03T01:00:19.000000Z"
        ; created_at = Datetime.of_string_exn "2013-02-04T01:00:19.127893Z" }]
  in
  {|
    [
      {
        "id": 3648,
        "feed_id": 203,
        "title": "Cleveland Drinkup February 6",
        "url": "https:\/\/github.com\/blog\/1398-cleveland-drinkup-february-6",
        "author": "juliamae",
        "content": "<p>Cleveland <img class=\"emoji\" title=\":metal:\" alt=\":metal:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/metal.png\" height=\"20\" width=\"20\" align=\"absmiddle\">! Let's <img class=\"emoji\" title=\":beers:\" alt=\":beers:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/beers.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":cocktail:\" alt=\":cocktail:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/cocktail.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":neckbeard:\" alt=\":neckbeard:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/neckbeard.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":guitar:\" alt=\":guitar:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/guitar.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":octocat:\" alt=\":octocat:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/octocat.png\" height=\"20\" width=\"20\" align=\"absmiddle\"> in one of Ohio's greatest cities, Cleveland!<\/p>\n\n<p>Join <a href=\"https:\/\/github.com\/asenchi\" class=\"user-mention\">@asenchi<\/a> and me Wednesday at the <a href=\"http:\/\/www.yelp.com\/biz\/great-lakes-brewing-company-cleveland-4\">Great Lakes Brewing Company Taproom<\/a>, drinks on GitHub.<\/p>\n\n<p><img src=\"https:\/\/f.cloud.github.com\/assets\/849\/119266\/79ef6bbe-6c9e-11e2-9150-47d7da0b85c9.jpg\" alt=\"Great Lakes Taproom\"><\/p>\n\n<p><strong>The Facts:<\/strong><\/p>\n\n<ul>\n<li>\n<a href=\"http:\/\/www.greatlakesbrewing.com\/brewpub\/around-the-brewpub\">Great Lakes Brewing Company<\/a> - <a href=\"https:\/\/maps.google.com\/?q=2516+Market+Ave,+Cleveland,+OH,+USA\">2516 Market Ave<\/a>\n<\/li>\n<li>Wednesday, February 6 at 8:00pm<\/li>\n<\/ul><p><a href=\"https:\/\/maps.google.com\/?q=2516+Market+Ave,+Cleveland,+OH,+USA\"><img src=\"https:\/\/f.cloud.github.com\/assets\/849\/119328\/c8cbb682-6ca0-11e2-81c8-246e4027f892.png\" alt=\"Screen Shot 2013-02-01 at 1 53 02 PM\"><\/a>          <\/p>",
        "summary": null,
        "published": "2013-02-03T01:00:19.000000Z",
        "created_at": "2013-02-04T01:00:19.127893Z"
      }
    ]
  |}
  |> list_of_string
  |> [%test_result: t list Or_error.t] ~expect

let%test_unit "parse single entry example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#get-v2entries3648jsonn *)
  let expect =
    Ok { id = 3648
       ; feed_id = 203
       ; title = Some "Cleveland Drinkup February 6"
       ; url = Uri.of_string "https://github.com/blog/1398-cleveland-drinkup-february-6"
       ; author = Some "juliamae"
       ; content = Some "<p>Cleveland <img class=\"emoji\" title=\":metal:\" alt=\":metal:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/metal.png\" height=\"20\" width=\"20\" align=\"absmiddle\">! Let's <img class=\"emoji\" title=\":beers:\" alt=\":beers:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/beers.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":cocktail:\" alt=\":cocktail:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/cocktail.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":neckbeard:\" alt=\":neckbeard:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/neckbeard.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":guitar:\" alt=\":guitar:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/guitar.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":octocat:\" alt=\":octocat:\" src=\"https://a248.e.akamai.net/assets.github.com/images/icons/emoji/octocat.png\" height=\"20\" width=\"20\" align=\"absmiddle\"> in one of Ohio's greatest cities, Cleveland!</p>\n\n<p>Join <a href=\"https://github.com/asenchi\" class=\"user-mention\">@asenchi</a> and me Wednesday at the <a href=\"http://www.yelp.com/biz/great-lakes-brewing-company-cleveland-4\">Great Lakes Brewing Company Taproom</a>, drinks on GitHub.</p>\n\n<p><img src=\"https://f.cloud.github.com/assets/849/119266/79ef6bbe-6c9e-11e2-9150-47d7da0b85c9.jpg\" alt=\"Great Lakes Taproom\"></p>\n\n<p><strong>The Facts:</strong></p>\n\n<ul>\n<li>\n<a href=\"http://www.greatlakesbrewing.com/brewpub/around-the-brewpub\">Great Lakes Brewing Company</a> - <a href=\"https://maps.google.com/?q=2516+Market+Ave,+Cleveland,+OH,+USA\">2516 Market Ave</a>\n</li>\n<li>Wednesday, February 6 at 8:00pm</li>\n</ul><p><a href=\"https://maps.google.com/?q=2516+Market+Ave,+Cleveland,+OH,+USA\"><img src=\"https://f.cloud.github.com/assets/849/119328/c8cbb682-6ca0-11e2-81c8-246e4027f892.png\" alt=\"Screen Shot 2013-02-01 at 1 53 02 PM\"></a>          </p>"
       ; summary = None
       ; published = Datetime.of_string_exn "2013-02-03T01:00:19.000000Z"
       ; created_at = Datetime.of_string_exn "2013-02-04T01:00:19.127893Z" }
  in
  {|
    {
      "id": 3648,
      "feed_id": 203,
      "title": "Cleveland Drinkup February 6",
      "url": "https:\/\/github.com\/blog\/1398-cleveland-drinkup-february-6",
      "author": "juliamae",
      "content": "<p>Cleveland <img class=\"emoji\" title=\":metal:\" alt=\":metal:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/metal.png\" height=\"20\" width=\"20\" align=\"absmiddle\">! Let's <img class=\"emoji\" title=\":beers:\" alt=\":beers:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/beers.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":cocktail:\" alt=\":cocktail:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/cocktail.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":neckbeard:\" alt=\":neckbeard:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/neckbeard.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":guitar:\" alt=\":guitar:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/guitar.png\" height=\"20\" width=\"20\" align=\"absmiddle\"><img class=\"emoji\" title=\":octocat:\" alt=\":octocat:\" src=\"https:\/\/a248.e.akamai.net\/assets.github.com\/images\/icons\/emoji\/octocat.png\" height=\"20\" width=\"20\" align=\"absmiddle\"> in one of Ohio's greatest cities, Cleveland!<\/p>\n\n<p>Join <a href=\"https:\/\/github.com\/asenchi\" class=\"user-mention\">@asenchi<\/a> and me Wednesday at the <a href=\"http:\/\/www.yelp.com\/biz\/great-lakes-brewing-company-cleveland-4\">Great Lakes Brewing Company Taproom<\/a>, drinks on GitHub.<\/p>\n\n<p><img src=\"https:\/\/f.cloud.github.com\/assets\/849\/119266\/79ef6bbe-6c9e-11e2-9150-47d7da0b85c9.jpg\" alt=\"Great Lakes Taproom\"><\/p>\n\n<p><strong>The Facts:<\/strong><\/p>\n\n<ul>\n<li>\n<a href=\"http:\/\/www.greatlakesbrewing.com\/brewpub\/around-the-brewpub\">Great Lakes Brewing Company<\/a> - <a href=\"https:\/\/maps.google.com\/?q=2516+Market+Ave,+Cleveland,+OH,+USA\">2516 Market Ave<\/a>\n<\/li>\n<li>Wednesday, February 6 at 8:00pm<\/li>\n<\/ul><p><a href=\"https:\/\/maps.google.com\/?q=2516+Market+Ave,+Cleveland,+OH,+USA\"><img src=\"https:\/\/f.cloud.github.com\/assets\/849\/119328\/c8cbb682-6ca0-11e2-81c8-246e4027f892.png\" alt=\"Screen Shot 2013-02-01 at 1 53 02 PM\"><\/a>          <\/p>",
      "summary": null,
      "published": "2013-02-03T01:00:19.000000Z",
      "created_at": "2013-02-04T01:00:19.127893Z"
    }
  |}
  |> of_string
  |> [%test_result: t Or_error.t] ~expect

let%test_unit "parse include_original example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#sample-responses *)
  let expect =
    Ok { id = 696388086
       ; feed_id = 47
       ; title = Some "Audio Hijack 3"
       ; url = Uri.of_string "http://weblog.rogueamoeba.com/2015/01/20/audio-hijack-3-has-arrived/"
       ; author = Some "John Gruber"
       ; summary = None
       ; content = Some {|<p>Gorgeous new interface in this major update to Rogue Amoeba&#8217;s venerable audio recording app. This is one of the best takes on Yosemite-style design I&#8217;ve seen.</p> <p><strong>See also:</strong> <a href="http://sixcolors.com/post/2015/01/audio-hijack-3-a-huge-amazing-update/">Jason Snell&#8217;s take on the app and interview with Paul Kafasis</a>.</p> <div> <a title="Permanent link to ‘Audio Hijack 3’" href="http://daringfireball.net/linked/2015/01/20/audio-hijack-3">&nbsp;★&nbsp;</a> </div>|}
       ; published = Datetime.of_string_exn "2015-01-21T01:34:41.000000Z"
       ; created_at = Datetime.of_string_exn "2015-01-21T01:37:57.679046Z" }
  in
  {|
    {
      "id": 696388086,
      "feed_id": 47,
      "title": "Audio Hijack 3",
      "author": "John Gruber",
      "content": "<p>Gorgeous new interface in this major update to Rogue Amoeba&#8217;s venerable audio recording app. This is one of the best takes on Yosemite-style design I&#8217;ve seen.<\/p> <p><strong>See also:<\/strong> <a href=\"http:\/\/sixcolors.com\/post\/2015\/01\/audio-hijack-3-a-huge-amazing-update\/\">Jason Snell&#8217;s take on the app and interview with Paul Kafasis<\/a>.<\/p> <div> <a title=\"Permanent link to ‘Audio Hijack 3’\" href=\"http:\/\/daringfireball.net\/linked\/2015\/01\/20\/audio-hijack-3\">&nbsp;★&nbsp;<\/a> <\/div>",
      "summary": null,
      "url": "http:\/\/weblog.rogueamoeba.com\/2015\/01\/20\/audio-hijack-3-has-arrived\/",
      "published": "2015-01-21T01:34:41.000000Z",
      "created_at": "2015-01-21T01:37:57.679046Z",
      "original": {
        "author": "John Gruber",
        "content": "<p>Gorgeous new interface in this major update to Rogue Amoeba&#8217;s venerable audio recording app. This is one of the best takes on Yosemite-style design I&#8217;ve seen.<\/p> <div> <a title=\"Permanent link to ‘Audio Hijack 3’\" href=\"http:\/\/daringfireball.net\/linked\/2015\/01\/20\/audio-hijack-3\">&nbsp;★&nbsp;<\/a> <\/div>",
        "title": "Audio Hijack 3",
        "url": "http:\/\/weblog.rogueamoeba.com\/2015\/01\/20\/audio-hijack-3-has-arrived\/",
        "entry_id": "tag:daringfireball.net,2015:/linked//6.30480",
        "published": "2015-01-21T01:34:41.000Z",
        "data": null
      }
    }
  |}
  |> of_string
  |> [%test_result: t Or_error.t] ~expect

let%test_unit "parse include_enclosure example" =
  (* https://github.com/feedbin/feedbin-api/blob/master/content/entries.md#sample-responses *)
  let expect =
    Ok { id = 683590343
       ; feed_id = 908904
       ; title = Some "99: Pop-Up Headlights"
       ; url = Uri.of_string "http://atp.fm/episodes/99"
       ; author = None
       ; content = Some "<ul> <li>Follow-Up: <ul><li>SSL <ul><li>In schools &amp; corporations</li> <li><a href=\"http://www.gogoair.com/\">Gogo</a> actually <a href=\"http://www.neowin.net/news/gogo-inflight-internet-is-intentionally-issuing-fake-ssl-certificates\">issues their own certificates to intercept SSL</a></li> <li><a href=\"https://en.wikipedia.org/wiki/SOCKS\">SOCKS</a></li></ul></li> <li>Using C# outside Windows (via <a href=\"https://twitter.com/praeclarum/status/551517070186541056\">Frank A. Krueger</a>)</li> <li>Marco's <a href=\"https://golang.org\">Go</a> feed poller <a href=\"https://twitter.com/marcoarment/status/552202315181326336\">update</a> <ul><li><a href=\"https://en.wikipedia.org/wiki/Integrated_development_environment\">IDE</a></li> <li><a href=\"http://www.eclipse.org\">Eclipse</a></li> <li><a href=\"http://www.rust-lang.org\">Rust</a></li> <li><a href=\"http://en.wikipedia.org/wiki/Communicating_sequential_processes\">Communicating sequential processes</a></li></ul></li></ul></li> <li>Apple's Software Quality <ul><li><a href=\"http://www.marco.org/2015/01/04/apple-lost-functional-high-ground\">Marco's post</a></li> <li><a href=\"http://www.marco.org/2015/01/05/popular-for-a-day\">Marco's retrospective</a></li> <li><a href=\"http://video.cnbc.com/gallery/?video=3000343764\">Mention on CNBC</a></li> <li><a href=\"http://5by5.tv/hypercritical/55\">Hypercritical #55</a></li> <li><a href=\"http://www.caseyliss.com/2015/1/5/bravery\">Casey's response to Marco</a></li> <li><a href=\"http://glog.glennf.com/blog/2015/1/6/the-software-and-services-apple-needs-to-fix\">Glenn Fleishman's list</a></li></ul></li> <li>How to write for understanding <ul><li><a href=\"http://www.marco.org/2013/12/29/apple-doesnt-have-time\">Marco laments about software quality in the past</a></li></ul></li> <li><a href=\"http://9to5mac.com/2015/01/06/macbook-air-12-inch-redesign/\">Rumored 12\" MacBook Air</a> <ul><li><a href=\"https://www.twelvesouth.com/product/plugbug\">PlugBug</a></li> <li><a href=\"https://twitter.com/chockenberry/status/552928449250078721\">Chockenberry on a potential ARM transition</a></li> <li><a href=\"https://en.wikipedia.org/wiki/Fat_binary\">Fat binary</a></li> <li>Special thanks to <a href=\"http://david-smith.org/\">_DavidSmith</a> for finding \"bezels\" in <a href=\"http://5by5.tv/hypercritical/22\">Hypercritical #22</a></li></ul></li> </ul> <p>Sponsored by:</p> <ul> <li><a href=\"http://automatic.com/atp\">Automatic</a>: Your smart driving assistant. Get $20 off with this link.</li> <li><a href=\"http://hover.com/atp\">Hover</a>: The best way to buy and manage domain names. Use coupon code <strong>HIGHGROUND</strong> for 10% off.</li> <li><a href=\"https://caspersleep.com/atp\">Casper</a>: A mattress with just the right sink, just the right bounce, for better nights and brighter days. Use code <strong>ATP</strong> for $50 off.</li> </ul>"
       ; summary = None
       ; published = Datetime.of_string_exn "2015-01-09T20:11:41.000000Z"
       ; created_at = Datetime.of_string_exn "2015-01-09T23:54:57.672303Z" }
  in
  {|
    {
      "id": 683590343,
      "feed_id": 908904,
      "title": "99: Pop-Up Headlights",
      "author": null,
      "content": "<ul> <li>Follow-Up: <ul><li>SSL <ul><li>In schools &amp; corporations<\/li> <li><a href=\"http:\/\/www.gogoair.com\/\">Gogo<\/a> actually <a href=\"http:\/\/www.neowin.net\/news\/gogo-inflight-internet-is-intentionally-issuing-fake-ssl-certificates\">issues their own certificates to intercept SSL<\/a><\/li> <li><a href=\"https:\/\/en.wikipedia.org\/wiki\/SOCKS\">SOCKS<\/a><\/li><\/ul><\/li> <li>Using C# outside Windows (via <a href=\"https:\/\/twitter.com\/praeclarum\/status\/551517070186541056\">Frank A. Krueger<\/a>)<\/li> <li>Marco's <a href=\"https:\/\/golang.org\">Go<\/a> feed poller <a href=\"https:\/\/twitter.com\/marcoarment\/status\/552202315181326336\">update<\/a> <ul><li><a href=\"https:\/\/en.wikipedia.org\/wiki\/Integrated_development_environment\">IDE<\/a><\/li> <li><a href=\"http:\/\/www.eclipse.org\">Eclipse<\/a><\/li> <li><a href=\"http:\/\/www.rust-lang.org\">Rust<\/a><\/li> <li><a href=\"http:\/\/en.wikipedia.org\/wiki\/Communicating_sequential_processes\">Communicating sequential processes<\/a><\/li><\/ul><\/li><\/ul><\/li> <li>Apple's Software Quality <ul><li><a href=\"http:\/\/www.marco.org\/2015\/01\/04\/apple-lost-functional-high-ground\">Marco's post<\/a><\/li> <li><a href=\"http:\/\/www.marco.org\/2015\/01\/05\/popular-for-a-day\">Marco's retrospective<\/a><\/li> <li><a href=\"http:\/\/video.cnbc.com\/gallery\/?video=3000343764\">Mention on CNBC<\/a><\/li> <li><a href=\"http:\/\/5by5.tv\/hypercritical\/55\">Hypercritical #55<\/a><\/li> <li><a href=\"http:\/\/www.caseyliss.com\/2015\/1\/5\/bravery\">Casey's response to Marco<\/a><\/li> <li><a href=\"http:\/\/glog.glennf.com\/blog\/2015\/1\/6\/the-software-and-services-apple-needs-to-fix\">Glenn Fleishman's list<\/a><\/li><\/ul><\/li> <li>How to write for understanding <ul><li><a href=\"http:\/\/www.marco.org\/2013\/12\/29\/apple-doesnt-have-time\">Marco laments about software quality in the past<\/a><\/li><\/ul><\/li> <li><a href=\"http:\/\/9to5mac.com\/2015\/01\/06\/macbook-air-12-inch-redesign\/\">Rumored 12\" MacBook Air<\/a> <ul><li><a href=\"https:\/\/www.twelvesouth.com\/product\/plugbug\">PlugBug<\/a><\/li> <li><a href=\"https:\/\/twitter.com\/chockenberry\/status\/552928449250078721\">Chockenberry on a potential ARM transition<\/a><\/li> <li><a href=\"https:\/\/en.wikipedia.org\/wiki\/Fat_binary\">Fat binary<\/a><\/li> <li>Special thanks to <a href=\"http:\/\/david-smith.org\/\">_DavidSmith<\/a> for finding \"bezels\" in <a href=\"http:\/\/5by5.tv\/hypercritical\/22\">Hypercritical #22<\/a><\/li><\/ul><\/li> <\/ul> <p>Sponsored by:<\/p> <ul> <li><a href=\"http:\/\/automatic.com\/atp\">Automatic<\/a>: Your smart driving assistant. Get $20 off with this link.<\/li> <li><a href=\"http:\/\/hover.com\/atp\">Hover<\/a>: The best way to buy and manage domain names. Use coupon code <strong>HIGHGROUND<\/strong> for 10% off.<\/li> <li><a href=\"https:\/\/caspersleep.com\/atp\">Casper<\/a>: A mattress with just the right sink, just the right bounce, for better nights and brighter days. Use code <strong>ATP<\/strong> for $50 off.<\/li> <\/ul>",
      "summary": null,
      "url": "http:\/\/atp.fm\/episodes\/99",
      "published": "2015-01-09T20:11:41.000000Z",
      "created_at": "2015-01-09T23:54:57.672303Z",
      "enclosure": {
        "enclosure_type": "audio/mpeg",
        "enclosure_url": "http:\/\/traffic.libsyn.com\/atpfm\/atp99.mp3",
        "enclosure_length": "86528647",
        "itunes_duration": "02:00:00"
      }
    }
  |}
  |> of_string
  |> [%test_result: t Or_error.t] ~expect