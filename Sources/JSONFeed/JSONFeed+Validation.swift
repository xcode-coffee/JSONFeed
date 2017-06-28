//
//  JSONFeed+Validation.swift
//  JSONFeed
//
//  Created by Phillip Harris on 6/27/17.
//

import Foundation

public extension JSONFeed {
    
    public enum Violation {
        case missingParameter(String)
        case atLeastOnePropertyMustBePresent(Author)
        case atLeastOneContentPropertyMustBePresent(Item)
        case nextUrlMustNotBeTheSameAsFeedUrl
    }
    
    public func validate() -> [Violation] {
        
        var violations = [Violation]()
        
        if version == nil { violations.append(.missingParameter("version")) }
        if title == nil { violations.append(.missingParameter("title")) }
        
        if let author = author {
            violations.append(contentsOf: author.validate())
        }
        
        if let items = items {
            violations.append(contentsOf: (items.flatMap { $0.validate() }) )
        } else {
            violations.append(.missingParameter("items"))
        }
        
        if let hubs = hubs {
            violations.append(contentsOf: (hubs.flatMap { $0.validate() }) )
        }
        
        if let nextUrl = nextUrl, let feedUrl = feedUrl, nextUrl == feedUrl {
            violations.append(.nextUrlMustNotBeTheSameAsFeedUrl)
        }
        
        return violations
    }
}

public extension JSONFeed.Item {
    
    public func validate() -> [JSONFeed.Violation] {
        
        var violations = Array<JSONFeed.Violation>()
        
        if contentHtml == nil && contentText == nil {
            violations.append(.atLeastOneContentPropertyMustBePresent(self))
        }
        
        if let author = author {
            violations.append(contentsOf: author.validate())
        }
        
        if let attachments = attachments {
            violations.append(contentsOf: (attachments.flatMap { $0.validate() }) )
        }
        
        return violations
    }
}

public extension JSONFeed.Author {
    
    public func validate() -> [JSONFeed.Violation] {
        
        if name == nil && url == nil && avatar == nil {
            return [.atLeastOnePropertyMustBePresent(self)]
        } else {
            return []
        }
    }
}

public extension JSONFeed.Item.Attachment {
    
    public func validate() -> [JSONFeed.Violation] {
        
        var violations = Array<JSONFeed.Violation>()
        
        if url == nil { violations.append(.missingParameter("url")) }
        if mimeType == nil { violations.append(.missingParameter("mimeType")) }
        
        return violations
    }
}

public extension JSONFeed.Hub {
    
    public func validate() -> [JSONFeed.Violation] {
        
        var violations = Array<JSONFeed.Violation>()
        
        if type == nil { violations.append(.missingParameter("type")) }
        if url == nil { violations.append(.missingParameter("url")) }
        
        return violations
    }
}
