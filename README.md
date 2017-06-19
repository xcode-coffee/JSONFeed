# JSONFeed

`JSONFeed` is a lightweight [JSON Feed](https://jsonfeed.org) parser written in Swift 4, using the brand new [`Codable`](https://developer.apple.com/documentation/swift/codable) protocol and Foundation's new [`JSONDecoder`](https://developer.apple.com/documentation/foundation/jsondecoder) and [`JSONEncoder`](https://developer.apple.com/documentation/foundation/jsonencoder) classes. It supports both decoding from JSON, and encoding to JSON.

The [JSON Feed](https://jsonfeed.org) format is an alternative to RSS and Atom, and was released on May 17th, 2017 by [Brent Simmons](http://inessential.com) and [Manton Reece](http://manton.org).

## Requirements

- [Xcode 9 beta](https://developer.apple.com/download/)
- Swift 4

## Usage

### Decoding

You can instatiate a `JSONFeed` object from raw data as follows:

```swift
let feed = try? JSONFeed.make(from: data)
```

For the really lazy developers out there, the `JSONFeed+Fetch.swift` extension provides a quick and lightweight way to fetch a JSON Feed from the web, without having to write any networking code (no need to worry with [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) or [`Alamofire`](https://github.com/Alamofire/Alamofire)).

```swift
JSONFeed.fetch("https://daringfireball.net/feeds/json") { (feed: JSONFeed?, error: Error?) in

    guard error == nil else { return }

    let titles = feed!.items[0..<5].map { $0.title ?? "No title" }

    print(titles.joined(separator: "\n"))
}
```

The example above prints out the five most recent [Daring Fireball](https://daringfireball.net) posts:

    Designing the Worst Volume Sliders Possible
    John Markoff to Interview Scott Forstall Next Week
    Brian Merchant Has Tony Fadell on Tape
    Inductive Charging Is Not ‘Wireless’
    Microsoft Surface Laptop Teardown

The decoder strictly enforces the following requirements of the spec:

- The feed must include a `version` string.
- The feed must include a `title` string.
- The feed must include an `items` array, although the array may be empty.
- All items must include an `id`, and the `id` must be a string, integer, or float.
- All dates (namely, `date_published` and `date_modified`) must conform to [RFC3339](https://tools.ietf.org/html/rfc3339).
- All values must match their specified data type. For example, the spec states that the value for `title` should be a string – if the decoder encounters an integer, float, or some other type for `title`, it will throw an error.

If even one requirement is not met, then the decoder throws an error and thus the entire feed is considered invalid.

### Encoding

You can also encode a native Swift `JSONFeed` object *to* JSON.

To encode the feed as data:

```swift
let data = try? feed.encodeToData()
```

To produce a string:

```swift
let string = try feed.encodeToString()
```

## Use Cases

Why would anyone need a JSON Feed encoder / decoder written in Swift?

- Write a feed reader app for iOS.
- Write a feed reader app for macOS.
- Write your own blog engine, and use it to generate the JSON Feed for your blog.
- Use a JSON Feed as a lightweight content management system for your iOS app.

## Integration

### Manually

Simply drag `JSONFeed.swift` and `JSONFeed+Fetch.swift` into your Xcode project.

### Swift Package Manager

I'm working on adding support for the [Swift Package Manager](https://swift.org/package-manager/).
