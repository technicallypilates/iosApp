import XCTest
@testable import TechnicallyPilates

class NetworkManagerTests: XCTestCase {
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
    }
    
    override func tearDown() {
        networkManager = nil
        super.tearDown()
    }
    
    func testPauseNonEssentialRequests() {
        // Create test requests with different priorities
        let highPriorityRequest = NetworkRequest(
            request: URLRequest(url: URL(string: "https://test.com/high")!),
            retryCount: 3,
            timeout: 30,
            priority: .high
        )
        
        let lowPriorityRequest = NetworkRequest(
            request: URLRequest(url: URL(string: "https://test.com/low")!),
            retryCount: 3,
            timeout: 30,
            priority: .low
        )
        
        // Add requests to queue
        networkManager.requestQueue = [highPriorityRequest, lowPriorityRequest]
        
        // Pause non-essential requests
        networkManager.pauseNonEssentialRequests()
        
        // Verify only high priority request remains
        XCTAssertEqual(networkManager.requestQueue.count, 1)
        XCTAssertEqual(networkManager.requestQueue.first?.priority, .high)
    }
    
    func testPerformRequestWithCache() async throws {
        // Create a test request
        let url = URL(string: "https://test.com")!
        let request = URLRequest(url: url)
        
        // Mock successful response
        let mockData = try JSONEncoder().encode(["test": "data"])
        let mockResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        // Create URLProtocol mock
        URLProtocolMock.mockResponses[url] = (mockData, mockResponse, nil)
        
        // Perform request
        let result: [String: String] = try await networkManager.performRequest(
            request,
            retryCount: 1,
            timeout: 5,
            priority: .normal,
            useCache: true
        )
        
        // Verify result
        XCTAssertEqual(result["test"], "data")
    }
    
    func testPerformRequestWithError() async {
        // Create a test request
        let url = URL(string: "https://test.com")!
        let request = URLRequest(url: url)
        
        // Mock error response
        let mockError = NSError(domain: "test", code: -1, userInfo: nil)
        URLProtocolMock.mockResponses[url] = (nil, nil, mockError)
        
        // Perform request and expect error
        do {
            let _: [String: String] = try await networkManager.performRequest(
                request,
                retryCount: 1,
                timeout: 5,
                priority: .normal,
                useCache: false
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - URLProtocol Mock

class URLProtocolMock: URLProtocol {
    static var mockResponses: [URL: (Data?, URLResponse?, Error?)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let (data, response, error) = URLProtocolMock.mockResponses[url] else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let response = response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}