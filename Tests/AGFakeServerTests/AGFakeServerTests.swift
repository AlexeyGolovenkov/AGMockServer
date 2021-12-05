import Foundation
import XCTest

@testable import AGFakeServer

var server = AGFakeServer()
var session: URLSession!

final class AGFakeServerTests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        if session == nil {
            session = server.hackedSession(for: URLSession.shared)
        }
        AGRequestLog.main.clear()
    }
    
    override func tearDown() {
        FakeRESTRequestHandlersFactory.clearAll()
        super.tearDown()
    }
    
    func testRegistration() throws {
        XCTAssertTrue(session.configuration.protocolClasses?.first == FakeURLProtocol.self, "Session not hacked")
    }
    
    func testEcho() {
        FakeRESTRequestHandlersFactory.add(handler: EchoHandler())
        
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
        let log = AGRequestLog.main.log()
        XCTAssertTrue(log.count == 1, "Wrong number of log messages: \(log.count)")
        XCTAssertTrue(log.first == url, "Wrong log: \(log)")
        
        print("\(FakeHandlersStorage.shared.handlers.count)")
    }
}

