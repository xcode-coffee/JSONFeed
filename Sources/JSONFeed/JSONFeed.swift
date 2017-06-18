
import Foundation

public struct JSONFeed: Codable {
    
    let version: String
    let title: String
    let items: [Item]
    let homePageUrl: String?
    let feedUrl: String?
    let description: String?
    let userComment: String?
    let nextUrl: String?
    let icon: String?
    let favicon: String?
    let author: Author?
    let expired: Bool?
    let hubs: [Hub]?
    
    public struct Item: Codable {
        
        let id: AmbiguouslyTypedIdentifier
        let url: String?
        let externalUrl: String?
        let title: String?
        let contentHtml: String?
        let contentText: String?
        let summary: String?
        let image: String?
        let bannerImage: String?
        let datePublished: Date?
        let dateModified: Date?
        let author: Author?
        let tags: [String]?
        let attachments: [Attachment]?
        
        public struct Attachment: Codable {
            
            let url: String
            let mimeType: String?
            let title: String?
            let sizeInBytes: Double?
            let durationInSeconds: Double?
        }
    }
    
    public struct Author: Codable {
        
        let name: String?
        let url: String?
        let avatar: String?
    }
    
    public struct Hub: Codable {
        
        let type: String
        let url: String
    }
}

//===============================================
// MARK: - CodingKeys
//===============================================

private extension JSONFeed {
    
    enum CodingKeys: String, CodingKey {
        case version
        case title
        case items
        case homePageUrl = "home_page_url"
        case feedUrl = "feed_url"
        case description
        case userComment = "user_comment"
        case nextUrl = "next_url"
        case icon
        case favicon
        case author
        case expired
        case hubs
    }
}

private extension JSONFeed.Item {
    
    enum CodingKeys: String, CodingKey {
        case id
        case url
        case externalUrl = "external_url"
        case title
        case contentHtml = "content_html"
        case contentText = "content_text"
        case summary
        case image
        case bannerImage = "banner_image"
        case datePublished = "date_published"
        case dateModified = "date_modified"
        case author
        case tags
        case attachments
    }
}

private extension JSONFeed.Item.Attachment {
    
    enum CodingKeys: String, CodingKey {
        case url
        case mimeType = "mime_type"
        case title
        case sizeInBytes = "size_in_bytes"
        case durationInSeconds = "duration_in_seconds"
    }
}

//===============================================
// MARK: - Easy Decoding
//===============================================

extension JSONFeed {
    
    enum DateDecodingError: Error {
        case dateStringDoesNotConformToRFC3339
    }
    
    static let defaultDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom() { (decoder: Decoder) -> Date in
            let string: String
            do {
                let container = try decoder.singleValueContainer()
                string = try container.decode(String.self)
            } catch {
                throw error
            }
            guard let date = RFC3339DateDecoder.date(from: string) else {
                throw JSONFeed.DateDecodingError.dateStringDoesNotConformToRFC3339
            }
            return date
        }
        return decoder
    }()
    
    static func make(from data: Data) throws -> JSONFeed {
        
        let decoder = defaultDecoder
        
        do {
            let feed = try decoder.decode(JSONFeed.self, from: data)
            return feed
        } catch {
            throw error
        }
    }
}

//===============================================
// MARK: - Easy Encoding
//===============================================

extension JSONFeed {
    
    static let defaultEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    func encodeToData() throws -> Data {
        
        let encoder = JSONFeed.defaultEncoder
        
        do {
            let data = try encoder.encode(self)
            return data
        } catch {
            throw error
        }
    }
    
    func encodeToString() throws -> String? {
        
        do {
            let data = try encodeToData()
            guard var json = String(data: data, encoding: .utf8) else { return nil }
            json = json.replacingOccurrences(of: "\\/", with: "/")
            return json
        } catch {
            throw error
        }
    }
}

//===============================================
// MARK: - RFC3339DateDecoder
//===============================================

extension JSONFeed {
    
    fileprivate struct RFC3339DateDecoder {
        
        static let dateFormatTemplate = "yyyy-MM-dd'%@'HH:mm:ss%@ZZZZZ"
        
        static var dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }()
        
        static func date(from string: String) -> Date? {
            
            guard let index = string.index(string.startIndex, offsetBy: 10, limitedBy: string.endIndex) else {
                return nil
            }
            
            let separator = string[index]
            
            guard separator == "T" || separator == "t" || separator == " " else {
                return nil
            }
            
            let fractionalSeconds = string.contains(".") ? ".SSS" : ""
            
            dateFormatter.dateFormat = String(format: dateFormatTemplate, String(separator), fractionalSeconds)
            
            return dateFormatter.date(from: string)
        }
    }
}

//===============================================
// MARK: - AmbiguouslyTypedIdentifier
//===============================================

extension JSONFeed.Item {
    
    struct AmbiguouslyTypedIdentifier: Codable {
        
        let stringValue: String
        
        init(from decoder: Decoder) throws {
            let container: SingleValueDecodingContainer
            do { container = try decoder.singleValueContainer() } catch { throw error }
            if let string = try? container.decode(String.self) {
                stringValue = string
            } else if let int = try? container.decode(Int.self) {
                stringValue = String(int)
            } else {
                let double: Double
                do { double = try container.decode(Double.self) } catch { throw error }
                stringValue = String(double)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var singleValueContainer = encoder.singleValueContainer()
            try singleValueContainer.encode(stringValue)
        }
    }
}
