import Foundation
import XCTest

@testable import AGMockServer

var server = AGMockServer.shared
var session: URLSession!

final class AGMockServerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        if session == nil {
            session = server.hackedSession(for: URLSession.shared)
        }
        server.clearLogs()
    }
    
    override func tearDown() {
        server.unregisterAllHandlers()
        super.tearDown()
    }
    
    func testRegistration() throws {
        XCTAssertTrue(session.configuration.protocolClasses?.first == AGMURLProtocol.self, "Session not hacked")
    }
        
    /// Tests echo handler
    /// Sends a request to echo-REST and expects the parameters sent in the response, wrapped in a JSON object
    func testEcho() {
        server.registerHandler(EchoHandler())
        
        let url = Constants.echoURL
        let expectation = self.expectation(description: "Echo expectation")
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response.count == 2, "Wrong response: \(response)")
                XCTAssertTrue(response["param1"] == "value1", "Wrong response: \(response)")
                XCTAssertTrue(response["param2"] == "value2", "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
        let log = AGMRequestLog.main.log()
        XCTAssertTrue(log.count == 1, "Wrong number of log messages: \(log.count)")
        XCTAssertTrue(log.first == url, "Wrong log: \(log)")
    }
    
    /// Tests custom response
    /// Sends a request to echo-REST but forces server to send another response, not the default one
    func testCustomResponse() throws {
        server.registerHandler(EchoHandler())
        
        let url = Constants.echoURL
        let expectation = self.expectation(description: "Custom response expectation")
        
        // Let's prepare custom response
        var response = AGMockServer.CustomResponse()
        response.setResponseBody(["param":"value"])
        server.prepareResponse(response, for: url)
        
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response.count == 1, "Wrong response: \(response)")
                XCTAssertTrue(response["param"] == "value", "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        
        
        wait(for: [expectation], timeout: 5)
        let log = AGMRequestLog.main.log()
        XCTAssertTrue(log.count == 1, "Wrong number of log messages: \(log.count)")
        XCTAssertTrue(log.first == url, "Wrong log: \(log)")
    }
    
    func testSeveralCustomReponses() {
        server.registerHandler(EchoHandler())
        let url = Constants.echoURL
        defer {
            // Remove responses prepared in this test to not break other tests in case of failure
            server.removeResponse(for: url, count: 2)
        }
        
        let expectation = self.expectation(description: "Custom response expectation")
        
        // Let's prepare custom response
        var response = AGMockServer.CustomResponse()
        response.setResponseBody(["param":"value"])
        server.prepareResponse(response, for: url, count: 2)
        
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response == ["param": "value"], "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
        var log = AGMRequestLog.main.log()
        XCTAssertTrue(log.count == 1, "Wrong number of log messages: \(log.count)")
        XCTAssertTrue(log.first == url, "Wrong log: \(log)")
        
        let secondExpectation = self.expectation(description: "Second attempt")
        // second request
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                secondExpectation.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response == ["param": "value"], "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            secondExpectation.fulfill()
        }.resume()
        
        wait(for: [secondExpectation], timeout: 5)
        log = AGMRequestLog.main.log()
        XCTAssertTrue(log.count == 2, "Wrong number of log messages: \(log.count)")
        
        let thirdExpectatin = self.expectation(description: "Third attempt")
        // second request
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                thirdExpectatin.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response == ["param1": "value1", "param2": "value2"], "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            thirdExpectatin.fulfill()
        }.resume()
        
        wait(for: [thirdExpectatin], timeout: 5)
        log = AGMRequestLog.main.log()
        XCTAssertTrue(log.count == 3, "Wrong number of log messages: \(log.count)")
    }
    
    func testRemovePreparedResponses() {
        server.registerHandler(EchoHandler())
        let url = Constants.echoURL
        defer {
            // Remove responses prepared in this test to not break other tests in case of failure
            server.removeResponse(for: url, count: 8)
        }
        
        let expectation = self.expectation(description: "Custom response expectation")
        
        // Let's prepare custom response
        var response = AGMockServer.CustomResponse()
        response.setResponseBody(["param":"value"])
        server.prepareResponse(response, for: url, count: 8)
        
        XCTAssertTrue(AGMURLProtocol.predefinedResponses.storage.count == 8)
        server.removeResponse(for: url)
        XCTAssertTrue(AGMURLProtocol.predefinedResponses.storage.count == 7)
        
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response == ["param": "value"], "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
        XCTAssertTrue(AGMURLProtocol.predefinedResponses.storage.count == 6)
        server.removeResponse(for: url, count: 6)
        XCTAssertTrue(AGMURLProtocol.predefinedResponses.storage.count == 0)
    }
    
    func testCorrectResourceHandler() {
        server.registerResponse(for: "localhost", with: "response.json", in: .module)
        
        let url = URL(string: "https://localhost/any/rest")!
        let expectation = self.expectation(description: "Correct resource handler expectation")
        
        session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            do {
                XCTAssertTrue((response as? HTTPURLResponse)?.statusCode == 200, "Wrong status code")
                let responseBody = try JSONDecoder().decode([String: String].self, from: data)
                XCTAssertTrue(responseBody == ["string": "Title"], "Wrong response: \(responseBody)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testIncorrectResourceHandler() {
        let bundle = Bundle.module
        let handler = AGMResourceBasedHandler(for: "localhost", with: "wrongResponse", ext: "json", in: bundle)
        server.registerHandler(handler)
        
        let url = URL(string: "https://localhost/any/rest")!
        let expectation = self.expectation(description: "Correct resource handler expectation")
        
        session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            XCTAssertTrue((response as? HTTPURLResponse)?.statusCode == 404, "Wrong status code")
            XCTAssertTrue(data.isEmpty)
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testNetworkAllowed() {
        guard let url = URL(string: Constants.externalURL) else {
            XCTFail("Wrong url")
            return
        }
        let expectation = self.expectation(description: "Correct resource handler expectation")
        
        session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            XCTAssertTrue((response as? HTTPURLResponse)?.statusCode == 200, "Wrong status code")
            XCTAssertTrue(data.count > 100)
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 30)
    }
    
    func testNetworkForbidden() {
        guard let url = URL(string: Constants.externalURL) else {
            XCTFail("Wrong url")
            return
        }
        let expectation = self.expectation(description: "Correct resource handler expectation")
        server.isNetworkBlocked = true
        session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            if let code = (response as? HTTPURLResponse)?.statusCode {
                XCTAssertTrue(code == 403, "Wrong status code: \(code)")
            } else {
                XCTFail("Status code not obtained")
            }
            do {
                let responseBody = try JSONDecoder().decode([String: String].self, from: data)
                XCTAssertTrue(responseBody == ["error": "Forbidden"], "Wrong response: \(responseBody)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
        server.isNetworkBlocked = false
    }
    
    func testClearLogs() {
        server.registerHandler(EchoHandler())
        
        let url = Constants.echoURL
        let expectation = self.expectation(description: "Echo expectation")
        session.dataTask(with: url) { data, _, error in
            expectation.fulfill()
        }.resume()
        
        wait(for: [expectation], timeout: 5)
        let requests = server.requests
        XCTAssertTrue(requests.count == 1, "Wrong number of log messages: \(requests.count)")
        XCTAssertTrue(requests.first == url, "Wrong log: \(requests)")
        
        let responses = server.responses
        XCTAssertTrue(responses.count == 1, "Wrong number of log messages: \(responses.count)")
        XCTAssertTrue(responses.first?.response.url == url, "Wrong log: \(responses)")
        
        server.clearLogs()
        XCTAssertTrue(server.requests.count == 0, "Wrong number of requests in server log: \(server.requests)")
        XCTAssertTrue(server.responses.count == 0, "Wrong number of requests in server log: \(server.responses)")
    }
    
    func testExecuteBlock() async throws {
        server.registerHandler(EchoHandler())
        XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.count == 1)
        let echoHandler = ErrorHandler()
        
        try await TimeoutTask(1_000_000_000) {
            try await server.execute(withHandlers: [echoHandler]) {
                XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.count == 2)
                let echoData = try await session.data(from: Constants.echoURL)
                let echoResponseBody = try JSONDecoder().decode([String: String].self, from: echoData.0)
                XCTAssertTrue(echoResponseBody == ["param1": "value1", "param2": "value2"], "Wrong response: \(echoResponseBody)")
                let errorData = try await session.data(from: Constants.errorURL)
                let errorResponseBody = try JSONDecoder().decode([String: String].self, from: errorData.0)
                XCTAssertTrue(errorResponseBody == ["error": "Error"], "Wrong response: \(errorResponseBody)")
            }
        }.value
        XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.count == 1)
    }
    
    func testDetailedLog() async throws {
        server.registerHandler(EchoHandler())
        try await TimeoutTask(1_000_000_000) {
            let _ = try await session.data(from: Constants.echoURL)
        }.value
        
        let log = server.detailedLog
        XCTAssertTrue(log.count == 1, "Wrong number of items in detailed log: \(log.count) instead of 1")
        guard let firstItem = log.first else {
            XCTFail("No items in detailed log")
            return
        }
        
        XCTAssertTrue(firstItem.request.url?.absoluteString.contains("echo") == true)
        XCTAssertEqual(firstItem.request.httpMethod, "GET")
        
        server.clearLogs()
        XCTAssertTrue(server.detailedLog.isEmpty, "Detailed log not cleared")
        guard let data = firstItem.responseData else {
            XCTFail("No data in response")
            return
        }
        let echoResponseBody = try JSONDecoder().decode([String: String].self, from: data)
        XCTAssertTrue(echoResponseBody == ["param1": "value1", "param2": "value2"], "Wrong response: \(echoResponseBody)")
        
        XCTAssertTrue(firstItem.response?.statusCode == 200, "Wrong status code: \(String(describing: firstItem.response?.statusCode))")
    }
    
    func testIsCollectedDetailedData() async throws {
        defer {
            server.isCollectingDetailedData = true
        }
        
        server.registerHandler(EchoHandler())
        server.isCollectingDetailedData = false
        try await TimeoutTask(1_000_000_000) {
            let _ = try await session.data(from: Constants.echoURL)
        }.value
     
        XCTAssertTrue(server.detailedLog.isEmpty, "Detailed log must be empty")
        
        server.isCollectingDetailedData = true
        try await TimeoutTask(1_000_000_000) {
            let _ = try await session.data(from: Constants.echoURL)
        }.value
        XCTAssertTrue(server.detailedLog.count == 1, "Wrong number of items in detailed log: \(server.detailedLog.count) instead of 1")
    }
}

private extension AGMockServerTests {
    
    enum Constants {
        static let externalURL = "https://example.com"
        static let echoURL = URL(string: "https://localhost/echo?param1=value1&param2=value2")!
        static let errorURL = URL(string: "https://localhost/error")!
    }
}
