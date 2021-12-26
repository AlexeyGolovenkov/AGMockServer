import Foundation
import XCTest

@testable import AGMockServer

var server = AGMockServer()
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
        response.setValue(["param":"value"])
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
        response.setValue(["param":"value"])
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
        
        let secondExpectatin = self.expectation(description: "Second attempt")
        // second request
        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                secondExpectatin.fulfill()
                return
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response == ["param": "value"], "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            secondExpectatin.fulfill()
        }.resume()
        
        wait(for: [secondExpectatin], timeout: 5)
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
        response.setValue(["param":"value"])
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
}
