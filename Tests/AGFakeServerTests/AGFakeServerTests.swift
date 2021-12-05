import Foundation
import XCTest

@testable import AGFakeServer

final class AGFakeServerTests: XCTestCase {
        
    var server = AGFakeServer()
    var session: URLSession!
    
    override func setUp() {
        super.setUp()
        if session == nil {
            session = server.register(for: URLSession.shared)
        }
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
    }
}

