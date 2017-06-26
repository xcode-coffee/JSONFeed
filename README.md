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

## Design Goals

The primary goal of this project (other than the most obvious goal, which is to successfully parse JSON Feeds) is to eliminate boilerplate JSON parsing code by using the new `Codable` protocol in Swift 4, along with the new `JSONDecoder` and `JSONEncoder` classes in Foundation. Historically, you would get `Data` from a server, deserialize that `Data` into a `[String: Any]` dictionary via the venerable [`JSONSerialization`](https://developer.apple.com/documentation/foundation/jsonserialization) class, and then instantiate your native Swift object(s) by manually setting each property from the key-value pairs in the dictionary. With `Codable` and `JSONDecoder`, you can go directly from `Data` to `JSONFeed` in one easy step, without the dictionary and without all of the boilerplate.

When I started this project, the second most important goal was for the parser to be flexible and lenient. During development, I discovered that this design goal was at odds with the first design goal. In other words, the out-of-the-box behavior of `Codable` is quite strict.

### `URL` vs `String`

### Dates

The JSON Feed specification defines two date parameters: `date_published` and `date_modified`. Both are specified as optional strings in the [RFC3339](https://tools.ietf.org/html/rfc3339) format. What is RFC3339?

> The following section defines a profile of ISO 8601 for use on the Internet. It is a conformant subset of the ISO 8601 extended format. Simplicity is achieved by making most fields and punctuation mandatory.

Great! A "conformant subset" of ISO 8601!

> &#x1F603; That means we can use the `iso8601` date decoding strategy built-in to `JSONDecoder`, right?

> &#x1F629; Wrong!

There's a [bug](http://www.openradar.me/28425750) in Apple's [`ISO8601DateFormatter`](https://developer.apple.com/documentation/foundation/iso8601dateformatter): It cannot parse date strings that include fractions of a second. RFC3339 allows for fractions of a second, but defines it as a "rarely used option" and states:

> Rarely used options should be made mandatory or omitted for the sake of interoperability whenever possible. The format defined below includes only one rarely used option: fractions of a second. It is expected that this will be used only by applications which require strict ordering of date/time stamps or which have an unusual precision requirement.

The JSON Feed spec does not specify whether this option is "mandatory or omitted". Most JSON Feeds in the wild don't use fractions of a second, but some do (namely, the [Flying Meat](http://flyingmeat.com) blog, and [Maybe Pizza?](http://maybepizza.com)). Therefore, we should support this option.

Luckily, `JSONDecoder` allows us to select a `DateDecodingStrategy`:

```swift
/// The strategy to use for decoding `Date` values.
public enum DateDecodingStrategy {

    /// Defer to `Date` for decoding. This is the default strategy.
    case deferredToDate

    /// Decode the `Date` as a UNIX timestamp from a JSON number.
    case secondsSince1970

    /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
    case millisecondsSince1970

    /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    case iso8601

    /// Decode the `Date` as a string parsed by the given formatter.
    case formatted(DateFormatter)

    /// Decode the `Date` as a custom value decoded by the given closure.
    case custom((Decoder) throws -> Date)
}
```

We've eliminated `iso8601`. We could use `formatted(DateFormatter)`, passing it our own custom subclass of `DateFormatter`. I actually tried this, but things got weird. You'll notice that Apple's `ISO8601DateFormatter` actually subclasses `Formatter` rather than `DateFormatter` - this is because `DateFormatter` is not particularly well suited to subclassing. The last remaining option is `case custom((Decoder) throws -> Date)`. 

### Item Identifiers

Per the spec, each item in the feed is required to have an `id`, which uniquely identifies the item. The specified data type is a string, however the spec allows for "a number or other type":

> id (required, string) is unique for that item for that feed over time. If an item is ever updated, the id should be unchanged. New items should never use a previously-used id. If an id is presented as a number or other type, a JSON Feed reader must coerce it to a string. Ideally, the id is the full URL of the resource described by the item, since URLs make great unique identifiers.

This presents us with a problem. If we simply define `id` as a `String` and use the default compiler-generated implementation of `Decodable`, then `JSONDecoder` will throw an error when parsing a feed which uses numbers instead of strings for the `id` parameter. We could provide our own custom implementation `Decodable`, but that would not be in line with our primary design goal: to eliminate boilerplate code.

Therefore, I decided to simply define `id` as a custom type, called `AmbiguouslyTypedIdentifier`, which has its own custom implementation of `Codable`, allowing for the `id` to be a `String`, `Int`, or `Double`. In this way we accommodate the flexible nature of the specification, all while keeping boilerplate to a minimum.

## Use Cases

Why would anyone need a JSON Feed encoder / decoder written in Swift?

- Write a feed reader app for iOS.
- Write a feed reader app for macOS.
- Write your own blog engine, and use it to generate the JSON Feed for your blog.
- Use a JSON Feed as a lightweight content management system for your iOS app.
- Use it as a JSON Feed validator.

## Integration

### Manually

Simply drag `JSONFeed.swift` and `JSONFeed+Fetch.swift` into your Xcode project.

### Swift Package Manager

I'm working on adding support for the [Swift Package Manager](https://swift.org/package-manager/).
