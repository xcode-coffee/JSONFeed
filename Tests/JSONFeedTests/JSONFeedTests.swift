import XCTest
@testable import JSONFeed

class JSONFeedTests: XCTestCase {
    
    static var allTests: [(String, (JSONFeedTests) -> () -> Void)] = [
        ("testVariousFiles", testVariousFiles),
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
        
        // The JSON Feed specification states that "If an id is presented as a number or other type, a JSON Feed reader must coerce it to a string.". The strict type system in Swift doesn't like this, so this will test our workaround.
        assertDecoding(ofFile: "alternateItemIdTypes", isSuccessful: true)
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
