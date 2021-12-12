import Foundation
import XCTest

@testable import AGMockServer

var server = AGMockServer()
var session: URLSession!

final class AGFakeServerTests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        if session == nil {
            session = server.hackedSession(for: URLSession.shared)
        }
        AGMRequestLog.main.clear()
    }
    
    override func tearDown() {
        AGMRequestHandlersFactory.clearAll()
        super.tearDown()
    }
    
    func testRegistration() throws {
        XCTAssertTrue(session.configuration.protocolClasses?.first == AGMURLProtocol.self, "Session not hacked")
    }
    
    func testEcho() {
        AGMRequestHandlersFactory.add(handler: EchoHandler())
        
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
    
    func testCustomResponse() throws {
        defer {
            server.autoHandling = true
        }
        AGMRequestHandlersFactory.add(handler: EchoHandler())
        server.autoHandling = false
        
        let urlString = "https://localhost/echo?param1=value1&param2=value2"
        let url = URL(string: urlString)!
        let expectation = self.expectation(description: "Custom response expectation")
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
        RunLoop.main.run(until: Date() + 0.1) // Server need sume time to create response handler
        var response = AGMockServer.CustomResponse()
        response.stringValue = "{\"param\":\"value\"}"
        try server.send(response, for: url)
        wait(for: [expectation], timeout: 5)
        let log = AGMRequestLog.main.log()
        XCTAssertTrue(log.count == 1, "Wrong number of log messages: \(log.count)")
        XCTAssertTrue(log.first == url, "Wrong log: \(log)")
    }
}

