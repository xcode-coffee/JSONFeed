
import Foundation

public extension JSONFeed {
    
    public enum FetchError: Error {
        case invalidPath
        case httpStatusCode
    }
    
    private static let session = URLSession(configuration: URLSessionConfiguration.default)
    
    public static func fetch(_ path: String, completionHandler: @escaping (JSONFeed?, Error?) -> Void) {
        
        guard let url = URL(string: path) else {
            completionHandler(nil, FetchError.invalidPath)
            return
        }
        
        let task = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                guard case 200..<300 = httpResponse.statusCode else {
                    completionHandler(nil, FetchError.httpStatusCode)
                    return
                }
            }
            
            do {
                let feed = try JSONFeed.make(from: data!)
                completionHandler(feed, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
        
        task.resume()
    }
}
