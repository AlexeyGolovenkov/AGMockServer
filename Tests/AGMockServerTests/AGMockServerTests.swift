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
        AGMRequestLog.main.clear()
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
        
        let url = URL(string: "https://localhost/echo?param1=value1&param2=value2")!
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
        
        let url = URL(string: "https://localhost/echo?param1=value1&param2=value2")!
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
        let url = URL(string: "https://localhost/echo?param1=value1&param2=value2")!
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
        let url = URL(string: "https://localhost/echo?param1=value1&param2=value2")!
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
}

private extension AGMockServerTests {
    
    enum Constants {
        static let externalURL = "https://example.com"
    }
}

