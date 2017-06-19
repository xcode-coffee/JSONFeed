import XCTest
@testable import JSONFeed

class JSONFeedTests: XCTestCase {
    
    static var allTests: [(String, (JSONFeedTests) -> () -> Void)] = [
        ("testVariousFiles", testVariousFiles),
        ("testFetching", testFetching),
        ("testEncoding", testEncoding)
    ]
    
    func testVariousFiles() {
        
        assertDecoding(ofFile: "noVersion", isSuccessful: false)
        assertDecoding(ofFile: "noTitle", isSuccessful: false)
        assertDecoding(ofFile: "noItems", isSuccessful: false)
        assertDecoding(ofFile: "noItemId", isSuccessful: false)
        assertDecoding(ofFile: "incorrectDateFormat", isSuccessful: false)
        
        assertDecoding(ofFile: "bare", isSuccessful: true)
        assertDecoding(ofFile: "bareWithItem", isSuccessful: true)
        
        assertDecoding(ofFile: "shapeOf", isSuccessful: true)
        assertDecoding(ofFile: "flyingMeat", isSuccessful: true)
        assertDecoding(ofFile: "maybePizza", isSuccessful: true)
        assertDecoding(ofFile: "daringFireball", isSuccessful: true)
        assertDecoding(ofFile: "hypercritical", isSuccessful: true)
        assertDecoding(ofFile: "inessential", isSuccessful: true)
        assertDecoding(ofFile: "mantonReece", isSuccessful: true)
        assertDecoding(ofFile: "timetable", isSuccessful: true)
        assertDecoding(ofFile: "theRecord", isSuccessful: true)
        assertDecoding(ofFile: "allenPike", isSuccessful: true)
        
        assertDecoding(ofFile: "alternateItemIdTypes", isSuccessful: true)
    }
    
    func testFetching() {
        
        let e = expectation(description: "daringfireball")
        
        JSONFeed.fetch("https://daringfireball.net/feeds/json") { (feed: JSONFeed?, error: Error?) in
            
            guard error == nil else {
                print(error!)
                e.fulfill()
                return
            }
            
            let titles = feed!.items[0..<5].map { $0.title ?? "No title" }
            print(titles.joined(separator: "\n"))
            
            e.fulfill()
        }
        
        wait(for: [e], timeout: 10.0)
    }
    
    func testEncoding() {
        
        let html = """
            <p>Hello World</p>
            <a href="http://www.google.com/">Link</a>
            """
        
        let item = JSONFeed.Item(
            id: JSONFeed.Item.AmbiguouslyTypedIdentifier(stringValue: "Hello World"),
            url: nil,
            externalUrl: nil,
            title: "Hello World",
            contentHtml: html,
            contentText: nil,
            summary: nil,
            image: nil,
            bannerImage: nil,
            datePublished: Date(),
            dateModified: nil,
            author: nil,
            tags: ["iOS", "Swift"],
            attachments: nil
        )
        
        let feed = JSONFeed(
            version: "https://jsonfeed.org/version/1",
            title: "xcode.coffee",
            items: [item],
            homePageUrl: "http://xcode.coffee",
            feedUrl: "http://xcode.coffee/feed.json",
            description: "A blog about iOS development.",
            userComment: "This feed allows you to read the posts from this site in any feed reader that supports the JSON Feed format.",
            nextUrl: nil,
            icon: nil,
            favicon: nil,
            author: nil,
            expired: nil,
            hubs: nil
        )
        
        do {
            guard let string = try feed.encodeToString() else {
                XCTFail()
                return
            }
            print("\n\(string)\n")
        } catch {
            print(error)
            XCTFail()
        }
    }
}

//===============================================
// MARK: - Helper
//===============================================

extension JSONFeedTests {
    
    @discardableResult func assertDecoding(ofFile file: String, isSuccessful: Bool) -> JSONFeed? {
        
        let result = attemptToDecode(file: file)
        switch result {
        case .success(let feed):
            if !isSuccessful {
                XCTFail("\(file): Decoding succeeded but should have failed.")
            }
            return feed
        case .failure(let error):
            if isSuccessful {
                XCTFail("\(file): \(error)")
            }
            return nil
        }
    }
    
    enum DecodingResult {
        case success(JSONFeed)
        case failure(Error)
    }
    
    func attemptToDecode(file: String) -> DecodingResult {
        
        let data = loadDataFromJsonFile(withName: file)!
        
        return attemptToDecode(data: data)
    }
    
    func attemptToDecode(data: Data) -> DecodingResult {
        
        do {
            let feed = try JSONFeed.make(from: data)
            return .success(feed)
        } catch {
            return .failure(error)
        }
    }
    
    func loadDataFromJsonFile(withName name: String) -> Data? {
        
        let bundle = Bundle(for: JSONFeedTests.self)
        
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return data
    }
}
